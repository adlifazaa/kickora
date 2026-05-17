import 'ad_placement.dart';

/// Remote-config placeholders (Firebase Remote Config / dart-define later).
///
/// Defaults: all ads off, native-only when explicitly enabled — no popups.
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
    this.maxInterstitialsPerSession = 0,
  });

  /// MVP default — no placeholders, no real ads.
  factory AdRemoteConfig.defaults() => const AdRemoteConfig();

  factory AdRemoteConfig.disabled() => const AdRemoteConfig();

  final bool adsMasterEnabled;
  final bool showPlaceholderSlots;
  final bool nativeEnabled;

  final bool matchListNativeEnabled;
  final bool competitionListNativeEnabled;
  final bool scrollBottomNativeEnabled;

  final int feedNativeInterval;
  final int maxNativeImpressionsPerSession;

  /// Non-native formats — always off for Kickora MVP.
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
      AdPlacement.homeBanner => false,
    };
  }

  bool placementEnabled(AdPlacement placement) =>
      nativePlacementEnabled(placement);

  bool allowsRealAds(AdPlacement placement) {
    if (!adsMasterEnabled || !nativeEnabled) return false;
    if (!placement.isNativeSlot &&
        placement != AdPlacement.feedNative &&
        placement != AdPlacement.competitionsNative &&
        placement != AdPlacement.matchDetailsNative) {
      return false;
    }
    return nativePlacementEnabled(placement);
  }
}
