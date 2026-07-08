-- Fase 6 · Misión 1 (cierre end-to-end) — persistencia del "Lado de Pista".
--
-- El cliente YA está cableado (Fase 6): MatchModel.player1CourtSide viaja en
-- toInsertJson y se envía desde MatchCreationController.createOrJoinMatch con
-- MatchFormController.selectedCourtSide. Falta SOLO aplicar esta migración en
-- el dashboard para crear la columna; hasta entonces los inserts que envíen
-- un valor no-nulo fallarán con "column does not exist".

ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS player1_court_side TEXT
  CHECK (player1_court_side IN ('Drive', 'Revés', 'Ambos'));
