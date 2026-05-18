/// AdMob runtime flags (test IDs by default).
class AdConfig {
  AdConfig._();

  /// Master switch for real AdMob loads (default off).
  static const bool productionAdsEnabled = bool.fromEnvironment(
    'KICKORA_ADS_ENABLED',
    defaultValue: false,
  );

  static bool get useTestAdUnits => !productionAdsEnabled;
}
