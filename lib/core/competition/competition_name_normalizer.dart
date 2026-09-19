/// Normalizes competition names for alias matching and deduplication.
class CompetitionNameNormalizer {
  CompetitionNameNormalizer._();

  static String normalize(String raw) {
    var value = raw.trim().toLowerCase();
    value = value.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    value = value
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    value = value.replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]+'), ' ');
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool equals(String a, String b) => normalize(a) == normalize(b);

  static bool containsNormalized(String haystack, String needle) {
    final h = ' ${normalize(haystack)} ';
    final n = ' ${normalize(needle)} ';
    return n.trim().isNotEmpty && h.contains(n);
  }
}
