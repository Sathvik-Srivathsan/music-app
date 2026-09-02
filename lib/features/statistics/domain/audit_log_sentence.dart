import 'package:music_collection/shared/models/audit_log.dart';

/// Renders an immutable [AuditLog] as a short human sentence.
///
/// Rules (from STATISTICS_LOG_PLAN.md / AUDIT_LOG_ACTIONS.csv):
///  * Show familiar data only — NEVER any id (user must not see ids; only the
///    admin, by querying the DB, may).
///  * Trigger rows wrap the row in details as {inserted:}, {before:, after:}
///    or {deleted:}; aggregate client writes (imports, app_boot) carry a flat
///    details map.
///  * If nothing maps cleanly, fall back to a "key: value" list — never throw.
class AuditLogSentence {
  AuditLogSentence._();

  static String build(AuditLog log) {
    final table = log.tableName;
    final action = log.action;
    final d = log.details ?? const <String, dynamic>{};

    switch (action) {
      case 'insert':
      case 'update':
      case 'delete':
        return _triggerSentence(table, action, d);
      case 'import_artists':
        return 'Imported ${d['count'] ?? '?'} artists from CSV.';
      case 'import_genres':
        return 'Imported ${d['count'] ?? '?'} genres'
            '${d['hierarchy_edges'] != null ? ' (${d['hierarchy_edges']} hierarchy edges)' : ''}'
            ' from CSV.';
      case 'import_descriptors':
        return 'Imported ${d['count'] ?? '?'} descriptors'
            '${d['hierarchy_edges'] != null ? ' (${d['hierarchy_edges']} hierarchy edges)' : ''}'
            ' from CSV.';
      case 'import_records':
        return 'Imported ${d['records'] ?? '?'} records'
            '${_links(d)} from CSV.';
      case 'app_boot':
        final device = d['device'] ?? log.device ?? '?';
        return 'App started on $device.';
      default:
        return _fallback(action, table, d);
    }
  }

  static String _links(Map<String, dynamic> d) {
    final parts = <String>[];
    for (final key in const ['artist_links', 'genre_links',
        'descriptor_links', 'streaming_links']) {
      if (d[key] != null) parts.add('$key: ${d[key]}');
    }
    return parts.isEmpty ? '' : ' (${parts.join(', ')})';
  }

  // ----- trigger rows (row wrapped in inserted/before/after/deleted) -------

  static String _triggerSentence(
      String table, String action, Map<String, dynamic> d) {
    if (action == 'insert') {
      final row = d['inserted'];
      return _verb('Added', table, row);
    }
    if (action == 'delete') {
      final row = d['deleted'];
      return _verb('Deleted', table, row);
    }
    // update
    final before = d['before'];
    final after = d['after'];
    if (before is Map && after is Map) {
      final changed = _changedPairs(before, after, table);
      final verb = _verb('Updated', table, after);
      return changed.isEmpty ? verb : '$verb — ${changed.join('; ')}.';
    }
    return _fallback(action, table, d);
  }

  static String _verb(String verb, String table, dynamic row) {
    final label = _subjectLabel(table);
    final name = _name(row, table);
    if (name != null) return '$verb $label $name.';
    return '$verb a $label.';
  }

  static String _subjectLabel(String table) => switch (table) {
        'records' => 'record',
        'artists' => 'artist',
        'genres' => 'genre',
        'descriptors' => 'descriptor',
        'record_artists' => 'record–artist link',
        'record_genres' => 'record–genre link',
        'record_descriptors' => 'record–descriptor link',
        'record_streaming' => 'streaming link',
        'genre_hierarchy' => 'genre hierarchy link',
        'descriptor_hierarchy' => 'descriptor hierarchy link',
        _ => table,
      };

  /// The display name of an entity row (name column long), or null when the
  /// row carries no friendly name — ids are never shown.
  static String? _name(dynamic row, String table) {
    if (row is Map) {
      for (final key in const ['record_name', 'artist_name', 'genre_name',
          'descriptor_name']) {
        final v = row[key];
        if (v is String && v.isNotEmpty) return '"$v"';
      }
    }
    return null;
  }

  static List<String> _changedPairs(
      Map before, Map after, String table) {
    final parts = <String>[];
    const friendly = {
      'record_name': 'name',
      'record_type': 'type',
      'release_date': 'release date',
      'status': 'status',
      'comments': 'comments',
      'artist_name': 'name',
      'genre_name': 'name',
      'descriptor_name': 'name',
    };
    final keys = <String>{
      ...before.keys,
      ...after.keys,
    };
    for (final key in keys) {
      if (key.endsWith('_id')) continue; // never surface ids
      final b = before[key];
      final a = after[key];
      if (b == a) continue;
      final label = friendly[key] ?? key;
      parts.add('$label: $b → $a');
    }
    return parts;
  }

  // ----- fallback: never crash, never show ids in the headline ------------

  static String _fallback(String action, String table, Map<String, dynamic> d) {
    final buff = StringBuffer('$action on $table');
    if (d.isNotEmpty) {
      final items = <String>[];
      d.forEach((k, v) {
        if (k.endsWith('_id') || k == 'record_id') return; // hide ids
        items.add('$k: $v');
      });
      if (items.isNotEmpty) buff.write(' — ${items.join('; ')}');
    }
    buff.write('.');
    return buff.toString();
  }
}
