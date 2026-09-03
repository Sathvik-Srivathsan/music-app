import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_collection/app.dart';
import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/logging/audit_outbox.dart';
import 'package:music_collection/core/logging/audit_reconciler.dart';
import 'package:music_collection/core/network/anon_http_client.dart';
import 'package:music_collection/core/network/app_env.dart';
import 'package:music_collection/core/network/supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final device = kIsWeb ? 'web' : defaultTargetPlatform.name;

  // Resolve the Supabase URL + publishable key. `AppEnv` checks compile-time
  // --dart-define first (how Vercel injects values) and falls back to the
  // bundled `.env` file read at runtime, so a plain `flutter run -d chrome`
  // with a local `.env` works with zero extra flags.
  await AppEnv.ensureLoaded();
  final url = AppEnv.supabaseUrl;
  final publishableKey = AppEnv.publishableKey;

  await Supabase.initialize(
    // The publishable (formerly "anon") key is used for client-side apps and is
    // safe to ship to the browser. Never use the secret/service_role key here.
    url: url ?? '',
    publishableKey: publishableKey ?? '',
    // x-device is static per platform and is read by the audit-log trigger to
    // stamp every logged write with the device it originated from.
    headers: {'x-device': device},
    // The publishable key (sb_publishable_...) is not a JWT, so it must never
    // be sent as `Authorization: Bearer`. This app is anonymous (no user JWT),
    // so stripping that header leaves auth to the `apikey` header alone, which
    // is the supported shape for new-format keys. See PublishableKeyHttpClient.
    httpClient: PublishableKeyHttpClient(),
  );

  await _logAppBoot(device);

  // Flush any record update/delete (or insert) whose audit-log write never
  // landed (e.g. the client crashed between the data write and the log write).
  // Entries carry the full tuple, so nothing needs refetching; entries whose
  // op_id already landed are deduped, so this never double-logs. Runs in the
  // background and never blocks startup.
  unawaited(AuditOutbox.shared.flush());

  // Repair any record whose insert was made on/after today's date but never
  // logged (e.g. the client crashed between the data write and the log
  // write). Runs fire-and-forget in the background so startup is never
  // blocked, and only touches recent records — legacy/imported records are
  // left alone, so no audit-log flood.
  unawaited(AuditReconciler().reconcile());

  runApp(const MusicCollectionApp());
}

/// Logs an application boot event. Unlike data-table writes there is no row
/// change here for a trigger to observe, so the client inserts the audit row
/// directly (device only - no IP address, per the audit-log spec).
Future<void> _logAppBoot(String device) async {
  try {
    await SupabaseService.from(AppConstants.tableAuditLog).insert({
      'action': 'app_boot',
      'table_name': AppConstants.tableAuditLog,
      'details': const {'event': 'app_boot'},
      'device': device,
      'origin_tab': 'boot',
    });
  } catch (_) {
    // Boot logging must never block app startup.
  }
}
