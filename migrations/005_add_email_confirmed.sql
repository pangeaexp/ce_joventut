-- migrations/005_add_email_confirmed.sql
BEGIN;

ALTER TABLE IF EXISTS public.profiles
ADD COLUMN IF NOT EXISTS email_confirmed boolean DEFAULT false;

-- Backfill from auth.users if possible
-- auth.users has columns: id, email, raw_user_meta, etc. Supabase also exposes
-- a boolean 'email_confirmed_at' in some setups; adjust if different.
UPDATE public.profiles p
SET email_confirmed = true
FROM auth.users u
WHERE p.id = u.id
  AND (u.email_confirmed OR (u.email IS NOT NULL AND u.confirmed_at IS NOT NULL));

COMMIT;