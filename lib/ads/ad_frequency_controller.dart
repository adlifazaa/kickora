import 'ad_placement.dart';
import 'ad_remote_config.dart';

/// Session-level caps for native in-feed insertions only.
class AdFrequencyController {
  AdFrequencyController(this._config);

  AdRemoteConfig _config;
  final Map<AdPlacement, int> _impressionCounts = {};

  void updateConfig(AdRemoteConfig config) => _config = config;

  void resetSession() {
    _impressionCounts.clear();
  }

  bool canShowPlacement(
    AdPlacement placement, {
    int? feedItemIndex,
  }) {
    if (!_config.placementEnabled(placement)) return false;

    switch (placement) {
      case AdPlacement.matchListNative:
      case AdPlacement.feedNative:
        if (feedItemIndex == null) return false;
        if (feedItemIndex % _config.feedNativeInterval != 0) return false;
        return _underCap(
          placement,
          _config.maxNativeImpressionsPerSession,
        );
      case AdPlacement.competitionListNative:
      case AdPlacement.competitionsNative:
        if (feedItemIndex == null) return false;
        if (feedItemIndex % (_config.feedNativeInterval + 1) != 0) {
          return false;
        }
        return _underCap(
          placement,
          _config.maxNativeImpressionsPerSession,
        );
      case AdPlacement.scrollBottomNative:
        return _underCap(placement, 1);
      case AdPlacement.matchDetailsNative:
        return _underCap(placement, 1);
      case AdPlacement.homeBanner:
        return false;
    }
  }

  void recordImpression(AdPlacement placement) {
    _impressionCounts[placement] = (_impressionCounts[placement] ?? 0) + 1;
  }

  bool _underCap(AdPlacement placement, int max) {
    return (_impressionCounts[placement] ?? 0) < max;
  }
}
