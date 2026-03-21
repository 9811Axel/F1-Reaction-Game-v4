-- Run this in Supabase SQL Editor (once) for your project.
-- This schema stores:
--  - user profiles (country)
--  - reaction attempts (for counting + computing best times)
--  - a view that computes best time per user for the leaderboard

-- Profiles table for storing country + email.
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  country text not null default 'Other',
  display_name text not null default 'Racer',
  created_at timestamptz not null default now()
);

-- If the profiles table already existed, ensure the new column is present.
alter table public.profiles
add column if not exists display_name text not null default 'Racer';

-- Each button press becomes an attempt row.
create table if not exists public.attempts (
  id bigserial primary key,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  email text not null,
  country text not null,
  display_name text,
  reaction_time_ms integer not null,
  is_valid boolean not null default false,
  is_false_start boolean not null default false,
  created_at timestamptz not null default now(),
  date_key text not null
);

alter table public.attempts
add column if not exists display_name text;

-- View for leaderboard: best valid time per user.
-- Uses only public.attempts so RLS on profiles does not hide other racers.
create or replace view public.leaderboard_best_times as
select
  a.user_id,
  coalesce(nullif(nullif(trim(a.display_name), ''), 'Racer'), a.email) as display_name,
  a.country as country,
  min(a.reaction_time_ms) as best_time_ms
from public.attempts a
where
  a.is_valid = true
  and a.is_false_start = false
  and a.reaction_time_ms >= 100
group by
  a.user_id,
  coalesce(nullif(nullif(trim(a.display_name), ''), 'Racer'), a.email),
  a.country;

-- Leaderboard by average valid reaction time (lower is better).
create or replace view public.leaderboard_avg_times as
select
  a.user_id,
  coalesce(nullif(nullif(trim(a.display_name), ''), 'Racer'), a.email) as display_name,
  a.country as country,
  round(avg(a.reaction_time_ms))::bigint as avg_time_ms
from public.attempts a
where
  a.is_valid = true
  and a.is_false_start = false
  and a.reaction_time_ms >= 100
group by
  a.user_id,
  coalesce(nullif(nullif(trim(a.display_name), ''), 'Racer'), a.email),
  a.country;

-- Enable Row Level Security
alter table public.profiles enable row level security;
alter table public.attempts enable row level security;

-- PROFILES RLS (drop first so you can re-run this whole file safely)
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;

create policy "profiles_select_own" on public.profiles
for select
to authenticated
using (auth.uid() = user_id);

create policy "profiles_insert_own" on public.profiles
for insert
to authenticated
with check (auth.uid() = user_id);

create policy "profiles_update_own" on public.profiles
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- ATTEMPTS RLS
drop policy if exists "attempts_insert_own" on public.attempts;
drop policy if exists "attempts_select_authenticated_all" on public.attempts;

-- Users can insert attempts only for themselves.
create policy "attempts_insert_own" on public.attempts
for insert
to authenticated
with check (auth.uid() = user_id);

-- Leaderboard needs to read all users' attempts.
-- Your UI only shows best times (not full raw attempts), but RLS must allow reading for the view.
create policy "attempts_select_authenticated_all" on public.attempts
for select
to authenticated
using (true);

