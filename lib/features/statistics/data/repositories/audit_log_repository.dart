import 'package:music_collection/core/constants/app_constants.dart';
import 'package:music_collection/core/network/supabase_client.dart';
import 'package:music_collection/shared/models/audit_log.dart';

/// A page of audit log rows plus a best-effort total (for pagination).
class AuditLogPage {
  final List<AuditLog> rows;
  final int? total;

  const AuditLogPage({required this.rows, this.total});

  bool get hasMore {
    if (total != null) return rows.length < total!;
    return rows.length >= AppConstants.defaultPageSize;
  }
}

/// Read-only access to the `audit_log` table for the Statistics > Log viewer.
///
/// Filters are applied server-side (eq / ilike over the JSONB details text) so
/// pagination stays correct. It never writes to audit_log; those rows are
/// produced exclusively by the DB trigger and the app's aggregate summaries,
/// and are immutable to the viewer.
class AuditLogRepository {
  /// Ordered filters to constrain the query.
  Future<AuditLogPage> fetchPage({
    String? action,
    String? table,
    String? search,
    required int page,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var builder = SupabaseService.from(AppConstants.tableAuditLog).select();

    if (action != null && action.isNotEmpty) {
      builder = builder.eq('action', action);
    }
    if (table != null && table.isNotEmpty) {
      builder = builder.eq('table_name', table);
    }

    // Free-text search over the JSONB details. Done server-side where possible;
    // if the ::text cast is rejected we retry without it (see below).
    var usedServerSearch = false;
    var searchQuery = builder;
    if (search != null && search.trim().isNotEmpty) {
      searchQuery = searchQuery.ilike('details::text', '%${_escapeLike(search)}%');
      usedServerSearch = true;
    }

    try {
      final resp = await searchQuery.order('created_at', ascending: false).range(from, to);
      final rows = (resp as List)
          .map((r) => AuditLog.fromJson(r as Map<String, dynamic>))
          .toList();
      return AuditLogPage(rows: rows);
    } catch (_) {
      // Fall back: ignore server-side full-text search (or cast) and just page.
      if (usedServerSearch) {
        try {
          final resp = await builder.order('created_at', ascending: false).range(from, to);
          final rows = (resp as List)
              .map((r) => AuditLog.fromJson(r as Map<String, dynamic>))
              .toList();
          return AuditLogPage(rows: rows);
        } catch (_) {
          return const AuditLogPage(rows: []);
        }
      }
      return const AuditLogPage(rows: []);
    }
  }

  static String _escapeLike(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
}
