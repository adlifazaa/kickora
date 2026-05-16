import 'package:flutter/foundation.dart';

/// Debug-only logs for match details data flow (never log secrets).
void logMatchDetails(String message) {
  if (kDebugMode) {
    debugPrint('[MatchDetails] $message');
  }
}
