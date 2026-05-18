import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/firebase/firebase_service.dart';
import '../fcm_local_display.dart';
import '../models/firebase_notification_payload.dart';
import '../models/kickora_notification.dart';
import '../models/notification_permission_status.dart';
import '../models/notification_tap_intent.dart';
import '../models/notification_type.dart';
import '../notification_manager.dart';
import '../notification_preferences.dart';
import '../notification_debug_log.dart';
import 'fcm_permission_handler.dart';
import 'firebase_messaging_bridge.dart';
import 'firebase_notification_bridge.dart';
import 'local_notification_helper.dart';
import 'notification_permission_handler.dart';
import 'notification_service.dart';

/// App-facing notifications API (FCM + local display when Firebase is configured).
class KickoraNotificationService {
  KickoraNotificationService({
    required NotificationManager manager,
    required LocalNotificationHelper localHelper,
    required NotificationPreferences preferences,
    FirebaseNotificationBridge? firebaseBridge,
  })  : _manager = manager,
        _local = localHelper,
        _preferences = preferences,
        _firebaseBridge = firebaseBridge;

  /// Mock stack for tests and platforms without FCM.
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
      preferences: NotificationPreferences(prefs),
      firebaseBridge: bridge,
    );
  }

  /// Live FCM when [FirebaseService] initialized on Android/iOS; otherwise mock.
  factory KickoraNotificationService.create(SharedPreferences prefs) {
    if (FirebaseService.isInitialized && _supportsPush) {
      final bridge = FirebaseMessagingBridge();
      final fcm = NotificationService(bridge);
      final manager = NotificationManager(
        notificationService: fcm,
        permissionHandler: FcmPermissionHandler(prefs),
        preferences: prefs,
      );
      return KickoraNotificationService(
        manager: manager,
        localHelper: FlutterLocalNotificationsHelper(),
        preferences: NotificationPreferences(prefs),
        firebaseBridge: bridge,
      );
    }
    return KickoraNotificationService.createMock(prefs);
  }

  static bool get _supportsPush {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  final NotificationManager _manager;
  final LocalNotificationHelper _local;
  final NotificationPreferences _preferences;
  final FirebaseNotificationBridge? _firebaseBridge;

  NotificationPreferences get preferences => _preferences;

  StreamSubscription<FirebaseNotificationPayload>? _foregroundSub;
  StreamSubscription<FirebaseNotificationPayload>? _openedSub;
  bool _initialized = false;

  final _tapController = StreamController<NotificationTapIntent>.broadcast();

  /// Cold-start tap intent (consume once after app boots).
  NotificationTapIntent? pendingTapIntent;

  /// Future navigation: listen for notification taps (match/team screens).
  Stream<NotificationTapIntent> get onNotificationTap => _tapController.stream;

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

  FirebaseMessagingBridge? get _messagingBridge =>
      _firebaseBridge is FirebaseMessagingBridge ? _firebaseBridge : null;

  Future<void> initialize() async {
    if (_initialized) return;
    await _local.initialize();
    await _manager.initialize();
    _foregroundSub = _manager.onForegroundMessage.listen(_onForegroundFcm);
    _openedSub = _manager.onMessageOpenedApp.listen(_onOpenedFcm);
    await _consumeInitialMessage();
    _initialized = true;
    if (kDebugMode) {
      debugPrint(
        '[Kickora Notifications] service ready (mock=$usesMockFirebase '
        'enabled=$isEnabled)',
      );
    }
  }

  Future<void> _consumeInitialMessage() async {
    final bridge = _messagingBridge;
    if (bridge == null || !isEnabled) return;
    final payload = await bridge.getInitialMessage();
    if (payload == null) return;
    _publishTapIntent(payload, coldStart: true);
  }

  Future<void> dispose() async {
    await _foregroundSub?.cancel();
    await _openedSub?.cancel();
    await _tapController.close();
    await _manager.dispose();
    final bridge = _firebaseBridge;
    if (bridge is MockFirebaseNotificationBridge) {
      bridge.dispose();
    } else if (bridge is FirebaseMessagingBridge) {
      bridge.dispose();
    }
  }

  Future<NotificationPermissionStatus> permissionStatus() =>
      _manager.permissionStatus();

  Future<bool> enable({
    Set<int> favoriteTeamIds = const {},
    Set<int> favoriteMatchIds = const {},
    Set<int> favoriteCompetitionIds = const {},
  }) async {
    final granted = await _manager.enable(
      favoriteTeamIds: const {},
      favoriteMatchIds: const {},
      favoriteCompetitionIds: const {},
    );
    if (granted) {
      await restoreFavoriteTopics(
        teamIds: favoriteTeamIds,
        matchIds: favoriteMatchIds,
        competitionIds: favoriteCompetitionIds,
      );
    }
    return granted;
  }

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
        subscribeTeams: _preferences.favoriteTeamUpdatesEnabled,
        subscribeMatches: _preferences.favoriteMatchUpdatesEnabled,
        subscribeCompetitions: _preferences.favoriteCompetitionUpdatesEnabled,
      );

  /// Applies saved preferences and favorite topic subscriptions after cold start.
  Future<int> restoreAfterStartup({
    required Set<int> teamIds,
    required Set<int> matchIds,
    required Set<int> competitionIds,
  }) async {
    if (!isEnabled) {
      NotificationDebugLog.preferencesRestored(
        enabled: false,
        enabledTypes: _preferences.enabledTypeLabels(),
        subscribedTopics: 0,
      );
      return 0;
    }
    final count = await restoreFavoriteTopics(
      teamIds: teamIds,
      matchIds: matchIds,
      competitionIds: competitionIds,
    );
    NotificationDebugLog.preferencesRestored(
      enabled: true,
      enabledTypes: _preferences.enabledTypeLabels(),
      subscribedTopics: count,
    );
    return count;
  }

  /// Re-syncs FCM topics when favorite-category toggles change.
  Future<void> applyPreferenceChange({
    required Set<int> teamIds,
    required Set<int> matchIds,
    required Set<int> competitionIds,
  }) async {
    if (!isEnabled) return;
    final count = await restoreFavoriteTopics(
      teamIds: teamIds,
      matchIds: matchIds,
      competitionIds: competitionIds,
    );
    NotificationDebugLog.preferencesRestored(
      enabled: true,
      enabledTypes: _preferences.enabledTypeLabels(),
      subscribedTopics: count,
    );
  }

  Future<void> syncFavoriteTeams(Set<int> teamIds) =>
      _manager.syncFavoriteTeams(teamIds);

  Future<void> syncFavoriteMatches(Set<int> matchIds) =>
      _manager.syncFavoriteMatches(matchIds);

  Future<void> syncFavoriteCompetitions(Set<int> competitionIds) =>
      _manager.syncFavoriteCompetitions(competitionIds);

  Future<void> subscribeFavoriteTeam(int teamId) async {
    if (!isEnabled || !_preferences.favoriteTeamUpdatesEnabled) return;
    await _manager.subscribeFavoriteTeam(teamId);
  }

  Future<void> unsubscribeFavoriteTeam(int teamId) =>
      _manager.unsubscribeFavoriteTeam(teamId);

  Future<void> subscribeFavoriteMatch(int matchId) async {
    if (!isEnabled || !_preferences.favoriteMatchUpdatesEnabled) return;
    await _manager.subscribeFavoriteMatch(matchId);
  }

  Future<void> unsubscribeFavoriteMatch(int matchId) =>
      _manager.unsubscribeFavoriteMatch(matchId);

  Future<void> subscribeFavoriteCompetition(int competitionId) async {
    if (!isEnabled || !_preferences.favoriteCompetitionUpdatesEnabled) return;
    await _manager.subscribeFavoriteCompetition(competitionId);
  }

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
    if (!isTypeEnabled(payload.type)) return;
    if (openedApp) {
      await _onOpenedFcm(payload);
    } else {
      await _onForegroundFcm(payload);
    }
  }

  bool isTypeEnabled(NotificationType type) =>
      _preferences.isMatchTypeEnabled(type);

  Future<void> _dispatch(
    FirebaseNotificationPayload payload, {
    bool isArabic = false,
  }) async {
    if (!isEnabled || !isTypeEnabled(payload.type)) return;
    await showLocal(payload.toKickoraNotification(isArabic: isArabic));
  }

  Future<void> _onForegroundFcm(FirebaseNotificationPayload payload) async {
    if (!isEnabled || !isTypeEnabled(payload.type)) return;
    await showLocal(payload.toKickoraNotification());
  }

  Future<void> _onOpenedFcm(FirebaseNotificationPayload payload) async {
    if (!isEnabled || !isTypeEnabled(payload.type)) return;
    _publishTapIntent(payload);
  }

  void _publishTapIntent(FirebaseNotificationPayload payload,
      {bool coldStart = false}) {
    final intent = NotificationTapIntent.fromPayload(payload);
    pendingTapIntent = intent;
    if (!_tapController.isClosed) {
      _tapController.add(intent);
    }
    if (kDebugMode) {
      debugPrint(
        '[Kickora Notifications] tap intent '
        'coldStart=$coldStart match=${intent.matchId} '
        'team=${intent.teamId} type=${intent.type.wireValue} '
        'topic=${intent.topic ?? '—'}',
      );
    }
  }
}
