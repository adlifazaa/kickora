import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_debug_log.dart';
import 'ad_frequency_controller.dart';
import 'ad_placement.dart';
import 'ad_remote_config.dart';
import '../subscription/premium_subscription_service.dart';
import 'managers/native_ad_manager.dart';

/// Central AdMob orchestrator — **native placements only**, disabled by default.
class AdService {
  AdService._internal();
  static final AdService instance = AdService._internal();
  factory AdService() => instance;

  AdRemoteConfig _config = AdRemoteConfig.defaults();
  late final AdFrequencyController _frequency = AdFrequencyController(_config);
  late final NativeAdManager _native = NativeAdManager(_config);

  bool _initialized = false;
  PremiumSubscriptionService? _premium;

  bool get isInitialized => _initialized;
  AdRemoteConfig get config => _config;
  NativeAdManager get native => _native;

  void bindPremium(PremiumSubscriptionService premium) {
    _premium = premium;
  }

  bool get _suppressAds => _premium?.isPremium ?? false;

  bool get adsEnabled =>
      !_suppressAds && (_config.showPlaceholderSlots || _config.adsMasterEnabled);

  /// Call once at app startup.
  Future<void> initialize({AdRemoteConfig? remoteConfig}) async {
    if (_initialized) return;
    if (remoteConfig != null) {
      await updateRemoteConfig(remoteConfig);
    }
    if (AdConfig.productionAdsEnabled) {
      try {
        await MobileAds.instance.initialize();
      } catch (e) {
        AdDebugLog.nativeLoadSkipped(
          AdPlacement.feedNative,
          reason: 'MobileAds init failed',
        );
      }
    }
    await _native.prepareAllNativePlacements();
    _initialized = true;
    AdDebugLog.initialized(
      adsEnabled: adsEnabled,
      nativeOnly: true,
      placeholders: _config.showPlaceholderSlots,
    );
  }

  Future<void> updateRemoteConfig(AdRemoteConfig config) async {
    _config = config;
    _frequency.updateConfig(config);
    _native.updateConfig(config);
  }

  bool shouldShowPlaceholder(AdPlacement placement, {int? feedItemIndex}) {
    if (_suppressAds) return false;
    if (!placement.isNativeSlot &&
        placement != AdPlacement.feedNative &&
        placement != AdPlacement.competitionsNative) {
      return false;
    }
    if (!_config.placementEnabled(placement)) return false;
    return _frequency.canShowPlacement(
      placement,
      feedItemIndex: feedItemIndex,
    );
  }

  bool shouldShowRealAd(AdPlacement placement) {
    if (_suppressAds) return false;
    return _config.allowsRealAds(placement);
  }

  void recordPlaceholderImpression(AdPlacement placement) {
    _frequency.recordImpression(placement);
  }

  /// Interstitials disabled for MVP — no-op.
  Future<void> onNavigationAction() async {}

  Future<void> dispose() async {
    await _native.dispose();
    _initialized = false;
  }
}
