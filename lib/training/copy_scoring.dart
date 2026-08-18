class CopyScoring {
  const CopyScoring._();

  static String normalize(String value) => value
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'\s+'), ' ');

  static double accuracy(String expected, String actual) {
    final a = normalize(expected);
    final b = normalize(actual);

    if (a.isEmpty) return b.isEmpty ? 1 : 0;

    final distance = _levenshtein(a, b);
    final longest = a.length > b.length ? a.length : b.length;
    if (longest == 0) return 1;

    return (1 - (distance / longest)).clamp(0.0, 1.0);
  }

  static int _levenshtein(String a, String b) {
    final previous = List<int>.generate(b.length + 1, (i) => i);
    final current = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      current[0] = i;

      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        current[j] = _min3(
          current[j - 1] + 1,
          previous[j] + 1,
          previous[j - 1] + cost,
        );
      }

      for (var j = 0; j <= b.length; j++) {
        previous[j] = current[j];
      }
    }

    return previous[b.length];
  }

  static int _min3(int a, int b, int c) {
    var value = a < b ? a : b;
    if (c < value) value = c;
    return value;
  }
}
