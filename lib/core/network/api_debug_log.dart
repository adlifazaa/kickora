import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';

/// Safe API logging for local testing. Never logs API keys or auth headers.
class ApiDebugLog {
  ApiDebugLog._();

  static bool get _httpVerbose => kDebugMode && ApiConstants.enableDebugLogs;

  static void boot() {
    if (!kDebugMode) return;
    debugPrint(
      '[Kickora] apiKeyPresent=${ApiConstants.hasApiKey} '
      'dataSource=${ApiConstants.hasApiKey ? "api" : "mock"}',
    );
    debugPrint('[Kickora] baseUrl=${ApiConstants.baseUrl}');
    if (ApiConstants.hasApiKey) {
      debugPrint(
        '[Kickora] header=${ApiConstants.headerApiKey} (value not logged)',
      );
    }
  }

  static void request(String method, Uri uri) {
    if (!kDebugMode) return;
    final path = uri.path.isEmpty ? '/' : uri.path;
    final query = uri.query.isEmpty ? '' : '?${_redactQuery(uri.query)}';
    debugPrint('[Kickora] → $method $path$query');
  }

  static void response({
    required int statusCode,
    required String path,
    int? results,
    String? errorCode,
  }) {
    if (!kDebugMode) return;
    final count = results != null ? ' resultCount=$results' : '';
    final err = errorCode != null ? ' error=$errorCode' : '';
    debugPrint('[Kickora] ← HTTP $statusCode $path$count$err');
  }

  static void retry(String path, int attempt, String reason) {
    if (!_httpVerbose) return;
    debugPrint('[Kickora] ↻ retry $attempt $path ($reason)');
  }

  static void failure(String path, String code) {
    if (!kDebugMode) return;
    debugPrint('[Kickora] ✗ $path [$code]');
  }

  /// Repository layer: api vs mock, never logs secrets.
  static void dataSource({
    required String operation,
    required String source,
    int? count,
    String? message,
  }) {
    if (!kDebugMode) return;
    final n = count != null ? ' resultCount=$count' : '';
    final msg = message != null ? ' $message' : '';
    debugPrint(
      '[Kickora] apiKeyPresent=${ApiConstants.hasApiKey} '
      '$operation dataSource=$source$n$msg',
    );
  }

  static String _redactQuery(String query) {
    return query
        .split('&')
        .map((part) {
          final eq = part.indexOf('=');
          if (eq <= 0) return part;
          final key = part.substring(0, eq);
          if (key.toLowerCase().contains('key') ||
              key.toLowerCase().contains('token')) {
            return '$key=***';
          }
          return part;
        })
        .join('&');
  }
}
