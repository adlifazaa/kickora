import 'api_constants.dart';
import 'api_mode_service.dart';
import 'api_release_policy.dart';

/// Compile-time guidance for production vs development API modes.
class ApiProductionGuidance {
  ApiProductionGuidance._();

  static const String directApiDevOnlyWarning =
      'directApi is for development only. Use backendProxy in production.';

  static const String recommendedProductionMode =
      'Production: flutter build appbundle --release (backend proxy is the default).';

  static bool get isDirectApiDevOnly =>
      ApiConstants.isDirectApi && ApiConstants.hasApiKey;

  static bool get isRecommendedProductionMode =>
      ApiModeService.isBackendProxy && ApiConstants.hasBackendUrl;

  static List<String> bootMessages() {
    final messages = <String>[];
    if (ApiConstants.isExplicitMock) {
      messages.add(
        'Explicit mock mode — use only for local UI/testing. '
        'Production builds always use backendProxy.',
      );
    }
    if (isDirectApiDevOnly) {
      messages.add(directApiDevOnlyWarning);
    }
    if (isRecommendedProductionMode) {
      messages.add('backendProxy active (production default).');
    }
    messages.addAll(ApiReleasePolicy.releaseWarnings());
    return messages;
  }
}
