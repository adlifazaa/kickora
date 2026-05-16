import 'package:flutter/foundation.dart';

import 'ad_frequency_controller.dart';
import 'ad_placement.dart';
import 'ad_remote_config.dart';
import '../subscription/premium_subscription_service.dart';
import 'managers/banner_ad_manager.dart';
import 'managers/interstitial_ad_manager.dart';
import 'managers/rewarded_ad_manager.dart';

/// Central AdMob orchestrator — placeholders only until [AdRemoteConfig.adsMasterEnabled].
class AdService {
  AdService._internal();
  static final AdService instance = AdService._internal();
  factory AdService() => instance;

  AdRemoteConfig _config = AdRemoteConfig.defaults();
  late final AdFrequencyController _frequency = AdFrequencyController(_config);
  late final BannerAdManager _banners = BannerAdManager(_config);
  late final InterstitialAdManager _interstitials =
      InterstitialAdManager(_config, _frequency);
  late final RewardedAdManager _rewarded = RewardedAdManager(_config);

  bool _initialized = false;
  PremiumSubscriptionService? _premium;

  bool get isInitialized => _initialized;
  AdRemoteConfig get config => _config;
  BannerAdManager get banners => _banners;
  InterstitialAdManager get interstitials => _interstitials;
  RewardedAdManager get rewarded => _rewarded;

  /// Links premium state so ad placeholders hide when [PremiumSubscriptionService.isPremium].
  void bindPremium(PremiumSubscriptionService premium) {
    _premium = premium;
  }

  bool get _suppressAds => _premium?.isPremium ?? false;

  /// Call once at app startup.
  Future<void> initialize({AdRemoteConfig? remoteConfig}) async {
    if (_initialized) return;
    if (remoteConfig != null) {
      await updateRemoteConfig(remoteConfig);
    }
  // TODO(admob): await MobileAds.instance.initialize();
    await _banners.load(AdPlacement.homeBanner);
    await _interstitials.preload();
    await _rewarded.preload();
    _initialized = true;
    if (kDebugMode) {
      debugPrint(
        '[Kickora Ads] initialized placeholders=${_config.showPlaceholderSlots} '
        'liveAds=${_config.adsMasterEnabled}',
      );
    }
  }

  Future<void> updateRemoteConfig(AdRemoteConfig config) async {
    _config = config;
    _frequency.updateConfig(config);
    _banners.updateConfig(config);
    _interstitials.updateConfig(config);
    _rewarded.updateConfig(config);
  }

  bool shouldShowPlaceholder(AdPlacement placement, {int? feedItemIndex}) {
    if (_suppressAds) return false;
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

  Future<void> onNavigationAction() async {
    if (_suppressAds) return;
    await _interstitials.showIfAllowed();
  }

  Future<void> dispose() async {
    await _banners.dispose();
    await _interstitials.dispose();
    await _rewarded.dispose();
    _initialized = false;
  }
}
