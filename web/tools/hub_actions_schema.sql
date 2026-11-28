-- H33 PROPOSAL - NOT APPLIED. The hub lane owns web/ only and does not touch the live Supabase project.
-- Whoever applies it (team lead / game build / Mr. E) also has to: (1) enable the Twitch provider in
-- Supabase Auth with the Twitch app's client id+secret, (2) add the hub URL to Auth > Redirect URLs
-- (https://<user>.github.io/<repo>/ exactly, no wildcard). The page probes /auth/v1/settings and shows
-- the sign-in button only when external.twitch is true, so it is safe to ship before either is done.
-- The engine uses the SERVICE key (user://supabase.json), which bypasses RLS: it polls status='queued',
-- executes, then sets status to done|refused and writes a short text into result. Rows are never deleted by viewers.
-- H33b FIX (28 Nov): the first draft keyed identity on auth.jwt()->'user_metadata'->>'provider_id'. user_metadata is
-- WRITABLE BY THE SIGNED-IN USER (supabase.auth.updateUser), so a viewer could have set it to someone else's Twitch id
-- and filed requests as them. Identity now comes from auth.identities (server-owned, not user-editable) through a
-- SECURITY DEFINER function that returns only the caller's own id.
create schema if not exists private;
create or replace function private.my_twitch_id() returns text
  language sql stable security definer set search_path = ''
  as $$ select i.identity_data->>'provider_id' from auth.identities i where i.user_id = auth.uid() and i.provider = 'twitch' limit 1 $$;
revoke all on function private.my_twitch_id() from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.my_twitch_id() to authenticated;
create table if not exists public.hub_actions (
  id           bigint generated always as identity primary key,
  twitch_id    text   not null default private.my_twitch_id(),
  viewer_login text   not null default '' check (char_length(viewer_login) <= 40),  -- display only; the engine keys on twitch_id
  kind         text   not null check (kind in ('wear','dye','sell','buy','respec','reroll','specialize','party_invite','party_join','party_leave')),
  args         jsonb  not null default '{}'::jsonb check (jsonb_typeof(args) = 'object' and pg_column_size(args) <= 600),
  status       text   not null default 'queued' check (status in ('queued','done','refused','expired')),
  result       text   check (char_length(result) <= 200),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists hub_actions_queue on public.hub_actions (status, created_at);
create index if not exists hub_actions_owner on public.hub_actions (twitch_id, created_at desc);
alter table public.hub_actions enable row level security;
-- a viewer reads only their own rows
create policy hub_actions_select_own on public.hub_actions for select to authenticated
  using (twitch_id = private.my_twitch_id());
-- a viewer may only INSERT, only as themselves, only as 'queued', and never set result
create policy hub_actions_insert_own on public.hub_actions for insert to authenticated
  with check (twitch_id = private.my_twitch_id() and status = 'queued' and result is null
              and (select count(*) from public.hub_actions h where h.twitch_id = private.my_twitch_id()
                   and h.status = 'queued') < 20);   -- backlog cap; add a time-window rate limit in an edge function if abused
-- no update / delete policy for authenticated => denied. anon has no policy => denied.
-- APPLIED LIVE by the supervisor 28 Nov 05:18 CT (the file was behind; this line records it):
grant select, insert on public.hub_actions to authenticated;   -- SELECT is live-verified true (05:18); stated here so a fresh apply does not depend on default privileges
revoke select on public.hub_actions from anon;
