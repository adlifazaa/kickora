import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/match_model.dart';
import '../notifications/models/notification_type.dart';
import '../notifications/services/kickora_notification_service.dart';
import 'favorites_service.dart';

/// UI-facing favorites state: persists via [FavoritesService], syncs notification topics.
class FavoriteManager extends ChangeNotifier {
  FavoriteManager(
    SharedPreferences prefs, {
    KickoraNotificationService? notificationService,
    FavoritesService? favoritesService,
  })  : _notifications = notificationService,
        _favorites = favoritesService ?? FavoritesService(prefs);

  final KickoraNotificationService? _notifications;
  final FavoritesService _favorites;

  FavoritesService get favoritesService => _favorites;

  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool get isLoaded => _favorites.isLoaded;

  Set<int> get teamIds => _favorites.getFavorites(FavoriteType.team);
  Set<int> get competitionIds =>
      _favorites.getFavorites(FavoriteType.competition);
  Set<int> get matchIds => _favorites.getFavorites(FavoriteType.match);

  int get totalCount =>
      teamIds.length + competitionIds.length + matchIds.length;

  bool isTeamFavorite(int id) =>
      _favorites.isFavorite(FavoriteType.team, id);
  bool isCompetitionFavorite(int id) =>
      _favorites.isFavorite(FavoriteType.competition, id);
  bool isMatchFavorite(int id) =>
      _favorites.isFavorite(FavoriteType.match, id);

  bool isMatchInvolvingFavoriteTeam(MatchModel match) =>
      isTeamFavorite(match.homeTeam.id) || isTeamFavorite(match.awayTeam.id);

  /// Loads persisted favorites (survives app restart).
  Future<void> load() async {
    if (_favorites.isLoaded) return;
    _isLoading = true;
    notifyListeners();

    await _favorites.load();

    _isLoading = false;
    notifyListeners();

    await _syncNotificationTopics();
  }

  Future<bool> addTeam(int id) =>
      _mutate(() => _favorites.addFavorite(FavoriteType.team, id));

  Future<bool> removeTeam(int id) =>
      _mutate(() => _favorites.removeFavorite(FavoriteType.team, id));

  Future<bool> toggleTeam(int id) =>
      _mutate(() => _favorites.toggleFavorite(FavoriteType.team, id));

  Future<bool> addCompetition(int id) =>
      _mutate(() => _favorites.addFavorite(FavoriteType.competition, id));

  Future<bool> removeCompetition(int id) =>
      _mutate(() => _favorites.removeFavorite(FavoriteType.competition, id));

  Future<bool> toggleCompetition(int id) =>
      _mutate(() => _favorites.toggleFavorite(FavoriteType.competition, id));

  Future<bool> addMatch(int id) =>
      _mutate(() => _favorites.addFavorite(FavoriteType.match, id));

  Future<bool> removeMatch(int id) =>
      _mutate(() => _favorites.removeFavorite(FavoriteType.match, id));

  Future<bool> toggleMatch(int id) =>
      _mutate(() => _favorites.toggleFavorite(FavoriteType.match, id));

  Future<bool> _mutate(Future<bool> Function() action) async {
    await _favorites.load();
    final changed = await action();
    if (!changed) return false;
    // Future push: FavoriteTopicNames.team|competition|match(id) via FCM subscribe.
    notifyListeners();
    await _syncNotificationTopics();
    return true;
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

    switch (type.canonical) {
      case NotificationType.matchStarted:
        await notifications.notifyMatchStarting(
          matchId: match.id,
          homeTeam: home,
          awayTeam: away,
          kickoffLabel: kickoffLabel ?? match.timeLabel,
          isArabic: isArabic,
        );
      case NotificationType.goalScored:
        await notifications.notifyGoal(
          matchId: match.id,
          scorer: scorer ?? '',
          homeTeam: home,
          awayTeam: away,
          score: score,
          minute: match.timeLabel,
          isArabic: isArabic,
        );
      case NotificationType.redCard:
        await notifications.notifyRedCard(
          matchId: match.id,
          playerName: scorer ?? '',
          homeTeam: home,
          awayTeam: away,
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
      case NotificationType.matchFinished:
        await notifications.notifyMatchFinished(
          matchId: match.id,
          homeTeam: home,
          awayTeam: away,
          score: score,
          isArabic: isArabic,
        );
      case NotificationType.favoriteTeamUpdate:
        final teamId = isTeamFavorite(match.homeTeam.id)
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
      default:
        break;
    }
  }

  Future<void> _syncNotificationTopics() async {
    final notifications = _notifications;
    if (notifications == null || !notifications.isEnabled) return;
    await notifications.syncFavoriteTeams(teamIds);
    await notifications.syncFavoriteMatches(matchIds);
    await notifications.syncFavoriteCompetitions(competitionIds);
  }

  Future<void> onNotificationsEnabledChanged(bool enabled) async {
    if (enabled) {
      await _syncNotificationTopics();
    }
  }
}
