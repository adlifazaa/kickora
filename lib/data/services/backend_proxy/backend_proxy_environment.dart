/// Compile-time environment for Kickora backend proxy (no secrets logged).
class BackendProxyEnvironment {
  BackendProxyEnvironment._();

  /// `mock` (default), `direct`, or `backend` / `backendproxy`.
  static const String apiMode = String.fromEnvironment(
    'KICKORA_API_MODE',
    defaultValue: 'mock',
  );

  /// Production backend base URL (no trailing slash required).
  static const String backendUrl = String.fromEnvironment(
    'KICKORA_BACKEND_URL',
    defaultValue: '',
  );

  /// Legacy alias supported by [ApiConstants].
  static const String backendBaseUrl = String.fromEnvironment(
    'KICKORA_BACKEND_BASE_URL',
    defaultValue: '',
  );

  static bool get isConfigured =>
      backendUrl.trim().isNotEmpty || backendBaseUrl.trim().isNotEmpty;
}
