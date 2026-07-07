// create_preference — crea una preferencia de Mercado Pago Checkout Pro.
//
// Seguridad:
//  - verify_jwt = true (config.toml): solo usuarios autenticados llegan aquí.
//  - El user_id y el email se derivan del JWT, NO del body.
//  - El precio se calcula SIEMPRE en el servidor; el cliente solo envía
//    cantidad y tipo de ticket.
//  - El access token de MP vive en secrets de la función (MP_ACCESS_TOKEN),
//    nunca en la app.
//
// Request (POST, JSON):  { ticket_quantity: number, ticket_type: 'singles'|'doubles' }
// Response 200:          { preference_id, init_point, external_reference }

import { createClient } from "npm:@supabase/supabase-js@2";

const MP_API = "https://api.mercadopago.com";

// Los precios viven en public.ticket_products (fuente de verdad, editable
// sin redesplegar). El cliente nunca envía montos.
const CURRENCY = "CLP";
const MAX_QUANTITY = 100;

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  const mpAccessToken = Deno.env.get("MP_ACCESS_TOKEN");
  if (!mpAccessToken) {
    console.error("MP_ACCESS_TOKEN secret is not configured");
    return json(500, { error: "payment_provider_not_configured" });
  }

  // ── Identificar al usuario desde su JWT (no confiar en el body) ───────────
  const authHeader = req.headers.get("Authorization") ?? "";
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData?.user) {
    return json(401, { error: "unauthorized" });
  }
  const user = userData.user;

  // ── Validar input ──────────────────────────────────────────────────────────
  let body: { ticket_quantity?: unknown; ticket_type?: unknown };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "invalid_json" });
  }

  const ticketType = body.ticket_type;
  const quantity = body.ticket_quantity;
  if (ticketType !== "singles" && ticketType !== "doubles") {
    return json(400, { error: "invalid_ticket_type" });
  }
  if (
    typeof quantity !== "number" || !Number.isInteger(quantity) ||
    quantity < 1 || quantity > MAX_QUANTITY
  ) {
    return json(400, { error: "invalid_ticket_quantity" });
  }

  // ── Precio real desde la BD (conexión interna, service role) ──────────────
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  const { data: product, error: productError } = await admin
    .from("ticket_products")
    .select("price_clp, active")
    .eq("ticket_type", ticketType)
    .maybeSingle();
  if (productError) {
    console.error("ticket_products lookup failed:", productError.message);
    return json(500, { error: "pricing_unavailable" });
  }
  if (!product || !product.active) {
    return json(400, { error: "product_not_available" });
  }
  const unitPrice = Number(product.price_clp);
  if (!Number.isFinite(unitPrice) || unitPrice <= 0) {
    console.error(`Invalid price for ${ticketType}: ${product.price_clp}`);
    return json(500, { error: "pricing_unavailable" });
  }

  const typeLabel = ticketType === "doubles" ? "Dobles" : "Singles";
  const externalReference =
    `user_${user.id}_type_${ticketType}_qty_${quantity}_ts_${Date.now()}`;

  // ── Crear preferencia en Mercado Pago ─────────────────────────────────────
  const preferenceBody = {
    items: [{
      title: `Matchmake Ticket ${typeLabel}`,
      description: `${quantity} ticket${quantity > 1 ? "s" : ""} ${typeLabel} para Matchmake`,
      quantity,
      unit_price: unitPrice,
      currency_id: CURRENCY,
    }],
    payer: { email: user.email },
    back_urls: {
      success: "sportsconnect://payment/success",
      failure: "sportsconnect://payment/failure",
      pending: "sportsconnect://payment/pending",
    },
    auto_return: "approved",
    external_reference: externalReference,
    notification_url: `${Deno.env.get("SUPABASE_URL")}/functions/v1/mp_webhook`,
    metadata: {
      user_id: user.id,
      ticket_type: ticketType,
      ticket_quantity: quantity,
      total_amount: unitPrice * quantity,
    },
  };

  const mpResponse = await fetch(`${MP_API}/checkout/preferences`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${mpAccessToken}`,
      // Idempotencia a nivel MP ante reintentos de la app
      "X-Idempotency-Key": externalReference,
    },
    body: JSON.stringify(preferenceBody),
  });

  if (!mpResponse.ok) {
    const errBody = await mpResponse.text();
    console.error(`MP preference error ${mpResponse.status}: ${errBody}`);
    return json(502, { error: "mercadopago_error" });
  }

  const preference = await mpResponse.json();

  // ── Registrar transacción pendiente (service role) para que la app pueda
  //    consultar su estado; el webhook la marcará como approved. ─────────────
  const { error: insertError } = await admin.from("ticket_transactions").insert({
    user_id: user.id,
    type: "purchase",
    ticket_type: ticketType,
    quantity,
    amount: unitPrice * quantity,
    currency: CURRENCY,
    payment_status: "pending",
    external_reference: externalReference,
    mercadopago_preference_id: preference.id,
  });
  if (insertError) {
    // No bloquear el checkout por esto, pero dejar rastro en logs.
    console.error("Failed to insert pending transaction:", insertError.message);
  }

  return json(200, {
    preference_id: preference.id,
    init_point: preference.init_point,
    external_reference: externalReference,
    unit_price: unitPrice,
    total_amount: unitPrice * quantity,
    currency: CURRENCY,
  });
});
