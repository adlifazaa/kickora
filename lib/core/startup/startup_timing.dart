import 'package:flutter/foundation.dart';

/// Debug timing markers for cold-start investigation (no secrets logged).
class StartupTiming {
  StartupTiming._();

  static final Map<String, int> _marksMs = {};
  static int? _originMs;

  static void mark(String label) {
    if (!kDebugMode) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _originMs ??= now;
    _marksMs[label] = now - (_originMs ?? now);
    debugPrint('[Kickora Startup] $label +${_marksMs[label]}ms');
  }

  @visibleForTesting
  static void reset() {
    _marksMs.clear();
    _originMs = null;
  }

  @visibleForTesting
  static int? elapsedMs(String label) => _marksMs[label];
}
