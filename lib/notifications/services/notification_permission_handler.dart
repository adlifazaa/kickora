import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_permission_status.dart';

/// Requests and tracks notification permission (mock until OS plugins are added).
abstract class NotificationPermissionHandler {
  Future<NotificationPermissionStatus> getStatus();

  Future<NotificationPermissionStatus> request();

  Future<bool> openAppSettings();
}

/// Simulates permission: granted after user enables notifications in settings.
class MockNotificationPermissionHandler implements NotificationPermissionHandler {
  MockNotificationPermissionHandler(this._prefs);

  final SharedPreferences _prefs;
  static const String _grantedKey = 'notification_permission_granted';

  @override
  Future<NotificationPermissionStatus> getStatus() async {
    if (_prefs.getBool(_grantedKey) == true) {
      return NotificationPermissionStatus.granted;
    }
    return NotificationPermissionStatus.notDetermined;
  }

  @override
  Future<NotificationPermissionStatus> request() async {
    await _prefs.setBool(_grantedKey, true);
    return NotificationPermissionStatus.granted;
  }

  @override
  Future<bool> openAppSettings() async => false;
}
