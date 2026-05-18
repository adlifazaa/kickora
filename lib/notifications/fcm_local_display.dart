import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firebase/firebase_service.dart';
import 'models/firebase_notification_payload.dart';
import 'models/kickora_notification.dart';
import 'models/notification_type.dart';
import 'notification_channels.dart';
import 'notification_debug_log.dart';
import 'notification_manager.dart';
import 'notification_preferences.dart';
import 'services/local_notification_helper.dart';

/// Shared local notification display for foreground and background FCM.
class FcmLocalDisplay {
  FcmLocalDisplay._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
    await _createAndroidChannels();
    _initialized = true;
  }

  static Future<void> showKickora(KickoraNotification notification) async {
    await ensureInitialized();
    await _showKickoraNotification(notification);
  }

  static Future<void> showFromPayload(
    FirebaseNotificationPayload payload, {
    required String deliveryPhase,
    bool requireUserEnabled = true,
  }) async {
    if (requireUserEnabled) {
      final enabled = await _notificationsEnabled();
      if (!enabled) return;
      final prefs = await SharedPreferences.getInstance();
      final settings = NotificationPreferences(prefs);
      if (!settings.isMatchTypeEnabled(payload.type)) return;
    }

    await ensureInitialized();
    final notification = payload.toKickoraNotification();
    await _showKickoraNotification(notification);

    NotificationDebugLog.received(
      type: payload.type.wireValue,
      deliveryPhase: deliveryPhase,
      topic: payload.topic,
      matchId: payload.matchId,
      teamId: payload.teamId,
      competitionId: payload.competitionId,
    );
  }

  static Future<bool> _notificationsEnabled() async {
    try {
      if (!FirebaseService.isInitialized) return false;
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(NotificationManager.enabledPreferenceKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _showKickoraNotification(KickoraNotification notification) async {
    final channelId = NotificationChannels.forType(notification.type.wireValue);
    final android = AndroidNotificationDetails(
      channelId,
      channelId,
      channelDescription: 'Kickora match alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);

    final id = notification.id.hashCode & 0x7fffffff;
    await _plugin.show(
      id,
      notification.title,
      notification.body,
      details,
      payload: notification.matchId?.toString(),
    );

    if (kDebugMode) {
      debugPrint(
        '[Kickora Notifications] local → channel=$channelId '
        'title=${notification.title}',
      );
    }
  }

  static Future<void> cancel(String id) async {
    await _plugin.cancel(id.hashCode & 0x7fffffff);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> _createAndroidChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    const channels = [
      AndroidNotificationChannel(
        NotificationChannels.matchAlerts,
        'Match alerts',
        description: 'Live match updates',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannels.goals,
        'Goals',
        description: 'Goal scored alerts',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        NotificationChannels.favorites,
        'Favorites',
        description: 'Favorite team and match updates',
        importance: Importance.high,
      ),
    ];

    for (final channel in channels) {
      await android.createNotificationChannel(channel);
    }
  }
}

/// Foreground/local helper backed by [flutter_local_notifications].
class FlutterLocalNotificationsHelper implements LocalNotificationHelper {
  @override
  Future<void> initialize() async {
    await FcmLocalDisplay.ensureInitialized();
  }

  @override
  Future<void> show(KickoraNotification notification) async {
    await FcmLocalDisplay.showKickora(notification);
  }

  @override
  Future<void> cancel(String id) async {
    await FcmLocalDisplay.cancel(id);
  }

  @override
  Future<void> cancelAll() async {
    await FcmLocalDisplay.cancelAll();
  }
}
