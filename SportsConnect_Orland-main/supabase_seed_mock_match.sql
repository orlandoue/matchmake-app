-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║        SEED SCRIPT: MOCK CONFIRMED MATCH (DEV / QA ONLY)            ║
-- ║  Ejecutar en: Supabase → SQL Editor                                  ║
-- ║  Propósito: Crear un escenario completo (4 jugadores + árbitro +     ║
-- ║             cancha bloqueada) sin pasar por el flujo de matchmaking. ║
-- ╚══════════════════════════════════════════════════════════════════════╝

DO $$
DECLARE
  -- ── IDs fijos para que el script sea idempotente (re-ejecutable) ────────
  v_player1_id  UUID := 'aa000001-0000-0000-0000-000000000001';
  v_player2_id  UUID := 'aa000001-0000-0000-0000-000000000002';
  v_player3_id  UUID := 'aa000001-0000-0000-0000-000000000003';
  v_player4_id  UUID := 'aa000001-0000-0000-0000-000000000004';
  v_referee_id  UUID := 'aa000001-0000-0000-0000-000000000005';

  -- ── IDs de negocio — adaptados a tu BD ─────────────────────────────────
  v_padel_id    UUID;   -- se busca dinámicamente
  v_court_id    UUID;   -- primera cancha activa disponible
  v_club_id     UUID;   -- club de esa cancha

  -- ── Horario del partido de prueba ───────────────────────────────────────
  v_match_date  DATE   := CURRENT_DATE;
  v_start_time  TEXT   := '10:00 AM';
  v_end_time    TEXT   := '11:00 AM';

  v_match_id    UUID;

BEGIN
  -- ════════════════════════════════════════════════════════════════════════
  -- PASO 1 · Resolver deporte "Pádel"
  -- ════════════════════════════════════════════════════════════════════════
  SELECT id INTO v_padel_id
    FROM public.sports
   WHERE lower(name) IN ('pádel','padel')
   LIMIT 1;

  IF v_padel_id IS NULL THEN
    RAISE EXCEPTION 'No se encontró el deporte Pádel. Ejecuta supabase_cleanup_seed_sports.sql primero.';
  END IF;
  RAISE NOTICE '✅ Pádel ID: %', v_padel_id;

  -- ════════════════════════════════════════════════════════════════════════
  -- PASO 2 · Obtener la primera cancha activa (con su club)
  -- ════════════════════════════════════════════════════════════════════════
  SELECT c.id, c.club_id
    INTO v_court_id, v_club_id
    FROM public.courts c
   WHERE c.is_active = TRUE
     AND c.club_id IS NOT NULL
   ORDER BY c.created_at
   LIMIT 1;

  IF v_court_id IS NULL THEN
    RAISE EXCEPTION 'No hay canchas activas con club_id. Crea una cancha desde el panel de admin.';
  END IF;
  RAISE NOTICE '✅ Cancha ID: %  |  Club ID: %', v_court_id, v_club_id;

  -- ════════════════════════════════════════════════════════════════════════
  -- PASO 3 · Asegurarse de que los 5 usuarios mock existen en public.users
  --          (se hace un UPSERT, no destruye cuentas reales)
  -- ════════════════════════════════════════════════════════════════════════
  INSERT INTO public.users (id, email, name, role, is_profile_complete, balance)
  VALUES
    (v_player1_id, 'mock_player1@dev.test', 'Mock Player 1', 'player',  TRUE, 0),
    (v_player2_id, 'mock_player2@dev.test', 'Mock Player 2', 'player',  TRUE, 0),
    (v_player3_id, 'mock_player3@dev.test', 'Mock Player 3', 'player',  TRUE, 0),
    (v_player4_id, 'mock_player4@dev.test', 'Mock Player 4', 'player',  TRUE, 0),
    (v_referee_id, 'mock_referee@dev.test', 'Mock Referee',  'referee', TRUE, 0)
  ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        role = EXCLUDED.role;

  RAISE NOTICE '✅ Usuarios mock listos.';

  -- ════════════════════════════════════════════════════════════════════════
  -- PASO 4 · Eliminar cualquier partido mock previo en esa cancha/fecha/hora
  --          (mantiene el script idempotente)
  -- ════════════════════════════════════════════════════════════════════════
  DELETE FROM public.matches
   WHERE court_id       = v_court_id
     AND scheduled_date = v_match_date
     AND scheduled_time = v_start_time
     AND player1_id     = v_player1_id;

  -- ════════════════════════════════════════════════════════════════════════
  -- PASO 5 · Insertar el partido confirmado (estado = confirmed)
  -- ════════════════════════════════════════════════════════════════════════
  INSERT INTO public.matches (
    court_id,
    sport_id,
    player1_id,
    player2_id,
    player3_id,
    player4_id,
    referee_id,
    match_type,
    match_mode,
    match_category,
    status,
    scheduled_date,
    scheduled_time,
    scheduled_end_time
  ) VALUES (
    v_court_id,
    v_padel_id,
    v_player1_id,
    v_player2_id,
    v_player3_id,
    v_player4_id,
    v_referee_id,
    '2v2',
    'competitive',
    'Masculino',
    'confirmed',
    v_match_date,
    v_start_time,
    v_end_time
  )
  RETURNING id INTO v_match_id;

  RAISE NOTICE '✅ Partido mock creado  ID: %', v_match_id;

  -- ════════════════════════════════════════════════════════════════════════
  -- PASO 6 · Verificación visual
  -- ════════════════════════════════════════════════════════════════════════
  RAISE NOTICE '──────────────────────────────────────────────────────────';
  RAISE NOTICE 'RESUMEN DEL ESCENARIO DE PRUEBA:';
  RAISE NOTICE '  Match ID   : %', v_match_id;
  RAISE NOTICE '  Cancha     : %  (club: %)', v_court_id, v_club_id;
  RAISE NOTICE '  Fecha      : %  %  →  %', v_match_date, v_start_time, v_end_time;
  RAISE NOTICE '  Estado     : confirmed';
  RAISE NOTICE '  Jugadores  : % / % / % / %', v_player1_id, v_player2_id, v_player3_id, v_player4_id;
  RAISE NOTICE '  Árbitro    : %', v_referee_id;
  RAISE NOTICE '──────────────────────────────────────────────────────────';
  RAISE NOTICE '✅ Script completado. Recarga la Agenda del Club para ver el bloqueo.';

END $$;

-- ── VERIFICACIÓN OPCIONAL (ejecutar suelto para ver la fila) ────────────
-- SELECT m.id, m.status, m.scheduled_date, m.scheduled_time, m.scheduled_end_time,
--        c.name AS court, u1.name AS p1, u2.name AS p2, u3.name AS p3, u4.name AS p4,
--        ref.name AS referee
--   FROM public.matches m
--   JOIN public.courts c ON c.id = m.court_id
--   JOIN public.users u1 ON u1.id = m.player1_id
--   LEFT JOIN public.users u2 ON u2.id = m.player2_id
--   LEFT JOIN public.users u3 ON u3.id = m.player3_id
--   LEFT JOIN public.users u4 ON u4.id = m.player4_id
--   LEFT JOIN public.users ref ON ref.id = m.referee_id
--  WHERE m.player1_id = 'aa000001-0000-0000-0000-000000000001'::uuid;

-- ── LIMPIEZA: Ejecutar este bloque cuando quieras borrar los datos mock ──
-- DELETE FROM public.matches WHERE player1_id = 'aa000001-0000-0000-0000-000000000001'::uuid;
-- DELETE FROM public.users   WHERE id IN (
--   'aa000001-0000-0000-0000-000000000001'::uuid,
--   'aa000001-0000-0000-0000-000000000002'::uuid,
--   'aa000001-0000-0000-0000-000000000003'::uuid,
--   'aa000001-0000-0000-0000-000000000004'::uuid,
--   'aa000001-0000-0000-0000-000000000005'::uuid
-- );
