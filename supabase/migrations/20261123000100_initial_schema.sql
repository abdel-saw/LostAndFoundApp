-- Baseline for a NEW Supabase database. Deliberately fail if application
-- tables already exist: do not silently accept an incompatible legacy schema.
create table public.items (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('lost', 'found')),
  name text not null check (char_length(btrim(name)) between 1 and 120),
  description text not null default '' check (char_length(description) <= 2000),
  category text not null default 'Other' check (category in ('Personal', 'Electronics', 'Other')),
  location text not null default '' check (char_length(location) <= 200),
  photo_url text not null default '' check (char_length(photo_url) <= 2048),
  timestamp timestamptz not null default now()
);
create index items_timestamp_idx on public.items(timestamp desc);
create index items_user_id_idx on public.items(user_id);

create table public.user_reports (
  id bigint generated always as identity primary key,
  item_id bigint not null unique references public.items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('lost', 'found')),
  timestamp timestamptz not null default now()
);
create index user_reports_user_id_idx on public.user_reports(user_id);

create table public.comments (
  id bigint generated always as identity primary key,
  item_id bigint not null references public.items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  text text not null check (char_length(btrim(text)) between 1 and 2000),
  timestamp timestamptz not null default now()
);
create index comments_item_timestamp_idx on public.comments(item_id, timestamp);
create index comments_user_id_idx on public.comments(user_id);

alter table public.items enable row level security;
alter table public.user_reports enable row level security;
alter table public.comments enable row level security;

revoke all on public.items, public.user_reports, public.comments from anon, authenticated;
revoke all on sequence public.items_id_seq, public.user_reports_id_seq, public.comments_id_seq from anon, authenticated;
grant select on public.items, public.user_reports, public.comments to authenticated;
grant insert (item_id, user_id, text, timestamp) on public.comments to authenticated;
grant usage on sequence public.comments_id_seq to authenticated;

create policy "Authenticated users browse items" on public.items
  for select to authenticated using ((select auth.uid()) is not null);
create policy "Users read their reports" on public.user_reports
  for select to authenticated using (user_id = (select auth.uid()));
create policy "Authenticated users read comments" on public.comments
  for select to authenticated using ((select auth.uid()) is not null);
create policy "Users post their own comments" on public.comments
  for insert to authenticated with check (user_id = (select auth.uid()));

-- Definer is necessary because direct item/report inserts are forbidden.
-- No dynamic SQL; identity/time are derived on the server, never from payload.
create function public.report_item(payload jsonb)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := auth.uid();
  item_id bigint;
  reported_at timestamptz := now();
begin
  if actor is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  if payload is null or jsonb_typeof(payload) <> 'object' then
    raise exception 'Report payload must be an object' using errcode = '22023';
  end if;

  insert into public.items (user_id, type, name, description, category, location, photo_url, timestamp)
  values (
    actor, payload->>'type', btrim(payload->>'name'),
    coalesce(payload->>'description', ''), coalesce(payload->>'category', 'Other'),
    coalesce(payload->>'location', ''), coalesce(payload->>'photo_url', ''), reported_at
  ) returning id into item_id;

  insert into public.user_reports (item_id, user_id, type, timestamp)
  values (item_id, actor, payload->>'type', reported_at);

  return item_id;
end;
$$;
revoke all on function public.report_item(jsonb) from public, anon;
grant execute on function public.report_item(jsonb) to authenticated;

-- Photos match the existing getPublicUrl() client. Public downloads are
-- intentional; listing and writes still require an authenticated owner folder.
insert into storage.buckets (id, name, public, file_size_limit)
values ('items', 'items', true, 5242880);

create policy "Users upload to their own item folder" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'items' and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "Users list their own item photos" on storage.objects
  for select to authenticated using (
    bucket_id = 'items' and (storage.foldername(name))[1] = (select auth.uid())::text
  );
create policy "Users delete their own item photos" on storage.objects
  for delete to authenticated using (
    bucket_id = 'items' and (storage.foldername(name))[1] = (select auth.uid())::text
  );

-- Client subscriptions use these two tables. user_reports remains private.
alter publication supabase_realtime add table public.items, public.comments;
