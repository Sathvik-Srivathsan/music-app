import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => Supabase.instance.client.auth;

  static PostgrestQueryBuilder from(String table) {
    return Supabase.instance.client.from(table);
  }

  /// Returns a query builder whose requests carry the `x-origin-tab` header,
  /// which the audit-log trigger reads to stamp the flow (insert / search /
  /// db / manage) that performed the write. Use at user-action write sites so
  /// logs record which tab the action was done in.
  static PostgrestQueryBuilder fromWithContext(String table, String originTab) {
    final builder = Supabase.instance.client.from(table);
    try {
      builder.setHeader('x-origin-tab', originTab);
    } catch (_) {
      // Header injection is best-effort; absence just leaves origin_tab NULL.
    }
    return builder;
  }

  /// The platform this app is running on (web or a target platform name).
  static String get device =>
      kIsWeb ? 'web' : defaultTargetPlatform.name;
}
