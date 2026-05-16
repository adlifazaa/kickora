import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/football_repository.dart';

class AppController extends ChangeNotifier {
  AppController(
    this._preferences, {
    FootballRepository? footballRepository,
  }) : footballRepository = footballRepository ?? FootballRepository();

  final FootballRepository footballRepository;

  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';
  static const String _favTeamsKey = 'favorite_teams';
  static const String _favCompetitionsKey = 'favorite_competitions';
  static const String _favMatchesKey = 'favorite_matches';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 8;

  final SharedPreferences _preferences;

  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('ar');
  Set<int> _favoriteTeamIds = <int>{};
  Set<int> _favoriteCompetitionIds = <int>{};
  Set<int> _favoriteMatchIds = <int>{};
  bool _notificationsEnabled = false;
  List<String> _recentSearches = const <String>[];

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  Set<int> get favoriteTeamIds => _favoriteTeamIds;
  Set<int> get favoriteCompetitionIds => _favoriteCompetitionIds;
  Set<int> get favoriteMatchIds => _favoriteMatchIds;
  bool get notificationsEnabled => _notificationsEnabled;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  Future<void> load() async {
    final themeValue = _preferences.getString(_themeKey) ?? ThemeMode.dark.name;
    _themeMode = themeValue == ThemeMode.light.name ? ThemeMode.light : ThemeMode.dark;

    final languageCode = _preferences.getString(_languageKey) ?? 'ar';
    _locale = Locale(languageCode);

    _favoriteTeamIds = _readSet(_favTeamsKey);
    _favoriteCompetitionIds = _readSet(_favCompetitionsKey);
    _favoriteMatchIds = _readSet(_favMatchesKey);
    _notificationsEnabled = _preferences.getBool(_notificationsKey) ?? false;
    _recentSearches =
        _preferences.getStringList(_recentSearchesKey) ?? const <String>[];
    notifyListeners();
  }

  /// Adds [query] to the front of the recent searches list (dedup, capped).
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

  /// Persists preference only; no OS push registration yet.
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _preferences.setBool(_notificationsKey, enabled);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _preferences.setString(_themeKey, mode.name);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await _preferences.setString(_languageKey, locale.languageCode);
    notifyListeners();
  }

  Future<void> toggleTeamFavorite(int id) => _toggleSet(id, _favoriteTeamIds, _favTeamsKey);
  Future<void> toggleCompetitionFavorite(int id) => _toggleSet(id, _favoriteCompetitionIds, _favCompetitionsKey);
  Future<void> toggleMatchFavorite(int id) => _toggleSet(id, _favoriteMatchIds, _favMatchesKey);

  bool isTeamFavorite(int id) => _favoriteTeamIds.contains(id);
  bool isCompetitionFavorite(int id) => _favoriteCompetitionIds.contains(id);
  bool isMatchFavorite(int id) => _favoriteMatchIds.contains(id);

  Set<int> _readSet(String key) {
    final values = _preferences.getStringList(key) ?? <String>[];
    final out = <int>{};
    for (final s in values) {
      final v = int.tryParse(s);
      if (v != null) out.add(v);
    }
    return out;
  }

  Future<void> _toggleSet(int id, Set<int> source, String key) async {
    if (source.contains(id)) {
      source.remove(id);
    } else {
      source.add(id);
    }
    await _preferences.setStringList(key, source.map((item) => '$item').toList());
    notifyListeners();
  }
}
