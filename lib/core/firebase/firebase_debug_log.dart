import 'package:flutter/foundation.dart';

/// Debug-only Firebase product logs (no PII, tokens, or secrets).
class FirebaseDebugLog {
  FirebaseDebugLog._();

  static void analytics({required bool enabled, String? message}) {
    if (!kDebugMode) return;
    final extra = message != null ? ' $message' : '';
    debugPrint('[Kickora Analytics] ${enabled ? 'enabled' : 'disabled'}$extra');
  }

  static void crashlytics({required bool enabled, String? message}) {
    if (!kDebugMode) return;
    final extra = message != null ? ' $message' : '';
    debugPrint(
      '[Kickora Crashlytics] ${enabled ? 'enabled' : 'disabled'}$extra',
    );
  }

  static void analyticsEvent(String name) {
    if (!kDebugMode) return;
    debugPrint('[Kickora Analytics] event → $name');
  }
}
