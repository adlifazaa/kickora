import 'dart:async';

import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/cache_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_debug_log.dart';
import '../../api/clients/football_remote_client.dart';
import '../../api/football_api_envelope.dart';
import '../../api/mappers/football_api_mapper.dart';
import '../../models/competition_model.dart';
import '../../models/lineup_model.dart';
import '../../models/match_model.dart';
import '../../models/player_model.dart';
import '../../models/standing_model.dart';
import '../../models/team_model.dart';
import '../api_football_parser.dart';
import '../football_api_routes.dart' as shared;
import 'backend_proxy_routes.dart';

/// Prepared Kickora backend proxy client (Flutter-only foundation).
///
/// Disabled by default. Active only when:
/// `--dart-define=KICKORA_API_MODE=backend --dart-define=KICKORA_BACKEND_URL=YOUR_URL`
///
/// Uses [ApiClient] timeouts, [CacheService] TTL buckets, and [FootballApiMapper].
/// Not wired into UI — [FootballRepository] still uses mock by default.
class BackendProxyService {
  BackendProxyService({
    BackendProxyFootballClient? client,
    CacheManager? cache,
  })  : _client = client ?? BackendProxyFootballClient(),
        _cache = cache != null ? CacheService(cache) : null;

  final BackendProxyFootballClient _client;
  final CacheService? _cache;

  int get _season => ApiConstants.currentSeason();

  /// True when backend proxy mode and [KICKORA_BACKEND_URL] are configured.
  bool get isEnabled =>
      ApiConstants.isBackendProxy &&
      ApiConstants.hasBackendUrl &&
      _client.isConfigured;

  void logStatus() {
    ApiDebugLog.dataSource(
      operation: 'BackendProxyService',
      source: isEnabled ? 'backend-proxy' : 'disabled',
      message:
          'mode=${ApiConstants.apiMode.name} enabled=$isEnabled urlConfigured=${ApiConstants.hasBackendUrl} (URL not logged)',
    );
  }

  void _ensureEnabled() {
    if (!isEnabled) throw const ApiException.notConfigured();
  }

  Future<FootballApiEnvelope> _get(shared.ApiRouteRequest route) async {
    _ensureEnabled();
    return _client.get(route.path, queryParameters: route.queryParameters);
  }

  /// Maps unexpected errors to [ApiException] (friendly messages upstream).
  static Future<T> safe<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException.timeout();
    } catch (e) {
      throw ApiException.unknown(e.toString());
    }
  }

  Future<List<MatchModel>> getLiveMatches({int? competitionId}) => safe(() async {
        final cacheKey = _cacheKey('live', league: competitionId);
        final cached = _readMatches(cacheKey, CacheBucket.liveMatches);
        if (cached != null) return cached;

        final route = BackendProxyRoutes.liveMatches(
          competitionId: competitionId,
          season: _season,
        );
        final envelope = await _get(route);
        final matches = FootballApiMapper.liveMatches(envelope);
        await _writeMatches(cacheKey, matches, CacheBucket.liveMatches);
        return matches;
      });

  Future<List<MatchModel>> getMatchesToday({
    DateTime? date,
    int? competitionId,
  }) =>
      safe(() async {
        final cacheKey = _cacheKey('today', date: date, league: competitionId);
        final cached = _readMatches(cacheKey, CacheBucket.todayMatches);
        if (cached != null) return cached;

        final route = BackendProxyRoutes.matchesToday(
          date: date,
          competitionId: competitionId,
          season: _season,
        );
        final envelope = await _get(route);
        final matches = FootballApiMapper.matchesByDate(envelope);
        await _writeMatches(cacheKey, matches, CacheBucket.todayMatches);
        return matches;
      });

  Future<List<MatchModel>> getUpcomingMatches({
    DateTime? date,
    int? competitionId,
  }) =>
      safe(() async {
        final cacheKey =
            _cacheKey('upcoming', date: date, league: competitionId);
        final cached = _readMatches(cacheKey, CacheBucket.upcomingMatches);
        if (cached != null) return cached;

        final route = BackendProxyRoutes.upcomingMatches(
          date: date,
          competitionId: competitionId,
          season: _season,
        );
        final envelope = await _get(route);
        final matches = FootballApiMapper.matchesByDate(envelope);
        await _writeMatches(cacheKey, matches, CacheBucket.upcomingMatches);
        return matches;
      });

  Future<List<MatchModel>> getFinishedMatches({
    DateTime? date,
    int? competitionId,
  }) =>
      safe(() async {
        final cacheKey =
            _cacheKey('finished', date: date, league: competitionId);
        final cached = _readMatches(cacheKey, CacheBucket.finishedMatches);
        if (cached != null) return cached;

        final route = BackendProxyRoutes.finishedMatches(
          date: date,
          competitionId: competitionId,
          season: _season,
        );
        final envelope = await _get(route);
        final matches = FootballApiMapper.matchesByDate(envelope);
        await _writeMatches(cacheKey, matches, CacheBucket.finishedMatches);
        return matches;
      });

  Future<List<CompetitionModel>> getCompetitions() => safe(() async {
        const cacheKey = 'backend_cache_competitions';
        final cached = _readCompetitions(cacheKey);
        if (cached != null) return cached;

        final envelope = await _get(BackendProxyRoutes.competitions);
        final list = FootballApiMapper.competitions(envelope);
        await _cache?.writeJsonList(
          cacheKey,
          list.map((c) => c.toJson()).toList(),
          CacheBucket.competitions,
        );
        return list;
      });

  Future<List<StandingModel>> getStandings({
    required int competitionId,
  }) =>
      safe(() async {
        final cacheKey = 'backend_cache_standings_$competitionId';
        final cached = _readStandings(cacheKey);
        if (cached != null) return cached;

        final route = BackendProxyRoutes.standings(
          competitionId: competitionId,
          season: _season,
        );
        final envelope = await _get(route);
        final list = FootballApiMapper.standings(envelope);
        await _cache?.writeJsonList(
          cacheKey,
          list
              .map(
                (s) => {
                  'rank': s.position,
                  'position': s.position,
                  'team': s.team.toJson(),
                  'played': s.played,
                  'wins': s.wins,
                  'draws': s.draws,
                  'losses': s.losses,
                  'goalDifference': s.goalDifference,
                  'points': s.points,
                },
              )
              .toList(),
          CacheBucket.standings,
        );
        return list;
      });

  Future<List<TeamModel>> getTeams({required int competitionId}) =>
      safe(() async {
        final cacheKey = 'backend_cache_teams_$competitionId';
        final cached = _readTeams(cacheKey);
        if (cached != null) return cached;

        final route = BackendProxyRoutes.teams(
          competitionId: competitionId,
          season: _season,
        );
        final envelope = await _get(route);
        final list = FootballApiMapper.teams(envelope);
        await _cache?.writeJsonList(
          cacheKey,
          list.map((t) => t.toJson()).toList(),
          CacheBucket.teams,
        );
        return list;
      });

  Future<List<PlayerModel>> searchPlayers(String query) => safe(() async {
        final trimmed = query.trim();
        if (trimmed.isEmpty) return const [];

        final route = BackendProxyRoutes.playersSearch(
          query: trimmed,
          season: _season,
        );
        final envelope = await _get(route);
        return FootballApiMapper.searchPlayers(envelope);
      });

  Future<MatchModel?> getMatchDetails(int matchId) => safe(() async {
        final cacheKey = 'backend_cache_fixture_$matchId';
        final cached = _readMatches(cacheKey, CacheBucket.matchDetails);
        if (cached != null && cached.isNotEmpty) return cached.first;

        final envelope = await _get(BackendProxyRoutes.matchById(matchId));
        final match = FootballApiMapper.matchDetails(envelope);
        if (match != null) {
          await _writeMatches(
            cacheKey,
            [match],
            CacheBucket.matchDetails,
          );
        }
        return match;
      });

  Future<List<MatchEventModel>> getMatchEvents(int matchId) => safe(() async {
        final fixture = await getMatchDetails(matchId);
        final envelope = await _get(BackendProxyRoutes.matchEvents(matchId));
        return FootballApiMapper.matchEvents(
          envelope,
          homeTeamId: fixture?.homeTeam.id,
          awayTeamId: fixture?.awayTeam.id,
        );
      });

  Future<List<MatchStatisticModel>> getMatchStatistics(int matchId) =>
      safe(() async {
        final fixture = await getMatchDetails(matchId);
        final envelope =
            await _get(BackendProxyRoutes.matchStatistics(matchId));
        return FootballApiMapper.matchStatistics(
          envelope,
          homeTeamId: fixture?.homeTeam.id,
        );
      });

  Future<({LineupModel? home, LineupModel? away})> getLineups(int matchId) =>
      safe(() async {
        final fixture = await getMatchDetails(matchId);
        final envelope = await _get(BackendProxyRoutes.matchLineups(matchId));
        return FootballApiMapper.matchLineups(
          envelope,
          homeTeamId: fixture?.homeTeam.id,
          awayTeamId: fixture?.awayTeam.id,
        );
      });

  String _cacheKey(String prefix, {DateTime? date, int? league}) {
    final d = date != null ? ApiConstants.formatDate(date) : 'any';
    return 'backend_${prefix}_${league ?? 'all'}_$d';
  }

  List<MatchModel>? _readMatches(String key, CacheBucket bucket) {
    final list = _cache?.readJsonList(key, bucket);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => ApiFootballParser.parseFixture(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _writeMatches(
    String key,
    List<MatchModel> matches,
    CacheBucket bucket,
  ) async {
    await _cache?.writeJsonList(
      key,
      matches
          .map(
            (m) => {
              'fixture': {
                'id': m.id,
                'date': m.date.toIso8601String(),
                'status': {'short': _statusShort(m.status)},
                'venue': {'name': m.stadium},
              },
              'league': {
                'id': m.competition.id,
                'name': m.competition.name,
                'country': m.competition.region,
                'logo': m.competition.logo,
              },
              'teams': {
                'home': m.homeTeam.toJson(),
                'away': m.awayTeam.toJson(),
              },
              'goals': {'home': m.homeScore, 'away': m.awayScore},
            },
          )
          .toList(),
      bucket,
    );
  }

  List<CompetitionModel>? _readCompetitions(String key) {
    final list = _cache?.readJsonList(key, CacheBucket.competitions);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => CompetitionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<StandingModel>? _readStandings(String key) {
    final list = _cache?.readJsonList(key, CacheBucket.standings);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => StandingModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<TeamModel>? _readTeams(String key) {
    final list = _cache?.readJsonList(key, CacheBucket.teams);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => TeamModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  String _statusShort(MatchStatus status) {
    switch (status) {
      case MatchStatus.live:
        return '1H';
      case MatchStatus.finished:
        return 'FT';
      case MatchStatus.upcoming:
        return 'NS';
    }
  }
}
