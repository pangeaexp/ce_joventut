-- Esquema principal: tablas, FK, índices y extensiones
create extension if not exists pgcrypto;

-- Tabla profiles (referencia a auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  email text,
  full_name text,
  display_name text,
  role text not null default 'member', -- member | coach | admin
  phone text,
  locale text,
  avatar_url text,
  metadata jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_profiles_role on public.profiles (role);

-- Teams
create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique,
  description text,
  coach_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_teams_name on public.teams using gin (to_tsvector('simple', coalesce(name,'')));

-- Team memberships
create table if not exists public.team_memberships (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references public.teams(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  role text default 'player', -- player | assistant | manager
  joined_at timestamptz default now(),
  unique (team_id, user_id)
);

create index if not exists idx_team_memberships_team on public.team_memberships (team_id);
create index if not exists idx_team_memberships_user on public.team_memberships (user_id);

-- News / Announcements
create table if not exists public.news (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  summary text,
  content text,
  author_id uuid references public.profiles(id) on delete set null,
  is_draft boolean default true,
  published_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_news_title on public.news using gin (to_tsvector('simple', coalesce(title,'')));

-- Events
create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  location text,
  starts_at timestamptz,
  ends_at timestamptz,
  all_day boolean default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Trainings (sessions)
create table if not exists public.trainings (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references public.teams(id) on delete cascade,
  title text,
  description text,
  scheduled_at timestamptz,
  duration_minutes integer,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_trainings_team on public.trainings (team_id);
create index if not exists idx_trainings_scheduled on public.trainings (scheduled_at);

-- Attendance
create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  training_id uuid references public.trainings(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  status text not null default 'absent', -- present | absent | excused
  note text,
  recorded_by uuid references public.profiles(id) on delete set null,
  recorded_at timestamptz default now(),
  unique (training_id, user_id)
);

create index if not exists idx_attendance_training on public.attendance (training_id);
create index if not exists idx_attendance_user on public.attendance (user_id);

-- Media (public bucket)
create table if not exists public.media (
  id uuid primary key default gen_random_uuid(),
  bucket text not null,
  path text not null,
  mime_type text,
  size bigint,
  public boolean default true,
  uploaded_by uuid references public.profiles(id) on delete set null,
  associated_type text, -- 'news','event','training','team','profile' etc.
  associated_id uuid,
  metadata jsonb,
  created_at timestamptz default now()
);

create index if not exists idx_media_associated on public.media (associated_type, associated_id);

-- Missions & Badges (Gamification)
create table if not exists public.missions (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  points integer default 0,
  created_at timestamptz default now()
);

create table if not exists public.badges (
  id uuid primary key default gen_random_uuid(),
  code text unique,
  title text not null,
  description text,
  icon_url text,
  created_at timestamptz default now()
);

-- User badges (awarded)
create table if not exists public.user_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  badge_id uuid references public.badges(id) on delete cascade,
  awarded_by uuid references public.profiles(id) on delete set null,
  awarded_at timestamptz default now(),
  unique (user_id, badge_id)
);

-- Registrations for events
create table if not exists public.event_registrations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid references public.events(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  status text default 'registered', -- registered | cancelled | attended
  created_at timestamptz default now(),
  unique (event_id, user_id)
);

create index if not exists idx_event_registrations_event on public.event_registrations (event_id);
create index if not exists idx_event_registrations_user on public.event_registrations (user_id);

-- Audit logs
create table if not exists public.audit_logs (
  id bigserial primary key,
  actor_id uuid references public.profiles(id),
  action text not null,
  object_type text,
  object_id uuid,
  changes jsonb,
  ip inet,
  created_at timestamptz default now()
);

create index if not exists idx_audit_logs_actor on public.audit_logs (actor_id);
create index if not exists idx_audit_logs_action on public.audit_logs (action);

-- Sessions / Notifications (optional)
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  title text,
  body text,
  data jsonb,
  read boolean default false,
  created_at timestamptz default now()
);

create index if not exists idx_notifications_user on public.notifications (user_id);
-- Roles & Permissions extension (optional future)
-- (If you want fine-grained permissions later, add tables role_permissions etc.)

