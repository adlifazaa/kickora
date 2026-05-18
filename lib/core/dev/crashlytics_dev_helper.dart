import 'package:flutter/foundation.dart';

import '../firebase/crashlytics_service.dart';

/// Debug-only non-fatal crash test (not exposed in production UI).
class CrashlyticsDevHelper {
  CrashlyticsDevHelper._();

  static Future<void> recordTestError() async {
    if (!kDebugMode) return;
    await CrashlyticsService.instance.recordError(
      Exception('Kickora debug crashlytics test'),
      StackTrace.current,
      reason: 'dev_test',
    );
  }
}
