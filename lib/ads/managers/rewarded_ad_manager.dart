import 'package:flutter/foundation.dart';

import '../ad_remote_config.dart';

/// Rewarded video (mock — for future premium unlocks / bonus content).
class RewardedAdManager {
  RewardedAdManager(this._config);

  AdRemoteConfig _config;

  bool _ready = false;

  void updateConfig(AdRemoteConfig config) => _config = config;

  String get unitId => '';

  bool get isReady => _ready;

  Future<void> preload() async {
    if (!_config.rewardedEnabled && !_config.adsMasterEnabled) return;
  // TODO(admob): RewardedAd.load(adUnitId: unitId, ...)
    _ready = true;
  }

  Future<bool> show({required VoidCallback onReward}) async {
    if (!_config.adsMasterEnabled || !_ready) return false;
  // TODO(admob): show rewarded; onUserEarnedReward → onReward()
    if (kDebugMode) {
      debugPrint('[Kickora Ads] rewarded completed (mock)');
    }
    onReward();
    _ready = false;
    await preload();
    return true;
  }

  Future<void> dispose() async {
    _ready = false;
  }
}
