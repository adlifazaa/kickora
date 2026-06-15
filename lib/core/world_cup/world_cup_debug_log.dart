import 'package:flutter/foundation.dart';

import '../../data/models/match_model.dart';

/// Temporary investigation logs for World Cup fixture discovery (debug only).
class WorldCupDebugLog {
  WorldCupDebugLog._();

  static void discovered({
    required int leagueId,
    int? season,
    required String name,
    String source = 'competitions',
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[Kickora WorldCup] discovered source=$source '
      'leagueId=$leagueId season=$season name="$name"',
    );
  }

  static void fixtureProbe({
    required String operation,
    required int? leagueId,
    required int? season,
    required int rawCount,
    required int parsedCount,
    String? firstFixtureSummary,
    String? nextFixtureDate,
    String? apiSnippet,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[Kickora WorldCup] fixtureProbe operation=$operation '
      'leagueId=$leagueId season=$season raw=$rawCount parsed=$parsedCount '
      'first=${firstFixtureSummary ?? 'none'} next=${nextFixtureDate ?? 'none'}',
    );
    if (apiSnippet != null && apiSnippet.isNotEmpty) {
      debugPrint('[Kickora WorldCup] apiSnippet $apiSnippet');
    }
  }

  static void seasonMismatch({
    required int leagueId,
    required int requestedSeason,
    required int? apiSeason,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[Kickora WorldCup] seasonMismatch leagueId=$leagueId '
      'requested=$requestedSeason apiFixtureSeason=$apiSeason',
    );
  }

  /// Logs distinct `league.round` values from loaded World Cup fixtures.
  static void fixtureRounds(List<MatchModel> matches) {
    if (!kDebugMode) return;
    final counts = <String, int>{};
    for (final m in matches) {
      final round = m.round.trim();
      final key = round.isEmpty ? '(empty)' : round;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    debugPrint(
      '[Kickora WorldCup] fixtureRounds distinct=${sorted.length} '
      'total=${matches.length}',
    );
    for (final e in sorted) {
      debugPrint('[Kickora WorldCup]   round="${e.key}" count=${e.value}');
    }
  }
}
