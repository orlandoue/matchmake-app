-- Migrate `matches` table to support Email-based 2v2 partner invitations

-- 1. Add the column for invited_player2_id, which references the `users` table
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS invited_player2_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- 2. Add an index to speed up the "Mis Invitaciones" queries
CREATE INDEX IF NOT EXISTS idx_matches_invited_player2_id ON public.matches(invited_player2_id);

-- Opcionalmente: Verificar que supabase_elo_trigger.sql no rompa con esta nueva columna (no debería porque no afecta la lógica ELO).
