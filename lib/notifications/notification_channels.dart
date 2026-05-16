/// Android notification channel IDs (used when [flutter_local_notifications] is added).
class NotificationChannels {
  NotificationChannels._();

  static const String matchAlerts = 'kickora_match_alerts';
  static const String goals = 'kickora_goals';
  static const String favorites = 'kickora_favorites';

  static String forType(String wireType) {
    switch (wireType) {
      case 'goal':
        return goals;
      case 'favorite_team_reminder':
        return favorites;
      default:
        return matchAlerts;
    }
  }
}

/// FCM topic naming for favorite teams / leagues (subscribe when Firebase is live).
class NotificationTopics {
  NotificationTopics._();

  static String favoriteTeam(int teamId) => 'team_$teamId';
  static String favoriteMatch(int matchId) => 'match_$matchId';
  static const String globalLive = 'kickora_live';
}
