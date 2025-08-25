
-- Políticas RLS (profiles/teams/news/events/trainings/attendance/media/...).
-- Asume uso de auth.uid() y que profiles.id == auth.uid().

-- Profiles
alter table public.profiles enable row level security;

create policy "profiles_select_public" on public.profiles
  for select using ( true );

create policy "profiles_insert_self" on public.profiles
  for insert with check ( auth.uid() = id );

create policy "profiles_update_self" on public.profiles
  for update using ( auth.uid() = id ) with check ( auth.uid() = id );

-- Allow admins to select/update all profiles via service role or explicit policy:
create policy "profiles_admin_update" on public.profiles
  for update using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  ) with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- Teams
alter table public.teams enable row level security;

create policy "teams_select_public" on public.teams
  for select using ( true );

create policy "teams_insert_coach_admin" on public.teams
  for insert with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
  );

create policy "teams_update_coach_admin" on public.teams
  for update using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
  );

create policy "teams_delete_admin" on public.teams
  for delete using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- Team memberships: coaches/admins can insert/remove, members can select their own membership
alter table public.team_memberships enable row level security;

create policy "tm_select_user_or_staff" on public.team_memberships
  for select using (
    auth.uid() = user_id
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
  );

create policy "tm_insert_staff" on public.team_memberships
  for insert with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
  );

create policy "tm_delete_staff" on public.team_memberships
  for delete using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
  );

-- News
alter table public.news enable row level security;

create policy "news_select_public" on public.news
  for select using ( not is_draft );

create policy "news_insert_staff" on public.news
  for insert with check (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
  );

create policy "news_update_author_or_admin" on public.news
  for update using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and (p.role = 'admin' or p.id = news.author_id))
  );

create policy "news_delete_admin" on public.news
  for delete using (
    exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- Events
alter table public.events enable row level security;

create policy "events_select_public" on public.events
  for select using ( true );

create policy "events_insert_staff" on public.events
  for insert with check ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin')) );

create policy "events_update_staff" on public.events
  for update using ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin')) );

create policy "events_delete_admin" on public.events
  for delete using ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin') );

-- Trainings
alter table public.trainings enable row level security;

create policy "trainings_select_public" on public.trainings
  for select using ( true );

create policy "trainings_insert_staff" on public.trainings
  for insert with check ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin')) );

create policy "trainings_update_staff" on public.trainings
  for update using ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin')) );

-- Attendance
alter table public.attendance enable row level security;

create policy "attendance_select_owner_or_staff" on public.attendance
  for select using (
    auth.uid() = user_id
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
  );

create policy "attendance_insert_staff" on public.attendance
  for insert with check ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin')) );

create policy "attendance_update_staff_or_self" on public.attendance
  for update using (
    auth.uid() = user_id
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
  ) with check (
    auth.uid() = user_id
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
  );

-- Media
alter table public.media enable row level security;

create policy "media_select_public" on public.media
  for select using ( public = true );

create policy "media_insert_auth" on public.media
  for insert with check ( auth.uid() IS NOT NULL );

create policy "media_update_owner_or_admin" on public.media
  for update using (
    uploaded_by = auth.uid()
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
  );

-- Missions & Badges
alter table public.missions enable row level security;
create policy "missions_select_public" on public.missions for select using ( true );

alter table public.badges enable row level security;
create policy "badges_select_public" on public.badges for select using ( true );

alter table public.user_badges enable row level security;
create policy "user_badges_select_owner_or_staff" on public.user_badges
  for select using (
    user_id = auth.uid()
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
  );

create policy "user_badges_insert_staff_or_self" on public.user_badges
  for insert with check (
    user_id = auth.uid()
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
  );

-- Event registrations
alter table public.event_registrations enable row level security;
create policy "er_insert_auth" on public.event_registrations for insert with check ( auth.uid() = user_id );
create policy "er_select_user_or_staff" on public.event_registrations for select using ( auth.uid() = user_id or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('coach','admin')) );

-- Notifications & Audit
alter table public.notifications enable row level security;
create policy "notif_select_owner" on public.notifications for select using ( user_id = auth.uid() );
create policy "notif_insert_server" on public.notifications for insert with check ( auth.uid() IS NOT NULL );

alter table public.audit_logs enable row level security;
-- Only admins (via service role or role check) can insert/select audit logs from client; but we'll allow server inserts via service key.
create policy "audit_no_client_access" on public.audit_logs for select using ( false );
create policy "audit_insert_server" on public.audit_logs for insert with check ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin') );
