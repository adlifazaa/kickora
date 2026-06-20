import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hidden developer tools (notification diagnostics, etc.).
class DeveloperMode {
  DeveloperMode._();

  static const String prefsKey = 'kickora_developer_mode_enabled';

  /// Debug builds always see diagnostics; release requires unlock.
  static bool showNotificationDiagnostics(SharedPreferences prefs) {
    if (kDebugMode) return true;
    return prefs.getBool(prefsKey) ?? false;
  }

  static Future<void> enable(SharedPreferences prefs) async {
    await prefs.setBool(prefsKey, true);
  }
}
