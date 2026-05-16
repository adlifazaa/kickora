import 'package:flutter/foundation.dart';

import '../ad_placement.dart';
import '../ad_remote_config.dart';
import '../ad_unit_ids.dart';

/// Loads and tracks anchored banner units (mock until AdMob SDK is added).
class BannerAdManager {
  BannerAdManager(this._config);

  AdRemoteConfig _config;
  bool _loaded = false;

  void updateConfig(AdRemoteConfig config) => _config = config;

  String get unitId => AdUnitIds.banner;

  bool get isLoaded => _loaded;

  Future<void> load(AdPlacement placement) async {
    if (!_config.placementEnabled(placement)) return;
    if (_config.adsMasterEnabled && !_config.bannerEnabled) return;
  // TODO(admob): BannerAd.load(adUnitId: unitId, ...)
    _loaded = true;
    if (kDebugMode && _config.adsMasterEnabled) {
      debugPrint('[Kickora Ads] banner loaded ($unitId)');
    }
  }

  Future<void> dispose() async {
    _loaded = false;
  // TODO(admob): _bannerAd?.dispose()
  }
}
