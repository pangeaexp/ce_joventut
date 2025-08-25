-- 004_triggers.sql
-- Crea función y trigger para sincronizar auth.users -> profiles

-- Función que crea perfil cuando se registra un nuevo usuario
create or replace function public.handle_new_auth_user()
returns trigger as $$
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
$$ language plpgsql security definer;

-- Trigger que ejecuta la función después de insertar en auth.users
drop trigger if exists handle_new_auth_user on auth.users;
create trigger handle_new_auth_user
  after insert on auth.users
  for each row
  execute procedure public.handle_new_auth_user();

-- Nota:
-- - new.raw_user_meta_data contiene JSON metadata enviada al crear el usuario (e.g. via signUp options).
-- - La función es SECURITY DEFINER para que pueda ejecutarse aunque RLS pueda bloquear operaciones.
-- - Asegúrate de revisar permisos y ajustar si necesitas copiar más campos (phone, locale, etc.).
----