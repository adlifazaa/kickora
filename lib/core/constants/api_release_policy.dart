import 'package:flutter/foundation.dart';

import 'api_constants.dart';
import 'api_mode.dart';

/// Release vs development API behavior (compile-time dart-define + [kReleaseMode]).
class ApiReleasePolicy {
  ApiReleasePolicy._();

  /// True for `flutter build --release` / profile release binaries.
  static bool get isReleaseBuild => kReleaseMode;

  /// Development builds may use directApi with a personal API key.
  static bool get allowsDirectApi => !isReleaseBuild;

  /// Production Play Store builds should use backend proxy + URL.
  static bool get prefersBackendProxy => isReleaseBuild;

  /// Effective mode used by data layer after release safety rules.
  static ApiMode get effectiveMode {
    if (ApiConstants.isMock) return ApiMode.mock;
    if (ApiConstants.isBackendProxy && ApiConstants.hasBackendUrl) {
      return ApiMode.backendProxy;
    }
    if (ApiConstants.isDirectApi) {
      if (allowsDirectApi && ApiConstants.hasApiKey) {
        return ApiMode.directApi;
      }
      return ApiMode.mock;
    }
    if (ApiConstants.isBackendProxy && !ApiConstants.hasBackendUrl) {
      return ApiMode.mock;
    }
    return ApiMode.mock;
  }

  static bool get usesRemoteApi =>
      effectiveMode != ApiMode.mock &&
      (effectiveMode == ApiMode.backendProxy
          ? ApiConstants.hasBackendUrl
          : ApiConstants.hasApiKey);

  /// Debug-only warnings for misconfigured release builds (never crashes).
  static List<String> releaseWarnings() {
    if (!isReleaseBuild) return const [];
    final warnings = <String>[];
    if (ApiConstants.isDirectApi) {
      warnings.add(
        'RELEASE: KICKORA_API_MODE=direct is for development only. '
        'Ship with KICKORA_API_MODE=backend and KICKORA_BACKEND_URL.',
      );
    }
    if (ApiConstants.isBackendProxy && !ApiConstants.hasBackendUrl) {
      warnings.add(
        'RELEASE: backendProxy without KICKORA_BACKEND_URL — falling back to mock data.',
      );
    }
    return warnings;
  }
}
