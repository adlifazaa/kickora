import 'ad_placement.dart';

/// Remote-config placeholders (Firebase Remote Config / similar later).
///
/// Defaults keep premium placeholder slots visible but block real AdMob loads.
class AdRemoteConfig {
  const AdRemoteConfig({
    this.adsMasterEnabled = false,
    this.showPlaceholderSlots = true,
    this.bannerEnabled = false,
    this.nativeEnabled = false,
    this.interstitialEnabled = false,
    this.rewardedEnabled = false,
    this.appOpenEnabled = false,
    this.homeBannerEnabled = true,
    this.matchDetailsNativeEnabled = false,
    this.competitionsNativeEnabled = false,
    this.feedNativeEnabled = true,
    this.feedNativeInterval = 4,
    this.interstitialEveryNActions = 5,
    this.maxInterstitialsPerSession = 3,
    this.maxNativeImpressionsPerSession = 12,
  });

  factory AdRemoteConfig.defaults() => const AdRemoteConfig();

  /// All slots off — for tests or strict no-ads mode.
  factory AdRemoteConfig.disabled() => const AdRemoteConfig(
        showPlaceholderSlots: false,
        homeBannerEnabled: false,
        feedNativeEnabled: false,
      );

  final bool adsMasterEnabled;
  final bool showPlaceholderSlots;
  final bool bannerEnabled;
  final bool nativeEnabled;
  final bool interstitialEnabled;
  final bool rewardedEnabled;
  final bool appOpenEnabled;

  final bool homeBannerEnabled;
  final bool matchDetailsNativeEnabled;
  final bool competitionsNativeEnabled;
  final bool feedNativeEnabled;

  final int feedNativeInterval;
  final int interstitialEveryNActions;
  final int maxInterstitialsPerSession;
  final int maxNativeImpressionsPerSession;

  bool placementEnabled(AdPlacement placement) {
    if (!showPlaceholderSlots && !adsMasterEnabled) return false;
    return switch (placement) {
      AdPlacement.homeBanner => homeBannerEnabled,
      AdPlacement.matchDetailsNative => matchDetailsNativeEnabled,
      AdPlacement.competitionsNative => competitionsNativeEnabled,
      AdPlacement.feedNative => feedNativeEnabled,
    };
  }

  bool allowsRealAds(AdPlacement placement) {
    if (!adsMasterEnabled) return false;
    return switch (placement) {
      AdPlacement.homeBanner => bannerEnabled,
      AdPlacement.matchDetailsNative ||
      AdPlacement.competitionsNative ||
      AdPlacement.feedNative =>
        nativeEnabled,
    };
  }
}
