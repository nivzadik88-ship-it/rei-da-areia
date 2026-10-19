-- Rei da Areia · leaderboard, shared careers and weekly challenge
-- Run once in Supabase → SQL Editor. Safe to re-run.

create extension if not exists pgcrypto;

create table if not exists public.careers (
  id            uuid primary key default gen_random_uuid(),
  created_at    timestamptz not null default now(),
  player_name   text not null check (char_length(player_name) between 1 and 14),
  face          text not null default 'a01' check (char_length(face) <= 4),
  club          text not null default 'bot' check (char_length(club) <= 4),
  side          text not null default 'L' check (side in ('L','R')),
  money         integer not null check (money between -100000 and 3000000),
  made_million  boolean generated always as (money >= 1000000) stored,
  titles        smallint not null default 0 check (titles between 0 and 8),
  crowned       boolean not null default false,
  world         boolean not null default false,
  ovr           smallint not null check (ovr between 1 and 99),
  results       jsonb not null,           -- [{ev, placement, prize}] one per stop
  money_hist    jsonb not null,           -- bankroll after each stop
  weekly_id     text check (weekly_id ~ '^\d{4}-W\d{2}$'),
  seconds       integer check (seconds between 0 and 86400),
  version       text
);
create index if not exists careers_money_idx  on public.careers (money desc);
create index if not exists careers_weekly_idx on public.careers (weekly_id, money desc);

alter table public.careers enable row level security;

-- Anyone may read (leaderboards + share pages). Nobody may write directly.
drop policy if exists "careers are public" on public.careers;
create policy "careers are public" on public.careers for select using (true);
grant select on public.careers to anon, authenticated;
revoke insert, update, delete on public.careers from anon, authenticated;

-- Submissions go through this function, which sanity-checks the career
-- (a browser game can't be fully cheat-proof, but this stops casual tampering).
create or replace function public.submit_career(c jsonb)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
  n_results int := jsonb_array_length(c->'results');
  n_hist int := jsonb_array_length(c->'money_hist');
  prize_sum bigint;
  recent int;
begin
  if n_results <> 8 or n_hist < 8 then raise exception 'career must have 8 stops'; end if;
  select coalesce(sum((r->>'prize')::bigint), 0) into prize_sum from jsonb_array_elements(c->'results') r;
  if prize_sum > 1500000 then raise exception 'prizes out of range'; end if;
  if (c->>'money')::bigint > prize_sum + 900000 then raise exception 'money out of range'; end if;
  if (c->>'money')::bigint <> (c->'money_hist'->>(n_hist - 1))::bigint then raise exception 'history mismatch'; end if;
  -- light rate limit: max 20 careers per name per hour
  select count(*) into recent from careers where player_name = c->>'player_name' and created_at > now() - interval '1 hour';
  if recent >= 20 then raise exception 'slow down'; end if;

  insert into careers (player_name, face, club, side, money, titles, crowned, world, ovr, results, money_hist, weekly_id, seconds, version)
  values (
    left(trim(c->>'player_name'), 14), coalesce(c->>'face','a01'), coalesce(c->>'club','bot'), coalesce(c->>'side','L'),
    (c->>'money')::int, coalesce((c->>'titles')::smallint, 0), coalesce((c->>'crowned')::boolean, false), coalesce((c->>'world')::boolean, false),
    (c->>'ovr')::smallint, c->'results', c->'money_hist', nullif(c->>'weekly_id',''), (c->>'seconds')::int, c->>'version'
  ) returning id into new_id;
  return new_id;
end $$;
grant execute on function public.submit_career(jsonb) to anon, authenticated;

-- Leaderboard rows without the heavy JSON.
create or replace view public.leaderboard with (security_invoker = true) as
  select id, created_at, player_name, face, club, money, made_million, titles, crowned, world, ovr, weekly_id
  from public.careers;
grant select on public.leaderboard to anon, authenticated;
