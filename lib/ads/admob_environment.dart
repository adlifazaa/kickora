import 'admob_generated_config.dart';
import 'ad_placement.dart';
import 'ad_unit_ids.dart';

/// AdMob IDs from local config ([AdMobGeneratedConfig]) or `--dart-define` only.
abstract final class AdMobEnvironment {
  static const String nativeMainKey = 'kickora_native_main';
  static const String nativeFeedKey = 'kickora_native_feed';

  static const String _androidAppIdDefine = String.fromEnvironment(
    'KICKORA_ADMOB_ANDROID_APP_ID',
    defaultValue: '',
  );

  static const String _nativeMainDefine = String.fromEnvironment(
    'KICKORA_AD_NATIVE_MAIN',
    defaultValue: '',
  );

  static const String _nativeFeedDefine = String.fromEnvironment(
    'KICKORA_AD_NATIVE_FEED',
    defaultValue: '',
  );

  static String get androidAppId => _firstNonEmpty([
        _androidAppIdDefine,
        AdMobGeneratedConfig.androidAppId,
        AdUnitIds.androidAppId,
      ]);

  static String get nativeMain => _firstNonEmpty([
        _nativeMainDefine,
        AdMobGeneratedConfig.kickoraNativeMain,
      ]);

  static String get nativeFeed => _firstNonEmpty([
        _nativeFeedDefine,
        AdMobGeneratedConfig.kickoraNativeFeed,
      ]);

  static bool get hasProductionNativeUnits =>
      nativeMain.isNotEmpty && nativeFeed.isNotEmpty;

  static String nativeUnitId(AdPlacement placement) {
    final main = nativeMain;
    final feed = nativeFeed;
    return switch (placement) {
      AdPlacement.matchListNative || AdPlacement.feedNative =>
        feed.isNotEmpty ? feed : main,
      AdPlacement.competitionListNative ||
      AdPlacement.competitionsNative ||
      AdPlacement.scrollBottomNative ||
      AdPlacement.matchDetailsNative =>
        main.isNotEmpty ? main : feed,
      _ => main.isNotEmpty ? main : feed,
    };
  }

  static String get effectiveAndroidAppId => androidAppId;

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}
