-- Triggers and helper functions

-- Function to upsert profile when auth.users created
create or replace function public.handle_new_auth_user()
returns trigger as $$
begin
  if exists (select 1 from public.profiles where id = new.id) then
    update public.profiles
      set
        email = coalesce(new.email, public.profiles.email),
        full_name = coalesce(new.raw_user_meta_data->>'full_name', public.profiles.full_name),
        display_name = coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1)),
        avatar_url = coalesce(new.raw_user_meta_data->>'avatar_url', public.profiles.avatar_url),
        updated_at = now()
    where id = new.id;
    return new;
  end if;

  insert into public.profiles (id, email, full_name, display_name, avatar_url, created_at)
  values (
    new.id,
    new.email,
    nullif(new.raw_user_meta_data->>'full_name',''),
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email,'@',1)),
    new.raw_user_meta_data->>'avatar_url',
    now()
  );

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists handle_new_auth_user on auth.users;
create trigger handle_new_auth_user
  after insert on auth.users
  for each row
  execute procedure public.handle_new_auth_user();

-- Trigger to update updated_at on profiles/teams/trainings/news/events/media when row updated
create or replace function public.timestamp_on_update()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Attach timestamp triggers
drop trigger if exists profiles_timestamp on public.profiles;
create trigger profiles_timestamp before update on public.profiles for each row execute procedure public.timestamp_on_update();

drop trigger if exists teams_timestamp on public.teams;
create trigger teams_timestamp before update on public.teams for each row execute procedure public.timestamp_on_update();

drop trigger if exists trainings_timestamp on public.trainings;
create trigger trainings_timestamp before update on public.trainings for each row execute procedure public.timestamp_on_update();

drop trigger if exists news_timestamp on public.news;
create trigger news_timestamp before update on public.news for each row execute procedure public.timestamp_on_update();

drop trigger if exists events_timestamp on public.events;
create trigger events_timestamp before update on public.events for each row execute procedure public.timestamp_on_update();
