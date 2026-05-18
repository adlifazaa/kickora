import 'package:shared_preferences/shared_preferences.dart';

import 'models/notification_type.dart';

/// Persisted per-category notification settings (SharedPreferences).
class NotificationPreferences {
  NotificationPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const String keyGoals = 'notify_goals';
  static const String keyMatchStarted = 'notify_match_started';
  static const String keyRedCards = 'notify_red_cards';
  static const String keyMatchFinished = 'notify_match_finished';
  static const String keyFavoriteTeam = 'notify_favorite_team';
  static const String keyFavoriteCompetition = 'notify_favorite_competition';
  static const String keyFavoriteMatch = 'notify_favorite_match';

  bool get goalsEnabled => _prefs.getBool(keyGoals) ?? true;
  bool get matchStartedEnabled => _prefs.getBool(keyMatchStarted) ?? true;
  bool get redCardsEnabled => _prefs.getBool(keyRedCards) ?? true;
  bool get matchFinishedEnabled => _prefs.getBool(keyMatchFinished) ?? true;
  bool get favoriteTeamUpdatesEnabled =>
      _prefs.getBool(keyFavoriteTeam) ?? true;
  bool get favoriteCompetitionUpdatesEnabled =>
      _prefs.getBool(keyFavoriteCompetition) ?? true;
  bool get favoriteMatchUpdatesEnabled =>
      _prefs.getBool(keyFavoriteMatch) ?? true;

  Future<void> setGoalsEnabled(bool value) => _prefs.setBool(keyGoals, value);

  Future<void> setMatchStartedEnabled(bool value) =>
      _prefs.setBool(keyMatchStarted, value);

  Future<void> setRedCardsEnabled(bool value) =>
      _prefs.setBool(keyRedCards, value);

  Future<void> setMatchFinishedEnabled(bool value) =>
      _prefs.setBool(keyMatchFinished, value);

  Future<void> setFavoriteTeamUpdatesEnabled(bool value) =>
      _prefs.setBool(keyFavoriteTeam, value);

  Future<void> setFavoriteCompetitionUpdatesEnabled(bool value) =>
      _prefs.setBool(keyFavoriteCompetition, value);

  Future<void> setFavoriteMatchUpdatesEnabled(bool value) =>
      _prefs.setBool(keyFavoriteMatch, value);

  bool isMatchTypeEnabled(NotificationType type) {
    switch (type.canonical) {
      case NotificationType.goalScored:
        return goalsEnabled;
      case NotificationType.matchStarted:
        return matchStartedEnabled;
      case NotificationType.redCard:
        return redCardsEnabled;
      case NotificationType.matchFinished:
        return matchFinishedEnabled;
      case NotificationType.favoriteTeamUpdate:
        return favoriteTeamUpdatesEnabled;
      default:
        return true;
    }
  }

  /// Debug-safe summary (no secrets).
  List<String> enabledTypeLabels() {
    final labels = <String>[];
    if (goalsEnabled) labels.add('goals');
    if (matchStartedEnabled) labels.add('match_started');
    if (redCardsEnabled) labels.add('red_cards');
    if (matchFinishedEnabled) labels.add('match_finished');
    if (favoriteTeamUpdatesEnabled) labels.add('favorite_team');
    if (favoriteCompetitionUpdatesEnabled) labels.add('favorite_competition');
    if (favoriteMatchUpdatesEnabled) labels.add('favorite_match');
    return labels;
  }
}
