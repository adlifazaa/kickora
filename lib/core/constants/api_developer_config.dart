import 'api_constants.dart';
import 'api_mode.dart';
import 'api_release_policy.dart';

/// Compile-time API mode validation for local developer testing (console only).
class ApiDeveloperConfig {
  ApiDeveloperConfig._();

  /// Active football data mode after release safety rules.
  static ApiMode get apiMode => ApiReleasePolicy.effectiveMode;

  static bool get isMockDefault => ApiConstants.isExplicitMock;

  /// True when remote HTTP can run (credentials present).
  static bool get remoteActive => ApiReleasePolicy.usesRemoteApi;

  /// Human-readable label for logs: `mock`, `directApi`, `backendProxy`.
  static String get dataSourceLabel {
    final mode = apiMode;
    if (mode == ApiMode.mock) return 'mock';
    if (mode == ApiMode.directApi) return 'directApi';
    if (mode == ApiMode.backendProxy) return 'backendProxy';
    return 'mock';
  }

  /// Friendly console warnings when dart-define mode lacks credentials (no crash).
  static List<String> get configurationWarnings {
    final warnings = <String>[];
    if (ApiConstants.isDirectApi && !ApiConstants.hasApiKey) {
      warnings.add(
        'directApi mode requested but KICKORA_API_KEY is missing. '
        'Using backend proxy — app will not crash. '
        'Run: flutter run --dart-define=KICKORA_API_MODE=direct '
        '--dart-define=KICKORA_API_KEY=YOUR_KEY',
      );
    }
    return warnings;
  }
}
