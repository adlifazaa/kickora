import 'package:flutter/foundation.dart';

import '../ad_debug_log.dart';
import '../ad_placement.dart';
import '../ad_remote_config.dart';

/// Native AdMob loads only — no banners, interstitials, or rewarded (Phase 5).
class NativeAdManager {
  NativeAdManager(this._config);

  AdRemoteConfig _config;
  final Set<AdPlacement> _prepared = {};

  void updateConfig(AdRemoteConfig config) => _config = config;

  String unitIdFor(AdPlacement placement) => '';

  bool canPrepare(AdPlacement placement) {
    if (!_config.nativePlacementEnabled(placement)) return false;
    if (!_config.adsMasterEnabled && !_config.showPlaceholderSlots) {
      return false;
    }
    return true;
  }

  /// Registers a placement for future native loads (no UI widget yet).
  Future<void> prepare(AdPlacement placement) async {
    if (!canPrepare(placement)) {
      AdDebugLog.nativeLoadSkipped(placement, reason: 'disabled');
      return;
    }
    if (_prepared.contains(placement)) return;

    _prepared.add(placement);
    AdDebugLog.placementPrepared(placement);

    if (_config.adsMasterEnabled) {
      // TODO(admob): NativeAd.load(adUnitId: unitIdFor(placement), ...)
      if (kDebugMode) {
        debugPrint('[Kickora Ads] native placement reserved (not shown)');
      }
    }
  }

  Future<void> prepareAllNativePlacements() async {
    for (final placement in AdPlacementX.nativePlacements) {
      await prepare(placement);
    }
  }

  Future<void> dispose() async {
    _prepared.clear();
  }
}
