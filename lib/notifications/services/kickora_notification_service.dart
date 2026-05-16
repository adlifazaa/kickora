import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/firebase_notification_payload.dart';
import '../models/kickora_notification.dart';
import '../models/notification_permission_status.dart';
import '../models/notification_type.dart';
import '../notification_channels.dart';
import 'firebase_notification_bridge.dart';
import 'local_notification_helper.dart';
import 'notification_permission_handler.dart';

/// Central notifications API for Kickora (mock-safe until Firebase/plugins are added).
class KickoraNotificationService {
  KickoraNotificationService({
    required NotificationPermissionHandler permissionHandler,
    required LocalNotificationHelper localHelper,
    required FirebaseNotificationBridge firebaseBridge,
    required SharedPreferences preferences,
  })  : _permission = permissionHandler,
        _local = localHelper,
        _firebase = firebaseBridge,
        _prefs = preferences;

  factory KickoraNotificationService.createMock(SharedPreferences prefs) {
    return KickoraNotificationService(
      permissionHandler: MockNotificationPermissionHandler(prefs),
      localHelper: MockLocalNotificationHelper(),
      firebaseBridge: MockFirebaseNotificationBridge(),
      preferences: prefs,
    );
  }

  final NotificationPermissionHandler _permission;
  final LocalNotificationHelper _local;
  final FirebaseNotificationBridge _firebase;
  final SharedPreferences _prefs;

  /// Shared with [AppController] preferences toggle.
  static const String enabledPreferenceKey = 'notifications_enabled';

  StreamSubscription<FirebaseNotificationPayload>? _foregroundSub;
  bool _initialized = false;

  bool get isEnabled => _prefs.getBool(enabledPreferenceKey) ?? false;

  bool get usesMockFirebase => !_firebase.isAvailable;

  MockFirebaseNotificationBridge? get mockFirebase =>
      _firebase is MockFirebaseNotificationBridge ? _firebase : null;

  MockLocalNotificationHelper? get mockLocal =>
      _local is MockLocalNotificationHelper ? _local : null;

  Future<void> initialize() async {
    if (_initialized) return;
    await _local.initialize();
    await _firebase.initialize();
    _foregroundSub = _firebase.onForegroundMessage.listen(_onForegroundFcm);
    _firebase.onMessageOpenedApp.listen(_onOpenedFcm);
    _initialized = true;
    if (kDebugMode) {
      debugPrint(
        '[Kickora Notifications] initialized (mock=$usesMockFirebase)',
      );
    }
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    if (_firebase is MockFirebaseNotificationBridge) {
      _firebase.dispose();
    }
  }

  Future<NotificationPermissionStatus> permissionStatus() =>
      _permission.getStatus();

  /// Enables alerts: requests permission, registers FCM topics for favorites.
  Future<bool> enable({Set<int> favoriteTeamIds = const {}}) async {
    final status = await _permission.request();
    if (status != NotificationPermissionStatus.granted &&
        status != NotificationPermissionStatus.provisional) {
      await _prefs.setBool(enabledPreferenceKey, false);
      return false;
    }

    await _prefs.setBool(enabledPreferenceKey, true);
    await syncFavoriteTeams(favoriteTeamIds);
    return true;
  }

  Future<void> disable() async {
    await _prefs.setBool(enabledPreferenceKey, false);
    await _local.cancelAll();
    if (_firebase is MockFirebaseNotificationBridge) {
      // Topics cleared on next enable sync.
    }
  }

  static const String _subscribedTeamsKey = 'fcm_subscribed_team_ids';
  static const String _subscribedMatchesKey = 'fcm_subscribed_match_ids';

  Future<void> syncFavoriteTeams(Set<int> teamIds) async {
    if (!isEnabled) return;
    await _syncTopicSet(
      preferenceKey: _subscribedTeamsKey,
      desiredIds: teamIds,
      topicFor: NotificationTopics.favoriteTeam,
    );
  }

  Future<void> syncFavoriteMatches(Set<int> matchIds) async {
    if (!isEnabled) return;
    await _syncTopicSet(
      preferenceKey: _subscribedMatchesKey,
      desiredIds: matchIds,
      topicFor: NotificationTopics.favoriteMatch,
    );
  }

  Future<void> _syncTopicSet({
    required String preferenceKey,
    required Set<int> desiredIds,
    required String Function(int id) topicFor,
  }) async {
    final previous = _readIdSet(preferenceKey);
    for (final id in previous.difference(desiredIds)) {
      await _firebase.unsubscribeFromTopic(topicFor(id));
    }
    for (final id in desiredIds.difference(previous)) {
      await _firebase.subscribeToTopic(topicFor(id));
    }
    await _prefs.setStringList(
      preferenceKey,
      desiredIds.map((e) => '$e').toList(),
    );
  }

  Set<int> _readIdSet(String key) {
    final raw = _prefs.getStringList(key) ?? <String>[];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> showLocal(KickoraNotification notification) async {
    if (!isEnabled) return;
    await _local.show(notification);
  }

  Future<void> notifyMatchStarting({
    required int matchId,
    required String homeTeam,
    required String awayTeam,
    String? kickoffLabel,
    bool isArabic = false,
  }) =>
      _dispatch(
        FirebaseNotificationPayload(
          type: NotificationType.matchStarting,
          matchId: matchId,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          minute: kickoffLabel,
        ),
        isArabic: isArabic,
      );

  Future<void> notifyGoal({
    required int matchId,
    required String scorer,
    required String homeTeam,
    required String awayTeam,
    required String score,
    String? minute,
    bool isArabic = false,
  }) =>
      _dispatch(
        FirebaseNotificationPayload(
          type: NotificationType.goal,
          matchId: matchId,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          score: score,
          minute: minute,
          body: isArabic ? 'هدف — $scorer' : 'Goal — $scorer',
        ),
        isArabic: isArabic,
      );

  Future<void> notifyHalftime({
    required int matchId,
    required String homeTeam,
    required String awayTeam,
    required String score,
    bool isArabic = false,
  }) =>
      _dispatch(
        FirebaseNotificationPayload(
          type: NotificationType.halftime,
          matchId: matchId,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          score: score,
        ),
        isArabic: isArabic,
      );

  Future<void> notifyFulltime({
    required int matchId,
    required String homeTeam,
    required String awayTeam,
    required String score,
    bool isArabic = false,
  }) =>
      _dispatch(
        FirebaseNotificationPayload(
          type: NotificationType.fulltime,
          matchId: matchId,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          score: score,
        ),
        isArabic: isArabic,
      );

  Future<void> notifyFavoriteTeamReminder({
    required int teamId,
    required int matchId,
    required String homeTeam,
    required String awayTeam,
    String? kickoffLabel,
    bool isArabic = false,
  }) =>
      _dispatch(
        FirebaseNotificationPayload(
          type: NotificationType.favoriteTeamReminder,
          teamId: teamId,
          matchId: matchId,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          minute: kickoffLabel,
        ),
        isArabic: isArabic,
      );

  Future<void> handleRemoteData(
    Map<String, dynamic> data, {
    bool isArabic = false,
    bool openedApp = false,
  }) async {
    if (!isEnabled) return;
    final payload = FirebaseNotificationPayload.fromData(data);
    if (openedApp) {
      await _onOpenedFcm(payload);
    } else {
      await _onForegroundFcm(payload);
    }
  }

  Future<void> _dispatch(
    FirebaseNotificationPayload payload, {
    bool isArabic = false,
  }) async {
    if (!isEnabled) return;
    await showLocal(payload.toKickoraNotification(isArabic: isArabic));
  }

  Future<void> _onForegroundFcm(FirebaseNotificationPayload payload) async {
    if (!isEnabled) return;
    await showLocal(payload.toKickoraNotification());
  }

  Future<void> _onOpenedFcm(FirebaseNotificationPayload payload) async {
    if (kDebugMode) {
      debugPrint(
        '[Kickora Notifications] opened → match=${payload.matchId} '
        'type=${payload.type.wireValue}',
      );
    }
  }
}
