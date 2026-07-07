-- Migration: Create separate identity_verifications table
-- Run this AFTER creating the table, then remove identity columns from users table

-- 1. Create the identity_verifications table
CREATE TABLE public.identity_verifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  document_type text NOT NULL,
  front_image_url text NOT NULL,
  back_image_url text NOT NULL,
  selfie_url text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT identity_verifications_pkey PRIMARY KEY (id),
  CONSTRAINT identity_verifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users (id) ON DELETE CASCADE,
  CONSTRAINT identity_verifications_status_check CHECK (
    status = ANY (ARRAY['pending'::text, 'verified'::text, 'rejected'::text])
  )
) TABLESPACE pg_default;

-- Index for fast lookup by user_id
CREATE INDEX IF NOT EXISTS idx_identity_verifications_user_id 
  ON public.identity_verifications USING btree (user_id) TABLESPACE pg_default;

-- Index for filtering by status
CREATE INDEX IF NOT EXISTS idx_identity_verifications_status 
  ON public.identity_verifications USING btree (status) TABLESPACE pg_default;

-- Trigger to auto-update updated_at
CREATE TRIGGER update_identity_verifications_updated_at 
  BEFORE UPDATE ON public.identity_verifications 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- 2. Remove identity-related columns from users table
ALTER TABLE public.users 
  DROP COLUMN IF EXISTS identity_document_type,
  DROP COLUMN IF EXISTS identity_front_url,
  DROP COLUMN IF EXISTS identity_back_url,
  DROP COLUMN IF EXISTS selfie_url,
  DROP COLUMN IF EXISTS is_identity_verified;
