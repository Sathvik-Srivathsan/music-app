# Testing (music_collection)

Test documentation for the `music_collection` app. The suite is **hermetic**:
no real network, no live Supabase, no emulator/device is used. Every test runs
against in-memory seeds and the Flutter test binding, so `flutter test` is fast
and deterministic on any machine.

Current status: **304 tests pass**, `flutter analyze` reports **0 errors**
(≈140 pre-existing info/warning lints, mostly `withOpacity` deprecations that
were there before; none are caused by the test files).

## Run the suite

From the repo root (`music_collection/`):

```bash
flutter test                 # full suite (302 app + 2 Android-specific)
flutter test test/search_query_test.dart   # one file
flutter test test/android    # Android-specific tests only
flutter test --watch         # re-run on file changes
```

`flutter pub get` must have been run once first. The app's `.env` asset is
required at build time only; the tests do **not** need real credentials.

## Layout

```
test/
  android/                   # Android-specific behavior (see "Android tests")
    android_back_button_test.dart
  audit_log_sentence_test.dart
  audit_outbox_test.dart
  audit_reconciler_test.dart
  chip_input_field_widget_test.dart
  chip_type2_probing_test.dart
  chip_type2_spec_test.dart
  database_provider_test.dart
  fzy_similarity_test.dart
  hierarchy_adoption_test.dart
  import_row_overlay_test.dart
  info_tip_test.dart
  insert_validation_test.dart
  manage_import_export_screen_test.dart
  manage_provider_full_db_warnings_test.dart
  manage_provider_parent_parsing_test.dart
  manage_provider_standalone_import_test.dart
  record_tuple_log_test.dart
  search_query_test.dart
  search_results_crash_test.dart
  statistics_engine_test.dart
  statistics_screen_test.dart
  widget_test.dart
```

## Coverage by file

| File | What it covers |
| --- | --- |
| `android/android_back_button_test.dart` | **Android system back-button regression** (2 tests): the root `WidgetsBindingObserver` interceptor closes an open dialog without hitting go_router's null-check crash, and a back-press at root exits cleanly. Mocks `SystemChannels.platform` because `SystemNavigator.pop()` never resolves under the test binding. |
| `audit_log_sentence_test.dart` | Human-readable audit-log sentences (insert/update/delete/import/boot), detail fallbacks, and the IST time formatter (UTC+5:30) including month/day wraparounds. |
| `audit_outbox_test.dart` | `AuditOutbox` best-effort queueing, flush/prune, retry-on-failure, idempotency. |
| `audit_reconciler_test.dart` | `AuditReconciler` repairs missing insert logs, skips legacy/unparseable rows, survives throw + fetch failure, is idempotent. |
| `chip_input_field_widget_test.dart` | Chip input: paste + commit, Enter, recommendations, unmatched→create flow, chip uniform sizing, arrow-key preview, commas in entity names, `sortFn`/`usedIds`. |
| `chip_type2_probing_test.dart` | Type-2 chip parsing robustness: separators, whitespace (incl. non-breaking/zero-width/BOM), quotes, case + accents, junk segments, 100-segment scale. |
| `chip_type2_spec_test.dart` | Type-2 paste-pipeline spec contract (5 substrings, exact/fuzzy commit rules, CSV round-trip). |
| `database_provider_test.dart` | `DatabaseProvider` core logic (buckets, search, sort cycles, grouping, column visibility, fuzzy, memoization, used-id sets, filter field) **and** rendering (search bar, error state, edit modal, group-by, filter dropdown, no back-to-search in the DB tab). |
| `fzy_similarity_test.dart` | fzy match scoring regression (prefix > scatter, runs, thresholds, ≤1.0) and normalized fuzzy matching (hyphens/whitespace/zero-width normalized away). |
| `hierarchy_adoption_test.dart` | Adopt/leave delete-parenting: edge cases (additive union, self-loops, 2-cycles) plus a **randomized oracle probe** over gnarly trees. |
| `import_row_overlay_test.dart` | `ManageProvider.overlayRows` (in-place row modifications, order preservation, out-of-range keys). |
| `info_tip_test.dart` | `InfoTip` tiering (square/square/wide) and mandatory-vs-body rendering. |
| `insert_validation_test.dart` | `validateInsertInput` (empty name, zero artists, precedence). |
| `manage_import_export_screen_test.dart` | "Download Format of CSV" button hidden until Full Database mode. |
| `manage_provider_full_db_warnings_test.dart` | Full-database import warnings, **19 subcases**. |
| `manage_provider_parent_parsing_test.dart` | Parent-column probing, **28 subcases**. |
| `manage_provider_standalone_import_test.dart` | Standalone genre/descriptor import: skip-parent-not-found, rectify-to-root, skip reporting. |
| `record_tuple_log_test.dart` | `RecordTupleLog.buildFullTuple` + insert/update/delete detail builders; never leaks ids. |
| `search_query_test.dart` | Search engine: flexible dates, date operators, record-type/streaming/comment filters, fuzzy, hierarchy-aware ANY/ALL closures, `previewLines`, collation, `groupKeysFor`. |
| `search_results_crash_test.dart` | Results table: fill vs scroll mode, header wrap, grouped bands, sort badges, edit modal, copy-to-clipboard, columns picker (frozen trio), equal-width columns, genre grouping + depth sort, memoization, _scroll mode uses a draggable horizontal scrollbar and no pills_. |
| `statistics_engine_test.dart` | `StatisticsEngine`: year/decade parsing, decade buckets, overview, status slices, top entities, record-type bars, streaming pie (≤6 slices + `Other`), relationship summaries. |
| `statistics_screen_test.dart` | Statistics screen rendering: overview headlines, collapsible charts, audit-log viewer sub-tab, **and phone-size (360×740) sub-tab switching with no overflow**. |
| `widget_test.dart` | App renders; `AuthProvider` is unauthenticated when Supabase is not initialized. |

## How the tests stay hermetic

- Providers are constructed with small in-memory seed data instead of touching
  Supabase (see `_rows()`, seeded `SearchProvider`/`DatabaseProvider` in the
  test helpers).
- Screens are pumped at fixed surface sizes; narrow/phone widths exercise the
  scroll/responsive branches (e.g. the 360×740 statistics test).
- Anything that touches a platform channel is mocked with
  `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger`
  (`setMockMethodCallHandler`). The Android back-button tests do this for
  `SystemChannels.platform` in `setUp`/`tearDown`.
- `tester.pumpAndSettle()` is used after dialogs/animation; async `setState`
  calls are guarded with `mounted` in app code and awaited in tests.

## Android tests

`test/android/` holds tests that only make sense for the mobile/Android
behavior of the app and need platform mocks (the system-back regression tests).
They run with the same `flutter test` command as everything else, but are kept
in their own folder so web-only CI can exclude them if ever needed:

```bash
flutter test test/android
```

Running the **full suite is the default**: plain `flutter test` runs both
folders. The 304 total = 302 app tests + 2 Android tests.

## Conventions for new tests

1. **Never touch the network or a real database** — seed data only.
2. Keep tests independent; no shared mutable global state between tests.
3. Widget tests: pump the real screen/widget (not fakes), settle animations,
   and assert on user-visible text/state rather than implementation detail
   where practical. Structural assertions must be intentional (e.g. checking
   the draggable scrollbar or frozen-column checkbox).
4. If a test needs a platform channel, mock it in `setUp` and clean up in
   `tearDown`.
5. Match existing naming: `group('Series N - topic', ...)` for logic suites,
   descriptive `testWidgets('behaviour under conditions')` for UI.
6. After adding or changing tests, run `flutter analyze` (0 errors) and the
   full `flutter test` before considering work done.