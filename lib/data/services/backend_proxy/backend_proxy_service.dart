import 'dart:async';

import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/cache_service.dart';
import '../../../core/competition/competition_season_resolver.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/world_cup/world_cup_debug_log.dart';
import '../../../core/world_cup/world_cup_discovery.dart';
import '../../../core/world_cup/world_cup_priority.dart';
import '../../../core/constants/api_mode_service.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_debug_log.dart';
import '../../api/clients/football_remote_client.dart';
import '../../api/football_api_envelope.dart';
import '../../api/mappers/football_api_mapper.dart';
import '../../models/competition_model.dart';
import '../../models/lineup_model.dart';
import '../../models/match_model.dart';
import '../../models/player_model.dart';
import '../../models/standing_group_model.dart';
import '../../models/standing_model.dart';
import '../../models/team_model.dart';
import '../../models/news_article_model.dart';
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

  int get _defaultSeason => ApiConstants.currentSeason();

  int? _seasonForLeague(int? competitionId) {
    if (competitionId == null) return null;
    return CompetitionSeasonResolver.seasonFor(competitionId) ??
        _defaultSeason;
  }

  /// True when backend proxy mode and [KICKORA_BACKEND_URL] are configured.
  bool get isEnabled =>
      ApiModeService.isBackendProxy &&
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

        final season = _seasonForLeague(competitionId);
        final route = BackendProxyRoutes.liveMatches(
          competitionId: competitionId,
          season: season,
        );
        final envelope = await _get(route);
        final matches = FootballApiMapper.liveMatches(envelope);
        _logWorldCupFixtures(
          operation: 'liveMatches',
          competitionId: competitionId,
          season: season,
          envelope: envelope,
          matches: matches,
        );
        await _writeMatches(cacheKey, matches, CacheBucket.liveMatches);
        return matches;
      });

  Future<List<MatchModel>> getMatchesToday({
    DateTime? date,
    int? competitionId,
  }) =>
      safe(() async {
        final cacheKey = _cacheKey('today', date: date, league: null);
        final cached = _readMatches(cacheKey, CacheBucket.todayMatches);
        if (cached != null) {
          return competitionId == null
              ? cached
              : cached.where((m) => m.competition.id == competitionId).toList();
        }

        final route = BackendProxyRoutes.matchesToday(date: date);
        final envelope = await _get(route);
        final matches = FootballApiMapper.matchesByDate(envelope);
        _logWorldCupFixtures(
          operation: 'matchesToday',
          competitionId: competitionId,
          season: _seasonForLeague(competitionId),
          envelope: envelope,
          matches: matches,
        );
        await _writeMatches(cacheKey, matches, CacheBucket.todayMatches);
        if (competitionId == null) return matches;
        return matches.where((m) => m.competition.id == competitionId).toList();
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

        final season = _seasonForLeague(competitionId);
        final route = BackendProxyRoutes.upcomingMatches(
          date: date,
          competitionId: competitionId,
          season: season,
        );
        final envelope = await _get(route);
        final matches = FootballApiMapper.matchesByDate(envelope);
        _logWorldCupFixtures(
          operation: 'upcomingMatches',
          competitionId: competitionId,
          season: season,
          envelope: envelope,
          matches: matches,
        );
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

        final season = _seasonForLeague(competitionId);
        final route = BackendProxyRoutes.finishedMatches(
          date: date,
          competitionId: competitionId,
          season: season,
        );
        final envelope = await _get(route);
        final matches = FootballApiMapper.matchesByDate(envelope);
        _logWorldCupFixtures(
          operation: 'finishedMatches',
          competitionId: competitionId,
          season: season,
          envelope: envelope,
          matches: matches,
        );
        await _writeMatches(cacheKey, matches, CacheBucket.finishedMatches);
        return matches;
      });

  /// All fixtures for a league/season — one upstream call (World Cup schedule).
  Future<List<MatchModel>> getCompetitionMatches({
    required int competitionId,
    required int season,
  }) =>
      safe(() async {
        final cacheKey = 'backend_competition_matches_${competitionId}_$season';
        final cached = _readMatches(cacheKey, CacheBucket.competitionFixtures);
        if (cached != null) return cached;

        final route = BackendProxyRoutes.competitionMatches(
          competitionId: competitionId,
          season: season,
        );
        final envelope = await _get(route);
        final matches = FootballApiMapper.matchesByDate(envelope);
        _logWorldCupFixtures(
          operation: 'competitionMatches',
          competitionId: competitionId,
          season: season,
          envelope: envelope,
          matches: matches,
        );
        await _writeMatches(cacheKey, matches, CacheBucket.competitionFixtures);
        return matches;
      });

  Future<List<CompetitionModel>> getCompetitions() => safe(() async {
        const cacheKey = 'backend_cache_competitions';
        final cached = _readCompetitions(cacheKey);
        if (cached != null) return cached;

        final envelope = await _get(BackendProxyRoutes.competitions);
        final list = FootballApiMapper.competitions(envelope);
        CompetitionSeasonResolver.registerAll(list);
        WorldCupDiscovery.applyFromCompetitions(list);
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
          season: CompetitionSeasonResolver.seasonForOrDefault(competitionId),
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

  Future<List<StandingGroupModel>> getStandingGroups({
    required int competitionId,
  }) =>
      safe(() async {
        final route = BackendProxyRoutes.standings(
          competitionId: competitionId,
          season: CompetitionSeasonResolver.seasonForOrDefault(competitionId),
        );
        final envelope = await _get(route);
        return ApiFootballParser.parseStandingGroups(envelope.raw);
      });

  Future<List<TeamModel>> getTeams({required int competitionId}) =>
      safe(() async {
        final cacheKey = 'backend_cache_teams_$competitionId';
        final cached = _readTeams(cacheKey);
        if (cached != null) return cached;

        final route = BackendProxyRoutes.teams(
          competitionId: competitionId,
          season: CompetitionSeasonResolver.seasonForOrDefault(competitionId),
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
          season: _defaultSeason,
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

  Future<CompetitionModel?> getCompetitionById(int id) => safe(() async {
        final cacheKey = 'backend_competition_$id';
        final cached = _readCompetitions(cacheKey);
        if (cached != null && cached.isNotEmpty) return cached.first;

        final season = CompetitionSeasonResolver.seasonFor(id);
        final envelope = await _get(
          BackendProxyRoutes.competitionById(id: id, season: season),
        );
        final competition = FootballApiMapper.competitionById(envelope);
        if (competition != null) {
          await _cache?.writeJsonList(
            cacheKey,
            [competition.toJson()],
            CacheBucket.competitions,
          );
        }
        return competition;
      });

  Future<WorldCupNewsResult> getWorldCupNews() => safe(() async {
        if (!isEnabled) return WorldCupNewsResult.notConfigured;
        final envelope = await _get(BackendProxyRoutes.worldCupNews);
        return WorldCupNewsResult.fromJson(envelope.raw);
      });

  Future<List<PlayerModel>> getTopScorers(int competitionId) => safe(() async {
        final cacheKey = 'backend_scorers_$competitionId';
        final cached = _readPlayers(cacheKey);
        if (cached != null) return cached;

        final envelope = await _get(
          BackendProxyRoutes.topScorers(
            competitionId: competitionId,
            season: CompetitionSeasonResolver.seasonForOrDefault(competitionId),
          ),
        );
        final list = FootballApiMapper.players(envelope);
        await _writePlayers(cacheKey, list);
        return list;
      });

  Future<PlayerModel?> getPlayerById(int id) => safe(() async {
        final cacheKey = 'backend_player_$id';
        final cached = _readPlayers(cacheKey);
        if (cached != null && cached.isNotEmpty) return cached.first;

        final envelope = await _get(
          BackendProxyRoutes.playerById(id: id, season: _defaultSeason),
        );
        final player = FootballApiMapper.playerById(envelope);
        if (player != null) {
          await _writePlayers(cacheKey, [player]);
        }
        return player;
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

  List<PlayerModel>? _readPlayers(String key) {
    final list = _cache?.readJsonList(key, CacheBucket.playerProfile);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map((e) => PlayerModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _writePlayers(String key, List<PlayerModel> list) async {
    await _cache?.writeJsonList(
      key,
      list.map(_playerToJson).toList(),
      CacheBucket.playerProfile,
    );
  }

  Map<String, dynamic> _playerToJson(PlayerModel p) => {
        'id': p.id,
        'name': p.name,
        'shortName': p.shortName,
        'number': p.number,
        'nationality': p.nationality,
        'age': p.age,
        'position': p.position,
        'team': p.team,
        'teamLogoShort': p.teamLogoShort,
        'appearances': p.appearances,
        'goals': p.goals,
        'seasonRating': p.seasonRating,
        if (p.photoUrl.isNotEmpty) 'photoUrl': p.photoUrl,
      };

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

  void _logWorldCupFixtures({
    required String operation,
    required int? competitionId,
    required int? season,
    required FootballApiEnvelope envelope,
    required List<MatchModel> matches,
  }) {
    final wcId = WorldCupDiscovery.leagueId;
    if (wcId == null && competitionId == null) return;
    final targetId = competitionId ?? wcId;
    if (targetId == null) return;
    if (competitionId != null && competitionId != wcId) return;

    final raw = envelope.raw['response'];
    final rawList = raw is List ? raw : const [];
    final rawCount = rawList.length;
    final wcMatches = matches
        .where((m) => WorldCupPriority.isWorldCupMatch(m))
        .toList();
    final first = wcMatches.isNotEmpty ? wcMatches.first : null;
    final next = wcMatches
        .where((m) => m.status == MatchStatus.upcoming)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final rawFirst = rawList.isNotEmpty && rawList.first is Map
        ? Map<String, dynamic>.from(rawList.first as Map)
        : null;
    String? snippet;
    if (rawFirst != null) {
      final fixture = rawFirst['fixture'];
      final league = rawFirst['league'];
      final teams = rawFirst['teams'];
      String? homeName;
      if (teams is Map) {
        final home = teams['home'];
        if (home is Map) homeName = home['name']?.toString();
      }
      snippet =
          'fixtureId=${fixture is Map ? fixture['id'] : null} '
          'leagueId=${league is Map ? league['id'] : null} '
          'season=${league is Map ? league['season'] : null} '
          'home=$homeName';
    }

    WorldCupDebugLog.fixtureProbe(
      operation: operation,
      leagueId: targetId,
      season: season,
      rawCount: rawCount,
      parsedCount: wcMatches.length,
      firstFixtureSummary: first == null
          ? null
          : '${first.homeTeam.name} vs ${first.awayTeam.name} '
              '(${first.competition.name} ${first.date.toIso8601String()})',
      nextFixtureDate: next.isNotEmpty ? next.first.date.toIso8601String() : null,
      apiSnippet: snippet,
    );
  }
}
