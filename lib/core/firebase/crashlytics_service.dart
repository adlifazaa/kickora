import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'firebase_debug_log.dart';
import 'firebase_features.dart';

/// Safe Firebase Crashlytics facade (no-op until [FirebaseFeatures.crashlyticsEnabled]).
class CrashlyticsService {
  CrashlyticsService._();

  static final CrashlyticsService instance = CrashlyticsService._();

  bool _initialized = false;
  bool _handlersInstalled = false;

  bool get isEnabled => FirebaseFeatures.crashlyticsEnabled;

  /// Installs error handlers only when Crashlytics is configured and enabled.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!isEnabled) {
      FirebaseDebugLog.crashlytics(enabled: false);
      return;
    }

    try {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(true);
      _installFlutterErrorHandlers(crashlytics);
      FirebaseDebugLog.crashlytics(enabled: true);
    } catch (e) {
      FirebaseDebugLog.crashlytics(enabled: false, message: 'init skipped');
      if (kDebugMode) {
        debugPrint('[Kickora Crashlytics] init error (swallowed): $e');
      }
    }
  }

  void _installFlutterErrorHandlers(FirebaseCrashlytics crashlytics) {
    if (_handlersInstalled) return;
    _handlersInstalled = true;

    final previousFlutterOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      previousFlutterOnError?.call(details);
      try {
        crashlytics.recordFlutterFatalError(details);
      } catch (_) {
        // Never break the default error path.
      }
    };

    final previousPlatformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      try {
        crashlytics.recordError(error, stack, fatal: true);
      } catch (_) {
        // Swallow — reporting must not crash the app.
      }
      if (previousPlatformOnError != null) {
        return previousPlatformOnError(error, stack);
      }
      return true;
    };
  }

  /// Records a non-fatal error when Crashlytics is active.
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) async {
    if (!isEnabled) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
        fatal: false,
      );
    } catch (_) {
      // No-op
    }
  }
}
