-- ==============================================================================
-- MOTOR DE PROGRESIÓN LP — SportsConnect
-- Reemplaza el sistema ELO por un motor de ligas con puntos fijos.
-- ==============================================================================
-- EJECUTAR EN: Supabase SQL Editor (una sola vez)
--
-- REGLAS IMPLEMENTADAS:
--   Victoria  → +25 LP
--   Derrota   → -15 LP
--   Ligas     → Bronce / Plata / Oro / Platino / Diamante (cada una con div 3→2→1)
--   Promoción → al llegar a 100 LP, sube de división; los LP sobrantes se conservan.
--               División 1 → siguiente liga en División 3.
--               Tope máximo: Diamante 1 (LP se capa en 99).
--   Descenso  → SOLO si el jugador tenía 0 LP antes de perder.
--               Baja a la división anterior con 75 LP.
--               Si tenía LP > 0 y la resta da negativo → queda en 0 (sin descenso).
--               No se puede bajar de Bronce 3 (0 LP).
-- ==============================================================================


-- ==============================================================================
-- PASO 1: Asegurar columnas tier / division / lp en user_rankings
-- ==============================================================================
ALTER TABLE public.user_rankings
  ADD COLUMN IF NOT EXISTS tier     VARCHAR(50) NOT NULL DEFAULT 'Bronce',
  ADD COLUMN IF NOT EXISTS division INTEGER     NOT NULL DEFAULT 3,
  ADD COLUMN IF NOT EXISTS lp       INTEGER     NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_user_rankings_user_id
  ON public.user_rankings(user_id);


-- ==============================================================================
-- PASO 2: Helper — convierte nombre de liga a número de rango y viceversa
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.tier_to_rank(p_tier TEXT)
RETURNS INT AS $$
BEGIN
  IF    p_tier = 'Bronce'   THEN RETURN 1;
  ELSIF p_tier = 'Plata'    THEN RETURN 2;
  ELSIF p_tier = 'Oro'      THEN RETURN 3;
  ELSIF p_tier = 'Platino'  THEN RETURN 4;
  ELSIF p_tier = 'Diamante' THEN RETURN 5;
  ELSE  RETURN 1;
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.rank_to_tier(p_rank INT)
RETURNS TEXT AS $$
BEGIN
  IF    p_rank = 1 THEN RETURN 'Bronce';
  ELSIF p_rank = 2 THEN RETURN 'Plata';
  ELSIF p_rank = 3 THEN RETURN 'Oro';
  ELSIF p_rank = 4 THEN RETURN 'Platino';
  ELSIF p_rank = 5 THEN RETURN 'Diamante';
  ELSE  RETURN 'Bronce';
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER;


-- ==============================================================================
-- PASO 3: Motor principal de progresión → apply_lp_change()
-- Recibe el estado actual (tier, division, lp) y el delta (+25 o -15).
-- Retorna el nuevo estado (new_tier, new_division, new_lp).
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.apply_lp_change(
  p_tier     TEXT,
  p_division INT,
  p_lp       INT,
  p_delta    INT   -- +25 victoria | -15 derrota
)
RETURNS TABLE (new_tier TEXT, new_division INT, new_lp INT) AS $$
DECLARE
  v_tier       TEXT := p_tier;
  v_division   INT  := p_division;
  v_lp         INT  := p_lp + p_delta;
  v_tier_rank  INT;
BEGIN

  -- PROMOCION: mientras LP >= 100, sigue subiendo
  WHILE v_lp >= 100 LOOP
    v_lp := v_lp - 100;

    IF v_division > 1 THEN
      v_division := v_division - 1;
    ELSE
      v_tier_rank := public.tier_to_rank(v_tier);
      IF v_tier_rank < 5 THEN
        v_tier     := public.rank_to_tier(v_tier_rank + 1);
        v_division := 3;
      ELSE
        v_lp := 99;
        EXIT;
      END IF;
    END IF;
  END LOOP;

  -- DESCENSO: solo ocurre si el jugador tenia 0 LP antes de perder
  IF v_lp < 0 THEN
    IF p_lp = 0 THEN
      IF v_division < 3 THEN
        v_division := v_division + 1;
        v_lp       := 75;
      ELSE
        v_tier_rank := public.tier_to_rank(v_tier);
        IF v_tier_rank > 1 THEN
          v_tier     := public.rank_to_tier(v_tier_rank - 1);
          v_division := 1;
          v_lp       := 75;
        ELSE
          v_lp := 0;
        END IF;
      END IF;
    ELSE
      v_lp := 0;
    END IF;
  END IF;

  RETURN QUERY SELECT v_tier, v_division, v_lp;
END;
$$ LANGUAGE plpgsql IMMUTABLE SECURITY DEFINER;


-- ==============================================================================
-- PASO 4: Trigger — process_match_progression()
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.process_match_progression()
RETURNS TRIGGER AS $$
DECLARE
  is_draw    BOOLEAN := FALSE;
  winners    UUID[];
  losers     UUID[];
  player_id  UUID;

  v_tier     TEXT;
  v_division INT;
  v_lp       INT;

  v_new_tier     TEXT;
  v_new_division INT;
  v_new_lp       INT;
BEGIN
  IF NEW.score_data IS NOT NULL THEN
    is_draw := COALESCE((NEW.score_data->>'is_draw')::BOOLEAN, FALSE);
  END IF;
  IF is_draw OR NEW.winner_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.match_type = '1v1' OR (NEW.player3_id IS NULL AND NEW.player4_id IS NULL) THEN
    IF NEW.winner_id = NEW.player1_id THEN
      winners := ARRAY[NEW.player1_id];
      losers  := ARRAY[NEW.player2_id];
    ELSIF NEW.winner_id = NEW.player2_id THEN
      winners := ARRAY[NEW.player2_id];
      losers  := ARRAY[NEW.player1_id];
    ELSE
      RETURN NEW;
    END IF;
  ELSE
    IF NEW.winner_id = NEW.player1_id OR NEW.winner_id = NEW.player2_id THEN
      winners := ARRAY[NEW.player1_id, NEW.player2_id];
      losers  := ARRAY[NEW.player3_id, NEW.player4_id];
    ELSIF NEW.winner_id = NEW.player3_id OR NEW.winner_id = NEW.player4_id THEN
      winners := ARRAY[NEW.player3_id, NEW.player4_id];
      losers  := ARRAY[NEW.player1_id, NEW.player2_id];
    ELSE
      RETURN NEW;
    END IF;
  END IF;

  winners := array_remove(winners, NULL);
  losers  := array_remove(losers,  NULL);

  IF array_length(winners, 1) IS NULL OR array_length(losers, 1) IS NULL THEN
    RETURN NEW;
  END IF;

  FOREACH player_id IN ARRAY (winners || losers) LOOP
    INSERT INTO public.user_rankings (user_id, sport_id, category, tier, division, lp, elo_score)
    VALUES (player_id, NEW.sport_id, NEW.match_category, 'Bronce', 3, 0, 1200)
    ON CONFLICT (user_id, sport_id, category) DO NOTHING;
  END LOOP;

  FOREACH player_id IN ARRAY winners LOOP
    SELECT ur.tier, ur.division, ur.lp
      INTO v_tier, v_division, v_lp
      FROM public.user_rankings ur
      WHERE ur.user_id = player_id
        AND ur.sport_id = NEW.sport_id
        AND ur.category = NEW.match_category;

    SELECT r.new_tier, r.new_division, r.new_lp
      INTO v_new_tier, v_new_division, v_new_lp
      FROM public.apply_lp_change(v_tier, v_division, v_lp, 25) r;

    UPDATE public.user_rankings
      SET tier = v_new_tier, division = v_new_division, lp = v_new_lp, updated_at = NOW()
      WHERE user_id = player_id AND sport_id = NEW.sport_id AND category = NEW.match_category;
  END LOOP;

  FOREACH player_id IN ARRAY losers LOOP
    SELECT ur.tier, ur.division, ur.lp
      INTO v_tier, v_division, v_lp
      FROM public.user_rankings ur
      WHERE ur.user_id = player_id
        AND ur.sport_id = NEW.sport_id
        AND ur.category = NEW.match_category;

    SELECT r.new_tier, r.new_division, r.new_lp
      INTO v_new_tier, v_new_division, v_new_lp
      FROM public.apply_lp_change(v_tier, v_division, v_lp, -15) r;

    UPDATE public.user_rankings
      SET tier = v_new_tier, division = v_new_division, lp = v_new_lp, updated_at = NOW()
      WHERE user_id = player_id AND sport_id = NEW.sport_id AND category = NEW.match_category;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==============================================================================
-- PASO 5: Adjuntar trigger
-- ==============================================================================
DROP TRIGGER IF EXISTS trigger_update_match_elo_on_completion  ON public.matches;
DROP TRIGGER IF EXISTS trigger_match_progression_on_completion ON public.matches;

CREATE TRIGGER trigger_match_progression_on_completion
AFTER UPDATE ON public.matches
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM 'completed' AND NEW.status = 'completed')
EXECUTE FUNCTION public.process_match_progression();


-- ==============================================================================
-- PASO 6: RPC complete_match_and_update_stats
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.complete_match_and_update_stats(
  p_match_id       UUID,
  p_winner_id      UUID    DEFAULT NULL,
  p_score_data     JSONB   DEFAULT '{}'::JSONB,
  p_referee_reward INTEGER DEFAULT 5000
)
RETURNS VOID AS $$
DECLARE
  v_match RECORD;
BEGIN
  SELECT * INTO v_match FROM public.matches WHERE id = p_match_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Partido no encontrado: %', p_match_id;
  END IF;
  IF v_match.status = 'completed' THEN
    RAISE EXCEPTION 'El partido % ya fue completado anteriormente', p_match_id;
  END IF;

  UPDATE public.matches
    SET status = 'completed', winner_id = p_winner_id, score_data = p_score_data, updated_at = NOW()
    WHERE id = p_match_id;

  IF v_match.referee_id IS NOT NULL THEN
    BEGIN
      INSERT INTO public.referee_payouts (referee_id, match_id, amount, status, created_at)
      VALUES (v_match.referee_id, p_match_id, p_referee_reward, 'pending', NOW());
    EXCEPTION WHEN undefined_table THEN NULL;
    END;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.complete_match_and_update_stats(UUID, UUID, JSONB, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.apply_lp_change(TEXT, INT, INT, INT) TO authenticated;

-- VERIFICACION:
-- SELECT * FROM public.apply_lp_change('Bronce', 3, 90, 25);  -- -> Bronce 2, 15 LP
-- SELECT * FROM public.apply_lp_change('Bronce', 3, 0, -15);  -- -> Bronce 3, 0 LP (suelo)
-- SELECT * FROM public.apply_lp_change('Bronce', 2, 0, -15);  -- -> Bronce 3, 75 LP (descenso)
-- SELECT * FROM public.apply_lp_change('Bronce', 3, 10, -15); -- -> Bronce 3, 0 LP (clamp, sin descenso)
-- SELECT * FROM public.apply_lp_change('Bronce', 1, 90, 25);  -- -> Plata 3, 15 LP (sube liga)
