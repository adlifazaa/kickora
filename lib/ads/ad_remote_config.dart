import 'ad_placement.dart';

/// Remote-config placeholders (Firebase Remote Config / dart-define later).
class AdRemoteConfig {
  const AdRemoteConfig({
    this.adsMasterEnabled = false,
    this.showPlaceholderSlots = false,
    this.nativeEnabled = false,
    this.matchListNativeEnabled = false,
    this.competitionListNativeEnabled = false,
    this.scrollBottomNativeEnabled = false,
    this.feedNativeInterval = 4,
    this.maxNativeImpressionsPerSession = 12,
    this.bannerEnabled = false,
    this.interstitialEnabled = false,
    this.rewardedEnabled = false,
    this.appOpenEnabled = false,
    this.homeBannerEnabled = false,
    this.matchDetailsNativeEnabled = false,
    this.feedNativeEnabled = false,
    this.competitionsNativeEnabled = false,
    this.interstitialEveryNActions = 5,
    this.maxInterstitialsPerSession = 20,
  });

  /// Debug / tests — no real ads.
  factory AdRemoteConfig.defaults() => const AdRemoteConfig();

  factory AdRemoteConfig.disabled() => const AdRemoteConfig();

  /// Release builds — banner + interstitial only (non-intrusive).
  factory AdRemoteConfig.production() => const AdRemoteConfig(
        adsMasterEnabled: true,
        bannerEnabled: true,
        interstitialEnabled: true,
        showPlaceholderSlots: false,
        nativeEnabled: false,
        maxInterstitialsPerSession: 20,
      );

  final bool adsMasterEnabled;
  final bool showPlaceholderSlots;
  final bool nativeEnabled;

  final bool matchListNativeEnabled;
  final bool competitionListNativeEnabled;
  final bool scrollBottomNativeEnabled;

  final int feedNativeInterval;
  final int maxNativeImpressionsPerSession;

  final bool bannerEnabled;
  final bool interstitialEnabled;
  final bool rewardedEnabled;
  final bool appOpenEnabled;
  final bool homeBannerEnabled;
  final bool matchDetailsNativeEnabled;
  final bool feedNativeEnabled;
  final bool competitionsNativeEnabled;
  final int interstitialEveryNActions;
  final int maxInterstitialsPerSession;

  bool nativePlacementEnabled(AdPlacement placement) {
    if (!showPlaceholderSlots && !adsMasterEnabled) return false;
    return switch (placement) {
      AdPlacement.matchListNative || AdPlacement.feedNative =>
        matchListNativeEnabled || feedNativeEnabled,
      AdPlacement.competitionListNative ||
      AdPlacement.competitionsNative =>
        competitionListNativeEnabled || competitionsNativeEnabled,
      AdPlacement.scrollBottomNative => scrollBottomNativeEnabled,
      AdPlacement.matchDetailsNative => matchDetailsNativeEnabled,
      AdPlacement.homeBanner ||
      AdPlacement.matchesBanner ||
      AdPlacement.competitionsBanner ||
      AdPlacement.standingsBanner =>
        false,
    };
  }

  bool placementEnabled(AdPlacement placement) {
    if (placement.isTopBanner) {
      return adsMasterEnabled && bannerEnabled;
    }
    return nativePlacementEnabled(placement);
  }

  bool allowsRealAds(AdPlacement placement) {
    if (!adsMasterEnabled) return false;
    if (placement.isTopBanner) {
      return bannerEnabled;
    }
    if (!nativeEnabled) return false;
    return nativePlacementEnabled(placement);
  }
}
