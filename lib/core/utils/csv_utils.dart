import 'package:csv/csv.dart';
import 'package:music_collection/core/utils/chip_text_logic.dart';

class CsvUtils {
  CsvUtils._();

  static final _csv = Csv(dynamicTyping: true);

  static List<List<dynamic>> parseRows(String csvString) {
    return _csv.decode(csvString);
  }

  static List<Map<String, dynamic>> parseCsv(String csvString) {
    final rows = parseRows(csvString);
    if (rows.isEmpty) return [];

    final headers = rows.first.map((e) => e.toString().trim()).toList();
    final result = <Map<String, dynamic>>[];

    for (var i = 1; i < rows.length; i++) {
      final row = <String, dynamic>{};
      for (var j = 0; j < headers.length && j < rows[i].length; j++) {
        row[headers[j]] = rows[i][j];
      }
      result.add(row);
    }

    return result;
  }

  static String toCsv(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';

    final headers = data.first.keys.toList();
    final rows = data.map((row) => headers.map((h) => row[h] ?? '').toList()).toList();

    return _csv.encode([headers, ...rows]);
  }

  static List<String> extractHeaders(String csvString) {
    final rows = parseRows(csvString);
    if (rows.isEmpty) return [];
    return rows.first.map((e) => e.toString().trim()).toList();
  }

  static String normalizeColumnHeader(String header) {
    return header
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  static String normalizeValue(String value) {
    return value.toLowerCase().trim();
  }

  static double calculateSimilarity(String query, String target) {
    final q = ChipTextLogic.normalizeForMatch(query);
    final t = ChipTextLogic.normalizeForMatch(target);

    if (q == t) return 1.0;
    if (q.isEmpty || t.isEmpty) return 0.0;

    final raw = _fzyScore(q, t);
    if (raw == null) return 0.0;

    return (raw / q.length).clamp(0.0, 1.0);
  }

  // --- fzy algorithm (port of jhawthorn/fzy src/match.c) ---

  static const double _scoreMin = double.negativeInfinity;
  static const double _gapLeading = -0.005;
  static const double _gapTrailing = -0.005;
  static const double _gapInner = -0.01;
  static const double _matchConsecutive = 1.0;
  static const double _matchSlash = 0.9;
  static const double _matchWord = 0.8;
  static const double _matchCapital = 0.7;
  static const double _matchDot = 0.6;

  static double? _fzyScore(String needle, String haystack) {
    final n = needle.length;
    final m = haystack.length;

    if (n == 0 || m == 0 || n > m) return null;

    if (n == m) {
      for (var i = 0; i < n; i++) {
        if (needle[i] != haystack[i]) return null;
      }
      return n * _matchConsecutive;
    }

    final bonus = _precomputeBonus(haystack);

    final d = List.generate(n, (_) => List<double>.filled(m, _scoreMin));
    final mt = List.generate(n, (_) => List<double>.filled(m, _scoreMin));

    for (var i = 0; i < n; i++) {
      var prevScore = _scoreMin;
      final gapScore = (i == n - 1) ? _gapTrailing : _gapInner;

      for (var j = 0; j < m; j++) {
        if (needle[i] == haystack[j]) {
          double score;
          if (i == 0) {
            score = j * _gapLeading + bonus[j];
          } else if (j > 0) {
            final viaMatch = mt[i - 1][j - 1] + bonus[j];
            final viaConsecutive = d[i - 1][j - 1] + _matchConsecutive;
            score = viaMatch > viaConsecutive ? viaMatch : viaConsecutive;
          } else {
            score = _scoreMin;
          }
          d[i][j] = score;
          final withGap = prevScore + gapScore;
          prevScore = score > withGap ? score : withGap;
          mt[i][j] = prevScore;
        } else {
          d[i][j] = _scoreMin;
          prevScore = prevScore + gapScore;
          mt[i][j] = prevScore;
        }
      }
    }

    final result = mt[n - 1][m - 1];
    return result == _scoreMin ? null : result;
  }

  static List<double> _precomputeBonus(String haystack) {
    final m = haystack.length;
    final matchBonus = List<double>.filled(m, 0);
    var lastCh = '/';
    for (var i = 0; i < m; i++) {
      final ch = haystack[i];
      matchBonus[i] = _computeBonus(lastCh, ch);
      lastCh = ch;
    }
    return matchBonus;
  }

  static double _computeBonus(String prev, String cur) {
    if (prev == '/') return _matchSlash;
    if (prev == '-' || prev == '_' || prev == ' ') return _matchWord;
    if (prev == '.') return _matchDot;
    final prevIsLower =
        prev.compareTo('a') >= 0 && prev.compareTo('z') <= 0;
    final curIsUpper =
        cur.codeUnitAt(0) >= 65 && cur.codeUnitAt(0) <= 90;
    if (prevIsLower && curIsUpper) return _matchCapital;
    return 0;
  }
}
