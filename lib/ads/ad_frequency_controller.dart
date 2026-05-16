import 'ad_placement.dart';
import 'ad_remote_config.dart';

/// Session-level caps so ads never feel aggressive.
class AdFrequencyController {
  AdFrequencyController(this._config);

  AdRemoteConfig _config;
  final Map<AdPlacement, int> _impressionCounts = {};
  int _interstitialActionCount = 0;
  int _interstitialShownThisSession = 0;

  void updateConfig(AdRemoteConfig config) => _config = config;

  void resetSession() {
    _impressionCounts.clear();
    _interstitialActionCount = 0;
    _interstitialShownThisSession = 0;
  }

  bool canShowPlacement(
    AdPlacement placement, {
    int? feedItemIndex,
  }) {
    if (!_config.placementEnabled(placement)) return false;

    switch (placement) {
      case AdPlacement.homeBanner:
        return true;
      case AdPlacement.feedNative:
        if (feedItemIndex == null) return false;
        if (feedItemIndex % _config.feedNativeInterval != 0) return false;
        return _underCap(
          placement,
          _config.maxNativeImpressionsPerSession,
        );
      case AdPlacement.competitionsNative:
        if (feedItemIndex == null) return false;
        if (feedItemIndex % (_config.feedNativeInterval + 1) != 0) {
          return false;
        }
        return _underCap(
          placement,
          _config.maxNativeImpressionsPerSession,
        );
      case AdPlacement.matchDetailsNative:
        return _underCap(placement, 1);
    }
  }

  bool canShowInterstitial() {
    if (!_config.interstitialEnabled && !_config.adsMasterEnabled) {
      return false;
    }
    if (_interstitialShownThisSession >= _config.maxInterstitialsPerSession) {
      return false;
    }
    _interstitialActionCount++;
    return _interstitialActionCount % _config.interstitialEveryNActions == 0;
  }

  void recordImpression(AdPlacement placement) {
    _impressionCounts[placement] = (_impressionCounts[placement] ?? 0) + 1;
  }

  void recordInterstitialShown() {
    _interstitialShownThisSession++;
  }

  bool _underCap(AdPlacement placement, int max) {
    return (_impressionCounts[placement] ?? 0) < max;
  }
}
