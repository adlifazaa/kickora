import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/firebase_notification_payload.dart';
import '../notification_channels.dart';

/// Firebase Cloud Messaging bridge (stub — swap for `firebase_messaging` later).
///
/// Setup checklist (not required now):
/// - Add `firebase_core` + `firebase_messaging` to pubspec
/// - Add `google-services.json` / `GoogleService-Info.plist`
/// - Call [Firebase.initializeApp] before [KickoraNotificationService.initialize]
abstract class FirebaseNotificationBridge {
  bool get isAvailable;

  Future<void> initialize();

  Future<String?> getDeviceToken();

  Future<void> subscribeToTopic(String topic);

  Future<void> unsubscribeFromTopic(String topic);

  Stream<FirebaseNotificationPayload> get onForegroundMessage;

  Stream<FirebaseNotificationPayload> get onMessageOpenedApp;
}

/// Mock FCM: no network, no Firebase project, safe for current builds.
class MockFirebaseNotificationBridge implements FirebaseNotificationBridge {
  MockFirebaseNotificationBridge();

  final _foreground = StreamController<FirebaseNotificationPayload>.broadcast();
  final _opened = StreamController<FirebaseNotificationPayload>.broadcast();
  final Set<String> _topics = {};

  @override
  bool get isAvailable => false;

  @override
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('[Kickora Notifications] Firebase bridge → mock (not configured)');
    }
  }

  @override
  Future<String?> getDeviceToken() async => 'mock-fcm-token';

  @override
  Future<void> subscribeToTopic(String topic) async {
    _topics.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    _topics.remove(topic);
  }

  /// Test helper: topics currently subscribed in mock FCM.
  Set<String> get subscribedTopics => Set.unmodifiable(_topics);

  @override
  Stream<FirebaseNotificationPayload> get onForegroundMessage =>
      _foreground.stream;

  @override
  Stream<FirebaseNotificationPayload> get onMessageOpenedApp => _opened.stream;

  /// Dev-only: simulate an incoming FCM data message.
  void simulateIncoming(Map<String, dynamic> data, {bool openedApp = false}) {
    final payload = FirebaseNotificationPayload.fromData(data);
    if (openedApp) {
      _opened.add(payload);
    } else {
      _foreground.add(payload);
    }
  }

  Future<void> subscribeFavoriteTeam(int teamId) =>
      subscribeToTopic(NotificationTopics.team(teamId));

  void dispose() {
    _foreground.close();
    _opened.close();
  }
}
