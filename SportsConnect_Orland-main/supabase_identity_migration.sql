-- Add identity verification columns to users table
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS identity_document_type text,
  ADD COLUMN IF NOT EXISTS identity_front_url text,
  ADD COLUMN IF NOT EXISTS identity_back_url text,
  ADD COLUMN IF NOT EXISTS selfie_url text,
  ADD COLUMN IF NOT EXISTS is_identity_verified boolean DEFAULT false;
