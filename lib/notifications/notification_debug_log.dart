import 'package:flutter/foundation.dart';

/// Debug-only notification logs (never logs FCM tokens or secrets).
class NotificationDebugLog {
  NotificationDebugLog._();

  static void initialized({required bool firebaseAvailable, required bool enabled}) {
    if (!kDebugMode) return;
    debugPrint(
      '[Kickora Notifications] initialized '
      'firebase=$firebaseAvailable enabled=$enabled',
    );
  }

  static void status({
    required bool enabled,
    required String permission,
    required int subscribedTopics,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[Kickora Notifications] status enabled=$enabled '
      'permission=$permission topics=$subscribedTopics',
    );
  }

  static void topicSubscribe(String topic) {
    if (!kDebugMode) return;
    debugPrint('[Kickora Notifications] topic subscribe → $topic');
  }

  static void topicUnsubscribe(String topic) {
    if (!kDebugMode) return;
    debugPrint('[Kickora Notifications] topic unsubscribe → $topic');
  }

  static void received({
    required String type,
    int? matchId,
    int? teamId,
    int? competitionId,
    bool openedApp = false,
  }) {
    if (!kDebugMode) return;
    final ctx = <String>[
      if (matchId != null) 'match=$matchId',
      if (teamId != null) 'team=$teamId',
      if (competitionId != null) 'competition=$competitionId',
    ].join(' ');
    debugPrint(
      '[Kickora Notifications] received type=$type '
      '${openedApp ? 'openedApp ' : ''}$ctx'.trim(),
    );
  }

  static void permissionRequested(String result) {
    if (!kDebugMode) return;
    debugPrint('[Kickora Notifications] permission request → $result');
  }
}
