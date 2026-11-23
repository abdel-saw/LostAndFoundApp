# Browser workflow verification

The Chrome integration suite runs the real Flutter app against a disposable
local Supabase stack. It covers:

- Signup and login through the form at a 390 × 844 logical-pixel viewport.
- A photo-backed report through the UI and atomic database RPC.
- Comment posting through the UI.
- Item and comment delivery from a second authenticated client while the
  original UI stays open, including after search field rebuilds.
- Signing out from the report route and signing back in.

The photo selection is synthetic: the test assigns a real PNG File through a
DataTransfer object and dispatches the file input's change event. The app's
FileReader, preview, MIME/extension handling, upload and report submission run
normally. This does not automate or validate the operating-system file dialog.

## Run locally

Use Flutter 3.29.3, Docker, Supabase CLI 3.3.0 and a matching Chrome/ChromeDriver
pair. Run these from the repository root:

```bash
supabase start
chromedriver --port=4444
```

Leave ChromeDriver running. From another terminal at the repository root:

```bash
python3 scripts/run_browser_test.py
```

The runner reads local URL/anon credentials from `supabase status -o json` and
calls `flutter drive`. It refuses a non-local API URL. The test creates fictional
Auth accounts, items, comments and a small PNG; use a disposable local stack.
Stop that stack with `supabase stop --no-backup` after testing.

The database workflow installs matched Chrome/ChromeDriver and runs this suite
after the SQL and API checks. The ordinary Flutter workflow separately runs
static analysis, unit/widget tests and release Web compilation.

## Manual checks before a public demo

1. Run the app against a new development project configured per DATABASE.md.
2. Choose a real JPEG, PNG and WebP from the file dialog; cancel it once and
   confirm the picker remains usable.
3. Confirm the 5 MiB limit, hosted email confirmation and Auth redirects.
4. Open two browser sessions to inspect live updates and the final layout.
5. Refresh the report route while signed out and confirm it displays login.

The app remains Web-only. A phone-sized Chrome viewport does not establish
native Android/iOS compatibility. Repeated submissions after an uncertain
network response are not idempotent; photo cleanup after a failed report
remains future work.
