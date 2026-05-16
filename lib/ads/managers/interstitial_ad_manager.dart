import 'package:flutter/foundation.dart';

import '../ad_frequency_controller.dart';
import '../ad_remote_config.dart';
import '../ad_unit_ids.dart';

/// Full-screen interstitial (mock — never shown while [AdRemoteConfig.adsMasterEnabled] is false).
class InterstitialAdManager {
  InterstitialAdManager(this._config, this._frequency);

  AdRemoteConfig _config;
  final AdFrequencyController _frequency;

  bool _ready = false;

  void updateConfig(AdRemoteConfig config) => _config = config;

  String get unitId => AdUnitIds.interstitial;

  bool get isReady => _ready;

  Future<void> preload() async {
    if (!_config.interstitialEnabled && !_config.adsMasterEnabled) return;
  // TODO(admob): InterstitialAd.load(adUnitId: unitId, ...)
    _ready = true;
  }

  Future<bool> showIfAllowed() async {
    if (!_config.adsMasterEnabled) return false;
    if (!_frequency.canShowInterstitial() || !_ready) return false;
  // TODO(admob): await _interstitial?.show()
    _frequency.recordInterstitialShown();
    _ready = false;
    if (kDebugMode) {
      debugPrint('[Kickora Ads] interstitial shown (mock)');
    }
    await preload();
    return true;
  }

  Future<void> dispose() async {
    _ready = false;
  }
}
