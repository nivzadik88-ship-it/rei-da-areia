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

-- =====================================================================
-- Analytics: anonymous gameplay events (no cookies, no personal data).
-- The game can only INSERT events. Reading happens through stats_overview(),
-- which returns totals only — never individual rows.
-- =====================================================================
create table if not exists public.events (
  id       bigint generated always as identity primary key,
  at       timestamptz not null default now(),
  visitor  text not null check (char_length(visitor) <= 40),   -- random id kept in the browser
  session  text not null check (char_length(session) <= 40),
  run      text check (char_length(run) <= 40),                 -- one career
  name     text not null check (name ~ '^[a-z_]{2,24}$'),
  stop     smallint check (stop between 0 and 8),
  props    jsonb not null default '{}' check (pg_column_size(props) < 1500),
  version  text check (char_length(version) <= 12),
  device   text check (char_length(device) <= 12)
);
create index if not exists events_at_idx on public.events (at);
create index if not exists events_name_idx on public.events (name, at);
alter table public.events enable row level security;
drop policy if exists "anyone can log events" on public.events;
create policy "anyone can log events" on public.events for insert to anon, authenticated with check (at > now() - interval '5 minutes');
grant insert on public.events to anon, authenticated;
revoke select, update, delete on public.events from anon, authenticated;

create or replace function public.stats_overview(days int default 30)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
with ev as (select * from events where at > now() - make_interval(days => least(greatest(days, 1), 365))),
ends as (select (props->>'money')::bigint as money, (props->>'made')::boolean as made from ev where name = 'career_end')
select jsonb_build_object(
  'days', days,
  'visitors', (select count(distinct visitor) from ev),
  'sessions', (select count(distinct session) from ev),
  'starts', (select count(*) from ev where name = 'career_start'),
  'finishes', (select count(*) from ends),
  'millions', (select count(*) from ends where made),
  'avg_money', (select coalesce(round(avg(money)), 0) from ends),
  'median_money', (select coalesce(percentile_cont(0.5) within group (order by money), 0) from ends),
  'weekly_starts', (select count(*) from ev where name = 'career_start' and (props->>'weekly') is not null),
  'shares', (select count(*) from ev where name = 'share_click'),
  'shared_views', (select count(*) from ev where name = 'shared_view'),
  'daily', (select coalesce(jsonb_agg(d order by d->>'day'), '[]') from (
      select jsonb_build_object('day', to_char(date_trunc('day', at), 'YYYY-MM-DD'),
        'visitors', count(distinct visitor),
        'starts', count(*) filter (where name = 'career_start'),
        'finishes', count(*) filter (where name = 'career_end')) d
      from ev group by date_trunc('day', at)) x),
  'funnel', (select coalesce(jsonb_agg(jsonb_build_object('stop', s, 'runs', n) order by s), '[]') from (
      select stop as s, count(distinct run) as n from ev where name = 'stop_done' group by stop) f),
  'placements', (select coalesce(jsonb_object_agg(p, n), '{}') from (
      select props->>'placement' as p, count(*) as n from ev where name = 'stop_done' group by 1) x),
  'money_buckets', (select coalesce(jsonb_agg(jsonb_build_object('bucket', b, 'n', n) order by b), '[]') from (
      select least(width_bucket(money, 0, 1200000, 12), 13) as b, count(*) as n from ends group by 1) x),
  'attacks', (select coalesce(jsonb_object_agg(k, n), '{}') from (select props->>'atk' k, count(*) n from ev where name = 'plan' group by 1) x),
  'defences', (select coalesce(jsonb_object_agg(k, n), '{}') from (select props->>'def' k, count(*) n from ev where name = 'plan' group by 1) x),
  'training', (select coalesce(jsonb_object_agg(k, n), '{}') from (select jsonb_array_elements_text(props->'picks') k, count(*) n from ev where name = 'training' group by 1) x),
  'golden', (select jsonb_build_object('played', count(*), 'won', count(*) filter (where (props->>'won')::boolean)) from ev where name = 'golden'),
  'incidents', (select coalesce(jsonb_object_agg(k, jsonb_build_object('shown', n, 'yes', y)), '{}') from (
      select props->>'id' k, count(*) n, count(*) filter (where (props->>'yes')::boolean) y from ev where name = 'incident' group by 1) x),
  'devices', (select coalesce(jsonb_object_agg(coalesce(device, '?'), n), '{}') from (select device, count(distinct visitor) n from ev group by 1) x),
  'referrers', (select coalesce(jsonb_object_agg(r, n), '{}') from (
      select coalesce(nullif(props->>'ref', ''), 'direct') r, count(*) n from ev where name = 'visit' group by 1 order by 2 desc limit 8) x),
  'versions', (select coalesce(jsonb_object_agg(coalesce(version, '?'), n), '{}') from (select version, count(distinct session) n from ev group by 1) x)
);
$$;
grant execute on function public.stats_overview(int) to anon, authenticated;
