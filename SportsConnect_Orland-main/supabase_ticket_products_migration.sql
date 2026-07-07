-- Catálogo de productos de tickets: precios dinámicos para create_preference.
-- Ejecutar en el SQL Editor de Supabase (después de supabase_mp_webhook_migration.sql).

CREATE TABLE IF NOT EXISTS public.ticket_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_type TEXT NOT NULL UNIQUE CHECK (ticket_type IN ('singles', 'doubles')),
  price_clp NUMERIC(10, 0) NOT NULL CHECK (price_clp > 0),
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed inicial (idempotente): mismos precios que tenía la constante.
INSERT INTO public.ticket_products (ticket_type, price_clp)
VALUES ('singles', 500), ('doubles', 500)
ON CONFLICT (ticket_type) DO NOTHING;

-- RLS: lectura pública autenticada (la app muestra el precio en la tienda);
-- escritura solo server-side.
ALTER TABLE public.ticket_products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ticket_products_read ON public.ticket_products;
CREATE POLICY ticket_products_read ON public.ticket_products
  FOR SELECT TO authenticated USING (TRUE);
-- Sin policies de INSERT/UPDATE/DELETE: solo service_role puede modificar precios.
