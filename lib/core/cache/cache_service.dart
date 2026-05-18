import '../constants/api_cache_policy.dart';
import '../network/api_debug_log.dart';
import 'cache_manager.dart';

/// TTL buckets aligned with [ApiCachePolicy].
enum CacheBucket {
  liveMatches,
  todayMatches,
  standings,
  competitions,
  matchDetails,
  matchEvents,
  matchStatistics,
  matchLineups,
  teams,
  upcomingMatches,
  finishedMatches,
  playerProfile,
}

/// Disk TTL cache with debug hit/miss logging (no secrets).
class CacheService {
  CacheService(this._manager);

  final CacheManager _manager;

  static Duration ttlFor(CacheBucket bucket) {
    switch (bucket) {
      case CacheBucket.liveMatches:
        return ApiCachePolicy.liveMatches;
      case CacheBucket.todayMatches:
        return ApiCachePolicy.todayMatches;
      case CacheBucket.standings:
        return ApiCachePolicy.standings;
      case CacheBucket.competitions:
        return ApiCachePolicy.competitions;
      case CacheBucket.matchDetails:
        return ApiCachePolicy.matchDetails;
      case CacheBucket.matchEvents:
        return ApiCachePolicy.matchEvents;
      case CacheBucket.matchStatistics:
        return ApiCachePolicy.matchStatistics;
      case CacheBucket.matchLineups:
        return ApiCachePolicy.matchLineups;
      case CacheBucket.teams:
        return ApiCachePolicy.teams;
      case CacheBucket.upcomingMatches:
        return ApiCachePolicy.fixturesUpcoming;
      case CacheBucket.finishedMatches:
        return ApiCachePolicy.fixturesFinished;
      case CacheBucket.playerProfile:
        return ApiCachePolicy.playerProfile;
    }
  }

  Map<String, dynamic>? readJson(String key, CacheBucket bucket) {
    final value = _manager.getJson(key);
    ApiDebugLog.cache(
      key: key,
      hit: value != null,
      bucket: bucket.name,
      layer: 'disk',
    );
    return value;
  }

  List<dynamic>? readJsonList(String key, CacheBucket bucket) {
    final value = _manager.getJsonList(key);
    ApiDebugLog.cache(
      key: key,
      hit: value != null,
      bucket: bucket.name,
      layer: 'disk',
    );
    return value;
  }

  Future<void> writeJson(
    String key,
    Object value,
    CacheBucket bucket,
  ) async {
    await _manager.setJson(key, value, ttl: ttlFor(bucket));
    ApiDebugLog.cacheWrite(key: key, bucket: bucket.name, layer: 'disk');
  }

  Future<void> writeJsonList(
    String key,
    List<dynamic> value,
    CacheBucket bucket,
  ) async {
    await _manager.setJsonList(key, value, ttl: ttlFor(bucket));
    ApiDebugLog.cacheWrite(key: key, bucket: bucket.name, layer: 'disk');
  }

  Future<void> remove(String key) => _manager.remove(key);

  Future<void> removeByPrefix(String prefix) =>
      _manager.removeByPrefix(prefix);
}
