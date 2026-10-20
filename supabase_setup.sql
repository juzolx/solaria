-- Solaria online setup for Supabase.
-- Paste this whole file into Supabase -> SQL Editor -> New query, then press Run.
-- It's safe to run again: it only creates what's missing.

-- ============================================================
-- Players: one row per player, just a name
-- ============================================================
create table if not exists public.players (
  id uuid primary key references auth.users on delete cascade,
  name text not null unique check (char_length(name) between 3 and 16),
  created_at timestamptz not null default now()
);

-- ============================================================
-- Hardcore runs and the leaderboard (each player's deepest run)
-- ============================================================
create table if not exists public.hc_runs (
  id bigserial primary key,
  player_id uuid not null references public.players on delete cascade,
  name text not null,
  floor int not null check (floor between 1 and 100000),
  level int not null check (level between 1 and 10000),
  title text not null default '',
  race text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists hc_runs_floor on public.hc_runs (floor desc);

create or replace view public.leaderboard as
  select distinct on (player_id) player_id, name, floor, level, title, race, created_at
  from public.hc_runs
  order by player_id, floor desc, created_at asc;

-- ============================================================
-- Guilds (max 20 members)
-- ============================================================
create table if not exists public.guilds (
  id bigserial primary key,
  name text not null unique check (char_length(name) between 3 and 24),
  tag text not null check (char_length(tag) between 2 and 4),
  leader uuid not null references public.players on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.guild_members (
  player_id uuid primary key references public.players on delete cascade,
  guild_id bigint not null references public.guilds on delete cascade,
  name text not null,
  best_floor int not null default 0 check (best_floor between 0 and 100000),
  joined_at timestamptz not null default now()
);
create index if not exists guild_members_guild on public.guild_members (guild_id);

create or replace view public.guild_rankings as
  select g.id, g.name, g.tag, g.leader,
         count(m.player_id)::int as members,
         coalesce(sum(m.best_floor), 0)::int as power
  from public.guilds g
  left join public.guild_members m on m.guild_id = g.id
  group by g.id;

-- No more than 20 members
create or replace function public.check_guild_size() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.guild_members where guild_id = new.guild_id) >= 20 then
    raise exception 'guild_full';
  end if;
  return new;
end $$;
drop trigger if exists guild_size on public.guild_members;
create trigger guild_size before insert on public.guild_members
  for each row execute function public.check_guild_size();

-- When someone leaves: an empty guild is deleted, and a leader who leaves hands over to the oldest member
create or replace function public.after_member_leaves() returns trigger
language plpgsql security definer set search_path = public as $$
declare next_leader uuid;
begin
  if not exists (select 1 from public.guild_members where guild_id = old.guild_id) then
    delete from public.guilds where id = old.guild_id;
  elsif (select leader from public.guilds where id = old.guild_id) = old.player_id then
    select player_id into next_leader from public.guild_members
      where guild_id = old.guild_id order by joined_at asc limit 1;
    update public.guilds set leader = next_leader where id = old.guild_id;
  end if;
  return old;
end $$;
drop trigger if exists member_leaves on public.guild_members;
create trigger member_leaves after delete on public.guild_members
  for each row execute function public.after_member_leaves();

-- ============================================================
-- Weekly guild raids: 3 attacks per player per day, damage adds up
-- ============================================================
create table if not exists public.raid_hits (
  id bigserial primary key,
  guild_id bigint not null references public.guilds on delete cascade,
  player_id uuid not null references public.players on delete cascade,
  name text not null,
  week text not null,
  day text not null,
  damage bigint not null check (damage between 0 and 1000000000000000),
  created_at timestamptz not null default now()
);
create index if not exists raid_hits_guild_week on public.raid_hits (guild_id, week);

create or replace function public.check_raid_limit() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.raid_hits where player_id = new.player_id and day = new.day) >= 3 then
    raise exception 'raid_limit';
  end if;
  return new;
end $$;
drop trigger if exists raid_limit on public.raid_hits;
create trigger raid_limit before insert on public.raid_hits
  for each row execute function public.check_raid_limit();

create table if not exists public.raid_claims (
  player_id uuid not null references public.players on delete cascade,
  week text not null,
  guild_id bigint not null references public.guilds on delete cascade,
  claimed_at timestamptz not null default now(),
  primary key (player_id, week)
);

-- ============================================================
-- Who can do what (row level security)
-- Everyone can read; you can only write your own rows.
-- ============================================================
alter table public.players enable row level security;
alter table public.hc_runs enable row level security;
alter table public.guilds enable row level security;
alter table public.guild_members enable row level security;
alter table public.raid_hits enable row level security;
alter table public.raid_claims enable row level security;

drop policy if exists "read players" on public.players;
create policy "read players" on public.players for select using (true);
drop policy if exists "add self" on public.players;
create policy "add self" on public.players for insert to authenticated with check (id = auth.uid());
drop policy if exists "rename self" on public.players;
create policy "rename self" on public.players for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "read runs" on public.hc_runs;
create policy "read runs" on public.hc_runs for select using (true);
drop policy if exists "add own runs" on public.hc_runs;
create policy "add own runs" on public.hc_runs for insert to authenticated with check (player_id = auth.uid());

drop policy if exists "read guilds" on public.guilds;
create policy "read guilds" on public.guilds for select using (true);
drop policy if exists "found guild" on public.guilds;
create policy "found guild" on public.guilds for insert to authenticated with check (leader = auth.uid());

drop policy if exists "read members" on public.guild_members;
create policy "read members" on public.guild_members for select using (true);
drop policy if exists "join guild" on public.guild_members;
create policy "join guild" on public.guild_members for insert to authenticated with check (player_id = auth.uid());
drop policy if exists "update self" on public.guild_members;
create policy "update self" on public.guild_members for update to authenticated using (player_id = auth.uid()) with check (player_id = auth.uid());
drop policy if exists "leave guild" on public.guild_members;
create policy "leave guild" on public.guild_members for delete to authenticated using (player_id = auth.uid());

drop policy if exists "read hits" on public.raid_hits;
create policy "read hits" on public.raid_hits for select using (true);
drop policy if exists "hit own guild boss" on public.raid_hits;
create policy "hit own guild boss" on public.raid_hits for insert to authenticated with check (
  player_id = auth.uid()
  and exists (select 1 from public.guild_members m where m.player_id = auth.uid() and m.guild_id = raid_hits.guild_id)
);

drop policy if exists "read claims" on public.raid_claims;
create policy "read claims" on public.raid_claims for select using (true);
drop policy if exists "claim own reward" on public.raid_claims;
create policy "claim own reward" on public.raid_claims for insert to authenticated with check (
  player_id = auth.uid()
  and exists (select 1 from public.guild_members m where m.player_id = auth.uid() and m.guild_id = raid_claims.guild_id)
);

grant select on public.players, public.hc_runs, public.guilds, public.guild_members, public.raid_hits, public.raid_claims,
  public.leaderboard, public.guild_rankings to anon, authenticated;
grant insert, update on public.players to authenticated;
grant insert on public.hc_runs, public.guilds, public.raid_hits, public.raid_claims to authenticated;
grant insert, update, delete on public.guild_members to authenticated;
grant usage, select on all sequences in schema public to authenticated;

-- ---------------------------------------------------------------------------
-- Cloud backup (added in 0.7.5). Each player's heroes, Codex and stash, packed
-- into one text blob. Restoring on another device uses the backup code, which
-- is the only way to read a backup (through get_cloud_save below).
-- ---------------------------------------------------------------------------
create table if not exists public.cloud_saves (
  code text primary key check (char_length(code) between 8 and 16),
  owner uuid not null default auth.uid() references auth.users on delete cascade,
  data text not null check (char_length(data) < 4000000),
  updated_at timestamptz not null default now()
);
alter table public.cloud_saves enable row level security;

drop policy if exists "back up own" on public.cloud_saves;
create policy "back up own" on public.cloud_saves for insert to authenticated with check (owner = auth.uid());
drop policy if exists "update own backup" on public.cloud_saves;
create policy "update own backup" on public.cloud_saves for update to authenticated using (owner = auth.uid()) with check (owner = auth.uid());
-- No select policy: nobody can list backups. Reading one needs its code:
create or replace function public.get_cloud_save(p_code text) returns text
language sql security definer set search_path = public as $$
  select data from public.cloud_saves where code = p_code;
$$;
revoke all on function public.get_cloud_save(text) from public;
grant execute on function public.get_cloud_save(text) to authenticated;

create or replace function public.touch_cloud_save() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;
drop trigger if exists cloud_save_touch on public.cloud_saves;
create trigger cloud_save_touch before update on public.cloud_saves for each row execute function public.touch_cloud_save();

grant insert, update on public.cloud_saves to authenticated;

-- Stage 4 (Apple rule): players can delete their online account from inside the game.
-- Deleting the login removes their name, runs, guild seats, raid hits and cloud backups (all cascade).
create or replace function public.delete_my_account() returns void
language sql security definer set search_path = public, auth as $$
  delete from auth.users where id = auth.uid();
$$;
revoke all on function public.delete_my_account() from public;
grant execute on function public.delete_my_account() to authenticated;
