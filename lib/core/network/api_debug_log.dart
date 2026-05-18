import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../constants/api_mode_service.dart';
import 'api_request_coordinator.dart';

/// Safe API logging for local testing. Never logs API keys or auth headers.
class ApiDebugLog {
  ApiDebugLog._();

  static bool get _httpVerbose => kDebugMode && ApiConstants.enableDebugLogs;

  static void boot() {
    if (!kDebugMode) return;
    debugPrint(
      '[Kickora Dev] boot apiMode=${ApiModeService.mode.name} '
      'dataSource=${ApiModeService.effectiveDataSource} '
      'remoteActive=${ApiModeService.remoteActive} '
      'apiDevMode=${ApiConstants.apiDevMode}',
    );
    debugPrint('[Kickora Dev] baseUrl=${ApiConstants.effectiveBaseUrl}');
    if (ApiConstants.isMock) {
      debugPrint(
        '[Kickora Dev] default=mock (Play Store / release builds use mock unless dart-define is set)',
      );
    }
    if (ApiConstants.isDirectApi && ApiConstants.hasApiKey) {
      debugPrint(
        '[Kickora Dev] directApi header=${ApiConstants.headerApiKey} (value not logged)',
      );
    }
    if (ApiConstants.isBackendProxy) {
      debugPrint('[Kickora Dev] backendProxy: no API key header from app');
    }
  }

  static void configurationWarning(String message) {
    if (!kDebugMode) return;
    debugPrint('[Kickora Dev] ⚠ $message');
  }

  static void providerSelected({
    required String provider,
    required bool remoteActive,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[Kickora Dev] provider=$provider apiMode=${ApiModeService.mode.name} '
      'dataSource=${ApiModeService.effectiveDataSource} remoteActive=$remoteActive',
    );
  }

  /// Standard per-request developer line: apiMode, dataSource, resultCount.
  static void developerTrace({
    required String operation,
    required String dataSource,
    int? resultCount,
  }) {
    if (!kDebugMode) return;
    final count = resultCount != null ? ' resultCount=$resultCount' : '';
    debugPrint(
      '[Kickora Dev] $operation apiMode=${ApiModeService.mode.name} '
      'dataSource=$dataSource$count',
    );
  }

  static void request(String method, Uri uri, {required int requestId}) {
    if (!kDebugMode) return;
    final path = uri.path.isEmpty ? '/' : uri.path;
    final query = uri.query.isEmpty ? '' : '?${_redactQuery(uri.query)}';
    final total = ApiRequestCoordinator.instance.requestCount;
    debugPrint(
      '[Kickora] apiMode=${ApiModeService.mode.name} '
      'request#$requestId (total=$total) → $method $path$query',
    );
  }

  static void response({
    required int requestId,
    required int statusCode,
    required String path,
    int? results,
    String? errorCode,
    String dataSource = 'api',
  }) {
    if (!kDebugMode) return;
    final count = results != null ? ' resultCount=$results' : '';
    final err = errorCode != null ? ' error=$errorCode' : '';
    debugPrint(
      '[Kickora] apiMode=${ApiModeService.mode.name} '
      'request#$requestId ← HTTP $statusCode $path '
      'dataSource=$dataSource$count$err',
    );
  }

  static void cache({
    required String key,
    required bool hit,
    required String bucket,
    String layer = 'disk',
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[Kickora] apiMode=${ApiModeService.mode.name} '
      'cache ${hit ? 'HIT' : 'MISS'} layer=$layer bucket=$bucket key=$key',
    );
  }

  static void cacheWrite({
    required String key,
    required String bucket,
    String layer = 'disk',
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[Kickora] apiMode=${ApiModeService.mode.name} '
      'cache WRITE layer=$layer bucket=$bucket key=$key',
    );
  }

  static void deduped(String dedupeKey) {
    if (!kDebugMode) return;
    debugPrint('[Kickora] deduped in-flight $dedupeKey');
  }

  static void retry(String path, int attempt, String reason) {
    if (!_httpVerbose) return;
    debugPrint('[Kickora] ↻ retry $attempt $path ($reason)');
  }

  static void failure(String path, String code) {
    if (!kDebugMode) return;
    debugPrint(
      '[Kickora] apiMode=${ApiModeService.mode.name} ✗ $path [$code]',
    );
  }

  /// Repository / provider layer: api vs mock, never logs secrets.
  static void dataSource({
    required String operation,
    required String source,
    int? count,
    String? message,
  }) {
    if (!kDebugMode) return;
    developerTrace(
      operation: operation,
      dataSource: source,
      resultCount: count,
    );
    if (message != null && message.isNotEmpty) {
      debugPrint('[Kickora Dev] $operation note=$message');
    }
  }

  static String _redactQuery(String query) {
    return query
        .split('&')
        .map((part) {
          final eq = part.indexOf('=');
          if (eq <= 0) return part;
          final key = part.substring(0, eq);
          if (key.toLowerCase().contains('key') ||
              key.toLowerCase().contains('token') ||
              key.toLowerCase().contains('secret')) {
            return '$key=***';
          }
          return part;
        })
        .join('&');
  }
}
