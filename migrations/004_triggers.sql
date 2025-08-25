-- migrations/004_triggers.sql
-- Creates a function and trigger that keeps public.profiles in sync with auth.users.
-- Copies email, full_name, phone, locale, and sets role='member' by default.
-- Also updates email_confirmed when possible.

BEGIN;

CREATE OR REPLACE FUNCTION public.handle_auth_user_insert() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
  meta jsonb;
  phone_text text;
  locale_text text;
  display_name text;
  email_confirmed_bool boolean := false;
BEGIN
  -- user metadata in Supabase is usually stored in NEW.raw_user_meta or NEW.user_metadata
  IF TG_OP = 'INSERT' THEN
    -- try to extract metadata
    IF (NEW.user_metadata IS NOT NULL) THEN
      meta := NEW.user_metadata::jsonb;
    ELSIF (NEW.raw_user_meta_data IS NOT NULL) THEN
      meta := NEW.raw_user_meta_data::jsonb;
    ELSE
      meta := NULL;
    END IF;

    IF meta IS NOT NULL THEN
      phone_text := meta ->> 'phone';
      locale_text := meta ->> 'locale';
      display_name := meta ->> 'full_name';
      IF (meta ->> 'email_confirmed') IS NOT NULL THEN
        email_confirmed_bool := (meta ->> 'email_confirmed')::boolean;
      END IF;
    END IF;

    -- Some Supabase setups have confirmed_at column
    BEGIN
      IF (NEW.confirmed_at IS NOT NULL) THEN
        email_confirmed_bool := true;
      END IF;
    EXCEPTION WHEN undefined_column THEN
      -- ignore if column not present
      NULL;
    END;

    INSERT INTO public.profiles (id, email, full_name, phone, locale, role, created_at, email_confirmed)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(display_name, NEW.email),
      phone_text,
      COALESCE(locale_text, 'en'),
      'member',
      now(),
      email_confirmed_bool
    )
    ON CONFLICT (id) DO UPDATE
    SET
      email = EXCLUDED.email,
      full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
      phone = COALESCE(EXCLUDED.phone, public.profiles.phone),
      locale = COALESCE(EXCLUDED.locale, public.profiles.locale),
      email_confirmed = COALESCE(EXCLUDED.email_confirmed, public.profiles.email_confirmed),
      updated_at = now();

    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    -- If user's confirmed_at flips to non-null, ensure profile updated
    PERFORM 1 FROM public.profiles WHERE id = NEW.id;
    IF FOUND THEN
      UPDATE public.profiles
      SET email = NEW.email,
          full_name = COALESCE((NEW.user_metadata::jsonb ->> 'full_name'), public.profiles.full_name),
          phone = COALESCE((NEW.user_metadata::jsonb ->> 'phone'), public.profiles.phone),
          locale = COALESCE((NEW.user_metadata::jsonb ->> 'locale'), public.profiles.locale),
          email_confirmed = COALESCE((CASE WHEN (NEW.confirmed_at IS NOT NULL) THEN true ELSE public.profiles.email_confirmed END), public.profiles.email_confirmed),
          updated_at = now()
      WHERE id = NEW.id;
    END IF;
    RETURN NEW;
  END IF;

  RETURN NEW;
END;
$$;

-- Trigger on auth.users (fires on INSERT or UPDATE)
DROP TRIGGER IF EXISTS trigger_handle_auth_user_insert ON auth.users;
CREATE TRIGGER trigger_handle_auth_user_insert
AFTER INSERT OR UPDATE ON auth.users
FOR EACH ROW
EXECUTE PROCEDURE public.handle_auth_user_insert();

COMMIT;