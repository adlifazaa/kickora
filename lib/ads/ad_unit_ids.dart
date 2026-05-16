/// Demo AdMob unit IDs — replace with real IDs before release.
///
/// Never commit production ad unit IDs to public repos; prefer `--dart-define`
/// or secure CI injection when enabling [AdRemoteConfig.adsMasterEnabled].
class AdUnitIds {
  AdUnitIds._();

  static const String banner = String.fromEnvironment(
    'KICKORA_AD_BANNER',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111',
  );

  static const String native = String.fromEnvironment(
    'KICKORA_AD_NATIVE',
    defaultValue: 'ca-app-pub-3940256099942544/2247696110',
  );

  static const String interstitial = String.fromEnvironment(
    'KICKORA_AD_INTERSTITIAL',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );

  static const String rewarded = String.fromEnvironment(
    'KICKORA_AD_REWARDED',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917',
  );

  static const String appOpen = String.fromEnvironment(
    'KICKORA_AD_APP_OPEN',
    defaultValue: 'ca-app-pub-3940256099942544/9257395921',
  );
}
