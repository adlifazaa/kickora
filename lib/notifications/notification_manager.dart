import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/firebase_notification_payload.dart';
import 'models/notification_permission_status.dart';
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

  Set<int> get subscribedTeamIds => _readIdSet(_subscribedTeamsKey);
  Set<int> get subscribedMatchIds => _readIdSet(_subscribedMatchesKey);
  Set<int> get subscribedCompetitionIds =>
      _readIdSet(_subscribedCompetitionsKey);

  List<String> get subscribedTopicNames {
    final topics = <String>[
      for (final id in subscribedTeamIds) NotificationTopics.team(id),
      for (final id in subscribedMatchIds) NotificationTopics.match(id),
      for (final id in subscribedCompetitionIds)
        NotificationTopics.competition(id),
    ]..sort();
    return topics;
  }

  Future<bool> hasFcmTokenAvailable() async {
    final token = await _fcm.getDeviceToken();
    return token != null && token.isNotEmpty;
  }

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
    await unsubscribeAllFavoriteTopics();
    await _prefs.setBool(enabledPreferenceKey, false);
    await _logStatus();
  }

  /// Re-subscribes all favorite topics after restart when notifications are on.
  Future<int> restoreFavoriteTopics({
    required Set<int> teamIds,
    required Set<int> matchIds,
    required Set<int> competitionIds,
    bool subscribeTeams = true,
    bool subscribeMatches = true,
    bool subscribeCompetitions = true,
  }) async {
    if (!isEnabled) return 0;
    await syncFavoriteTeams(subscribeTeams ? teamIds : const {});
    await syncFavoriteMatches(subscribeMatches ? matchIds : const {});
    await syncFavoriteCompetitions(
      subscribeCompetitions ? competitionIds : const {},
    );
    final count = subscribedTopicCount;
    NotificationDebugLog.topicsRestored(count);
    return count;
  }

  Future<void> unsubscribeAllFavoriteTopics() async {
    await _syncTopicSet(
      preferenceKey: _subscribedTeamsKey,
      desiredIds: const {},
      topicFor: NotificationTopics.team,
      requireEnabled: false,
    );
    await _syncTopicSet(
      preferenceKey: _subscribedMatchesKey,
      desiredIds: const {},
      topicFor: NotificationTopics.match,
      requireEnabled: false,
    );
    await _syncTopicSet(
      preferenceKey: _subscribedCompetitionsKey,
      desiredIds: const {},
      topicFor: NotificationTopics.competition,
      requireEnabled: false,
    );
  }

  Future<void> subscribeFavoriteTeam(int teamId) async {
    if (!isEnabled) return;
    await _subscribeOne(
      preferenceKey: _subscribedTeamsKey,
      id: teamId,
      topicFor: NotificationTopics.team,
    );
  }

  Future<void> unsubscribeFavoriteTeam(int teamId) async {
    await _unsubscribeOne(
      preferenceKey: _subscribedTeamsKey,
      id: teamId,
      topicFor: NotificationTopics.team,
    );
  }

  Future<void> subscribeFavoriteMatch(int matchId) async {
    if (!isEnabled) return;
    await _subscribeOne(
      preferenceKey: _subscribedMatchesKey,
      id: matchId,
      topicFor: NotificationTopics.match,
    );
  }

  Future<void> unsubscribeFavoriteMatch(int matchId) async {
    await _unsubscribeOne(
      preferenceKey: _subscribedMatchesKey,
      id: matchId,
      topicFor: NotificationTopics.match,
    );
  }

  Future<void> subscribeFavoriteCompetition(int competitionId) async {
    if (!isEnabled) return;
    await _subscribeOne(
      preferenceKey: _subscribedCompetitionsKey,
      id: competitionId,
      topicFor: NotificationTopics.competition,
    );
  }

  Future<void> unsubscribeFavoriteCompetition(int competitionId) async {
    await _unsubscribeOne(
      preferenceKey: _subscribedCompetitionsKey,
      id: competitionId,
      topicFor: NotificationTopics.competition,
    );
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

  Future<void> _subscribeOne({
    required String preferenceKey,
    required int id,
    required String Function(int id) topicFor,
  }) async {
    final previous = _readIdSet(preferenceKey);
    if (previous.contains(id)) return;
    await _fcm.subscribeToTopic(topicFor(id));
    previous.add(id);
    await _prefs.setStringList(
      preferenceKey,
      previous.map((e) => '$e').toList(),
    );
    await _logStatus();
  }

  Future<void> _unsubscribeOne({
    required String preferenceKey,
    required int id,
    required String Function(int id) topicFor,
  }) async {
    final previous = _readIdSet(preferenceKey);
    if (!previous.remove(id)) return;
    await _fcm.unsubscribeFromTopic(topicFor(id));
    await _prefs.setStringList(
      preferenceKey,
      previous.map((e) => '$e').toList(),
    );
    await _logStatus();
  }

  Future<void> _syncTopicSet({
    required String preferenceKey,
    required Set<int> desiredIds,
    required String Function(int id) topicFor,
    bool requireEnabled = true,
  }) async {
    if (requireEnabled && !isEnabled) return;
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
    _foregroundController.add(payload);
  }

  void _onOpened(FirebaseNotificationPayload payload) {
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
