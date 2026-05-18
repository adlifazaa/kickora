import 'package:flutter/foundation.dart';

/// Debug-only competition logs (never log API keys or secrets).
void logCompetitionDebug({
  required String name,
  required String country,
  required String filterSelected,
  required bool logoExists,
}) {
  if (!kDebugMode) return;
  debugPrint(
    '[Kickora Competition] name=$name country=$country '
    'filter=$filterSelected logoExists=$logoExists',
  );
}
