import 'ad_placement.dart';
import 'ad_unit_ids.dart';

/// AdMob runtime flags (Google test IDs by default).
class AdConfig {
  AdConfig._();

  /// Master switch for real AdMob loads (default off).
  static const bool productionAdsEnabled = bool.fromEnvironment(
    'KICKORA_ADS_ENABLED',
    defaultValue: false,
  );

  static bool get useTestAdUnits => !productionAdsEnabled;

  /// Native unit for a placement (test or production via dart-define).
  static String nativeUnitId(AdPlacement placement) {
    if (useTestAdUnits) {
      return AdUnitIds.nativeFor(placement);
    }
    final prod = switch (placement) {
      AdPlacement.matchListNative || AdPlacement.feedNative =>
        _prodMatchList,
      AdPlacement.competitionListNative ||
      AdPlacement.competitionsNative =>
        _prodCompetition,
      AdPlacement.scrollBottomNative => _prodScrollBottom,
      _ => _prodNativeDefault,
    };
    if (prod.trim().isNotEmpty) return prod;
    return AdUnitIds.nativeFor(placement);
  }

  static const String _prodMatchList = String.fromEnvironment(
    'KICKORA_AD_NATIVE_MATCH_LIST_PROD',
    defaultValue: '',
  );

  static const String _prodCompetition = String.fromEnvironment(
    'KICKORA_AD_NATIVE_COMPETITION_PROD',
    defaultValue: '',
  );

  static const String _prodScrollBottom = String.fromEnvironment(
    'KICKORA_AD_NATIVE_SCROLL_PROD',
    defaultValue: '',
  );

  static const String _prodNativeDefault = String.fromEnvironment(
    'KICKORA_AD_NATIVE_PROD',
    defaultValue: '',
  );
}
