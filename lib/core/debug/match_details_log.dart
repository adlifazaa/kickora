import 'package:flutter/foundation.dart';

/// Debug-only logs for match details data flow (never log secrets).
void logMatchDetails(String message) {
  if (kDebugMode) {
    debugPrint('[MatchDetails] $message');
  }
}

void logMatchDetailsEndpoint({
  required int matchId,
  required String league,
  required String endpoint,
  required int statusCode,
  required int itemCount,
  required bool empty,
  required bool failed,
}) {
  if (!kDebugMode) return;
  final outcome = failed
      ? 'failed'
      : (empty ? 'empty' : 'ok');
  debugPrint(
    '[MatchDetails] matchId=$matchId league=$league endpoint=$endpoint '
    'status=$statusCode count=$itemCount outcome=$outcome',
  );
}
