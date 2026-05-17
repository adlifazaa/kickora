import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/firebase_notification_payload.dart';
import 'models/notification_permission_status.dart';
import 'models/notification_type.dart';
import 'notification_channels.dart';
import 'notification_debug_log.dart';
import 'services/notification_permission_handler.dart';
import 'services/notification_service.dart';

/// Coordinates FCM topics, permission, and message routing (foundation only).
///
/// Does not request OS permission on [initialize] — call [enable] when the user
/// turns notifications on in settings.
class NotificationManager {
  NotificationManager({
    required NotificationService notificationService,
    required NotificationPermissionHandler permissionHandler,
    required SharedPreferences preferences,
  })  : _fcm = notificationService,
        _permission = permissionHandler,
        _prefs = preferences;

  final NotificationService _fcm;
  final NotificationPermissionHandler _permission;
  final SharedPreferences _prefs;

  static const String enabledPreferenceKey = 'notifications_enabled';
  static const String _subscribedTeamsKey = 'fcm_subscribed_team_ids';
  static const String _subscribedMatchesKey = 'fcm_subscribed_match_ids';
  static const String _subscribedCompetitionsKey =
      'fcm_subscribed_competition_ids';

  StreamSubscription<FirebaseNotificationPayload>? _foregroundSub;
  StreamSubscription<FirebaseNotificationPayload>? _openedSub;
  bool _initialized = false;

  final _foregroundController =
      StreamController<FirebaseNotificationPayload>.broadcast();
  final _openedController =
      StreamController<FirebaseNotificationPayload>.broadcast();

  Stream<FirebaseNotificationPayload> get onForegroundMessage =>
      _foregroundController.stream;

  Stream<FirebaseNotificationPayload> get onMessageOpenedApp =>
      _openedController.stream;

  bool get isEnabled => _prefs.getBool(enabledPreferenceKey) ?? false;

  bool get usesMockFirebase => !_fcm.isFirebaseAvailable;

  int get subscribedTopicCount =>
      _readIdSet(_subscribedTeamsKey).length +
      _readIdSet(_subscribedMatchesKey).length +
      _readIdSet(_subscribedCompetitionsKey).length;

  Future<void> initialize() async {
    if (_initialized) return;
    await _fcm.initialize();
    _foregroundSub = _fcm.onForegroundMessage.listen(_onForeground);
    _openedSub = _fcm.onMessageOpenedApp.listen(_onOpened);
    _initialized = true;
    NotificationDebugLog.initialized(
      firebaseAvailable: _fcm.isFirebaseAvailable,
      enabled: isEnabled,
    );
    await _logStatus();
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _foregroundController.close();
    await _openedController.close();
  }

  Future<NotificationPermissionStatus> permissionStatus() =>
      _permission.getStatus();

  /// Requests permission and enables push — only when user opts in (no auto popup).
  Future<bool> enable({
    Set<int> favoriteTeamIds = const {},
    Set<int> favoriteMatchIds = const {},
    Set<int> favoriteCompetitionIds = const {},
  }) async {
    final status = await _permission.request();
    NotificationDebugLog.permissionRequested(status.name);
    if (status != NotificationPermissionStatus.granted &&
        status != NotificationPermissionStatus.provisional) {
      await _prefs.setBool(enabledPreferenceKey, false);
      await _logStatus();
      return false;
    }

    await _prefs.setBool(enabledPreferenceKey, true);
    await syncFavoriteTeams(favoriteTeamIds);
    await syncFavoriteMatches(favoriteMatchIds);
    await syncFavoriteCompetitions(favoriteCompetitionIds);
    await _fcm.getDeviceToken();
    await _logStatus();
    return true;
  }

  Future<void> disable() async {
    await _prefs.setBool(enabledPreferenceKey, false);
    await _logStatus();
  }

  Future<void> syncFavoriteTeams(Set<int> teamIds) async {
    if (!isEnabled) return;
    await _syncTopicSet(
      preferenceKey: _subscribedTeamsKey,
      desiredIds: teamIds,
      topicFor: NotificationTopics.team,
    );
  }

  Future<void> syncFavoriteMatches(Set<int> matchIds) async {
    if (!isEnabled) return;
    await _syncTopicSet(
      preferenceKey: _subscribedMatchesKey,
      desiredIds: matchIds,
      topicFor: NotificationTopics.match,
    );
  }

  Future<void> syncFavoriteCompetitions(Set<int> competitionIds) async {
    if (!isEnabled) return;
    await _syncTopicSet(
      preferenceKey: _subscribedCompetitionsKey,
      desiredIds: competitionIds,
      topicFor: NotificationTopics.competition,
    );
  }

  Future<void> _syncTopicSet({
    required String preferenceKey,
    required Set<int> desiredIds,
    required String Function(int id) topicFor,
  }) async {
    final previous = _readIdSet(preferenceKey);
    for (final id in previous.difference(desiredIds)) {
      await _fcm.unsubscribeFromTopic(topicFor(id));
    }
    for (final id in desiredIds.difference(previous)) {
      await _fcm.subscribeToTopic(topicFor(id));
    }
    await _prefs.setStringList(
      preferenceKey,
      desiredIds.map((e) => '$e').toList(),
    );
    await _logStatus();
  }

  void _onForeground(FirebaseNotificationPayload payload) {
    if (!isEnabled) return;
    NotificationDebugLog.received(
      type: payload.type.wireValue,
      matchId: payload.matchId,
      teamId: payload.teamId,
      competitionId: payload.competitionId,
    );
    _foregroundController.add(payload);
  }

  void _onOpened(FirebaseNotificationPayload payload) {
    NotificationDebugLog.received(
      type: payload.type.wireValue,
      matchId: payload.matchId,
      teamId: payload.teamId,
      competitionId: payload.competitionId,
      openedApp: true,
    );
    _openedController.add(payload);
  }

  Future<void> _logStatus() async {
    final permission = (await permissionStatus()).name;
    NotificationDebugLog.status(
      enabled: isEnabled,
      permission: permission,
      subscribedTopics: subscribedTopicCount,
    );
  }

  Set<int> _readIdSet(String key) {
    final raw = _prefs.getStringList(key) ?? <String>[];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }
}
