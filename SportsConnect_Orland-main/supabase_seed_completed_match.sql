-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║   SEED SCRIPT: PARTIDO COMPLETADO (para probar Agenda + Billetera)  ║
-- ║   Ejecutar en: Supabase → SQL Editor                                 ║
-- ║   Resultado esperado:                                                ║
-- ║     • Agenda  → bloque del horario visible en el grid               ║
-- ║     • Billetera → saldo del club aumenta con el hourly_rate         ║
-- ╚══════════════════════════════════════════════════════════════════════╝

DO $$
DECLARE
  -- ── IDs fijos (idempotente) ─────────────────────────────────────────────
  v_player1_id  UUID := 'aa000001-0000-0000-0000-000000000001';
  v_player2_id  UUID := 'aa000001-0000-0000-0000-000000000002';
  v_player3_id  UUID := 'aa000001-0000-0000-0000-000000000003';
  v_player4_id  UUID := 'aa000001-0000-0000-0000-000000000004';
  v_referee_id  UUID := 'aa000001-0000-0000-0000-000000000005';

  -- ── IDs resueltos dinámicamente ─────────────────────────────────────────
  v_padel_id    UUID;
  v_court_id    UUID;
  v_club_id     UUID;
  v_hourly_rate NUMERIC;

  -- ── Horario: HOY, franja diferente al seed anterior ─────────────────────
  v_match_date  DATE   := CURRENT_DATE;
  v_start_time  TEXT   := '15:00';   -- Formato 24h para compatibilidad
  v_end_time    TEXT   := '16:00';

  v_match_id    UUID;

BEGIN
  -- ════════════════════════════════════════════════════════════════════════
  -- PASO 1 · Resolver deporte Pádel
  -- ════════════════════════════════════════════════════════════════════════
  SELECT id INTO v_padel_id
    FROM public.sports
   WHERE lower(name) IN ('pádel','padel')
   LIMIT 1;

  IF v_padel_id IS NULL THEN
    RAISE EXCEPTION '❌ No se encontró el deporte Pádel/Padel en la tabla sports.';
  END IF;
  RAISE NOTICE '✅ Pádel ID: %', v_padel_id;

  -- ════════════════════════════════════════════════════════════════════════
  -- PASO 2 · Obtener primera cancha activa con hourly_rate > 0
  --          (necesario para que la billetera cuente este ingreso)
  -- ════════════════════════════════════════════════════════════════════════
  SELECT c.id, c.club_id, c.hourly_rate
    INTO v_court_id, v_club_id, v_hourly_rate
    FROM public.courts c
   WHERE c.is_active   = TRUE
     AND c.club_id IS NOT NULL
     AND c.hourly_rate > 0           -- solo canchas con precio configurado
   ORDER BY c.created_at
   LIMIT 1;

  -- Si no hay ninguna con hourly_rate, caer al fallback (agenda igual funciona)
  IF v_court_id IS NULL THEN
    SELECT c.id, c.club_id, COALESCE(c.hourly_rate, 0)
      INTO v_court_id, v_club_id, v_hourly_rate
      FROM public.courts c
     WHERE c.is_active = TRUE
       AND c.club_id IS NOT NULL
     ORDER BY c.created_at
     LIMIT 1;
  END IF;

  IF v_court_id IS NULL THEN
    RAISE EXCEPTION '❌ No hay canchas activas con club_id. Crea una cancha desde el panel de admin.';
  END IF;

  RAISE NOTICE '✅ Cancha: %  |  Club: %  |  hourly_rate: $%', v_court_id, v_club_id, v_hourly_rate;

  -- ════════════════════════════════════════════════════════════════════════
  -- PASO 3 · Upsert usuarios mock
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
  -- PASO 4 · Limpiar partido anterior en misma cancha/fecha/hora (idempotente)
  -- ════════════════════════════════════════════════════════════════════════
  DELETE FROM public.matches
   WHERE court_id       = v_court_id
     AND scheduled_date = v_match_date
     AND scheduled_time = v_start_time
     AND player1_id     = v_player1_id;

  -- ════════════════════════════════════════════════════════════════════════
  -- PASO 5 · Insertar partido COMPLETADO
  --          • match_mode = 'competitive' (no manual_reservation)
  --            → la billetera lo contará
  --          • status = 'completed'
  --            → la agenda lo mostrará en el grid de HOY
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
    scheduled_end_time,
    winner_id,
    score_data
  ) VALUES (
    v_court_id,
    v_padel_id,
    v_player1_id,
    v_player2_id,
    v_player3_id,
    v_player4_id,
    v_referee_id,
    '2v2',
    'competitive',          -- ← contado por la billetera (≠ manual_reservation)
    'Masculino',
    'completed',            -- ← aparece en agenda + billetera
    v_match_date,
    v_start_time,
    v_end_time,
    v_player1_id,           -- ganador = equipo 1 (arbitrario)
    '{"sets": [{"team1": 6, "team2": 3}, {"team1": 6, "team2": 4}]}'::jsonb
  )
  RETURNING id INTO v_match_id;

  RAISE NOTICE '✅ Partido COMPLETADO creado → ID: %', v_match_id;

  -- ════════════════════════════════════════════════════════════════════════
  -- PASO 6 · Resumen
  -- ════════════════════════════════════════════════════════════════════════
  RAISE NOTICE '──────────────────────────────────────────────────────────';
  RAISE NOTICE 'RESUMEN:';
  RAISE NOTICE '  Match ID     : %', v_match_id;
  RAISE NOTICE '  Cancha       : %', v_court_id;
  RAISE NOTICE '  Club         : %', v_club_id;
  RAISE NOTICE '  Fecha/Hora   : % %  →  %', v_match_date, v_start_time, v_end_time;
  RAISE NOTICE '  Status       : completed';
  RAISE NOTICE '  match_mode   : competitive (billetera lo contará)';
  RAISE NOTICE '  hourly_rate  : $%  (ingreso esperado en billetera)', v_hourly_rate;
  RAISE NOTICE '──────────────────────────────────────────────────────────';
  RAISE NOTICE '👉 Pasos siguientes:';
  RAISE NOTICE '   1. Recarga la app (hot restart)';
  RAISE NOTICE '   2. Club Admin → Agenda → navega a HOY → verifica bloque en 15:00';
  RAISE NOTICE '   3. Club Admin → Billetera → verifica saldo = $%', v_hourly_rate;
  RAISE NOTICE '──────────────────────────────────────────────────────────';

END $$;

-- ── VERIFICACIÓN (ejecutar suelto después del DO block) ─────────────────
-- SELECT m.id, m.status, m.match_mode, m.scheduled_date,
--        m.scheduled_time, m.scheduled_end_time,
--        c.name AS court, c.hourly_rate,
--        c.club_id
--   FROM public.matches m
--   JOIN public.courts c ON c.id = m.court_id
--  WHERE m.player1_id = 'aa000001-0000-0000-0000-000000000001'::uuid
--    AND m.status = 'completed'
--  ORDER BY m.created_at DESC
--  LIMIT 5;

-- ── LIMPIEZA (ejecutar cuando ya no necesites el mock) ──────────────────
-- DELETE FROM public.matches WHERE player1_id = 'aa000001-0000-0000-0000-000000000001'::uuid;
