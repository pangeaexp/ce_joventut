

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."handle_auth_user_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
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


ALTER FUNCTION "public"."handle_auth_user_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_auth_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  -- Si ya existe, actualiza datos básicos
  if exists (select 1 from public.profiles where id = new.id) then
    update public.profiles
    set
      full_name = coalesce(new.raw_user_meta_data->>'full_name', public.profiles.full_name),
      display_name = coalesce(new.raw_user_meta_data->>'display_name',
                             split_part(new.email, '@', 1)),
      avatar_url = coalesce(new.raw_user_meta_data->>'avatar_url', public.profiles.avatar_url),
      created_at = coalesce(public.profiles.created_at, now())
    where id = new.id;
    return new;
  end if;

  -- Inserta perfil nuevo con datos básicos
  insert into public.profiles (id, full_name, display_name, created_at)
  values (
    new.id,
    nullif(coalesce(new.raw_user_meta_data->>'full_name', new.email), '') ,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1)),
    now()
  );

  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_auth_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."attendance" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "training_id" "uuid",
    "user_id" "uuid",
    "status" "text" DEFAULT 'absent'::"text" NOT NULL,
    "note" "text",
    "recorded_by" "uuid",
    "recorded_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."attendance" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."audit_logs" (
    "id" bigint NOT NULL,
    "actor_id" "uuid",
    "action" "text" NOT NULL,
    "object_type" "text",
    "object_id" "uuid",
    "changes" "jsonb",
    "ip" "inet",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."audit_logs" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."audit_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."audit_logs_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."audit_logs_id_seq" OWNED BY "public"."audit_logs"."id";



CREATE TABLE IF NOT EXISTS "public"."badges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text",
    "title" "text" NOT NULL,
    "description" "text",
    "icon_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."badges" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."event_registrations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid",
    "user_id" "uuid",
    "status" "text" DEFAULT 'registered'::"text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."event_registrations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "location" "text",
    "starts_at" timestamp with time zone,
    "ends_at" timestamp with time zone,
    "all_day" boolean DEFAULT false,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."media" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bucket" "text" NOT NULL,
    "path" "text" NOT NULL,
    "mime_type" "text",
    "size" bigint,
    "public" boolean DEFAULT true,
    "uploaded_by" "uuid",
    "associated_type" "text",
    "associated_id" "uuid",
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."media" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."missions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "description" "text",
    "starts_at" timestamp with time zone,
    "ends_at" timestamp with time zone,
    "points" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."missions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."news" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "title" "text" NOT NULL,
    "summary" "text",
    "content" "text",
    "author_id" "uuid",
    "is_draft" boolean DEFAULT true,
    "published_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."news" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "title" "text",
    "body" "text",
    "data" "jsonb",
    "read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "email" "text",
    "full_name" "text",
    "display_name" "text",
    "role" "text" DEFAULT 'member'::"text" NOT NULL,
    "phone" "text",
    "locale" "text",
    "avatar_url" "text",
    "metadata" "jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."team_memberships" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "team_id" "uuid",
    "user_id" "uuid",
    "role" "text" DEFAULT 'player'::"text",
    "joined_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."team_memberships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."teams" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "slug" "text",
    "description" "text",
    "coach_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."teams" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trainings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "team_id" "uuid",
    "title" "text",
    "description" "text",
    "scheduled_at" timestamp with time zone,
    "duration_minutes" integer,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."trainings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_badges" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "badge_id" "uuid",
    "awarded_by" "uuid",
    "awarded_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_badges" OWNER TO "postgres";


ALTER TABLE ONLY "public"."audit_logs" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."audit_logs_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."attendance"
    ADD CONSTRAINT "attendance_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."attendance"
    ADD CONSTRAINT "attendance_training_id_user_id_key" UNIQUE ("training_id", "user_id");



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."badges"
    ADD CONSTRAINT "badges_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."badges"
    ADD CONSTRAINT "badges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."event_registrations"
    ADD CONSTRAINT "event_registrations_event_id_user_id_key" UNIQUE ("event_id", "user_id");



ALTER TABLE ONLY "public"."event_registrations"
    ADD CONSTRAINT "event_registrations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."media"
    ADD CONSTRAINT "media_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."missions"
    ADD CONSTRAINT "missions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."news"
    ADD CONSTRAINT "news_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."team_memberships"
    ADD CONSTRAINT "team_memberships_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."team_memberships"
    ADD CONSTRAINT "team_memberships_team_id_user_id_key" UNIQUE ("team_id", "user_id");



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_slug_key" UNIQUE ("slug");



ALTER TABLE ONLY "public"."trainings"
    ADD CONSTRAINT "trainings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_user_id_badge_id_key" UNIQUE ("user_id", "badge_id");



CREATE INDEX "idx_attendance_training" ON "public"."attendance" USING "btree" ("training_id");



CREATE INDEX "idx_attendance_user" ON "public"."attendance" USING "btree" ("user_id");



CREATE INDEX "idx_audit_logs_action" ON "public"."audit_logs" USING "btree" ("action");



CREATE INDEX "idx_audit_logs_actor" ON "public"."audit_logs" USING "btree" ("actor_id");



CREATE INDEX "idx_event_registrations_event" ON "public"."event_registrations" USING "btree" ("event_id");



CREATE INDEX "idx_event_registrations_user" ON "public"."event_registrations" USING "btree" ("user_id");



CREATE INDEX "idx_media_associated" ON "public"."media" USING "btree" ("associated_type", "associated_id");



CREATE INDEX "idx_news_title" ON "public"."news" USING "gin" ("to_tsvector"('"simple"'::"regconfig", COALESCE("title", ''::"text")));



CREATE INDEX "idx_notifications_user" ON "public"."notifications" USING "btree" ("user_id");



CREATE INDEX "idx_profiles_role" ON "public"."profiles" USING "btree" ("role");



CREATE INDEX "idx_team_memberships_team" ON "public"."team_memberships" USING "btree" ("team_id");



CREATE INDEX "idx_team_memberships_user" ON "public"."team_memberships" USING "btree" ("user_id");



CREATE INDEX "idx_teams_name" ON "public"."teams" USING "gin" ("to_tsvector"('"simple"'::"regconfig", COALESCE("name", ''::"text")));



CREATE INDEX "idx_trainings_scheduled" ON "public"."trainings" USING "btree" ("scheduled_at");



CREATE INDEX "idx_trainings_team" ON "public"."trainings" USING "btree" ("team_id");



ALTER TABLE ONLY "public"."attendance"
    ADD CONSTRAINT "attendance_recorded_by_fkey" FOREIGN KEY ("recorded_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."attendance"
    ADD CONSTRAINT "attendance_training_id_fkey" FOREIGN KEY ("training_id") REFERENCES "public"."trainings"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."attendance"
    ADD CONSTRAINT "attendance_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."event_registrations"
    ADD CONSTRAINT "event_registrations_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."events"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."event_registrations"
    ADD CONSTRAINT "event_registrations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."events"
    ADD CONSTRAINT "events_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."media"
    ADD CONSTRAINT "media_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."news"
    ADD CONSTRAINT "news_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."team_memberships"
    ADD CONSTRAINT "team_memberships_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."team_memberships"
    ADD CONSTRAINT "team_memberships_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."teams"
    ADD CONSTRAINT "teams_coach_id_fkey" FOREIGN KEY ("coach_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."trainings"
    ADD CONSTRAINT "trainings_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."trainings"
    ADD CONSTRAINT "trainings_team_id_fkey" FOREIGN KEY ("team_id") REFERENCES "public"."teams"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_awarded_by_fkey" FOREIGN KEY ("awarded_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_badge_id_fkey" FOREIGN KEY ("badge_id") REFERENCES "public"."badges"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_badges"
    ADD CONSTRAINT "user_badges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE "public"."attendance" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "attendance_insert_staff" ON "public"."attendance" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"]))))));



CREATE POLICY "attendance_select_owner_or_staff" ON "public"."attendance" FOR SELECT USING ((("auth"."uid"() = "user_id") OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"])))))));



CREATE POLICY "attendance_update_staff_or_self" ON "public"."attendance" FOR UPDATE USING ((("auth"."uid"() = "user_id") OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"]))))))) WITH CHECK ((("auth"."uid"() = "user_id") OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"])))))));



CREATE POLICY "audit_insert_server" ON "public"."audit_logs" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = 'admin'::"text")))));



ALTER TABLE "public"."audit_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "audit_no_client_access" ON "public"."audit_logs" FOR SELECT USING (false);



ALTER TABLE "public"."badges" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "badges_select_public" ON "public"."badges" FOR SELECT USING (true);



CREATE POLICY "er_insert_auth" ON "public"."event_registrations" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "er_select_user_or_staff" ON "public"."event_registrations" FOR SELECT USING ((("auth"."uid"() = "user_id") OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"])))))));



ALTER TABLE "public"."event_registrations" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "events_delete_admin" ON "public"."events" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = 'admin'::"text")))));



CREATE POLICY "events_insert_staff" ON "public"."events" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"]))))));



CREATE POLICY "events_select_public" ON "public"."events" FOR SELECT USING (true);



CREATE POLICY "events_update_staff" ON "public"."events" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"]))))));



ALTER TABLE "public"."media" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "media_insert_auth" ON "public"."media" FOR INSERT WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "media_select_public" ON "public"."media" FOR SELECT USING (("public" = true));



CREATE POLICY "media_update_owner_or_admin" ON "public"."media" FOR UPDATE USING ((("uploaded_by" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = 'admin'::"text"))))));



ALTER TABLE "public"."missions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "missions_select_public" ON "public"."missions" FOR SELECT USING (true);



ALTER TABLE "public"."news" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "news_delete_admin" ON "public"."news" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = 'admin'::"text")))));



CREATE POLICY "news_insert_staff" ON "public"."news" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"]))))));



CREATE POLICY "news_select_public" ON "public"."news" FOR SELECT USING ((NOT "is_draft"));



CREATE POLICY "news_update_author_or_admin" ON "public"."news" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND (("p"."role" = 'admin'::"text") OR ("p"."id" = "news"."author_id"))))));



CREATE POLICY "notif_insert_server" ON "public"."notifications" FOR INSERT WITH CHECK (("auth"."uid"() IS NOT NULL));



CREATE POLICY "notif_select_owner" ON "public"."notifications" FOR SELECT USING (("user_id" = "auth"."uid"()));



ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_admin_update" ON "public"."profiles" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = 'admin'::"text"))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = 'admin'::"text")))));



CREATE POLICY "profiles_insert_self" ON "public"."profiles" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "profiles_select_public" ON "public"."profiles" FOR SELECT USING (true);



CREATE POLICY "profiles_update_self" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



ALTER TABLE "public"."team_memberships" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."teams" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "teams_delete_admin" ON "public"."teams" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = 'admin'::"text")))));



CREATE POLICY "teams_insert_coach_admin" ON "public"."teams" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"]))))));



CREATE POLICY "teams_select_public" ON "public"."teams" FOR SELECT USING (true);



CREATE POLICY "teams_update_coach_admin" ON "public"."teams" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"]))))));



CREATE POLICY "tm_delete_staff" ON "public"."team_memberships" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"]))))));



CREATE POLICY "tm_insert_staff" ON "public"."team_memberships" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"]))))));



CREATE POLICY "tm_select_user_or_staff" ON "public"."team_memberships" FOR SELECT USING ((("auth"."uid"() = "user_id") OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"])))))));



ALTER TABLE "public"."trainings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "trainings_insert_staff" ON "public"."trainings" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"]))))));



CREATE POLICY "trainings_select_public" ON "public"."trainings" FOR SELECT USING (true);



CREATE POLICY "trainings_update_staff" ON "public"."trainings" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"]))))));



ALTER TABLE "public"."user_badges" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "user_badges_insert_staff_or_self" ON "public"."user_badges" FOR INSERT WITH CHECK ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"])))))));



CREATE POLICY "user_badges_select_owner_or_staff" ON "public"."user_badges" FOR SELECT USING ((("user_id" = "auth"."uid"()) OR (EXISTS ( SELECT 1
   FROM "public"."profiles" "p"
  WHERE (("p"."id" = "auth"."uid"()) AND ("p"."role" = ANY (ARRAY['coach'::"text", 'admin'::"text"])))))));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."handle_auth_user_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_auth_user_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_auth_user_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_auth_user"() TO "service_role";


















GRANT ALL ON TABLE "public"."attendance" TO "anon";
GRANT ALL ON TABLE "public"."attendance" TO "authenticated";
GRANT ALL ON TABLE "public"."attendance" TO "service_role";



GRANT ALL ON TABLE "public"."audit_logs" TO "anon";
GRANT ALL ON TABLE "public"."audit_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."audit_logs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."audit_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."audit_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."audit_logs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."badges" TO "anon";
GRANT ALL ON TABLE "public"."badges" TO "authenticated";
GRANT ALL ON TABLE "public"."badges" TO "service_role";



GRANT ALL ON TABLE "public"."event_registrations" TO "anon";
GRANT ALL ON TABLE "public"."event_registrations" TO "authenticated";
GRANT ALL ON TABLE "public"."event_registrations" TO "service_role";



GRANT ALL ON TABLE "public"."events" TO "anon";
GRANT ALL ON TABLE "public"."events" TO "authenticated";
GRANT ALL ON TABLE "public"."events" TO "service_role";



GRANT ALL ON TABLE "public"."media" TO "anon";
GRANT ALL ON TABLE "public"."media" TO "authenticated";
GRANT ALL ON TABLE "public"."media" TO "service_role";



GRANT ALL ON TABLE "public"."missions" TO "anon";
GRANT ALL ON TABLE "public"."missions" TO "authenticated";
GRANT ALL ON TABLE "public"."missions" TO "service_role";



GRANT ALL ON TABLE "public"."news" TO "anon";
GRANT ALL ON TABLE "public"."news" TO "authenticated";
GRANT ALL ON TABLE "public"."news" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."team_memberships" TO "anon";
GRANT ALL ON TABLE "public"."team_memberships" TO "authenticated";
GRANT ALL ON TABLE "public"."team_memberships" TO "service_role";



GRANT ALL ON TABLE "public"."teams" TO "anon";
GRANT ALL ON TABLE "public"."teams" TO "authenticated";
GRANT ALL ON TABLE "public"."teams" TO "service_role";



GRANT ALL ON TABLE "public"."trainings" TO "anon";
GRANT ALL ON TABLE "public"."trainings" TO "authenticated";
GRANT ALL ON TABLE "public"."trainings" TO "service_role";



GRANT ALL ON TABLE "public"."user_badges" TO "anon";
GRANT ALL ON TABLE "public"."user_badges" TO "authenticated";
GRANT ALL ON TABLE "public"."user_badges" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






























RESET ALL;
