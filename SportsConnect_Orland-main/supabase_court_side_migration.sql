-- Fase 5 · Misión 1 — persistencia del "Lado de Pista" (Drive/Revés/Ambos).
--
-- Hoy la selección vive como estado de formulario (MatchFormController
-- .selectedCourtSide) y se muestra en el wizard y en ReviewSummary, pero NO
-- se guarda en la BD. Para persistirla, aplica esta migración y luego:
--   1. Añade `player1CourtSide` a MatchModel + toInsertJson/fromJson.
--   2. Pásalo desde MatchCreationController.createOrJoinMatch al construir
--      el MatchModel (matchCtrl.selectedCourtSide.value).
-- (No se cableó en toInsertJson todavía para no romper los inserts mientras
--  la columna no exista.)

ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS player1_court_side TEXT
  CHECK (player1_court_side IN ('Drive', 'Revés', 'Ambos'));
