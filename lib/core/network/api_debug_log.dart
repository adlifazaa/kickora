import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';

/// Safe API logging for local testing. Never logs API keys or auth headers.
///
/// Enable with: `flutter run --dart-define=KICKORA_API_DEBUG=true`
class ApiDebugLog {
  ApiDebugLog._();

  static bool get _enabled => kDebugMode && ApiConstants.enableDebugLogs;

  static void boot() {
    if (!_enabled) return;
    final mode = ApiConstants.hasApiKey
        ? 'API-Football (key configured via --dart-define)'
        : 'mock fallback (no KICKORA_API_KEY)';
    debugPrint('[Kickora API] Boot → $mode');
    debugPrint('[Kickora API] Base URL → ${ApiConstants.baseUrl}');
  }

  static void request(String method, Uri uri) {
    if (!_enabled) return;
    final safe = _redactUri(uri);
    debugPrint('[Kickora API] → $method $safe');
  }

  static void response({
    required int statusCode,
    required String path,
    int? results,
    String? errorCode,
  }) {
    if (!_enabled) return;
    final count = results != null ? ' results=$results' : '';
    final err = errorCode != null ? ' error=$errorCode' : '';
    debugPrint('[Kickora API] ← HTTP $statusCode $path$count$err');
  }

  static void retry(String path, int attempt, String reason) {
    if (!_enabled) return;
    debugPrint('[Kickora API] ↻ retry $attempt $path ($reason)');
  }

  static void failure(String path, String code) {
    if (!_enabled) return;
    debugPrint('[Kickora API] ✗ $path [$code]');
  }

  static String _redactUri(Uri uri) {
    final params = Map<String, String>.from(uri.queryParameters);
    for (final key in params.keys.toList()) {
      if (key.toLowerCase().contains('key') ||
          key.toLowerCase().contains('token')) {
        params[key] = '***';
      }
    }
    return uri.replace(queryParameters: params).toString();
  }
}
