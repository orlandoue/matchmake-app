-- Migración para el flujo seguro de pagos server-side (Fase 2).
-- Ejecutar en el SQL Editor de Supabase.

-- 1. Columnas para trazar la preferencia de MP y correlacionar el webhook.
ALTER TABLE public.ticket_transactions
  ADD COLUMN IF NOT EXISTS external_reference TEXT,
  ADD COLUMN IF NOT EXISTS mercadopago_preference_id TEXT;

CREATE INDEX IF NOT EXISTS idx_ticket_tx_external_reference
  ON public.ticket_transactions (external_reference);
CREATE INDEX IF NOT EXISTS idx_ticket_tx_mp_payment_id
  ON public.ticket_transactions (mercadopago_payment_id);

-- 2. RPC atómica de acreditación (la invoca mp_webhook con service role).
--    UPSERT + incremento en una sola sentencia: sin carreras read-then-write.
CREATE OR REPLACE FUNCTION public.increment_tickets(
  p_user_id UUID,
  p_ticket_type TEXT,
  p_quantity INT
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_ticket_type NOT IN ('singles', 'doubles') THEN
    RAISE EXCEPTION 'invalid ticket_type: %', p_ticket_type;
  END IF;
  IF p_quantity < 1 THEN
    RAISE EXCEPTION 'invalid quantity: %', p_quantity;
  END IF;

  INSERT INTO public.tickets (user_id, singles_quantity, doubles_quantity, updated_at)
  VALUES (
    p_user_id,
    CASE WHEN p_ticket_type = 'singles' THEN p_quantity ELSE 0 END,
    CASE WHEN p_ticket_type = 'doubles' THEN p_quantity ELSE 0 END,
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    singles_quantity = public.tickets.singles_quantity
      + CASE WHEN p_ticket_type = 'singles' THEN p_quantity ELSE 0 END,
    doubles_quantity = public.tickets.doubles_quantity
      + CASE WHEN p_ticket_type = 'doubles' THEN p_quantity ELSE 0 END,
    updated_at = NOW();
END;
$$;

-- Solo el service role (y postgres) pueden acreditar; nunca el cliente.
REVOKE EXECUTE ON FUNCTION public.increment_tickets(UUID, TEXT, INT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.increment_tickets(UUID, TEXT, INT) FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.increment_tickets(UUID, TEXT, INT) TO service_role;

-- 3. Endurecer RLS: los clientes NO deben poder escribir su propio saldo.
--    (Revisar en el dashboard que no exista una policy de UPDATE/INSERT
--    sobre public.tickets para 'authenticated'; el saldo solo lo mueven
--    las funciones del servidor. La lectura del propio saldo sí se permite.)
-- Ejemplo de política de solo-lectura del propio registro:
--   CREATE POLICY tickets_select_own ON public.tickets
--     FOR SELECT TO authenticated USING (auth.uid() = user_id);
