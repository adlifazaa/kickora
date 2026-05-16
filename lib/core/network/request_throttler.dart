import 'dart:async';

import '../constants/api_constants.dart';

/// Serializes HTTP calls so we stay within API-Football rate limits.
class RequestThrottler {
  RequestThrottler({
    this.minInterval = ApiConstants.requestThrottleInterval,
  });

  final Duration minInterval;
  DateTime? _lastRequestAt;
  Future<void>? _chain;

  Future<T> run<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _chain = (_chain ?? Future<void>.value()).then((_) async {
      final now = DateTime.now();
      if (_lastRequestAt != null) {
        final elapsed = now.difference(_lastRequestAt!);
        final wait = minInterval - elapsed;
        if (wait > Duration.zero) {
          await Future<void>.delayed(wait);
        }
      }
      _lastRequestAt = DateTime.now();
      try {
        completer.complete(await action());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }
}
