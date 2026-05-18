import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_permission_status.dart';
import 'notification_permission_handler.dart';

/// OS notification permission via Firebase Messaging (no token logging).
class FcmPermissionHandler implements NotificationPermissionHandler {
  FcmPermissionHandler(
    this._prefs, {
    FirebaseMessaging? messaging,
  }) : _messaging = messaging ?? FirebaseMessaging.instance;

  final SharedPreferences _prefs;
  final FirebaseMessaging _messaging;

  static const String _grantedKey = 'notification_permission_granted';

  @override
  Future<NotificationPermissionStatus> getStatus() async {
    if (_prefs.getBool(_grantedKey) == true) {
      return NotificationPermissionStatus.granted;
    }
    try {
      final settings = await _messaging.getNotificationSettings();
      return _mapAuthorization(settings.authorizationStatus);
    } catch (_) {
      return NotificationPermissionStatus.notDetermined;
    }
  }

  @override
  Future<NotificationPermissionStatus> request() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final status = _mapAuthorization(settings.authorizationStatus);
      if (status == NotificationPermissionStatus.granted ||
          status == NotificationPermissionStatus.provisional) {
        await _prefs.setBool(_grantedKey, true);
      }
      return status;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Kickora Notifications] permission request failed: $e');
      }
      return NotificationPermissionStatus.denied;
    }
  }

  @override
  Future<bool> openAppSettings() async => false;

  NotificationPermissionStatus _mapAuthorization(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return NotificationPermissionStatus.granted;
      case AuthorizationStatus.provisional:
        return NotificationPermissionStatus.provisional;
      case AuthorizationStatus.denied:
        return NotificationPermissionStatus.denied;
      case AuthorizationStatus.notDetermined:
        return NotificationPermissionStatus.notDetermined;
    }
  }
}
