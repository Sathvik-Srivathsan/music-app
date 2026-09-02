/// Record-name collation implementing the library's ordering policy:
///
///   bucket 0: leading digit            ('1', '42' ...)
///   bucket 1: uppercase-initial block   A À Á Â B C ... Z
///   bucket 2: lowercase-initial block   a à á â b c ... z
///   bucket 3: everything else           CJK, kana, symbols, emoji
///
/// Within a letter block the base letter precedes its diacritic
/// variants (E before É before È), and the two case blocks never
/// intermix - 'a' sorts after 'Z', not beside 'A'.
library;

const List<String> _bases = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

const Map<String, List<String>> _variants = {
  'A': ['À', 'Á', 'Â', 'Ã', 'Ä', 'Å', 'Ā', 'Ă', 'Ą', 'Æ'],
  'C': ['Ç', 'Ć', 'Ĉ', 'Č'],
  'D': ['Ď', 'Đ'],
  'E': ['È', 'É', 'Ê', 'Ë', 'Ē', 'Ė', 'Ę', 'Ě'],
  'G': ['Ĝ', 'Ğ', 'Ġ'],
  'H': ['Ĥ', 'Ħ'],
  'I': ['Ì', 'Í', 'Î', 'Ï', 'Ĩ', 'Ī', 'Į', 'İ'],
  'J': ['Ĵ'],
  'K': ['Ķ'],
  'L': ['Ĺ', 'Ļ', 'Ľ', 'Ł'],
  'N': ['Ñ', 'Ń', 'Ņ', 'Ň'],
  'O': ['Ò', 'Ó', 'Ô', 'Õ', 'Ö', 'Ø', 'Ő', 'Œ'],
  'R': ['Ŕ', 'Ŗ', 'Ř'],
  'S': ['Ś', 'Ŝ', 'Ş', 'Š', 'ß'],
  'T': ['Ţ', 'Ť', 'Þ'],
  'U': ['Ù', 'Ú', 'Û', 'Ü', 'Ũ', 'Ū', 'Ů', 'Ų', 'Ű'],
  'W': ['Ŵ'],
  'Y': ['Ý', 'ŷ', 'Ÿ'],
  'Z': ['Ź', 'Ż', 'Ž'],
};

/// rune -> global rank. Built once: digits keep their code points
/// (ascending inside bucket 0); letters get sequential ranks with the
/// base first, variants directly after; unknown runes fall into the
/// trailing bucket keyed by code point.
final Map<int, int> _ranks = _build();

int _digitBase = '0'.runes.first;
int _unknownBase = 0x110000;

Map<int, int> _build() {
  final map = <int, int>{};
  // Letters start ABOVE every digit code point ('0'-'9' = 48-57)
  // so the digit bucket always sorts first.
  var rank = '9'.runes.first + 1;

  // Bucket 1: uppercase block.
  for (final base in _bases) {
    map[base.runes.first] = rank++;
    final vars = _variants[base];
    if (vars != null) {
      for (final v in vars) {
        map[v.runes.first] = rank++;
      }
    }
  }

  // Bucket 2: lowercase block - mirror of the uppercase order.
  for (final base in _bases) {
    map[base.toLowerCase().runes.first] = rank++;
    final vars = _variants[base];
    if (vars != null) {
      for (final v in vars) {
        final lower = v.toLowerCase();
        map[lower.runes.first] = rank++;
      }
    }
  }

  _unknownBase = rank;
  return map;
}

int _rankOfRune(int rune) {
  if (rune >= _digitBase && rune <= _digitBase + 9) {
    return rune; // bucket 0, natural numeric order
  }
  return _ranks[rune] ??
      (_unknownBase + rune); // bucket 3, stable by code point
}

/// Character-by-character comparison over runes. Prefix sorts first.
int compareRecordNames(String a, String b) {
  final ra = a.runes.toList();
  final rb = b.runes.toList();
  final n = ra.length < rb.length ? ra.length : rb.length;
  for (var i = 0; i < n; i++) {
    final cmp = _rankOfRune(ra[i]).compareTo(_rankOfRune(rb[i]));
    if (cmp != 0) return cmp;
  }
  return ra.length.compareTo(rb.length);
}
