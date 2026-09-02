# music_collection

A Flutter music collection manager. Users maintain a catalogue of records
(albums/releases), linked to artists, genres, and descriptors. The app talks
directly to a Supabase backend using the public anon key (Row-Level Security
keeps reads/writes scoped), so there is **no own server** — this project
produces a static Flutter **web** build that is deployed to Vercel.

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
- [Supabase](https://supabase.com/) (Postgres + Row-Level Security)
- Deployed to [Vercel](https://vercel.com/) (auto-deploy on push to `main`)

## Local development

```bash
flutter pub get
flutter run -d chrome
```

The Supabase URL and anon key are compile-time defaults in `lib/main.dart`
(set via `--dart-define`). `.env` is git-ignored and only used by local tooling.

## Database

Migration scripts live in `database/migrations/` (run once in the Supabase SQL
Editor). Verification / diagnostic scripts live in `tools/`.

## Tests

The test suite lives in `test/`:

```bash
flutter test
```
