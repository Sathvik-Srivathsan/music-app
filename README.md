# MUSIC APP

A Flutter music collection manager. Users maintain a catalogue of records
(albums/releases), linked to artists, genres, and descriptors. The app talks
directly to a Supabase backend using the public publishable key, so there is
**no own server** — this project produces a static Flutter **web** build that
is deployed to Vercel.

> **No RLS is currently enabled.** Access is governed by broad grants to the
> `anon` / `authenticated` / `service_role` roles (see `database/schema.sql`).
> A deferred, harder `audit_log` lock is noted in the schema but not applied.

## Features

- Search records with terms, artists, genres, descriptors, and date operators
  (AND / ANY / ALL matching, hierarchy-aware closures).
- Manage records, artists, genres, and descriptors with import/export.
- Adopt / leave delete-parenting for genres and descriptors (re-homes child
  nodes before delete).
- Statistics screen with audit-log diagnostics; every app boot is timestamped
  in the audit log.

## Tech

- [Flutter](https://flutter.dev/) web (compiled with `flutter build web --release`)
- [Supabase](https://supabase.com/) (Postgres)
- Deployed to [Vercel](https://vercel.com/) (auto-deploy on push to `main`)

## Configuration (no secrets in the repo)

The Supabase URL and publishable key are **never hardcoded**. They are read
from `.env` at runtime, or injected at **build time** via `--dart-define`
(which `build.sh` uses on Vercel). This keeps a fresh clone from silently
pointing at someone else's production database.

Reference a copy of the expected keys in `.env.example`. Fill real values into
`.env` (git-ignored) or your shell / CI / Vercel.

> **Key type (migrated).** The repo uses the **publishable** key (starts with
> `sb_publishable_`), which replaces the legacy **anon** key that Supabase is
> phasing out by end of 2026. Use a publishable key for this client app, never
> the secret/service_role key. If your `.env` still has an old
> `SUPABASE_ANON_KEY`, you can leave it there but the app/build no longer read
> it — only `SUPABASE_PUBLISHABLE_KEY` is used. (See the deploy section for
> where to create the publishable key.)

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

### Run the app (Flutter web)

```bash
flutter pub get
flutter run -d chrome
```

**No `--dart-define` flags needed.** The app reads `SUPABASE_URL` /
`SUPABASE_PUBLISHABLE_KEY` from your local `.env`, which is bundled into the
web build as an asset and loaded at runtime (`lib/core/network/app_env.dart`).
A compile-time `--dart-define` still takes precedence when present (that is how
Vercel injects the values via `build.sh`). If neither is available the Supabase
SDK fails at startup with a clear connection error (expected — never connect to
a foreign DB by default).

### Authentication (owner-only GitHub sign-in)

The app gates on **one-click GitHub OAuth** (owner-only). Access is enforced at
two complementary layers:

- **Client gate (`lib/core/auth/`):** `AuthProvider` listens to Supabase auth
  state. Until the owner signs in, the router redirects to `/login`, which shows
  a single **"Login through GitHub"** button. On a rejected account a red
  **"Access denied"** message appears and the user may retry.
- **Server gate (Supabase Dashboard, NOT in the repo):** the
  `before-user-created` Auth Hook (a Postgres function created in the Dashboard)
  rejects any GitHub account that is not the configured owner (403). The owner
  is identified by the **GitHub `provider_id`** (the `sub` in `identity_data`),
  never by email/username. The owner id lives **only** in the Dashboard
  function — it is intentionally not committed.

Auth wiring notes (developer-relevant):

- `supabase_flutter 2.16` enables **PKCE** and **session persistence** by
  default; no custom `authOptions` are passed. The SDK restores the session on
  relaunch and re-injects the user JWT.
- OAuth uses the **Site URL** as the callback (redirectTo is omitted on web), so
  the Dashboard's **URL Configuration → Site URL** must point at the deployed
  app (e.g. `https://<your-app>.vercel.app`) and that origin must be in the
  **Redirect URLs** list.
- When signed in, requests carry the user's JWT. `PublishableKeyHttpClient`
  (`lib/core/network/anon_http_client.dart`) strips only the **non-JWT**
  publishable key from `Authorization` and never touches real JWTs, so
  anonymous reads remain `apikey`-only while authenticated requests keep their
  session token.
- The Dashboard steps (GitHub provider, URL config, `before-user-created`
  hook) are documented in `phase 6 deployment/PHASE6_DEPLOYMENT_TECHNICAL_DOCUMENTATION.txt`.

### CLI tools

The `tools/*.dart` scripts read `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY`
directly from the environment (no literals). In PowerShell:

```powershell
$env:SUPABASE_URL="https://<ref>.supabase.co"
$env:SUPABASE_PUBLISHABLE_KEY="<publishable-key>"
dart run tools/verify_audit_log.dart
dart run tools/verify_hierarchy_counts.dart
```

## Database

The single authoritative reference for the entire Supabase backend lives in
`database/` (apply to a **fresh empty project** only, in the SQL Editor):

- `database/schema.sql` — all 11 tables, 11 functions, 17 triggers, indexes,
  and grants.
- `database/seed_genres_descriptors.sql` — the genre + descriptor trees
  (~2.8k genres + edges, ~550 descriptors + edges), extracted live.
  Artists and records are **not** seeded here (private — new users start with
  an empty catalogue).

Diagnostic / verification scripts live in `tools/`.

## Tests

The test suite lives in `test/`:

```bash
flutter test
```

## Deploy to Vercel

Deploying this app to Vercel is fully **configured in the repo**, so anyone who
clones it can reproduce the same production setup. There is no build/push step
beyond what's committed. Pushing to GitHub `main` triggers Vercel to
auto-deploy.

### How the build works (what you get in the repo)

- **`vercel.json`** — drives the whole build on Vercel:
  - `buildCommand: "bash build.sh"` — Vercel runs our build script.
  - `installCommand: "echo \"skip npm...\""` — a no-op, because there is no
    npm project; Flutter setup is handled inside `build.sh`.
  - `outputDirectory: "build/web"` — publishes the compiled Flutter web build.
  - `framework: null` — no framework preset.
- **`build.sh`** — the actual build on Vercel's Linux runner:
  - Guards that `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` are present (fails
    fast with a clear message otherwise).
  - Self-locates its own directory (robust to whatever CWD Vercel uses).
  - Idempotently installs Flutter stable (`git clone ... || true`) and adds it
    to `PATH`.
  - Runs `flutter pub get`, writes a fresh `.env` from `$SUPABASE_URL` /
    `$SUPABASE_PUBLISHABLE_KEY`, then runs `flutter build web --release`.
  - The build forwards the config through both the generated `.env` (bundled and
    read at runtime by `lib/core/network/app_env.dart`) and
    `--dart-define=SUPABASE_URL="$SUPABASE_URL"`
    `--dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY"`.
  - This is why a fresh clone / Vercel build always has the config: the clean
    runner has no git-ignored `.env`, so `build.sh` regenerates it from the
    build-time env vars.
- **`.gitattributes`** forces `*.sh` to LF so `build.sh`'s shebang stays valid
  on the Linux runner.

### First-time setup for a fresh clone (one-off)

You need four things: a Supabase project with a publishable key, the repo, a
Vercel project connected to the repo, and a few env vars.

1. **Pre-requisite: a Supabase publishable key.** In your Supabase Dashboard →
   **Settings → API Keys → Publishable and Secret API keys** tab → create a key
   (a `default` publishable key suffices). Copy the publishable key
   (`sb_publishable_...`).
2. **Set `.env` locally** (optional, for local runs/tools). Copy `.env.example`
   to `.env` and fill `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY`. `.env` is
   git-ignored, so your values are never committed.
3. **Create the Vercel project** and connect it to the GitHub repo (branch
   `main`). Keep **Root Directory** at `/`. Vercel reads `vercel.json` and runs
   `bash build.sh` automatically — you do not set a build command or output dir
   in the dashboard (it comes from `vercel.json`).
4. **Add env vars in Vercel** → Project → Settings → Environment Variables
   (scoped to **Production**, and **Preview** if you want preview deploys):
   - `SUPABASE_URL` = `https://<project-ref>.supabase.co`
   - `SUPABASE_PUBLISHABLE_KEY` = `<your publishable key>`
5. **Trigger the first deploy:** push to `main` (or Vercel → **Deployments** →
   **Deploy** → branch `main`). Vercel clones, runs `build.sh`, and publishes
   `build/web`.
6. **Allow Vercel origins in Supabase.** In Supabase Dashboard → **Authentication
   → URL Configuration**, add `https://<your-app>.vercel.app` as an allowed
   **Site URL** and enable CORS. Without this, the deployed app's Supabase
   requests are rejected (you'd see a PostgREST/404 error in the search/db
   tabs).

### Everyday deploys

Every later update is just `git commit` + `git push origin main` → Vercel
auto-deploys. No reconfiguration needed.

> **Gotcha (deploying an old commit).** Vercel's "Redeploy" button re-runs the
> deployment's **recorded commit**, which may be stale. To deploy current
> `main`, push a new commit (or an empty `--allow-empty` commit) instead of
> clicking Redeploy.

### Migrating from the legacy anon key

Earlier builds used `SUPABASE_ANON_KEY`; the repo has since migrated to
`SUPABASE_PUBLISHABLE_KEY`. Both are handled:

- The app code, `build.sh`, `.env.example`, and `tools/*.dart` all now read
  `SUPABASE_PUBLISHABLE_KEY` only.
- If your `.env` / Vercel still has the old `SUPABASE_ANON_KEY`, leave it; it is
  simply no longer consumed. Add `SUPABASE_PUBLISHABLE_KEY` and, once the
  publishable deploy is confirmed working, you can deactivate the legacy `anon`
  key in the Supabase Dashboard.

See `phase 6 deployment/PHASE6_DEPLOYMENT_TECHNICAL_DOCUMENTATION.txt` for the
full git + Vercel deployment write-up and troubleshooting.
