import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/match_model.dart';
import '../notifications/models/notification_type.dart';
import '../notifications/services/kickora_notification_service.dart';

/// Persists favorite teams, competitions, and matches via [SharedPreferences].
class FavoriteManager extends ChangeNotifier {
  FavoriteManager(
    this._prefs, {
    KickoraNotificationService? notificationService,
  }) : _notifications = notificationService;

  final SharedPreferences _prefs;
  final KickoraNotificationService? _notifications;

  static const String teamsKey = 'favorite_teams';
  static const String competitionsKey = 'favorite_competitions';
  static const String matchesKey = 'favorite_matches';

  bool _isLoading = false;
  bool _isLoaded = false;
  Set<int> _teamIds = {};
  Set<int> _competitionIds = {};
  Set<int> _matchIds = {};

  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;

  Set<int> get teamIds => Set.unmodifiable(_teamIds);
  Set<int> get competitionIds => Set.unmodifiable(_competitionIds);
  Set<int> get matchIds => Set.unmodifiable(_matchIds);

  int get totalCount =>
      _teamIds.length + _competitionIds.length + _matchIds.length;

  bool isTeamFavorite(int id) => _teamIds.contains(id);
  bool isCompetitionFavorite(int id) => _competitionIds.contains(id);
  bool isMatchFavorite(int id) => _matchIds.contains(id);

  bool isMatchInvolvingFavoriteTeam(MatchModel match) =>
      _teamIds.contains(match.homeTeam.id) ||
      _teamIds.contains(match.awayTeam.id);

  /// Loads persisted favorites (survives app restart and device reboot).
  Future<void> load() async {
    if (_isLoaded) return;
    _isLoading = true;
    notifyListeners();

    _teamIds = _readSet(teamsKey);
    _competitionIds = _readSet(competitionsKey);
    _matchIds = _readSet(matchesKey);

    _isLoading = false;
    _isLoaded = true;
    notifyListeners();

    await _syncNotificationTopics();
  }

  Future<bool> addTeam(int id) async {
    if (_teamIds.contains(id)) return false;
    _teamIds.add(id);
    await _persist(teamsKey, _teamIds);
    notifyListeners();
    await _syncNotificationTopics();
    return true;
  }

  Future<bool> removeTeam(int id) async {
    if (!_teamIds.remove(id)) return false;
    await _persist(teamsKey, _teamIds);
    notifyListeners();
    await _syncNotificationTopics();
    return true;
  }

  Future<bool> toggleTeam(int id) async {
    if (_teamIds.contains(id)) {
      return removeTeam(id);
    }
    return addTeam(id);
  }

  Future<bool> addCompetition(int id) async {
    if (_competitionIds.contains(id)) return false;
    _competitionIds.add(id);
    await _persist(competitionsKey, _competitionIds);
    notifyListeners();
    return true;
  }

  Future<bool> removeCompetition(int id) async {
    if (!_competitionIds.remove(id)) return false;
    await _persist(competitionsKey, _competitionIds);
    notifyListeners();
    return true;
  }

  Future<bool> toggleCompetition(int id) async {
    if (_competitionIds.contains(id)) {
      return removeCompetition(id);
    }
    return addCompetition(id);
  }

  Future<bool> addMatch(int id) async {
    if (_matchIds.contains(id)) return false;
    _matchIds.add(id);
    await _persist(matchesKey, _matchIds);
    notifyListeners();
    await _syncNotificationTopics();
    return true;
  }

  Future<bool> removeMatch(int id) async {
    if (!_matchIds.remove(id)) return false;
    await _persist(matchesKey, _matchIds);
    notifyListeners();
    await _syncNotificationTopics();
    return true;
  }

  Future<bool> toggleMatch(int id) async {
    if (_matchIds.contains(id)) {
      return removeMatch(id);
    }
    return addMatch(id);
  }

  /// Delivers match alerts when [home]/[away] team is favorited and notifications are on.
  Future<void> dispatchFavoriteTeamMatchAlert({
    required MatchModel match,
    required NotificationType type,
    bool isArabic = false,
    String? scorer,
    String? kickoffLabel,
  }) async {
    final notifications = _notifications;
    if (notifications == null || !notifications.isEnabled) return;
    if (!isMatchInvolvingFavoriteTeam(match)) return;

    final home = match.homeTeam.name;
    final away = match.awayTeam.name;
    final score = '${match.homeScore} - ${match.awayScore}';

    switch (type) {
      case NotificationType.matchStarting:
        await notifications.notifyMatchStarting(
          matchId: match.id,
          homeTeam: home,
          awayTeam: away,
          kickoffLabel: kickoffLabel ?? match.timeLabel,
          isArabic: isArabic,
        );
      case NotificationType.goal:
        await notifications.notifyGoal(
          matchId: match.id,
          scorer: scorer ?? '',
          homeTeam: home,
          awayTeam: away,
          score: score,
          minute: match.timeLabel,
          isArabic: isArabic,
        );
      case NotificationType.halftime:
        await notifications.notifyHalftime(
          matchId: match.id,
          homeTeam: home,
          awayTeam: away,
          score: score,
          isArabic: isArabic,
        );
      case NotificationType.fulltime:
        await notifications.notifyFulltime(
          matchId: match.id,
          homeTeam: home,
          awayTeam: away,
          score: score,
          isArabic: isArabic,
        );
      case NotificationType.favoriteTeamReminder:
        final teamId = _teamIds.contains(match.homeTeam.id)
            ? match.homeTeam.id
            : match.awayTeam.id;
        await notifications.notifyFavoriteTeamReminder(
          teamId: teamId,
          matchId: match.id,
          homeTeam: home,
          awayTeam: away,
          kickoffLabel: kickoffLabel ?? match.timeLabel,
          isArabic: isArabic,
        );
    }
  }

  Future<void> _syncNotificationTopics() async {
    final notifications = _notifications;
    if (notifications == null || !notifications.isEnabled) return;
    await notifications.syncFavoriteTeams(_teamIds);
    await notifications.syncFavoriteMatches(_matchIds);
  }

  Future<void> onNotificationsEnabledChanged(bool enabled) async {
    if (enabled) {
      await _syncNotificationTopics();
    }
  }

  Set<int> _readSet(String key) {
    final values = _prefs.getStringList(key) ?? <String>[];
    final out = <int>{};
    for (final s in values) {
      final v = int.tryParse(s);
      if (v != null) out.add(v);
    }
    return out;
  }

  Future<void> _persist(String key, Set<int> ids) async {
    await _prefs.setStringList(key, ids.map((e) => '$e').toList());
  }
}
