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
  ///
  /// Release builds always use [ApiMode.backendProxy] — never mock or directApi.
  /// Development: mock only when explicitly requested; otherwise backend proxy.
  static ApiMode get effectiveMode {
    if (isReleaseBuild) {
      return ApiMode.backendProxy;
    }

    if (ApiConstants.isMock) {
      return ApiMode.mock;
    }

    if (ApiConstants.isDirectApi) {
      if (allowsDirectApi && ApiConstants.hasApiKey) {
        return ApiMode.directApi;
      }
      return ApiMode.backendProxy;
    }

    return ApiMode.backendProxy;
  }

  static bool get usesRemoteApi {
    switch (effectiveMode) {
      case ApiMode.mock:
        return false;
      case ApiMode.backendProxy:
        return ApiConstants.hasBackendUrl;
      case ApiMode.directApi:
        return ApiConstants.hasApiKey;
    }
  }

  /// Debug-only warnings for misconfigured release builds (never crashes).
  static List<String> releaseWarnings() {
    if (!isReleaseBuild) return const [];
    final warnings = <String>[];
    if (ApiConstants.isDirectApi) {
      warnings.add(
        'RELEASE: KICKORA_API_MODE=direct is ignored in production. '
        'Release builds always use backendProxy.',
      );
    }
    if (ApiConstants.isMock) {
      warnings.add(
        'RELEASE: KICKORA_API_MODE=mock is ignored in production. '
        'Release builds always use backendProxy.',
      );
    }
    return warnings;
  }
}
