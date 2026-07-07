-- Migration: Update matches table for Competitive/Friendly modes and time range
-- Run this in your Supabase SQL Editor AFTER the original matches migration

-- 1. Add scheduled_end_time column for time range selection
ALTER TABLE public.matches
ADD COLUMN IF NOT EXISTS scheduled_end_time text NULL;

-- 2. Update match_mode constraint to accept new values (competitive, friendly)
-- First drop the old constraint
ALTER TABLE public.matches
DROP CONSTRAINT IF EXISTS matches_match_mode_check;

-- Add new constraint that accepts both old and new values for backward compatibility
ALTER TABLE public.matches
ADD CONSTRAINT matches_match_mode_check
CHECK (match_mode IN ('random', 'private', 'team_up', 'competitive', 'friendly'));

-- 3. Migrate existing data from old mode names to new ones
UPDATE public.matches SET match_mode = 'competitive' WHERE match_mode = 'random';
UPDATE public.matches SET match_mode = 'friendly' WHERE match_mode = 'private';

-- 4. (Optional) After confirming all data is migrated, tighten the constraint
-- to only allow new values. Uncomment and run separately when ready:
--
-- ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS matches_match_mode_check;
-- ALTER TABLE public.matches ADD CONSTRAINT matches_match_mode_check
--   CHECK (match_mode IN ('competitive', 'friendly'));

-- 5. Update the default value for match_mode
ALTER TABLE public.matches
ALTER COLUMN match_mode SET DEFAULT 'competitive';

-- 6. Add index on scheduled_end_time for potential queries
CREATE INDEX IF NOT EXISTS idx_matches_scheduled_end_time
ON public.matches USING btree (scheduled_end_time) TABLESPACE pg_default;

-- Verify the migration
-- SELECT match_mode, count(*) FROM public.matches GROUP BY match_mode;
-- SELECT column_name, data_type, column_default FROM information_schema.columns WHERE table_name = 'matches' AND column_name = 'scheduled_end_time';
