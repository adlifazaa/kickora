import 'package:shared_preferences/shared_preferences.dart';

/// Persisted favorite category (no login required).
enum FavoriteType {
  team,
  competition,
  match,
}

/// Future FCM topic names when push subscriptions are wired.
class FavoriteTopicNames {
  FavoriteTopicNames._();

  static String team(int id) => 'team_$id';
  static String competition(int id) => 'competition_$id';
  static String match(int id) => 'match_$id';

  static String forType(FavoriteType type, int id) {
    switch (type) {
      case FavoriteType.team:
        return team(id);
      case FavoriteType.competition:
        return competition(id);
      case FavoriteType.match:
        return match(id);
    }
  }
}

/// Optional hooks invoked after persistence (e.g. topic subscribe later).
class FavoriteSubscriptionHooks {
  const FavoriteSubscriptionHooks({
    this.onFavoriteAdded,
    this.onFavoriteRemoved,
  });

  final Future<void> Function(FavoriteType type, int id)? onFavoriteAdded;
  final Future<void> Function(FavoriteType type, int id)? onFavoriteRemoved;
}

/// Local favorites persistence via [SharedPreferences].
class FavoritesService {
  FavoritesService(
    this._prefs, {
    FavoriteSubscriptionHooks hooks = const FavoriteSubscriptionHooks(),
  }) : _hooks = hooks;

  final SharedPreferences _prefs;
  final FavoriteSubscriptionHooks _hooks;

  static const String teamsKey = 'favorite_teams';
  static const String competitionsKey = 'favorite_competitions';
  static const String matchesKey = 'favorite_matches';

  bool _loaded = false;
  final Map<FavoriteType, Set<int>> _ids = {
    FavoriteType.team: {},
    FavoriteType.competition: {},
    FavoriteType.match: {},
  };

  bool get isLoaded => _loaded;

  /// Loads all favorite sets from disk (idempotent).
  Future<void> load() async {
    if (_loaded) return;
    _ids[FavoriteType.team] = _readKey(teamsKey);
    _ids[FavoriteType.competition] = _readKey(competitionsKey);
    _ids[FavoriteType.match] = _readKey(matchesKey);
    _loaded = true;
  }

  Future<bool> addFavorite(FavoriteType type, int id) async {
    await load();
    final set = _ids[type]!;
    if (set.contains(id)) return false;
    set.add(id);
    await _persist(type);
    await _hooks.onFavoriteAdded?.call(type, id);
    return true;
  }

  Future<bool> removeFavorite(FavoriteType type, int id) async {
    await load();
    if (!_ids[type]!.remove(id)) return false;
    await _persist(type);
    await _hooks.onFavoriteRemoved?.call(type, id);
    return true;
  }

  bool isFavorite(FavoriteType type, int id) {
    if (!_loaded) {
      _ids[type] = _readKey(_keyFor(type));
    }
    return _ids[type]!.contains(id);
  }

  Set<int> getFavorites(FavoriteType type) {
    if (!_loaded) {
      _ids[type] = _readKey(_keyFor(type));
    }
    return Set.unmodifiable(_ids[type]!);
  }

  Future<bool> toggleFavorite(FavoriteType type, int id) async {
    if (isFavorite(type, id)) {
      return removeFavorite(type, id);
    }
    return addFavorite(type, id);
  }

  String _keyFor(FavoriteType type) {
    switch (type) {
      case FavoriteType.team:
        return teamsKey;
      case FavoriteType.competition:
        return competitionsKey;
      case FavoriteType.match:
        return matchesKey;
    }
  }

  Future<void> _persist(FavoriteType type) async {
    final key = _keyFor(type);
    await _prefs.setStringList(
      key,
      _ids[type]!.map((e) => '$e').toList(),
    );
  }

  Set<int> _readKey(String key) {
    final values = _prefs.getStringList(key) ?? <String>[];
    final out = <int>{};
    for (final s in values) {
      final v = int.tryParse(s);
      if (v != null) out.add(v);
    }
    return out;
  }
}
