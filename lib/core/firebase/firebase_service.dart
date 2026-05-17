import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase bootstrap only — auth, messaging, analytics, and Crashlytics stay off
/// until explicitly enabled after `flutterfire configure`.
class FirebaseService {
  FirebaseService._();

  static bool _initializeAttempted = false;
  static bool _isInitialized = false;

  /// True after a successful [Firebase.initializeApp] (requires platform config).
  static bool get isInitialized => _isInitialized;

  /// Alias for guards elsewhere in the app.
  static bool get isAvailable => _isInitialized;

  /// Product features must check this before using Firebase SDKs.
  static const bool featuresEnabled = false;

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

      await Firebase.initializeApp();
      _isInitialized = true;
      _debugLog('core initialized (featuresEnabled=$featuresEnabled)');
    } catch (e, stack) {
      _isInitialized = false;
      _debugLog('initialization skipped: $e');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stack);
      }
    }
  }

  static void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[Kickora Firebase] $message');
    }
  }
}
