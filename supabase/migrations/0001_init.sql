-- ============================================================================
-- Aura Habit Tracker — initial schema (Phase 0)
-- ----------------------------------------------------------------------------
-- Design: every synced entity uses a uniform shape so the client SyncEngine has
-- ONE generic code path:
--     id text primary key      -- app-generated id (uuid, or "habitId|date" for logs,
--                                  or the user id for singletons like settings)
--     user_id uuid             -- owner; RLS restricts every row to its owner
--     data jsonb               -- the entity's full toJson() payload
--     updated_at timestamptz   -- last-write-wins clock (also drives Realtime)
--     deleted_at timestamptz   -- soft-delete tombstone (null = active)
--
-- Run this once in Supabase → SQL Editor (or via the Supabase CLI). It is
-- idempotent, so re-running is safe.
-- ============================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- updated_at touch trigger
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ===========================================================================
-- profiles (1 row per auth user; auto-created on signup)
-- ===========================================================================
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text,
  full_name   text,
  avatar_url  text,
  is_premium  boolean not null default false,
  data        jsonb   not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists profiles_select_own on public.profiles;
drop policy if exists profiles_insert_own on public.profiles;
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select using (auth.uid() = id);
create policy profiles_insert_own on public.profiles
  for insert with check (auth.uid() = id);
create policy profiles_update_own on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();

-- Auto-create a profile row whenever a new auth user is created (Google or email).
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ===========================================================================
-- Generic synced-entity tables (habits, logs, categories, goals, journal,
-- achievements, settings, gamification) — created in a loop for consistency.
-- ===========================================================================
do $$
declare
  t text;
  tables text[] := array[
    'habits', 'habit_logs', 'categories', 'goals',
    'journal_entries', 'achievements', 'settings', 'gamification'
  ];
begin
  foreach t in array tables loop
    -- table
    execute format($f$
      create table if not exists public.%I (
        id          text primary key,
        user_id     uuid not null references auth.users(id) on delete cascade,
        data        jsonb not null default '{}'::jsonb,
        updated_at  timestamptz not null default now(),
        deleted_at  timestamptz
      );
    $f$, t);

    execute format('alter table public.%I enable row level security;', t);

    -- RLS: owner-only for every operation
    execute format('drop policy if exists %I on public.%I;', t || '_select_own', t);
    execute format('drop policy if exists %I on public.%I;', t || '_insert_own', t);
    execute format('drop policy if exists %I on public.%I;', t || '_update_own', t);
    execute format('drop policy if exists %I on public.%I;', t || '_delete_own', t);
    execute format('create policy %I on public.%I for select using (auth.uid() = user_id);', t || '_select_own', t);
    execute format('create policy %I on public.%I for insert with check (auth.uid() = user_id);', t || '_insert_own', t);
    execute format('create policy %I on public.%I for update using (auth.uid() = user_id) with check (auth.uid() = user_id);', t || '_update_own', t);
    execute format('create policy %I on public.%I for delete using (auth.uid() = user_id);', t || '_delete_own', t);

    -- index for incremental pulls (user_id + updated_at)
    execute format('create index if not exists %I on public.%I (user_id, updated_at);', t || '_user_updated_idx', t);

    -- updated_at trigger
    execute format('drop trigger if exists %I on public.%I;', t || '_set_updated_at', t);
    execute format('create trigger %I before update on public.%I for each row execute function public.set_updated_at();', t || '_set_updated_at', t);
  end loop;
end;
$$;

-- ===========================================================================
-- Realtime: publish all synced tables so the client gets live change streams.
-- ===========================================================================
do $$
declare
  t text;
  tables text[] := array[
    'profiles', 'habits', 'habit_logs', 'categories', 'goals',
    'journal_entries', 'achievements', 'settings', 'gamification'
  ];
begin
  foreach t in array tables loop
    begin
      execute format('alter publication supabase_realtime add table public.%I;', t);
    exception
      when duplicate_object then null;  -- already published
      when undefined_object then null;  -- publication missing (non-Supabase pg)
    end;
  end loop;
end;
$$;
