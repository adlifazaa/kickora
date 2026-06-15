import 'package:flutter/foundation.dart';

import 'ad_placement.dart';
import 'ad_unit_ids.dart';
import 'admob_environment.dart';

/// AdMob runtime configuration — production units in release builds.
class AdConfig {
  AdConfig._();

  /// Release builds ship with real AdMob units enabled by default.
  static bool get productionAdsEnabled =>
      kReleaseMode ||
      const bool.fromEnvironment(
        'KICKORA_ADS_ENABLED',
        defaultValue: false,
      );

  /// When true, MobileAds initializes and real ad requests are sent.
  /// Debug APKs include this so verification works without dart-defines.
  static bool get adsSdkEnabled => productionAdsEnabled || kDebugMode;

  static String get androidAppId => AdUnitIds.androidAppId;

  static String get bannerUnitId => AdUnitIds.banner;

  static String get interstitialUnitId => AdUnitIds.interstitial;

  /// Native units remain optional (banner + interstitial are production defaults).
  static String nativeUnitId(AdPlacement placement) =>
      AdMobEnvironment.nativeUnitId(placement);
}
