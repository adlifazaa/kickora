import 'firebase_service.dart';

/// Product feature gates for Firebase SDKs (off until configured + enabled).
class FirebaseFeatures {
  FirebaseFeatures._();

  /// Master switch — set `true` only after `flutterfire configure` + store config.
  static const bool productEnabled = FirebaseService.featuresEnabled;

  /// Firebase core initialized with valid platform options.
  static bool get isConfigured => FirebaseService.isInitialized;

  static bool get analyticsEnabled => isConfigured && productEnabled;

  static bool get crashlyticsEnabled => isConfigured && productEnabled;
}
