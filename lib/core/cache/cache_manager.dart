import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Simple TTL cache on top of [SharedPreferences] (JSON strings).
class CacheManager {
  CacheManager(this._prefs);

  final SharedPreferences _prefs;

  static const String _tsSuffix = '__ts';

  Future<void> setJson(
    String key,
    Object value, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    await _prefs.setString(key, jsonEncode(value));
    await _setExpiry(key, ttl);
  }

  Future<void> setJsonList(
    String key,
    List<dynamic> value, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    await _prefs.setString(key, jsonEncode(value));
    await _setExpiry(key, ttl);
  }

  Future<void> _setExpiry(String key, Duration ttl) async {
    await _prefs.setInt(
      '$key$_tsSuffix',
      DateTime.now().add(ttl).millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic>? getJson(String key) {
    if (!_isValid(key)) return null;
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  List<dynamic>? getJsonList(String key) {
    if (!_isValid(key)) return null;
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    await _prefs.remove(key);
    await _prefs.remove('$key$_tsSuffix');
  }

  Future<void> clearAll() async {
    final keys = _prefs.getKeys().where(
      (k) => k.startsWith('cache_') || k.endsWith(_tsSuffix),
    );
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }

  bool _isValid(String key) {
    final expires = _prefs.getInt('$key$_tsSuffix');
    if (expires == null) return true;
    return DateTime.now().millisecondsSinceEpoch < expires;
  }
}
