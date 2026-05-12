/// Thin scaffolding for Google AdMob integration.
/// Real ad unit IDs and SDK calls (e.g. `google_mobile_ads`) are intentionally
/// not wired yet. Replace each TODO when AdMob is enabled.
class AdService {
  AdService._internal();
  static final AdService instance = AdService._internal();
  factory AdService() => instance;

  // ---------------- Demo placeholder IDs ----------------
  static const String bannerAdUnitId = 'demo-banner-id';
  static const String nativeAdUnitId = 'demo-native-id';
  static const String interstitialAdUnitId = 'demo-interstitial-id';
  static const String rewardedAdUnitId = 'demo-rewarded-id';
  static const String appOpenAdUnitId = 'demo-app-open-id';

  bool _initialized = false;
  bool _interstitialReady = false;
  bool _appOpenReady = false;
  int _interstitialFrequencyTaps = 0;

  bool get isInitialized => _initialized;
  bool get isInterstitialReady => _interstitialReady;
  bool get isAppOpenReady => _appOpenReady;

  /// Call once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    // TODO(admob): MobileAds.instance.initialize();
    _initialized = true;
  }

  /// Preload an interstitial so it can be shown without delay.
  Future<void> preloadInterstitial() async {
    // TODO(admob): InterstitialAd.load(...)
    _interstitialReady = true;
  }

  /// Show interstitial only every N taps to avoid spam.
  Future<void> showInterstitialIfReady({int frequency = 4}) async {
    _interstitialFrequencyTaps++;
    if (_interstitialFrequencyTaps % frequency != 0) return;
    if (!_interstitialReady) return;
    // TODO(admob): _interstitial?.show()
    _interstitialReady = false;
    await preloadInterstitial();
  }

  Future<void> preloadAppOpen() async {
    // TODO(admob): AppOpenAd.load(...)
    _appOpenReady = true;
  }

  Future<void> showAppOpenAdIfReady() async {
    if (!_appOpenReady) return;
    // TODO(admob): _appOpenAd?.show()
    _appOpenReady = false;
    await preloadAppOpen();
  }
}
