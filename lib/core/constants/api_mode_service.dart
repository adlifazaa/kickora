import '../network/api_debug_log.dart';
import 'api_constants.dart';
import 'api_mode.dart';

/// Resolves and exposes the active football data mode (compile-time via dart-define).
class ApiModeService {
  ApiModeService._();

  static ApiMode get mode => ApiConstants.apiMode;

  static bool get isMock => ApiConstants.isMock;

  static bool get isDirectApi => ApiConstants.isDirectApi;

  static bool get isBackendProxy => ApiConstants.isBackendProxy;

  /// True when remote HTTP should be used (direct key or backend URL configured).
  static bool get usesRemoteApi => ApiConstants.hasRemoteApi;

  static String get effectiveBaseUrl => ApiConstants.effectiveBaseUrl;

  static void logConfiguration() => ApiDebugLog.boot();
}
