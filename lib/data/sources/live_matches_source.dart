import '../../core/cache/cache_manager.dart';
import '../../core/cache/cache_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/api_mode.dart';
import '../../core/errors/api_exception.dart';
import '../../core/network/api_debug_log.dart';
import '../models/match_model.dart';
import '../services/api_football_parser.dart';
import '../services/api_football/api_football_service.dart';
import '../services/backend_proxy/backend_proxy_service.dart';

/// Live matches only — routes by [ApiMode] when remote credentials are set.
///
/// Default (`mock`): inactive; [FootballRepository] serves [MockData].
/// `directApi` + key → [ApiFootballService.getLiveMatches].
/// `backendProxy` + URL → [BackendProxyService.getLiveMatches].
class LiveMatchesSource {
  LiveMatchesSource({
    CacheManager? cache,
    ApiFootballService? apiFootball,
    BackendProxyService? backendProxy,
  })  : _cache = cache != null ? CacheService(cache) : null,
        _apiFootball = apiFootball ?? ApiFootballService(),
        _backendProxy = backendProxy ?? BackendProxyService(cache: cache);

  final CacheService? _cache;
  final ApiFootballService _apiFootball;
  final BackendProxyService _backendProxy;

  static bool get isRemoteLiveActive {
    if (ApiConstants.isMock) return false;
    if (ApiConstants.isDirectApi) {
      return ApiConstants.hasApiKey;
    }
    if (ApiConstants.isBackendProxy) {
      return ApiConstants.hasBackendUrl;
    }
    return false;
  }

  static String sourceLabelForMode(ApiMode mode) {
    switch (mode) {
      case ApiMode.mock:
        return 'mock';
      case ApiMode.directApi:
        return 'directApi';
      case ApiMode.backendProxy:
        return 'backendProxy';
    }
  }

  String get _activeSourceLabel {
    if (ApiConstants.isDirectApi) return 'directApi';
    if (ApiConstants.isBackendProxy) return 'backendProxy';
    return 'mock';
  }

  Future<List<MatchModel>> fetch({
    int? competitionId,
    bool skipCache = false,
  }) async {
    if (!isRemoteLiveActive) {
      throw const ApiException.notConfigured();
    }

    final cacheKey = _cacheKey(competitionId);

    if (!skipCache) {
      final cached = readCached(competitionId: competitionId);
      if (cached != null) {
        ApiDebugLog.dataSource(
          operation: 'getLiveMatches',
          source: 'cache',
          count: cached.length,
          message: 'mode=${ApiConstants.apiMode.name}',
        );
        return cached;
      }
    }

    List<MatchModel> matches;
    if (ApiConstants.isDirectApi) {
      if (!_apiFootball.isEnabled) {
        throw const ApiException.notConfigured();
      }
      matches = await _apiFootball.getLiveMatches(competitionId: competitionId);
    } else if (ApiConstants.isBackendProxy) {
      if (!_backendProxy.isEnabled) {
        throw const ApiException.notConfigured();
      }
      matches =
          await _backendProxy.getLiveMatches(competitionId: competitionId);
    } else {
      throw const ApiException.notConfigured();
    }

    await _writeCache(cacheKey, matches);
    ApiDebugLog.dataSource(
      operation: 'getLiveMatches',
      source: _activeSourceLabel,
      count: matches.length,
      message: 'mode=${ApiConstants.apiMode.name}',
    );
    return matches;
  }

  Future<void> invalidate({int? competitionId}) async {
    await _cache?.remove(_cacheKey(competitionId));
  }

  List<MatchModel>? readCached({int? competitionId}) {
    final list =
        _cache?.readJsonList(_cacheKey(competitionId), CacheBucket.liveMatches);
    if (list == null) return null;
    return list
        .whereType<Map>()
        .map(
          (e) => ApiFootballParser.parseFixture(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList(growable: false);
  }

  String _cacheKey(int? competitionId) =>
      'live_matches_${competitionId ?? 'all'}';

  Future<void> _writeCache(String key, List<MatchModel> matches) async {
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
      CacheBucket.liveMatches,
    );
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
