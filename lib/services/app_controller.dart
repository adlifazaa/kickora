import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firebase/analytics_service.dart';
import '../core/refresh/match_refresh_service.dart';
import '../data/repositories/football_repository.dart';
import '../notifications/notification_manager.dart';
import '../notifications/services/kickora_notification_service.dart';
import '../subscription/premium_service.dart';
import '../subscription/premium_subscription_service.dart';
import '../app/app_locale.dart';
import 'favorite_manager.dart';

class AppController extends ChangeNotifier {
  AppController(
    this._preferences, {
    FootballRepository? footballRepository,
    KickoraNotificationService? notificationService,
    FavoriteManager? favoriteManager,
    MatchRefreshService? matchRefreshService,
    PremiumSubscriptionService? premiumSubscriptionService,
    PremiumService? premiumService,
  })  : footballRepository = footballRepository ?? FootballRepository(),
        notificationService = notificationService ??
            KickoraNotificationService.createMock(_preferences),
        favoriteManager = favoriteManager ??
            FavoriteManager(
              _preferences,
              notificationService: notificationService ??
                  KickoraNotificationService.createMock(_preferences),
            ),
        matchRefreshService = matchRefreshService ??
            MatchRefreshService(
              footballRepository ?? FootballRepository(),
            ),
        premiumSubscriptionService = premiumSubscriptionService ??
            PremiumSubscriptionService(_preferences),
        premiumService = premiumService ??
            PremiumService(
              premiumSubscriptionService ??
                  PremiumSubscriptionService(_preferences),
            ) {
    this.favoriteManager.addListener(notifyListeners);
    this.premiumSubscriptionService.addListener(notifyListeners);
  }

  final FootballRepository footballRepository;
  final KickoraNotificationService notificationService;
  final FavoriteManager favoriteManager;
  final MatchRefreshService matchRefreshService;
  final PremiumSubscriptionService premiumSubscriptionService;
  final PremiumService premiumService;

  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 8;

  final SharedPreferences _preferences;

  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = AppLocale.defaultLocale;
  bool _notificationsEnabled = false;
  List<String> _recentSearches = const <String>[];

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isArabic => AppLocale.isArabic(_locale);

  bool get favoritesLoading => favoriteManager.isLoading;
  Set<int> get favoriteTeamIds => favoriteManager.teamIds;
  Set<int> get favoriteCompetitionIds => favoriteManager.competitionIds;
  Set<int> get favoriteMatchIds => favoriteManager.matchIds;

  bool get notificationsEnabled => _notificationsEnabled;

  bool get notifyGoalsEnabled =>
      notificationService.preferences.goalsEnabled;
  bool get notifyMatchStartedEnabled =>
      notificationService.preferences.matchStartedEnabled;
  bool get notifyRedCardsEnabled =>
      notificationService.preferences.redCardsEnabled;
  bool get notifyMatchFinishedEnabled =>
      notificationService.preferences.matchFinishedEnabled;
  bool get notifyFavoriteTeamUpdatesEnabled =>
      notificationService.preferences.favoriteTeamUpdatesEnabled;
  bool get notifyFavoriteCompetitionUpdatesEnabled =>
      notificationService.preferences.favoriteCompetitionUpdatesEnabled;
  bool get notifyFavoriteMatchUpdatesEnabled =>
      notificationService.preferences.favoriteMatchUpdatesEnabled;

  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  bool get isPremium => premiumSubscriptionService.isPremium;
  bool get adsEnabled => premiumSubscriptionService.adsEnabled;
  bool get trialAvailable => premiumSubscriptionService.trialAvailable;

  Future<void> load() async {
    final themeValue = _preferences.getString(_themeKey) ?? ThemeMode.dark.name;
    _themeMode =
        themeValue == ThemeMode.light.name ? ThemeMode.light : ThemeMode.dark;

    if (!_preferences.containsKey(_languageKey)) {
      await _preferences.setString(_languageKey, AppLocale.arabicCode);
    }
    _locale = AppLocale.fromLanguageCode(_preferences.getString(_languageKey));

    await favoriteManager.load();
    await premiumSubscriptionService.load();

    _notificationsEnabled =
        _preferences.getBool(NotificationManager.enabledPreferenceKey) ?? false;
    _recentSearches =
        _preferences.getStringList(_recentSearchesKey) ?? const <String>[];
    await notificationService.restoreAfterStartup(
      teamIds: favoriteManager.teamIds,
      matchIds: favoriteManager.matchIds,
      competitionIds: favoriteManager.competitionIds,
    );
    await matchRefreshService.start();
    notifyListeners();
  }

  Future<void> addRecentSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final updated = <String>[q];
    for (final item in _recentSearches) {
      if (item.toLowerCase() == q.toLowerCase()) continue;
      updated.add(item);
      if (updated.length >= _maxRecentSearches) break;
    }
    _recentSearches = updated;
    await _preferences.setStringList(_recentSearchesKey, _recentSearches);
    notifyListeners();
  }

  Future<void> removeRecentSearch(String query) async {
    final next = _recentSearches.where((e) => e != query).toList();
    if (next.length == _recentSearches.length) return;
    _recentSearches = next;
    await _preferences.setStringList(_recentSearchesKey, _recentSearches);
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    if (_recentSearches.isEmpty) return;
    _recentSearches = const <String>[];
    await _preferences.remove(_recentSearchesKey);
    notifyListeners();
  }

  /// `false` when the user turned notifications on but OS permission was denied.
  Future<bool> setNotificationsEnabled(bool enabled) async {
    if (!enabled) {
      _notificationsEnabled = false;
      notifyListeners();
      await notificationService.disable();
      await _preferences.setBool(
        NotificationManager.enabledPreferenceKey,
        false,
      );
      await favoriteManager.onNotificationsEnabledChanged(false);
      notifyListeners();
      return true;
    }

    _notificationsEnabled = true;
    notifyListeners();

    var granted = false;
    try {
      granted = await notificationService.enable(
        favoriteTeamIds: favoriteManager.teamIds,
        favoriteMatchIds: favoriteManager.matchIds,
        favoriteCompetitionIds: favoriteManager.competitionIds,
      );
    } catch (_) {
      granted = false;
    }

    _notificationsEnabled = granted;
    await _preferences.setBool(
      NotificationManager.enabledPreferenceKey,
      granted,
    );
    await favoriteManager.onNotificationsEnabledChanged(granted);
    if (granted) {
      await AnalyticsService.instance.logNotificationEnabled();
    }
    notifyListeners();
    return granted;
  }

  Future<void> setNotifyGoalsEnabled(bool enabled) async {
    await notificationService.preferences.setGoalsEnabled(enabled);
    notifyListeners();
  }

  Future<void> setNotifyMatchStartedEnabled(bool enabled) async {
    await notificationService.preferences.setMatchStartedEnabled(enabled);
    notifyListeners();
  }

  Future<void> setNotifyRedCardsEnabled(bool enabled) async {
    await notificationService.preferences.setRedCardsEnabled(enabled);
    notifyListeners();
  }

  Future<void> setNotifyMatchFinishedEnabled(bool enabled) async {
    await notificationService.preferences.setMatchFinishedEnabled(enabled);
    notifyListeners();
  }

  Future<void> setNotifyFavoriteTeamUpdatesEnabled(bool enabled) async {
    await notificationService.preferences.setFavoriteTeamUpdatesEnabled(
      enabled,
    );
    await favoriteManager.onNotificationPreferencesChanged();
    notifyListeners();
  }

  Future<void> setNotifyFavoriteCompetitionUpdatesEnabled(bool enabled) async {
    await notificationService.preferences
        .setFavoriteCompetitionUpdatesEnabled(enabled);
    await favoriteManager.onNotificationPreferencesChanged();
    notifyListeners();
  }

  Future<void> setNotifyFavoriteMatchUpdatesEnabled(bool enabled) async {
    await notificationService.preferences.setFavoriteMatchUpdatesEnabled(
      enabled,
    );
    await favoriteManager.onNotificationPreferencesChanged();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _preferences.setString(_themeKey, mode.name);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = AppLocale.fromLanguageCode(locale.languageCode);
    await _preferences.setString(_languageKey, _locale.languageCode);
    notifyListeners();
  }

  Future<void> toggleTeamFavorite(int id) => favoriteManager.toggleTeam(id);

  Future<void> toggleCompetitionFavorite(int id) =>
      favoriteManager.toggleCompetition(id);

  Future<void> toggleMatchFavorite(int id) => favoriteManager.toggleMatch(id);

  Future<void> addTeamFavorite(int id) => favoriteManager.addTeam(id);

  Future<void> removeTeamFavorite(int id) => favoriteManager.removeTeam(id);

  Future<void> addCompetitionFavorite(int id) =>
      favoriteManager.addCompetition(id);

  Future<void> removeCompetitionFavorite(int id) =>
      favoriteManager.removeCompetition(id);

  Future<void> addMatchFavorite(int id) => favoriteManager.addMatch(id);

  Future<void> removeMatchFavorite(int id) => favoriteManager.removeMatch(id);

  bool isTeamFavorite(int id) => favoriteManager.isTeamFavorite(id);
  bool isCompetitionFavorite(int id) =>
      favoriteManager.isCompetitionFavorite(id);
  bool isMatchFavorite(int id) => favoriteManager.isMatchFavorite(id);

  @override
  void dispose() {
    favoriteManager.removeListener(notifyListeners);
    premiumSubscriptionService.removeListener(notifyListeners);
    premiumService.dispose();
    super.dispose();
  }
}
