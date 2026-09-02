/// Comparison policy for partial dates. A record value is treated as
/// the interval it covers (e.g. '2020' = Jan 1..Dec 31). Operators
/// test overlap between that interval and the queried point/window:
///   onOrBefore: record starts at/before the query window ends
///   onOrAfter : record ends at/after the query window starts
///   between   : record interval lies inside the query window
///               (exclusive variant forbids touching boundaries)
enum DateOperator {
  exactDate,
  onOrBefore,
  onOrAfter,
  betweenInclusive,
  betweenExclusive,
}

extension DateOperatorLabel on DateOperator {
  String get shortLabel {
    switch (this) {
      case DateOperator.exactDate:
        return '=';
      case DateOperator.onOrBefore:
        return '<=';
      case DateOperator.onOrAfter:
        return '>=';
      case DateOperator.betweenInclusive:
        return 'between';
      case DateOperator.betweenExclusive:
        return 'strictly between';
    }
  }

  String get label {
    switch (this) {
      case DateOperator.exactDate:
        return 'Exact date';
      case DateOperator.onOrBefore:
        return '<= (on or before)';
      case DateOperator.onOrAfter:
        return '>= (on or after)';
      case DateOperator.betweenInclusive:
        return 'Between (inclusive)';
      case DateOperator.betweenExclusive:
        return 'Between (exclusive)';
    }
  }

  bool get needsSecondValue =>
      this == DateOperator.betweenInclusive ||
      this == DateOperator.betweenExclusive;
}

int? _tryInt(String s) {
  final v = int.tryParse(s);
  return v;
}

/// Accepts every volunteered format, '-' or '/' separators alike,
/// always returning a canonical ISO partial ('YYYY', 'YYYY-MM',
/// 'YYYY-MM-DD') or null:
///   YYYY         2026
///   YYYY-MM      2026-07
///   YYYY-MM-DD   2026-07-05
///   MM-YYYY      07-2026
///   DD-MM-YYYY   05-07-2026   (day-first, matching insert stamps)
String? parseFlexibleDate(String? raw) {
  if (raw == null) return null;
  var v = raw.trim();
  if (v.isEmpty) return null;
  v = v.replaceAll('/', '-');
  final parts = v.split('-');
  if (parts.length == 1) {
    if (parts[0].length != 4) return null;
    final y = _tryInt(parts[0]);
    if (y == null || y < 1) return null;
    return parts[0];
  }
  if (parts.length == 2) {
    final p1 = parts[0];
    final p2 = parts[1];
    if (p1.length == 4 && p2.length == 2) {
      final y = _tryInt(p1);
      final mo = _tryInt(p2);
      if (y == null || mo == null || mo < 1 || mo > 12) return null;
      return '$p1-${p2.padLeft(2, '0')}';
    }
    if (p1.length <= 2 && p2.length == 4) {
      final mo = _tryInt(p1);
      final y = _tryInt(p2);
      if (mo == null || y == null || mo < 1 || mo > 12) return null;
      return '$y-${p1.padLeft(2, '0')}';
    }
    return null;
  }
  if (parts.length == 3) {
    if (parts[0].length == 4 &&
        parts[1].length == 2 &&
        parts[2].length == 2) {
      final y = _tryInt(parts[0]);
      final mo = _tryInt(parts[1]);
      final d = _tryInt(parts[2]);
      if (y == null ||
          mo == null ||
          d == null ||
          mo < 1 ||
          mo > 12 ||
          d < 1 ||
          d > 31) {
        return null;
      }
      return v;
    }
    if (parts[0].length <= 2 &&
        parts[1].length == 2 &&
        parts[2].length == 4) {
      final d = _tryInt(parts[0]);
      final mo = _tryInt(parts[1]);
      final y = _tryInt(parts[2]);
      if (d == null ||
          mo == null ||
          y == null ||
          mo < 1 ||
          mo > 12 ||
          d < 1 ||
          d > 31) {
        return null;
      }
      return '$y-${parts[1]}-${parts[0].padLeft(2, '0')}';
    }
    return null;
  }
  return null;
}

class PartialDate {
  final int year;
  final int? month;
  final int? day;

  const PartialDate(this.year, [this.month, this.day]);

  static PartialDate? tryParse(String input) {
    final v = parseFlexibleDate(input);
    if (v == null) return null;
    final parts = v.split('-');
    final y = int.parse(parts[0]);
    final mo = parts.length > 1 ? int.parse(parts[1]) : null;
    final d = parts.length > 2 ? int.parse(parts[2]) : null;
    return PartialDate(y, mo, d);
  }

  int get _startComp => year * 10000 + (month ?? 1) * 100 + (day ?? 1);
  int get _endComp => year * 10000 + (month ?? 12) * 100 + (day ?? 31);

  bool strictlyInsideOf(PartialDate from, PartialDate to) =>
      _startComp > from._endComp && _endComp < to._startComp;

  bool containedIn(PartialDate from, PartialDate to) =>
      _startComp >= from._startComp && _endComp <= to._endComp;
}

bool dateMatches({
  required String? recordValue,
  required DateOperator operator,
  required String queryValue1,
  String queryValue2 = '',
}) {
  final normalizedRec = normalizeStoredDate(recordValue);
  if (normalizedRec == null) return false;
  final rec = PartialDate.tryParse(normalizedRec);
  if (rec == null) return false;

  switch (operator) {
    case DateOperator.exactDate:
      final qNorm = parseFlexibleDate(queryValue1);
      return qNorm != null && normalizedRec == qNorm;
    case DateOperator.onOrBefore:
      final q = PartialDate.tryParse(queryValue1);
      return q != null && rec._startComp <= q._endComp;
    case DateOperator.onOrAfter:
      final q = PartialDate.tryParse(queryValue1);
      return q != null && rec._endComp >= q._startComp;
    case DateOperator.betweenInclusive:
      final q1 = PartialDate.tryParse(queryValue1);
      final q2 = PartialDate.tryParse(queryValue2);
      return q1 != null && q2 != null && rec.containedIn(q1, q2);
    case DateOperator.betweenExclusive:
      final q1 = PartialDate.tryParse(queryValue1);
      final q2 = PartialDate.tryParse(queryValue2);
      return q1 != null &&
          q2 != null &&
          rec.strictlyInsideOf(q1, q2);
  }
}

/// Normalizes anything stored OR typed into an ISO partial. Covers
/// ISO partials plus dd/MM/yyyy stamps (the app-generated format).
String? normalizeStoredDate(String? raw) => parseFlexibleDate(raw);
