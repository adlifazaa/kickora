/// Short-lived in-memory cache so screen rebuilds / tab switches do not re-hit the API.
class RepositoryMemoryCache {
  final Map<String, _Entry> _store = {};

  T? get<T>(String key, Duration ttl) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.storedAt) > ttl) {
      _store.remove(key);
      return null;
    }
    return entry.value as T;
  }

  void put<T>(String key, T value) {
    _store[key] = _Entry(value, DateTime.now());
  }

  void remove(String key) => _store.remove(key);

  void clear() => _store.clear();
}

class _Entry {
  _Entry(this.value, this.storedAt);
  final Object? value;
  final DateTime storedAt;
}
