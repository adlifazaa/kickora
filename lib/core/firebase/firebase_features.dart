import 'firebase_service.dart';

/// Product feature gates for Firebase SDKs (active only when core init succeeded).
class FirebaseFeatures {
  FirebaseFeatures._();

  /// Firebase core initialized with [DefaultFirebaseOptions].
  static bool get isConfigured => FirebaseService.isInitialized;

  static bool get analyticsEnabled => isConfigured;

  static bool get crashlyticsEnabled => isConfigured;
}
