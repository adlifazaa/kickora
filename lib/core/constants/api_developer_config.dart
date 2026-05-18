import 'api_constants.dart';
import 'api_mode.dart';

/// Compile-time API mode validation for local developer testing (console only).
class ApiDeveloperConfig {
  ApiDeveloperConfig._();

  /// Active football data mode (default [ApiMode.mock]).
  static ApiMode get apiMode => ApiConstants.apiMode;

  static bool get isMockDefault => ApiConstants.isMock;

  /// True when remote HTTP can run (credentials present).
  static bool get remoteActive =>
      !ApiConstants.isMock && ApiConstants.hasRemoteApi;

  /// Human-readable label for logs: `mock`, `directApi`, `backendProxy`.
  static String get dataSourceLabel {
    if (ApiConstants.isMock) return 'mock';
    if (!ApiConstants.hasRemoteApi) return 'mock';
    if (ApiConstants.isDirectApi) return 'directApi';
    if (ApiConstants.isBackendProxy) return 'backendProxy';
    return 'mock';
  }

  /// Friendly console warnings when dart-define mode lacks credentials (no crash).
  static List<String> get configurationWarnings {
    final warnings = <String>[];
    if (ApiConstants.isDirectApi && !ApiConstants.hasApiKey) {
      warnings.add(
        'directApi mode requested but KICKORA_API_KEY is missing. '
        'Using mock data — app will not crash. '
        'Run: flutter run --dart-define=KICKORA_API_MODE=direct '
        '--dart-define=KICKORA_API_KEY=YOUR_KEY',
      );
    }
    if (ApiConstants.isBackendProxy && !ApiConstants.hasBackendUrl) {
      warnings.add(
        'backendProxy mode requested but KICKORA_BACKEND_URL is missing. '
        'Using mock data — app will not crash. '
        'Run: flutter run --dart-define=KICKORA_API_MODE=backend '
        '--dart-define=KICKORA_BACKEND_URL=https://your-api.example.com',
      );
    }
    return warnings;
  }
}
