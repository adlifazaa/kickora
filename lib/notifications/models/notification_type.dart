/// Match alert categories supported by Kickora (FCM data `type` field).
enum NotificationType {
  /// Match started / kickoff.
  matchStarted,

  /// Goal scored.
  goalScored,

  /// Red card shown.
  redCard,

  /// Match finished (full time).
  matchFinished,

  /// Favorite team match reminder / update.
  favoriteTeamUpdate,

  /// Favorite competition update.
  favoriteCompetitionUpdate,

  /// Favorite match update.
  favoriteMatchUpdate,

  /// @deprecated Use [matchStarted].
  matchStarting,

  /// @deprecated Use [goalScored].
  goal,

  /// @deprecated Use [matchFinished] (half time — kept for mock refresh).
  halftime,

  /// @deprecated Use [matchFinished].
  fulltime,

  /// @deprecated Use [favoriteTeamUpdate].
  favoriteTeamReminder,
}

extension NotificationTypeX on NotificationType {
  String get wireValue {
    switch (this) {
      case NotificationType.matchStarted:
      case NotificationType.matchStarting:
        return 'match_started';
      case NotificationType.goalScored:
      case NotificationType.goal:
        return 'goal_scored';
      case NotificationType.redCard:
        return 'red_card';
      case NotificationType.matchFinished:
      case NotificationType.fulltime:
        return 'match_finished';
      case NotificationType.halftime:
        return 'halftime';
      case NotificationType.favoriteTeamUpdate:
      case NotificationType.favoriteTeamReminder:
        return 'favorite_team_update';
      case NotificationType.favoriteCompetitionUpdate:
        return 'favorite_competition_update';
      case NotificationType.favoriteMatchUpdate:
        return 'favorite_match_update';
    }
  }

  static NotificationType? fromWireValue(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'match_started':
      case 'match_start':
      case 'match_starting':
        return NotificationType.matchStarted;
      case 'goal_scored':
      case 'goal':
        return NotificationType.goalScored;
      case 'red_card':
      case 'redcard':
        return NotificationType.redCard;
      case 'match_finished':
      case 'fulltime':
      case 'ft':
        return NotificationType.matchFinished;
      case 'halftime':
      case 'ht':
        return NotificationType.halftime;
      case 'favorite_team_update':
      case 'favorite_team_reminder':
      case 'favorite_team':
        return NotificationType.favoriteTeamUpdate;
      case 'favorite_competition_update':
      case 'favorite_competition':
        return NotificationType.favoriteCompetitionUpdate;
      case 'favorite_match_update':
      case 'favorite_match':
        return NotificationType.favoriteMatchUpdate;
      default:
        return null;
    }
  }

  /// Canonical type for routing (collapses deprecated aliases).
  NotificationType get canonical {
    switch (this) {
      case NotificationType.matchStarting:
        return NotificationType.matchStarted;
      case NotificationType.goal:
        return NotificationType.goalScored;
      case NotificationType.fulltime:
        return NotificationType.matchFinished;
      case NotificationType.favoriteTeamReminder:
        return NotificationType.favoriteTeamUpdate;
      case NotificationType.favoriteCompetitionUpdate:
      case NotificationType.favoriteMatchUpdate:
        return this;
      default:
        return this;
    }
  }
}
