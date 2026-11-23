# Database setup and verification

This is a versioned **fresh-project baseline** for the Flutter client. It is not
a dump of the historical hosted database and does not reconcile existing data.
The migration deliberately fails if its application tables already exist.
No automatic migration of old duplicate reports is included.

## Local setup

Install Docker and Supabase CLI **3.3.0**. From the repository root:

```bash
supabase start
supabase test db
python3 scripts/test_supabase_api.py
```

Startup applies the migration. The SQL tests run inside a rolled-back transaction.
The Python test creates fictional local Auth users, items, comments and files;
run it only against a disposable local stack. It refuses non-local API URLs.
Use `supabase stop --no-backup` to discard this local test stack.

Use `supabase status` to find the local API URL and anon key. From
`lost_and_found_app`, launch Flutter Web on port 3000 with the two dart-defines
shown in the root README. Never put a service-role key in Flutter.

## Access model

| Resource | Read | Write |
| --- | --- | --- |
| Items | Signed-in users | Creation through `report_item` only |
| User reports | Owner only | Creation through `report_item` only |
| Comments | Signed-in users | Insert with the caller's own user ID |
| Photo bytes | Anyone with the public URL | Upload/delete in caller's UUID folder only |
| Photo metadata/listing | Owner folder only | No client overwrite/update policy |

The public `items` bucket matches the current client's `getPublicUrl()` use.
Photos remain publicly downloadable even when the viewer is signed out. Use
fictional photos for a portfolio demo. A private-photo design would require
signed URLs and client changes. The bucket enforces a 5 MiB upload limit;
the current client does not inspect image contents or provide moderation.

Items and comments are added to the Realtime publication. Row-level read
policies apply to subscriptions. The tests check publication membership;
browser subscription delivery still needs a manual check.

## Atomic reporting

`public.report_item(payload jsonb)` accepts the descriptive item fields and
returns the new numeric ID. The function derives user ID from `auth.uid()`,
assigns the timestamp on the server and inserts both records in one transaction.
The client omits caller-provided identity and timestamp.

Direct client inserts/updates/deletes on items and reports are not granted.
The function uses `security definer` to perform those two restricted writes,
an empty search path, schema-qualified references, and execute permission
limited to the authenticated role. There is no dynamic SQL.

A unique constraint permits only one report per item. This is **not** request
idempotency: submitting the form twice creates two separate items. Uploading a
photo is a separate Storage operation; a later report failure may leave an
unreferenced photo. Photo cleanup and submission retry handling remain future work.

## Verification

The pgTAP suite exercises RLS, permissions, ownership spoofing, validation,
private report access, photo folder policies and public-bucket configuration.
A temporary trigger forces the second insert to fail and verifies that neither
an extra item nor an extra report survives.

The Python smoke test uses real local Auth signups, the REST RPC, item/report
queries, comments, Storage upload and public photo retrieval. It does not use
a service-role key and does not print credentials. Flutter tests separately
check RPC request shape and error propagation.

## New hosted development project

1. Create an empty Supabase development project.
2. Review and apply `supabase/migrations/20261123000100_initial_schema.sql`
   using the SQL editor or your normal reviewed migration process.
3. Configure email confirmation and Auth site/redirect URLs for your deployment.
   Local confirmation is disabled in config.toml for disposable tests; hosted
   Auth settings are managed separately.
4. Configure Flutter with that project's public URL/anon key.
5. Test the browser workflow and two-user access before publishing the demo.

Do not run this baseline blindly on the historical project. Compare/back up its
schema and data and write a dedicated upgrade migration if retaining it.
No hosted project is modified by CI.

References: [database functions](https://supabase.com/docs/guides/database/functions),
[RLS](https://supabase.com/docs/guides/database/postgres/row-level-security),
[Storage policies](https://supabase.com/docs/guides/storage/security/access-control)
and [database testing](https://supabase.com/docs/guides/local-development/cli/testing-and-linting).
