import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'firebase_features.dart';

/// Firebase bootstrap — Analytics and Crashlytics activate only after a successful init.
class FirebaseService {
  FirebaseService._();

  static bool _initializeAttempted = false;
  static bool _isInitialized = false;

  /// True after a successful [Firebase.initializeApp] with [DefaultFirebaseOptions].
  static bool get isInitialized => _isInitialized;

  /// Alias for guards elsewhere in the app.
  static bool get isAvailable => _isInitialized;

  /// Product SDKs (Analytics, Crashlytics) may run when core init succeeded.
  static bool get featuresEnabled => _isInitialized;

  /// Initializes Firebase once. Failures are swallowed so mock/offline MVP still runs.
  static Future<void> initialize() async {
    if (_initializeAttempted) return;
    _initializeAttempted = true;

    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        _debugLog('already initialized (${Firebase.apps.length} app(s))');
        return;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      _debugLog('core initialized with DefaultFirebaseOptions');
    } catch (e, stack) {
      _isInitialized = false;
      _debugLog('initialization failed (app continues): $e');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stack);
      }
    }
  }

  /// Debug boot summary (no secrets).
  static void logStartupStatus({required bool notificationsEnabled}) {
    if (!kDebugMode) return;
    debugPrint('[Kickora Firebase] initialized=$_isInitialized');
    debugPrint(
      '[Kickora Analytics] enabled=${FirebaseFeatures.analyticsEnabled}',
    );
    debugPrint(
      '[Kickora Crashlytics] enabled=${FirebaseFeatures.crashlyticsEnabled}',
    );
    debugPrint('[Kickora Notifications] enabled=$notificationsEnabled');
  }

  static void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[Kickora Firebase] $message');
    }
  }
}
