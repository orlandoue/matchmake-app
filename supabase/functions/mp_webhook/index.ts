// mp_webhook — endpoint de notificaciones (webhooks/IPN) de Mercado Pago.
//
// Seguridad:
//  - verify_jwt = false (config.toml): Mercado Pago no envía JWT de Supabase.
//  - Se valida la firma HMAC `x-signature` de MP con MP_WEBHOOK_SECRET.
//  - NUNCA se confía en el payload: el estado del pago se re-consulta
//    directamente a la API de MP con MP_ACCESS_TOKEN.
//  - La acreditación usa la Service Role Key (bypassa RLS) y es idempotente
//    por mercadopago_payment_id: los reintentos de MP no acreditan dos veces.
//
// Flujo: MP notifica {type:'payment', data:{id}} → GET /v1/payments/:id →
// si status === 'approved' → marcar transacción approved + sumar tickets.

import { createClient } from "npm:@supabase/supabase-js@2";

const MP_API = "https://api.mercadopago.com";

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** Valida la firma x-signature de Mercado Pago (esquema ts/v1 con HMAC-SHA256). */
async function verifySignature(
  req: Request,
  dataId: string,
  secret: string,
): Promise<boolean> {
  const signature = req.headers.get("x-signature") ?? "";
  const requestId = req.headers.get("x-request-id") ?? "";

  const parts = Object.fromEntries(
    signature.split(",").map((p) => p.trim().split("=") as [string, string]),
  );
  const ts = parts["ts"];
  const v1 = parts["v1"];
  if (!ts || !v1) return false;

  // Manifest según docs de MP: id en minúsculas si es alfanumérico
  const manifest = `id:${dataId.toLowerCase()};request-id:${requestId};ts:${ts};`;

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(manifest),
  );
  const expected = Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return expected === v1;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  const mpAccessToken = Deno.env.get("MP_ACCESS_TOKEN");
  const webhookSecret = Deno.env.get("MP_WEBHOOK_SECRET");
  if (!mpAccessToken) {
    console.error("MP_ACCESS_TOKEN secret is not configured");
    return json(500, { error: "not_configured" });
  }

  // ── Extraer el payment id (viene en query ?data.id= o en el body) ─────────
  const url = new URL(req.url);
  let body: Record<string, unknown> = {};
  try {
    body = await req.json();
  } catch {
    /* algunos pings de MP llegan sin body JSON */
  }
  const topic = url.searchParams.get("type") ?? url.searchParams.get("topic") ??
    (body["type"] as string | undefined) ?? "";
  const paymentId = url.searchParams.get("data.id") ??
    url.searchParams.get("id") ??
    ((body["data"] as Record<string, unknown> | undefined)?.["id"] as
      | string
      | number
      | undefined)?.toString() ?? "";

  // Solo nos interesan eventos de pago; a todo lo demás respondemos 200
  // para que MP no reintente indefinidamente.
  if (!topic.includes("payment") || !paymentId) {
    return json(200, { ignored: true });
  }

  // ── Verificar firma (obligatoria si el secret está configurado) ───────────
  if (webhookSecret) {
    const valid = await verifySignature(req, paymentId, webhookSecret);
    if (!valid) {
      console.error(`Invalid x-signature for payment ${paymentId}`);
      return json(401, { error: "invalid_signature" });
    }
  } else {
    console.warn("MP_WEBHOOK_SECRET not set — skipping signature check");
  }

  // ── Re-consultar el pago a MP: única fuente de verdad ─────────────────────
  const payResponse = await fetch(`${MP_API}/v1/payments/${paymentId}`, {
    headers: { Authorization: `Bearer ${mpAccessToken}` },
  });
  if (!payResponse.ok) {
    console.error(`MP payment lookup failed: ${payResponse.status}`);
    // 500 → MP reintentará más tarde
    return json(500, { error: "payment_lookup_failed" });
  }
  const payment = await payResponse.json();

  const status: string = payment.status ?? "unknown";
  const metadata = payment.metadata ?? {};
  const userId: string | undefined = metadata.user_id;
  const ticketType: string | undefined = metadata.ticket_type;
  const quantity: number = Number(metadata.ticket_quantity ?? 0);
  const externalReference: string | undefined = payment.external_reference;

  if (!userId || (ticketType !== "singles" && ticketType !== "doubles") ||
    !Number.isInteger(quantity) || quantity < 1) {
    console.error(
      `Payment ${paymentId} has invalid metadata: ${JSON.stringify(metadata)}`,
    );
    return json(200, { ignored: "invalid_metadata" });
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ── Estados no aprobados: reflejarlos en la transacción pendiente ─────────
  if (status !== "approved") {
    if (externalReference) {
      await admin
        .from("ticket_transactions")
        .update({ payment_status: status, mercadopago_payment_id: String(paymentId) })
        .eq("external_reference", externalReference)
        .neq("payment_status", "approved");
    }
    return json(200, { status });
  }

  // ── Idempotencia: si este payment_id ya fue acreditado, no repetir ─────────
  const { data: existing } = await admin
    .from("ticket_transactions")
    .select("id")
    .eq("mercadopago_payment_id", String(paymentId))
    .eq("payment_status", "approved")
    .maybeSingle();
  if (existing) {
    return json(200, { status: "already_processed" });
  }

  // ── Marcar la transacción pendiente como aprobada (o crearla si no existe) ─
  const { data: updated } = await admin
    .from("ticket_transactions")
    .update({
      payment_status: "approved",
      mercadopago_payment_id: String(paymentId),
    })
    .eq("external_reference", externalReference ?? "")
    .neq("payment_status", "approved")
    .select("id");

  if (!updated || updated.length === 0) {
    await admin.from("ticket_transactions").insert({
      user_id: userId,
      type: "purchase",
      ticket_type: ticketType,
      quantity,
      amount: Number(payment.transaction_amount ?? 0),
      currency: payment.currency_id ?? "CLP",
      payment_status: "approved",
      external_reference: externalReference,
      mercadopago_payment_id: String(paymentId),
    });
  }

  // ── Acreditar tickets (RPC atómica; ver supabase_mp_webhook_migration.sql) ─
  const { error: creditError } = await admin.rpc("increment_tickets", {
    p_user_id: userId,
    p_ticket_type: ticketType,
    p_quantity: quantity,
  });
  if (creditError) {
    console.error(
      `CRITICAL: payment ${paymentId} approved but ticket credit failed: ${creditError.message}`,
    );
    // 500 → MP reintenta; la idempotencia evita duplicar la transacción,
    // pero como la acreditación falló, revertimos el estado para que el
    // próximo intento vuelva a entrar por el camino de acreditación.
    await admin
      .from("ticket_transactions")
      .update({ payment_status: "credit_failed" })
      .eq("mercadopago_payment_id", String(paymentId));
    return json(500, { error: "credit_failed" });
  }

  console.log(
    `✅ Payment ${paymentId} approved: +${quantity} ${ticketType} tickets for ${userId}`,
  );
  return json(200, { status: "approved", credited: quantity });
});
