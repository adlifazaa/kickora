import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/firebase_notification_payload.dart';
import '../models/kickora_notification.dart';
import '../models/notification_permission_status.dart';
import '../models/notification_type.dart';
import '../notification_manager.dart';
import 'firebase_notification_bridge.dart';
import 'local_notification_helper.dart';
import 'notification_permission_handler.dart';
import 'notification_service.dart';

/// App-facing notifications API (mock-safe; FCM foundation via [NotificationManager]).
class KickoraNotificationService {
  KickoraNotificationService({
    required NotificationManager manager,
    required LocalNotificationHelper localHelper,
    FirebaseNotificationBridge? firebaseBridge,
  })  : _manager = manager,
        _local = localHelper,
        _firebaseBridge = firebaseBridge;

  factory KickoraNotificationService.createMock(SharedPreferences prefs) {
    final bridge = MockFirebaseNotificationBridge();
    final fcm = NotificationService(bridge);
    final manager = NotificationManager(
      notificationService: fcm,
      permissionHandler: MockNotificationPermissionHandler(prefs),
      preferences: prefs,
    );
    return KickoraNotificationService(
      manager: manager,
      localHelper: MockLocalNotificationHelper(),
      firebaseBridge: bridge,
    );
  }

  final NotificationManager _manager;
  final LocalNotificationHelper _local;
  final FirebaseNotificationBridge? _firebaseBridge;

  StreamSubscription<FirebaseNotificationPayload>? _foregroundSub;
  bool _initialized = false;

  static const String enabledPreferenceKey =
      NotificationManager.enabledPreferenceKey;

  bool get isEnabled => _manager.isEnabled;

  bool get usesMockFirebase => _manager.usesMockFirebase;

  MockFirebaseNotificationBridge? get mockFirebase =>
      _firebaseBridge is MockFirebaseNotificationBridge
          ? _firebaseBridge
          : null;

  MockLocalNotificationHelper? get mockLocal =>
      _local is MockLocalNotificationHelper ? _local : null;

  Future<void> initialize() async {
    if (_initialized) return;
    await _local.initialize();
    await _manager.initialize();
    _foregroundSub = _manager.onForegroundMessage.listen(_onForegroundFcm);
    _manager.onMessageOpenedApp.listen(_onOpenedFcm);
    _initialized = true;
    if (kDebugMode) {
      debugPrint(
        '[Kickora Notifications] service ready (mock=$usesMockFirebase '
        'enabled=$isEnabled)',
      );
    }
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _manager.dispose();
    if (_firebaseBridge is MockFirebaseNotificationBridge) {
      _firebaseBridge.dispose();
    }
  }

  Future<NotificationPermissionStatus> permissionStatus() =>
      _manager.permissionStatus();

  Future<bool> enable({
    Set<int> favoriteTeamIds = const {},
    Set<int> favoriteMatchIds = const {},
    Set<int> favoriteCompetitionIds = const {},
  }) =>
      _manager.enable(
        favoriteTeamIds: favoriteTeamIds,
        favoriteMatchIds: favoriteMatchIds,
        favoriteCompetitionIds: favoriteCompetitionIds,
      );

  Future<void> disable() async {
    await _manager.disable();
    await _local.cancelAll();
  }

  Future<int> restoreFavoriteTopics({
    required Set<int> teamIds,
    required Set<int> matchIds,
    required Set<int> competitionIds,
  }) =>
      _manager.restoreFavoriteTopics(
        teamIds: teamIds,
        matchIds: matchIds,
        competitionIds: competitionIds,
      );

  Future<void> syncFavoriteTeams(Set<int> teamIds) =>
      _manager.syncFavoriteTeams(teamIds);

  Future<void> syncFavoriteMatches(Set<int> matchIds) =>
      _manager.syncFavoriteMatches(matchIds);

  Future<void> syncFavoriteCompetitions(Set<int> competitionIds) =>
      _manager.syncFavoriteCompetitions(competitionIds);

  Future<void> subscribeFavoriteTeam(int teamId) =>
      _manager.subscribeFavoriteTeam(teamId);

  Future<void> unsubscribeFavoriteTeam(int teamId) =>
      _manager.unsubscribeFavoriteTeam(teamId);

  Future<void> subscribeFavoriteMatch(int matchId) =>
      _manager.subscribeFavoriteMatch(matchId);

  Future<void> unsubscribeFavoriteMatch(int matchId) =>
      _manager.unsubscribeFavoriteMatch(matchId);

  Future<void> subscribeFavoriteCompetition(int competitionId) =>
      _manager.subscribeFavoriteCompetition(competitionId);

  Future<void> unsubscribeFavoriteCompetition(int competitionId) =>
      _manager.unsubscribeFavoriteCompetition(competitionId);

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
          type: NotificationType.matchStarted,
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
          type: NotificationType.goalScored,
          matchId: matchId,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          score: score,
          minute: minute,
          body: isArabic ? 'هدف — $scorer' : 'Goal — $scorer',
        ),
        isArabic: isArabic,
      );

  Future<void> notifyRedCard({
    required int matchId,
    required String playerName,
    required String homeTeam,
    required String awayTeam,
    String? minute,
    bool isArabic = false,
  }) =>
      _dispatch(
        FirebaseNotificationPayload(
          type: NotificationType.redCard,
          matchId: matchId,
          homeTeam: homeTeam,
          awayTeam: awayTeam,
          minute: minute,
          body: isArabic ? 'بطاقة حمراء — $playerName' : 'Red card — $playerName',
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
      notifyMatchFinished(
        matchId: matchId,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        score: score,
        isArabic: isArabic,
      );

  Future<void> notifyMatchFinished({
    required int matchId,
    required String homeTeam,
    required String awayTeam,
    required String score,
    bool isArabic = false,
  }) =>
      _dispatch(
        FirebaseNotificationPayload(
          type: NotificationType.matchFinished,
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
          type: NotificationType.favoriteTeamUpdate,
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
