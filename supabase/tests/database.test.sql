begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

insert into auth.users (id, email) values
  ('11111111-1111-4111-8111-111111111111', 'alice@example.test'),
  ('22222222-2222-4222-8222-222222222222', 'bob@example.test');

select ok((select relrowsecurity from pg_class where oid = 'public.items'::regclass), 'items uses RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.user_reports'::regclass), 'reports uses RLS');
select ok((select relrowsecurity from pg_class where oid = 'public.comments'::regclass), 'comments uses RLS');
select ok(not has_function_privilege('anon', 'public.report_item(jsonb)', 'execute'), 'anon cannot execute report RPC');
select ok(not has_table_privilege('authenticated', 'public.items', 'insert'), 'direct item inserts are forbidden');
select ok(not has_table_privilege('authenticated', 'public.user_reports', 'insert'), 'direct report inserts are forbidden');
select is((select count(*)::int from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename in ('items', 'comments')), 2, 'both subscribed tables are published');
select is((select public from storage.buckets where id = 'items'), true, 'photo downloads are intentionally public');

set local role anon;
select throws_ok('select * from public.items', '42501', null, 'anon cannot browse items');
select throws_ok($sql$select public.report_item('{"type":"lost","name":"Keys"}')$sql$, '42501', null, 'anon cannot report');

set local role authenticated;
select set_config('request.jwt.claims', '{}', true);
select throws_ok($sql$select public.report_item('{"type":"lost","name":"Keys"}')$sql$, '42501', 'Authentication required', 'missing identity is rejected');

select set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}', true);
select lives_ok($sql$select public.report_item('{"type":"lost","name":"  Keys  ","user_id":"22222222-2222-4222-8222-222222222222","timestamp":"2000-01-01"}')$sql$, 'authenticated report succeeds');
select is((select count(*)::int from public.items), 1, 'one item exists');
select is((select count(*)::int from public.user_reports), 1, 'one report exists');
select is((select name from public.items limit 1), 'Keys', 'name is trimmed');
select is((select user_id::text from public.items limit 1), '11111111-1111-4111-8111-111111111111', 'caller cannot spoof item ownership');
select ok((select timestamp > '2026-01-01'::timestamptz from public.items limit 1), 'timestamp is server assigned');
select ok((select i.user_id = r.user_id and i.type = r.type and i.timestamp = r.timestamp from public.items i join public.user_reports r on r.item_id = i.id limit 1), 'report matches item identity, type and timestamp');
select throws_ok($sql$select public.report_item('{"type":"invalid","name":"Keys"}')$sql$, '23514', null, 'invalid type fails');
select throws_ok($sql$select public.report_item('{"type":"lost","name":"   "}')$sql$, '23514', null, 'blank name fails');
select throws_ok($sql$select public.report_item('[]')$sql$, '22023', null, 'non-object payload fails');
select is((select count(*)::int from public.items), 1, 'invalid reports leave no extra items');

select lives_ok($sql$insert into storage.objects(bucket_id,name) values ('items','11111111-1111-4111-8111-111111111111/photo.jpg')$sql$, 'owner can insert photo metadata');
select throws_ok($sql$insert into storage.objects(bucket_id,name) values ('items','22222222-2222-4222-8222-222222222222/spoof.jpg')$sql$, '42501', null, 'foreign photo folder is denied');

select set_config('request.jwt.claims', '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}', true);
select is((select count(*)::int from public.items), 1, 'another signed-in user can browse items');
select is((select count(*)::int from public.user_reports), 0, 'another user cannot read private reports');
select is((select count(*)::int from storage.objects where bucket_id = 'items'), 0, 'another user cannot list private photo metadata');
select throws_ok($sql$insert into public.comments(item_id,user_id,text) select id,'11111111-1111-4111-8111-111111111111','spoof' from public.items limit 1$sql$, '42501', null, 'comment identity spoofing is denied');
select lives_ok($sql$insert into public.comments(item_id,user_id,text) select id,'22222222-2222-4222-8222-222222222222','I found these' from public.items limit 1$sql$, 'another user can post their own comment');
select is((select count(*)::int from public.comments), 1, 'comment is visible to signed-in users');

-- Force the SECOND insert to fail: the first insert must roll back too.
reset role;
create function pg_temp.reject_report() returns trigger language plpgsql as $$
begin
  raise exception 'Forced second-insert failure' using errcode = '23514';
end;
$$;
create trigger test_reject_report before insert on public.user_reports
  for each row execute function pg_temp.reject_report();
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}', true);
select throws_ok($sql$select public.report_item('{"type":"found","name":"Rollback sentinel"}')$sql$, '23514', 'Forced second-insert failure', 'second-insert failure propagates');
select is((select count(*)::int from public.items), 1, 'failed second insert rolls back item creation');
select is((select count(*)::int from public.user_reports), 1, 'failed second insert leaves report count unchanged');
reset role;

select * from finish();
rollback;
