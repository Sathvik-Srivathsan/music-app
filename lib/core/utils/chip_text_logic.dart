/// Pure text-processing logic for ChipInputField.
///
/// Type 2 matching contract (commit path):
/// A segment matches an existing item only when their NORMALIZED forms are
/// exactly equal. Normalization strips wrapping/stray quote artifacts,
/// collapses every whitespace run (spaces, tabs, newlines, NBSP, BOM,
/// ideographic spaces) to single spaces, normalizes hyphens to spaces,
/// removes zero-width characters, trims, and lowercases. Fuzzy similarity
/// is Type 1 (dropdown) only and never auto-commits.
class ChipTextLogic {
  ChipTextLogic._();

  /// Splits raw input on commas, trims each part, drops empty segments.
  static List<String> splitSegments(String raw) {
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Canonical normalization used by Type 2 matching.
  static String normalizeForMatch(String raw) {
    var s = raw.trim();
    while (s.length >= 2 &&
        ((s.startsWith('"') && s.endsWith('"')) ||
            (s.startsWith("'") && s.endsWith("'")))) {
      s = s.substring(1, s.length - 1).trim();
    }
    s = s.replaceAll('"', '');
    s = s.replaceAll(RegExp(r'[\u200B\u200C\u200D\uFEFF\u3000]'), ' ');
    s = s.replaceAll('-', ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s.toLowerCase();
  }

  /// Type 2 matching: exact equality of normalized forms.
  /// Returns the canonical name from [names], or null when unmatched.
  static String? matchType2(String segment, List<String> names) {
    final segNorm = normalizeForMatch(segment);
    if (segNorm.isEmpty) return null;
    for (final name in names) {
      if (normalizeForMatch(name) == segNorm) return name;
    }
    return null;
  }
}
