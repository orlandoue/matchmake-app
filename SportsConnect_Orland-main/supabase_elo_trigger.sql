-- ==============================================================================
-- MIGRACIÓN SUPABASE: SISTEMA ELO DINÁMICO & TRIGGERS (MATCHMAKING)
-- ==============================================================================

-- 1. ESTRUCTURA DE LA TABLA (Si no existía previamente)
-- Nos aseguramos que exista la tabla para almacenar la progresión de ELO multi-ranking.
CREATE TABLE IF NOT EXISTS public.user_rankings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sport_id UUID NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'Masculino', 'Femenino', 'Mixto'
    elo_score NUMERIC DEFAULT 1200,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, sport_id, category) -- Clave única para evitar duplicidades del mismo ranking
);

-- ==============================================================================
-- 2. MOTOR MATEMÁTICO ELO
-- Función utilitaria para calcular la variación Delta en base a los ELOs actuales.
-- Retorna el puntaje que se le suma al ganador y el que se le resta al perdedor.
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.calculate_elo_delta(
    winner_elo NUMERIC, 
    loser_elo NUMERIC, 
    K NUMERIC DEFAULT 32
) RETURNS TABLE (winner_delta NUMERIC, loser_delta NUMERIC) AS $$
DECLARE
    expected_winner NUMERIC;
    expected_loser NUMERIC;
BEGIN
    -- Fórmula estándar de Expectativa (Win probability)
    expected_winner := 1 / (1 + POWER(10, (loser_elo - winner_elo) / 400.0));
    expected_loser := 1 / (1 + POWER(10, (winner_elo - loser_elo) / 400.0));

    -- Deltas: K * (Actual Resultado - Expected Resultado)
    -- El ganador siempre tiene resultado '1', el perdedor '0'.
    winner_delta := ROUND(K * (1 - expected_winner));
    loser_delta := ROUND(K * (0 - expected_loser)); -- Retorna un número negativo

    RETURN QUERY SELECT winner_delta, loser_delta;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==============================================================================
-- 3. FUNCIÓN DEL TRIGGER (PROCESS_MATCH_ELO)
-- Lógica core que escucha el completado del partido. Soportando 1v1 y 2v2.
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.process_match_elo()
RETURNS TRIGGER AS $$
DECLARE
    is_draw BOOLEAN := FALSE;
    winners UUID[];
    losers UUID[];
    
    player_id UUID;
    v_elo NUMERIC;
    
    avg_winner_elo NUMERIC := 0;
    avg_loser_elo NUMERIC := 0;
    
    v_winner_delta NUMERIC;
    v_loser_delta NUMERIC;
BEGIN
    -- [A] CONTROL DE EMPATE (DRAW)
    IF NEW.score_data IS NOT NULL THEN
        is_draw := COALESCE((NEW.score_data->>'is_draw')::BOOLEAN, FALSE);
    END IF;

    IF is_draw THEN
        RETURN NEW;
    END IF;

    IF NEW.winner_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- [B] CONSTRUIR EQUIPOS (Winners vs Losers)
    -- Si es 1v1 (player3 y player4 son NULL normalmente)
    IF NEW.match_type = '1v1' OR (NEW.player3_id IS NULL AND NEW.player4_id IS NULL) THEN
        IF NEW.winner_id = NEW.player1_id THEN
            winners := ARRAY[NEW.player1_id];
            losers := ARRAY[NEW.player2_id];
        ELSIF NEW.winner_id = NEW.player2_id THEN
            winners := ARRAY[NEW.player2_id];
            losers := ARRAY[NEW.player1_id];
        ELSE
            RETURN NEW;
        END IF;
    ELSE
        -- Lógica 2v2
        -- Identificar si el winner_id pertenece al Equipo 1 (P1, P2) o Equipo 2 (P3, P4)
        IF NEW.winner_id = NEW.player1_id OR NEW.winner_id = NEW.player2_id THEN
            winners := ARRAY[NEW.player1_id, NEW.player2_id];
            losers := ARRAY[NEW.player3_id, NEW.player4_id];
        ELSIF NEW.winner_id = NEW.player3_id OR NEW.winner_id = NEW.player4_id THEN
            winners := ARRAY[NEW.player3_id, NEW.player4_id];
            losers := ARRAY[NEW.player1_id, NEW.player2_id];
        ELSE
            RETURN NEW;
        END IF;
    END IF;

    -- Limpiar arrays quitando posibles nulos incrustados preventivamente
    winners := array_remove(winners, NULL);
    losers := array_remove(losers, NULL);

    IF array_length(winners, 1) IS NULL OR array_length(losers, 1) IS NULL THEN
        RETURN NEW; 
    END IF;

    -- [C] GARANTIZAR EXISTENCIA DE RANKINGS Y OBTENER ELO PROMEDIO
    -- UPSERT silencioso (ON CONFLICT DO NOTHING) para asegurar ranking base 1200
    FOREACH player_id IN ARRAY (winners || losers)
    LOOP
        INSERT INTO public.user_rankings (user_id, sport_id, category, elo_score)
        VALUES (player_id, NEW.sport_id, NEW.match_category, 1200)
        ON CONFLICT (user_id, sport_id, category) DO NOTHING;
    END LOOP;

    -- Obtener ELO de los ganadores (Sumatoria bloqueando fila FOR UPDATE)
    FOR player_id IN SELECT unnest(winners) LOOP
        SELECT elo_score INTO v_elo FROM public.user_rankings 
        WHERE user_id = player_id AND sport_id = NEW.sport_id AND category = NEW.match_category 
        FOR UPDATE;
        avg_winner_elo := avg_winner_elo + v_elo;
    END LOOP;
    avg_winner_elo := avg_winner_elo / array_length(winners, 1);

    -- Obtener ELO de los perdedores (Sumatoria)
    FOR player_id IN SELECT unnest(losers) LOOP
        SELECT elo_score INTO v_elo FROM public.user_rankings 
        WHERE user_id = player_id AND sport_id = NEW.sport_id AND category = NEW.match_category 
        FOR UPDATE;
        avg_loser_elo := avg_loser_elo + v_elo;
    END LOOP;
    avg_loser_elo := avg_loser_elo / array_length(losers, 1);

    -- [E] APLICACIÓN MATEMÁTICA CON ELO PROMEDIO
    SELECT * INTO v_winner_delta, v_loser_delta 
    FROM calculate_elo_delta(avg_winner_elo, avg_loser_elo);

    -- [F] UPDATE FINAL A LAS FILAS CON SU DELTA
    FOREACH player_id IN ARRAY winners LOOP
        UPDATE public.user_rankings 
        SET elo_score = elo_score + v_winner_delta,
            updated_at = NOW()
        WHERE user_id = player_id AND sport_id = NEW.sport_id AND category = NEW.match_category;
    END LOOP;

    FOREACH player_id IN ARRAY losers LOOP
        UPDATE public.user_rankings 
        SET elo_score = GREATEST(elo_score + v_loser_delta, 0), -- Clamping a 0
            updated_at = NOW()
        WHERE user_id = player_id AND sport_id = NEW.sport_id AND category = NEW.match_category;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==============================================================================
-- 4. ADJUNCIÓN DEL TRIGGER A LA TABLA MATCHES
-- ==============================================================================
DROP TRIGGER IF EXISTS trigger_update_match_elo_on_completion ON public.matches;

CREATE TRIGGER trigger_update_match_elo_on_completion
AFTER UPDATE ON public.matches
FOR EACH ROW
-- Se dispara ÚNICAMENTE cuando la fila pase de otro status hacia 'completed'
WHEN (OLD.status != 'completed' AND NEW.status = 'completed')
EXECUTE FUNCTION public.process_match_elo();
