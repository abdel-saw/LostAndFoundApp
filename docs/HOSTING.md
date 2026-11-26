# Free hosting: GitHub Pages + Supabase

The frontend uses GitHub Pages; Supabase Free supplies PostgreSQL, Auth,
Realtime and Storage. No Render service or paid domain is required.

Expected project URL after a successful deployment:
`https://abdel-saw.github.io/LostAndFoundApp/`

This is a deployment target, not a claim that the site is already live.

## 1. Prepare an empty Supabase Free project

Use a new empty project on a Free organization. Keep the existing historical
project separate. Apply the reviewed baseline:

`supabase/migrations/20261123000100_initial_schema.sql`

The migration fails if application tables already exist; it does not convert
legacy data. Check that items, user_reports, comments and the items bucket exist.
See [database setup](DATABASE.md) for permissions.

In Auth URL Configuration set:

- Site URL: `https://abdel-saw.github.io/LostAndFoundApp/`
- Allowed redirect URL: `https://abdel-saw.github.io/LostAndFoundApp/`

The web client explicitly passes its app directory as `emailRedirectTo` during
signup, retaining `/LostAndFoundApp/` and omitting hash routes/query parameters.
Both URLs above must match that directory exactly, including the trailing slash.
The confirmation email template should link to `{{ .ConfirmationURL }}` so
Supabase verifies the email before returning to the app. A bare link to
`{{ .SiteURL }}` or `{{ .RedirectTo }}` does not perform verification.

After changing redirects, test a **new** signup and its newly generated email.
Previously sent links retain their original redirect target. If verification
succeeds but the browser lands at the GitHub account root, the account can still
sign in at the project URL; the return navigation is the remaining issue.

Keep any temporary localhost redirect only if you use it for development.
The client uses hash routes, such as `/LostAndFoundApp/#/report`, so refreshes
do not require a server-side rewrite.

For this pinned client version, use the public **legacy anon key** from the
project's API keys settings. It is designed for client exposure. Never use the
service_role key, a secret key or a database password in the frontend.
The build rejects keys whose decoded role is not anon.

Hosted email confirmation is separate from local config.toml. If keeping email
confirmation enabled, configure a suitable SMTP sender before inviting arbitrary
visitors: Supabase's default SMTP is restricted to organization team addresses.
Do not describe public signup as working until it has been tested. A manually
provisioned test account is another way to verify the demo initially.

## 2. Set GitHub repository variables

In this repository's Settings → Secrets and variables → Actions → Variables,
create these repository variables:

| Name | Value |
| --- | --- |
| SUPABASE_URL | The new project's HTTPS API origin |
| SUPABASE_ANON_KEY | The project's public legacy anon key |

These are compiled public client settings, not server credentials.
The workflow fails before compilation when settings are missing or privileged.

## 3. Enable GitHub Pages

Settings → Pages → Build and deployment → Source: **GitHub Actions**.

Merge the deployment PR. Then open Actions → Deploy LostAndFound to Pages →
Run workflow, selecting main. Changes to client/build/deployment files on main
also trigger deployment.

The workflow validates public configuration, installs pinned Flutter 3.29.3,
analyzes/tests the client, compiles with `--base-href=/LostAndFoundApp/`,
uploads the artifact and publishes through GitHub's official Pages actions.
The service worker is disabled to avoid serving an outdated backend configuration.

Pull requests never publish and use only fixture configuration in their compile
check. Deployment jobs receive Pages/OIDC permissions; the build only reads source.

## 4. Check the published result

1. Confirm the Pages workflow succeeds and use its emitted deployment URL.
2. Load the site and refresh the hash report route while signed out.
3. Test hosted login, a fictional item with a real image file, comments and
   updates across two sessions.
4. Test signup/email confirmation according to the chosen hosted Auth setup.
5. Add the verified live URL to the README/About/CV only after this passes.

Photos use public URLs. Use fictional data and photos for this portfolio demo.
Native Android/iOS behavior is outside this deployment.

## Free-plan limits

GitHub Pages and standard Actions runners are available free for public
repositories. Supabase Free currently includes a 500 MB database and 1 GB
file storage, with up to two active free projects. Low-activity free projects
may pause after a week. Resume the project before sharing a paused demo.
No artificial keep-alive job is configured.

References:
- [GitHub Pages workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)
- [Supabase pricing](https://supabase.com/pricing)
- [Supabase project pausing](https://supabase.com/docs/guides/platform/free-project-pausing)
- [Supabase Auth SMTP](https://supabase.com/docs/guides/auth/auth-smtp)
