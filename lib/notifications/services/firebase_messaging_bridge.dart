import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../fcm_message_parser.dart';
import '../models/firebase_notification_payload.dart';
import '../models/notification_type.dart';
import '../notification_debug_log.dart';
import 'firebase_notification_bridge.dart';

/// Live Firebase Cloud Messaging bridge.
class FirebaseMessagingBridge implements FirebaseNotificationBridge {
  FirebaseMessagingBridge({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  final _foreground =
      StreamController<FirebaseNotificationPayload>.broadcast();
  final _opened = StreamController<FirebaseNotificationPayload>.broadcast();

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;

  @override
  bool get isAvailable => true;

  @override
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('[Kickora Notifications] Firebase bridge → messaging');
    }

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedMessage);
  }

  void _onForegroundMessage(RemoteMessage message) {
    final payload = FcmMessageParser.parse(message);
    NotificationDebugLog.received(
      type: payload.type.wireValue,
      deliveryPhase: 'foreground',
      topic: payload.topic,
      matchId: payload.matchId,
      teamId: payload.teamId,
      competitionId: payload.competitionId,
    );
    _foreground.add(payload);
  }

  void _onOpenedMessage(RemoteMessage message) {
    final payload = FcmMessageParser.parse(message);
    NotificationDebugLog.received(
      type: payload.type.wireValue,
      deliveryPhase: 'opened',
      topic: payload.topic,
      matchId: payload.matchId,
      teamId: payload.teamId,
      competitionId: payload.competitionId,
      openedApp: true,
    );
    _opened.add(payload);
  }

  @override
  Future<String?> getDeviceToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  @override
  Stream<FirebaseNotificationPayload> get onForegroundMessage =>
      _foreground.stream;

  @override
  Stream<FirebaseNotificationPayload> get onMessageOpenedApp => _opened.stream;

  /// Cold-start notification that opened the app.
  Future<FirebaseNotificationPayload?> getInitialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();
      if (message == null) return null;
      return FcmMessageParser.parse(message);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onOpenedSub?.cancel();
    _foreground.close();
    _opened.close();
  }
}
