-- 001_init.sql
-- Habilita funciones necesarias
--create extension if not exists pgcrypto;

-- Perfiles
create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  full_name text,
  display_name text,
  role text not null default 'member', -- member | coach | admin
  avatar_url text,
  created_at timestamptz default now()
);

-- Teams
create table if not exists teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  coach_id uuid references profiles(id),
  created_at timestamptz default now()
);

-- News
create table if not exists news (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  content text,
  author_id uuid references profiles(id),
  published_at timestamptz default now()
);

-- Events
create table if not exists events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- Trainings
create table if not exists trainings (
  id uuid primary key default gen_random_uuid(),
  team_id uuid references teams(id),
  title text,
  description text,
  scheduled_at timestamptz,
  created_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- Attendance
create table if not exists attendance (
  id uuid primary key default gen_random_uuid(),
  training_id uuid references trainings(id),
  user_id uuid references profiles(id),
  status text default 'absent', -- present | absent | excused
  recorded_at timestamptz default now()
);

-- Media
create table if not exists media (
  id uuid primary key default gen_random_uuid(),
  bucket text not null,
  path text not null,
  public boolean default true,
  uploaded_by uuid references profiles(id),
  created_at timestamptz default now()
);

-- Missions & Badges
create table if not exists missions (
  id uuid primary key default gen_random_uuid(),
  title text,
  description text,
  starts_at timestamptz,
  ends_at timestamptz
);

create table if not exists badges (
  id uuid primary key default gen_random_uuid(),
  code text unique,
  title text,
  description text
);

-- Enable RLS
alter table profiles enable row level security;
alter table teams enable row level security;
alter table news enable row level security;
alter table events enable row level security;
alter table trainings enable row level security;
alter table attendance enable row level security;
alter table media enable row level security;

----