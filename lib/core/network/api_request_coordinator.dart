import 'api_debug_log.dart';

/// Dedupes concurrent identical GETs and tracks outbound HTTP attempt count.
class ApiRequestCoordinator {
  ApiRequestCoordinator._();
  static final ApiRequestCoordinator instance = ApiRequestCoordinator._();

  int _requestCounter = 0;
  final Map<String, Future<dynamic>> _inFlight = {};

  int get requestCount => _requestCounter;

  Future<T> run<T>(String dedupeKey, Future<T> Function() action) {
    final existing = _inFlight[dedupeKey];
    if (existing != null) {
      ApiDebugLog.requestOutcome(
        path: dedupeKey,
        cacheHit: false,
        deduped: true,
      );
      return existing as Future<T>;
    }

    final future = action();
    _inFlight[dedupeKey] = future;
    return future.whenComplete(() {
      _inFlight.remove(dedupeKey);
    });
  }

  int nextRequestId() => ++_requestCounter;
}
