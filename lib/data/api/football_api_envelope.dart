/// Normalized HTTP JSON body from API-Football or Kickora backend proxy.
///
/// Both sources expose a top-level `response` list (and optional `results` count).
class FootballApiEnvelope {
  const FootballApiEnvelope(this.raw);

  final Map<String, dynamic> raw;

  factory FootballApiEnvelope.from(Map<String, dynamic> json) =>
      FootballApiEnvelope(json);

  List<Map<String, dynamic>> get items {
    final response = raw['response'];
    if (response is List) {
      return response
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final data = raw['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  int? get resultCount {
    final results = raw['results'];
    if (results is int) return results;
    if (results is num) return results.toInt();
    return items.isEmpty ? 0 : items.length;
  }

  bool get isEmpty => items.isEmpty;
}
