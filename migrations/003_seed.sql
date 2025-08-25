-- Seed: roles and example data
-- Nota: crea usuarios en Supabase Auth primero; luego asigna roles actualizando profiles.
-- Ejemplo: (reemplaza UUID con el id del usuario creado en Auth)
-- insert into public.profiles (id, email, full_name, display_name, role) values ('00000000-0000-0000-0000-000000000000','admin@example.com','Admin User','Admin','admin');

-- Ejemplo equipos y badges
insert into public.teams (id, name, slug, description) values (gen_random_uuid(), 'Equipo A', 'equipo-a', 'Equipo principal');
insert into public.badges (id, code, title, description) values (gen_random_uuid(), 'FIRST_LOGIN', 'Primer acceso', 'Otorgado al registrarse');

-- Example event and training
insert into public.events (id, title, description, starts_at, ends_at, created_at) values (gen_random_uuid(), 'Torneo local', 'Torneo abierto', now() + interval '7 days', now() + interval '7 days' + interval '4 hours', now());
insert into public.trainings (id, team_id, title, description, scheduled_at, created_at) values (gen_random_uuid(), (select id from public.teams limit 1), 'Entrenamiento sem.', 'Entrenamiento semanal', now() + interval '2 days', now());
