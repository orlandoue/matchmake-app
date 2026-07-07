-- ====================================================================
-- SUPABASE MIGRATION: FIX CLUB ADMIN BOOKING AND AGENDA BUG
-- Ejecuta este script en el SQL Editor de Supabase
-- ====================================================================

DO $$
BEGIN

  -- 1. Actualizar Check Constraints de 'matches'
  -- Reemplazar el constraint para permitir el modo de partido "manual_reservation"
  ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS matches_match_mode_check;
  ALTER TABLE public.matches ADD CONSTRAINT matches_match_mode_check 
    CHECK (match_mode IN ('competitive', 'random', 'friendly', 'private', 'team_up', 'manual_reservation', 'manual'));

  -- Reemplazar el constraint para permitir el status "blocked"
  ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS matches_status_check;
  ALTER TABLE public.matches ADD CONSTRAINT matches_status_check 
    CHECK (status IN ('pending', 'waiting_for_opponent', 'matched', 'confirmed', 'in_progress', 'completed', 'cancelled', 'blocked'));

  RAISE NOTICE '✅ Restricciones (Constraints) actualizadas correctamente.';
END $$;


-- 2. Políticas RLS (Row Level Security) para dueños de recintos (Club Admins)

-- A. Permitir a los Club Admins ver (SELECT) todos los partidos de sus canchas
DROP POLICY IF EXISTS "Admins can view court matches" ON public.matches;
CREATE POLICY "Admins can view court matches" ON public.matches
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.courts c
      JOIN public.clubs cb ON c.club_id = cb.id
      WHERE c.id = matches.court_id AND cb.owner_id = auth.uid()
    )
  );

-- B. Permitir a los Club Admins crear/bloquear (INSERT) reservas en sus canchas
DROP POLICY IF EXISTS "Admins can insert court matches" ON public.matches;
CREATE POLICY "Admins can insert court matches" ON public.matches
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.courts c
      JOIN public.clubs cb ON c.club_id = cb.id
      WHERE c.id = court_id AND cb.owner_id = auth.uid()
    )
  );

-- C. Permitir a los Club Admins actualizar (UPDATE) partidos en sus canchas
DROP POLICY IF EXISTS "Admins can update court matches" ON public.matches;
CREATE POLICY "Admins can update court matches" ON public.matches
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.courts c
      JOIN public.clubs cb ON c.club_id = cb.id
      WHERE c.id = matches.court_id AND cb.owner_id = auth.uid()
    )
  );

-- D. Permitir a los Club Admins eliminar/debsoquear (DELETE) reservas en sus canchas
DROP POLICY IF EXISTS "Admins can delete court matches" ON public.matches;
CREATE POLICY "Admins can delete court matches" ON public.matches
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.courts c
      JOIN public.clubs cb ON c.club_id = cb.id
      WHERE c.id = matches.court_id AND cb.owner_id = auth.uid()
    )
  );

-- Mensaje final
DO $$
BEGIN
  RAISE NOTICE '✅ Políticas RLS para administradores agregadas/corregidas exitosamente.';
END $$;
