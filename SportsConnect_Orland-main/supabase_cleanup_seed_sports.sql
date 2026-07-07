-- ═══════════════════════════════════════════════════════════════════
--  LIMPIEZA Y CONSOLIDACIÓN DE DEPORTES: Pádel y Tenis
--  Ejecuta este script completo en Supabase → SQL Editor
-- ═══════════════════════════════════════════════════════════════════

DO $$
DECLARE
  padel_id UUID;
  tenis_id UUID;
BEGIN
  -- 1. IDENTIFICAR O CREAR DEPORTES CANÓNICOS
  SELECT id INTO padel_id FROM sports WHERE lower(name) IN ('padel', 'pádel') LIMIT 1;
  IF padel_id IS NULL THEN
    INSERT INTO sports (name) VALUES ('Pádel') RETURNING id INTO padel_id;
  END IF;

  SELECT id INTO tenis_id FROM sports WHERE lower(name) IN ('tenis', 'tennis') AND lower(name) NOT LIKE '%table%' AND lower(name) NOT LIKE '%mesa%' LIMIT 1;
  IF tenis_id IS NULL THEN
    INSERT INTO sports (name) VALUES ('Tenis') RETURNING id INTO tenis_id;
  END IF;

  RAISE NOTICE 'Pádel ID: %', padel_id;
  RAISE NOTICE 'Tenis ID: %', tenis_id;

  -- 2. REASIGNAR REFERENCIAS AL DEPORTE CANÓNICO CORRESPONDIENTE
  -- Todo lo que suene a Padel va a 'padel_id'
  UPDATE courts SET sport_id = padel_id WHERE sport_id IN (SELECT id FROM sports WHERE lower(name) LIKE '%padel%' OR lower(name) LIKE '%pádel%') AND sport_id != padel_id;
  UPDATE matches SET sport_id = padel_id WHERE sport_id IN (SELECT id FROM sports WHERE lower(name) LIKE '%padel%' OR lower(name) LIKE '%pádel%') AND sport_id != padel_id;
  UPDATE user_rankings SET sport_id = padel_id WHERE sport_id IN (SELECT id FROM sports WHERE lower(name) LIKE '%padel%' OR lower(name) LIKE '%pádel%') AND sport_id != padel_id;

  -- Todo lo que suene a Tenis (y no sea table tennis) va a 'tenis_id'
  UPDATE courts SET sport_id = tenis_id WHERE sport_id IN (SELECT id FROM sports WHERE (lower(name) LIKE '%tenis%' OR lower(name) LIKE '%tennis%') AND lower(name) NOT LIKE '%table%') AND sport_id != tenis_id;
  UPDATE matches SET sport_id = tenis_id WHERE sport_id IN (SELECT id FROM sports WHERE (lower(name) LIKE '%tenis%' OR lower(name) LIKE '%tennis%') AND lower(name) NOT LIKE '%table%') AND sport_id != tenis_id;
  UPDATE user_rankings SET sport_id = tenis_id WHERE sport_id IN (SELECT id FROM sports WHERE (lower(name) LIKE '%tenis%' OR lower(name) LIKE '%tennis%') AND lower(name) NOT LIKE '%table%') AND sport_id != tenis_id;

  -- 3. DESVINCULAR DEPORTES BASURA (Table Tennis, Basketball, etc)
  UPDATE courts SET sport_id = NULL WHERE sport_id NOT IN (padel_id, tenis_id);
  UPDATE matches SET sport_id = NULL WHERE sport_id NOT IN (padel_id, tenis_id);
  DELETE FROM user_rankings WHERE sport_id NOT IN (padel_id, tenis_id);

  -- 4. ELIMINAR TODOS LOS DEPORTES QUE NO SEAN LOS CANÓNICOS
  DELETE FROM sports WHERE id NOT IN (padel_id, tenis_id);
  
  RAISE NOTICE '✅ Limpieza y Consolidación Completada.';
END $$;

-- ── Verificación final ───────────────────────────────────────────────
-- Solo deben aparecer Pádel y Tenis
SELECT id, name FROM sports ORDER BY name;

-- Cero rankings con deporte desconocido
SELECT s.name AS sport, COUNT(*) AS total
FROM user_rankings ur
JOIN sports s ON s.id = ur.sport_id
GROUP BY s.name;
