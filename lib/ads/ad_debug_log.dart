import 'package:flutter/foundation.dart';

import 'ad_placement.dart';

/// Debug-only AdMob logs (no user IDs, ad unit secrets, or device tokens).
class AdDebugLog {
  AdDebugLog._();

  static void initialized({
    required bool adsEnabled,
    required bool nativeOnly,
    required bool placeholders,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[Kickora Ads] initialized enabled=$adsEnabled nativeOnly=$nativeOnly '
      'placeholders=$placeholders',
    );
  }

  static void placementPrepared(AdPlacement placement) {
    if (!kDebugMode) return;
    debugPrint('[Kickora Ads] placement prepared → ${placement.name}');
  }

  static void nativeLoadSkipped(AdPlacement placement, {String? reason}) {
    if (!kDebugMode) return;
    final extra = reason != null ? ' ($reason)' : '';
    debugPrint('[Kickora Ads] native load skipped ${placement.name}$extra');
  }

  static void nativeLoaded(AdPlacement placement) {
    if (!kDebugMode) return;
    debugPrint('[Kickora Ads] native loaded → ${placement.name}');
  }

  static void nativeLoadFailed(AdPlacement placement, String message) {
    if (!kDebugMode) return;
    debugPrint('[Kickora Ads] native failed ${placement.name}: $message');
  }
}
