import 'ad_placement.dart';

/// Google AdMob **test** unit IDs (safe default for dev, tests, and mock mode).
class AdUnitIds {
  AdUnitIds._();

  static const String testAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';

  static const String banner = 'ca-app-pub-3940256099942544/6300978111';

  static const String native = 'ca-app-pub-3940256099942544/2247696110';

  static const String nativeMatchList = native;

  static const String nativeCompetition = native;

  static const String nativeScrollBottom = native;

  static String nativeFor(AdPlacement placement) {
    switch (placement) {
      case AdPlacement.matchListNative:
      case AdPlacement.feedNative:
        return nativeMatchList;
      case AdPlacement.competitionListNative:
      case AdPlacement.competitionsNative:
        return nativeCompetition;
      case AdPlacement.scrollBottomNative:
        return nativeScrollBottom;
      default:
        return native;
    }
  }

  static const String interstitial = 'ca-app-pub-3940256099942544/1033173712';

  static const String rewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const String appOpen = 'ca-app-pub-3940256099942544/9257395921';
}
