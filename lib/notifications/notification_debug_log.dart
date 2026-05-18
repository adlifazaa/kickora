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

  static void topicsRestored(int count) {
    if (!kDebugMode) return;
    debugPrint('[Kickora Notifications] restored topic count=$count');
  }

  static void preferencesRestored({
    required bool enabled,
    required List<String> enabledTypes,
    required int subscribedTopics,
  }) {
    if (!kDebugMode) return;
    final types = enabledTypes.isEmpty ? 'none' : enabledTypes.join(',');
    debugPrint(
      '[Kickora Notifications] preferences restored '
      'enabled=$enabled types=[$types] topics=$subscribedTopics',
    );
  }

  static void received({
    required String type,
    required String deliveryPhase,
    String? topic,
    int? matchId,
    int? teamId,
    int? competitionId,
    bool openedApp = false,
  }) {
    if (!kDebugMode) return;
    final ctx = <String>[
      'phase=$deliveryPhase',
      if (topic != null && topic.isNotEmpty) 'topic=$topic',
      if (matchId != null) 'match=$matchId',
      if (teamId != null) 'team=$teamId',
      if (competitionId != null) 'competition=$competitionId',
    ].join(' ');
    final opened = openedApp ? ' openedApp' : '';
    debugPrint(
      '[Kickora Notifications] received type=$type$opened $ctx'.trim(),
    );
  }

  static void permissionRequested(String result) {
    if (!kDebugMode) return;
    debugPrint('[Kickora Notifications] permission request → $result');
  }

  static void routing({
    required String type,
    required String target,
    int? matchId,
    int? teamId,
    int? competitionId,
    String? topic,
  }) {
    if (!kDebugMode) return;
    final ctx = <String>[
      'target=$target',
      if (topic != null && topic.isNotEmpty) 'topic=$topic',
      if (matchId != null) 'match=$matchId',
      if (teamId != null) 'team=$teamId',
      if (competitionId != null) 'competition=$competitionId',
    ].join(' ');
    debugPrint(
      '[Kickora Notifications] routing type=$type $ctx'.trim(),
    );
  }
}
