import 'api_constants.dart';
import 'api_release_policy.dart';

/// Compile-time guidance for production vs development API modes.
class ApiProductionGuidance {
  ApiProductionGuidance._();

  static const String directApiDevOnlyWarning =
      'directApi is for development only. Use backendProxy in production.';

  static const String recommendedProductionMode =
      'Production: flutter build appbundle --release '
      '--dart-define=KICKORA_API_MODE=backend '
      '--dart-define=KICKORA_BACKEND_URL=https://your-api.example.com';

  static bool get isDirectApiDevOnly =>
      ApiConstants.isDirectApi && ApiConstants.hasApiKey;

  static bool get isRecommendedProductionMode =>
      ApiConstants.isBackendProxy && ApiConstants.hasBackendUrl;

  static List<String> bootMessages() {
    final messages = <String>[];
    if (ApiConstants.isMock) {
      messages.add(
        'Default=mock. For production builds use backendProxy (not directApi).',
      );
    }
    if (isDirectApiDevOnly) {
      messages.add(directApiDevOnlyWarning);
    }
    if (isRecommendedProductionMode) {
      messages.add('backendProxy active (recommended for production).');
    }
    messages.addAll(ApiReleasePolicy.releaseWarnings());
    return messages;
  }
}
