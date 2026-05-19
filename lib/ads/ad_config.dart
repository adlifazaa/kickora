import 'admob_environment.dart';
import 'ad_placement.dart';
import 'ad_unit_ids.dart';

/// AdMob runtime flags — test units by default; production from local config only.
class AdConfig {
  AdConfig._();

  /// Master switch for real AdMob loads (default off).
  static const bool productionAdsEnabled = bool.fromEnvironment(
    'KICKORA_ADS_ENABLED',
    defaultValue: false,
  );

  static bool get useTestAdUnits =>
      !productionAdsEnabled || !AdMobEnvironment.hasProductionNativeUnits;

  /// Native unit for a placement (Google test or local production config).
  static String nativeUnitId(AdPlacement placement) {
    if (useTestAdUnits) {
      return AdUnitIds.nativeFor(placement);
    }
    final prod = AdMobEnvironment.nativeUnitId(placement);
    if (prod.isNotEmpty) return prod;
    return AdUnitIds.nativeFor(placement);
  }
}
