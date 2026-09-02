# music_collection

A Flutter music collection manager. Users maintain a catalogue of records
(albums/releases), linked to artists, genres, and descriptors. The app talks
directly to a Supabase backend using the public anon key, so there is **no own
server** — this project produces a static Flutter **web** build that is
deployed to Vercel.

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

The Supabase URL and anon key are **never hardcoded**. They are injected at
**build time** via `--dart-define` (see `lib/main.dart`). This keeps a fresh
clone from silently pointing at someone else's production database.

Reference a copy of the expected keys in `.env.example`. Fill real values into
`.env` (git-ignored) or your shell / CI / Vercel.

```
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=<anonymous-public-key>
```

### Run the app (Flutter web)

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

If the defines are missing the Supabase SDK fails at startup with a clear
connection error (expected — never connect to a foreign DB by default).

### CLI tools

The `tools/*.dart` scripts read `SUPABASE_URL` / `SUPABASE_ANON_KEY` directly
from the environment (no literals). In PowerShell:

```powershell
$env:SUPABASE_URL="https://<ref>.supabase.co"
$env:SUPABASE_ANON_KEY="<anon-key>"
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

- Framework preset: **Other** (or Flutter).
- Build command: install Flutter on the Linux runner, then
  `flutter build web --release`, passing the config into the build with
  `--dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY`.
- Output directory: `build/web`.
- Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` as **Environment Variables**
  (Production scope) so the build command above has values.
- In Supabase Dashboard → API settings, add your site URL to the allowed
  **Site URL** and enable CORS for `https://<your-app>.vercel.app`.
