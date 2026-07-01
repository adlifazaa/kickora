import 'package:shared_preferences/shared_preferences.dart';

/// Hidden developer tools (notification diagnostics, etc.).
class DeveloperMode {
  DeveloperMode._();

  static const String prefsKey = 'kickora_developer_mode_enabled';

  /// Only visible after explicit unlock — never shown by default in debug or release.
  static bool showNotificationDiagnostics(SharedPreferences prefs) {
    return prefs.getBool(prefsKey) ?? false;
  }

  static Future<void> enable(SharedPreferences prefs) async {
    await prefs.setBool(prefsKey, true);
  }
}
