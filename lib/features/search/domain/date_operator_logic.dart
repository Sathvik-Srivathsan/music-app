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
    if (p1.length == 4 && p2.length >= 1 && p2.length <= 2) {
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
        parts[1].length >= 1 &&
        parts[1].length <= 2 &&
        parts[2].length >= 1 &&
        parts[2].length <= 2) {
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
      return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
    }
    if (parts[0].length >= 1 &&
        parts[0].length <= 2 &&
        parts[1].length >= 1 &&
        parts[1].length <= 2 &&
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
      return '$y-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
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

// ── Insert/Edit release-date canonicalization + display mask ─────
//
// Storage: records.release_date stays a full canonical DATE
// (YYYY-MM-DD) so Postgres math / app sorting / grouping / statistics
// all keep working. A separate 3-bit mask records WHICH components the
// user actually volunteered, so display can faithfully reproduce the
// typed granularity (year-only, year+month, or full date).
//
// Mask encoding (day*4 + month*2 + year):
//   0 = empty (no date)
//   1 = year only            -> display "YYYY"
//   3 = year + month         -> display "MM-YYYY"
//   7 = year + month + day   -> display "DD-MM-YYYY"
// By construction only 0/1/3/7 can occur; the invariant is that a day
// implies a month, and a month implies a year.

const int releaseDateMaskEmpty = 0;
const int releaseDateMaskYear = 1;
const int releaseDateMaskYearMonth = 3;
const int releaseDateMaskFull = 7;

/// Canonicalizes a user-typed release date into an always-valid full
/// ISO date ('YYYY-MM-DD') plus the display mask (0/1/3/7).
///
/// Unspecified month/day default to 01 so the value is always a real,
/// sortable, Postgres-accepted DATE. Returns `(iso: null, mask: 0)` for
/// empty or invalid input.
({String? iso, int mask}) canonicalizeReleaseDate(String? raw) {
  if (raw == null) return (iso: null, mask: 0);
  final v = raw.trim();
  if (v.isEmpty) return (iso: null, mask: 0);

  var vv = v.replaceAll('/', '-');
  final parts = vv.split('-');

  int? year;
  int? month;
  int? day;

  if (parts.length == 1) {
    final y = _tryInt(parts[0]);
    if (y == null || y < 1) return (iso: null, mask: 0);
    year = y;
  } else if (parts.length == 2) {
    final p1 = parts[0];
    final p2 = parts[1];
    if (p1.length == 4) {
      final y = _tryInt(p1);
      final mo = _tryInt(p2);
      if (y == null || mo == null || mo < 1 || mo > 12) {
        return (iso: null, mask: 0);
      }
      year = y;
      month = mo;
    } else if (p2.length == 4) {
      final mo = _tryInt(p1);
      final y = _tryInt(p2);
      if (mo == null || y == null || mo < 1 || mo > 12) {
        return (iso: null, mask: 0);
      }
      year = y;
      month = mo;
    } else {
      return (iso: null, mask: 0);
    }
  } else if (parts.length == 3) {
    if (parts[0].length == 4) {
      final y = _tryInt(parts[0]);
      final mo = _tryInt(parts[1]);
      final d = _tryInt(parts[2]);
      if (y == null || mo == null || d == null) {
        return (iso: null, mask: 0);
      }
      year = y;
      month = mo;
      day = d;
    } else if (parts[2].length == 4) {
      final d = _tryInt(parts[0]);
      final mo = _tryInt(parts[1]);
      final y = _tryInt(parts[2]);
      if (d == null || mo == null || y == null) {
        return (iso: null, mask: 0);
      }
      year = y;
      month = mo;
      day = d;
    } else {
      return (iso: null, mask: 0);
    }
  } else {
    return (iso: null, mask: 0);
  }

  // Validate ranges strictly; build a real DateTime so impossible
  // dates (e.g. 2026-02-30) are rejected. Unspecified month/day
  // default to 01 so the stored value is always a valid full DATE.
  final m = month ?? 1;
  final d = day ?? 1;
  if (year < 1 || m < 1 || m > 12 || d < 1 || d > 31) {
    return (iso: null, mask: 0);
  }
  final dt = DateTime(year, m, d);
  if (dt.year != year || dt.month != m || dt.day != d) {
    return (iso: null, mask: 0);
  }

  final iso =
      '${year.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  final hasDay = day != null;
  final hasMonth = month != null;
  final hasYear = year != null;
  final mask = (hasDay ? 4 : 0) + (hasMonth ? 2 : 0) + (hasYear ? 1 : 0);
  return (iso: iso, mask: mask);
}

/// Formats a stored canonical date ('YYYY-MM-DD') for display, using the
/// mask to reproduce the granularity the user originally entered:
///   mask 1 -> 'YYYY'
///   mask 3 -> 'MM-YYYY'
///   mask 7 -> 'DD-MM-YYYY'
///   mask 0 -> null (empty)
String? formatDisplayDate(String? iso, int mask) {
  if (iso == null) return null;
  final parts = iso.split('-');
  if (parts.length != 3) {
    // Not a full canonical date (e.g. a partial stored before the mask
    // column existed, or a test fixture) - show it verbatim.
    return iso;
  }
  final y = parts[0];
  final mo = parts[1];
  final d = parts[2];
  switch (mask) {
    case releaseDateMaskYear:
      return y;
    case releaseDateMaskYearMonth:
      return '$mo-$y';
    case releaseDateMaskFull:
      return '$d-$mo-$y';
    default:
      return null;
  }
}
