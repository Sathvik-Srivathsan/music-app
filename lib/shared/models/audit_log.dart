/// A single immutable row from the `audit_log` table.
///
/// Rows are written ONLY by the database trigger `fn_audit_log()` (or the few
/// aggregate summary writes like import/export/app_boot from the client). They
/// are read-only here: the viewer never edits or deletes them.
class AuditLog {
  final int? logId;
  final String action;
  final String tableName;
  final int? recordId;
  final Map<String, dynamic>? details;
  final String? originTab;
  final String? device;
  final DateTime? createdAt;

  AuditLog({
    this.logId,
    required this.action,
    required this.tableName,
    this.recordId,
    this.details,
    this.originTab,
    this.device,
    this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      logId: json['log_id'] as int?,
      action: json['action'] as String,
      tableName: json['table_name'] as String,
      recordId: json['record_id'] as int?,
      details: json['details'] as Map<String, dynamic>?,
      originTab: json['origin_tab'] as String?,
      device: json['device'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  String get formattedTime {
    if (createdAt == null) return '';
    // Just add IST's fixed +5:30 offset; no device-timezone conversion. The
    // stored created_at is a UTC/simple wall-clock timestamp, so adding 5h30m
    // yields the same IST time on every device regardless of its timezone.
    final t = createdAt!.add(const Duration(hours: 5, minutes: 30));
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:'
        '${t.second.toString().padLeft(2, '0')} '
        '${t.day.toString().padLeft(2, '0')}/'
        '${t.month.toString().padLeft(2, '0')}/'
        '${t.year}';
  }

  @override
  String toString() => '$action on $tableName at $formattedTime';
}
