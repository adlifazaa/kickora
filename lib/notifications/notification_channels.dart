/// Android notification channel IDs (used when [flutter_local_notifications] is added).
class NotificationChannels {
  NotificationChannels._();

  static const String matchAlerts = 'kickora_match_alerts';
  static const String goals = 'kickora_goals';
  static const String favorites = 'kickora_favorites';

  static String forType(String wireType) {
    switch (wireType) {
      case 'goal':
      case 'goal_scored':
        return goals;
      case 'red_card':
        return matchAlerts;
      case 'favorite_team_reminder':
      case 'favorite_team_update':
        return favorites;
      default:
        return matchAlerts;
    }
  }
}

/// FCM topic naming (`team_{id}`, `match_{id}`, `competition_{id}`).
class NotificationTopics {
  NotificationTopics._();

  static String team(int teamId) => 'team_$teamId';
  static String match(int matchId) => 'match_$matchId';
  static String competition(int competitionId) => 'competition_$competitionId';

  /// @deprecated Use [team].
  static String favoriteTeam(int teamId) => team(teamId);

  /// @deprecated Use [match].
  static String favoriteMatch(int matchId) => match(matchId);

  static const String globalLive = 'kickora_live';
}
