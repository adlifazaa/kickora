import 'admob_environment.dart';

/// Local AdMob configuration layer (not used directly in widgets).
///
/// Production values live in [config/admob.local.json] (gitignored) under:
/// - `KICKORA_ADMOB_ANDROID_APP_ID`
/// - `KICKORA_AD_NATIVE_MAIN` → logical name [nativeMainKey]
/// - `KICKORA_AD_NATIVE_FEED` → logical name [nativeFeedKey]
abstract final class AdMobLocalConfig {
  static String get androidAppId => AdMobEnvironment.androidAppId;

  static String get kickoraNativeMain => AdMobEnvironment.nativeMain;

  static String get kickoraNativeFeed => AdMobEnvironment.nativeFeed;

  static String get nativeMainKey => AdMobEnvironment.nativeMainKey;

  static String get nativeFeedKey => AdMobEnvironment.nativeFeedKey;
}
