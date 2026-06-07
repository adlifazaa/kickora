import '../../../core/constants/api_constants.dart';

/// Compile-time environment for Kickora backend proxy (no secrets logged).
class BackendProxyEnvironment {
  BackendProxyEnvironment._();

  /// Resolved API mode name (see [ApiConstants.apiModeName]).
  static String get apiMode => ApiConstants.apiModeName;

  /// Production backend base URL (no trailing slash required).
  static String get backendUrl => ApiConstants.backendBaseUrl;

  /// Legacy alias supported by [ApiConstants].
  static const String backendBaseUrl = String.fromEnvironment(
    'KICKORA_BACKEND_BASE_URL',
    defaultValue: '',
  );

  static bool get isConfigured => ApiConstants.hasBackendUrl;
}
