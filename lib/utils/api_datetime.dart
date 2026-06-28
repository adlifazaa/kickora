/// Parses and normalizes API-Football fixture kickoff timestamps.
///
/// API-Football returns ISO 8601 strings in UTC (e.g. `2026-06-11T17:00:00+00:00`).
/// Display and grouping must use the device local timezone.
class ApiDateTime {
  ApiDateTime._();

  /// Parses a fixture kickoff string and returns device-local [DateTime].
  static DateTime? parseKickoffLocal(String? raw) {
    final parsed = DateTime.tryParse(raw?.trim() ?? '');
    if (parsed == null) return null;
    return toLocalKickoff(parsed);
  }

  /// Converts UTC kickoff to local; leaves already-local values unchanged.
  static DateTime toLocalKickoff(DateTime date) =>
      date.isUtc ? date.toLocal() : date;

  /// Parses API kickoff with optional fallback when raw is missing/invalid.
  static DateTime parseApiKickoff(String? raw, {DateTime? fallback}) {
    final fb = fallback ?? DateTime.now();
    if (raw == null || raw.trim().isEmpty) return fb;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return fb;
    return toLocalKickoff(parsed);
  }

  /// Compares two instants on the device-local calendar day.
  static bool isSameLocalDay(DateTime a, DateTime b) {
    final la = toLocalKickoff(a);
    final lb = toLocalKickoff(b);
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  /// Stable `yyyy-MM-dd` key for grouping fixtures by local day.
  static String localDateKey(DateTime kickoff) {
    final local = toLocalKickoff(kickoff);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  /// `HH:mm` in the device local timezone.
  static String formatClock(DateTime date) {
    final local = toLocalKickoff(date);
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
