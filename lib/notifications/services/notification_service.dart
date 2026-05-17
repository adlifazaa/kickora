import 'dart:async';

import '../models/firebase_notification_payload.dart';
import '../notification_debug_log.dart';
import 'firebase_notification_bridge.dart';

/// Low-level Firebase Cloud Messaging facade (mock-safe until FCM is live).
class NotificationService {
  NotificationService(this._bridge);

  final FirebaseNotificationBridge _bridge;

  bool get isFirebaseAvailable => _bridge.isAvailable;

  Stream<FirebaseNotificationPayload> get onForegroundMessage =>
      _bridge.onForegroundMessage;

  Stream<FirebaseNotificationPayload> get onMessageOpenedApp =>
      _bridge.onMessageOpenedApp;

  Future<void> initialize() async {
    await _bridge.initialize();
  }

  /// Device token for backend registration (never log the token value).
  Future<String?> getDeviceToken() => _bridge.getDeviceToken();

  Future<void> subscribeToTopic(String topic) async {
    await _bridge.subscribeToTopic(topic);
    NotificationDebugLog.topicSubscribe(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _bridge.unsubscribeFromTopic(topic);
    NotificationDebugLog.topicUnsubscribe(topic);
  }
}
