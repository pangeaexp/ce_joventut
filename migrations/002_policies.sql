-- 002_policies.sql: policies for roles

-- Helper function: get role from auth (using auth.uid in profiles)
-- Allow users to insert their own profile (signup)
create policy "profiles_insert_own" on profiles
for insert
with check ( auth.uid() = id );

create policy "profiles_select_public" on profiles
for select
using ( true );

create policy "profiles_update_own" on profiles
for update
using ( auth.uid() = id )
with check ( auth.uid() = id );

-- Teams: coaches and admins can insert/update/delete, members can select
create policy "teams_select" on teams
for select
using ( true );

create policy "teams_insert_coach_admin" on teams
for insert
with check (
exists (
select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin')
)
);

create policy "teams_update_coach_admin" on teams
for update
using (
exists (
select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin')
)
);

create policy "teams_delete_admin" on teams
for delete
using (
exists (
select 1 from profiles p where p.id = auth.uid() and p.role = 'admin'
)
);

-- News: authors, coaches, admins can insert/update; public select
create policy "news_select" on news
for select using ( true );

create policy "news_insert_roles" on news
for insert
with check (
exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
);

create policy "news_update_author_or_admin" on news
for update
using (
exists (select 1 from profiles p where p.id = auth.uid() and (p.role = 'admin' or p.id = news.author_id))
);

-- Trainings: coaches and admins insert/update; members select
create policy "trainings_select" on trainings for select using ( true );

create policy "trainings_insert_coach_admin" on trainings
for insert
with check ( exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin')) );

create policy "trainings_update_coach_admin" on trainings
for update
using ( exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin')) );

-- Attendance: coaches and admins can insert/update; members select their own
create policy "attendance_insert_coach_admin" on attendance
for insert
with check ( exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin')) );

create policy "attendance_update_coach_admin_or_self" on attendance
for update
using (
exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
or auth.uid() = attendance.user_id
);

create policy "attendance_select" on attendance for select using (
auth.uid() = attendance.user_id
or exists (select 1 from profiles p where p.id = auth.uid() and p.role in ('coach','admin'))
);

-- Media: public bucket -> allow select; upload by any authenticated user
create policy "media_select" on media for select using ( public = true );
create policy "media_insert_auth" on media for insert with check ( auth.uid() IS NOT NULL );

