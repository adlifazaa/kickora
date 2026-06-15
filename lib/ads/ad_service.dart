import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_debug_log.dart';
import 'ad_frequency_controller.dart';
import 'ad_placement.dart';
import 'ad_remote_config.dart';
import '../subscription/premium_subscription_service.dart';
import 'managers/interstitial_ad_manager.dart';
import 'managers/native_ad_manager.dart';

/// Central AdMob orchestrator — production banner + interstitial in release.
class AdService with WidgetsBindingObserver, ChangeNotifier {
  AdService._internal();
  static final AdService instance = AdService._internal();
  factory AdService() => instance;

  AdRemoteConfig _config = AdRemoteConfig.defaults();
  late final AdFrequencyController _frequency = AdFrequencyController(_config);
  late final NativeAdManager _native = NativeAdManager(_config);
  late final InterstitialAdManager _interstitial =
      InterstitialAdManager(_config);

  bool _configured = false;
  bool _sdkReady = false;
  bool _sdkInitStarted = false;
  bool _deferredScheduled = false;
  bool _observerRegistered = false;
  PremiumSubscriptionService? _premium;

  bool get isInitialized => _configured;
  bool get sdkReady => _sdkReady;
  AdRemoteConfig get config => _config;
  NativeAdManager get native => _native;

  void bindPremium(PremiumSubscriptionService premium) {
    _premium = premium;
  }

  bool get _suppressAds => _premium?.isPremium ?? false;

  bool get adsEnabled =>
      !_suppressAds &&
      _config.adsMasterEnabled &&
      (AdConfig.adsSdkEnabled || _config.showPlaceholderSlots);

  /// Lightweight config only — safe before [runApp] (tests / manual init).
  Future<void> initialize({AdRemoteConfig? remoteConfig}) async {
    if (_configured) return;
    _applyConfig(remoteConfig);
    _configured = true;
    await _startMobileAds();
  }

  /// Defers SDK init until after the first frame on the main navigation screen.
  void scheduleDeferredInitialize({AdRemoteConfig? remoteConfig}) {
    if (_deferredScheduled || _configured) return;
    _deferredScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(initialize(remoteConfig: remoteConfig));
    });
  }

  void _applyConfig(AdRemoteConfig? remoteConfig) {
    _config = remoteConfig ??
        (AdConfig.adsSdkEnabled
            ? AdRemoteConfig.production()
            : AdRemoteConfig.defaults());
    _frequency.updateConfig(_config);
    _native.updateConfig(_config);
    _interstitial.updateConfig(_config);
  }

  Future<void> _startMobileAds() async {
    if (_sdkInitStarted) return;
    _sdkInitStarted = true;

    if (!_observerRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _observerRegistered = true;
    }

    if (!_suppressAds && _config.adsMasterEnabled && AdConfig.adsSdkEnabled) {
      try {
        AdDebugLog.mobileAdsInitStarted();
        await MobileAds.instance.initialize();
        _sdkReady = true;
        notifyListeners();
        AdDebugLog.mobileAdsInitComplete();
        unawaited(_interstitial.preload());
      } catch (e) {
        AdDebugLog.initFailed(e.toString());
      }
    } else {
      AdDebugLog.mobileAdsInitSkipped(
        adsMasterEnabled: _config.adsMasterEnabled,
        sdkEnabled: AdConfig.adsSdkEnabled,
        suppressAds: _suppressAds,
      );
    }

    unawaited(_native.prepareAllNativePlacements());
    notifyListeners();
    AdDebugLog.initialized(
      adsEnabled: adsEnabled,
      nativeOnly: false,
      placeholders: _config.showPlaceholderSlots,
      sdkEnabled: AdConfig.adsSdkEnabled,
      sdkReady: _sdkReady,
    );
  }

  Future<void> updateRemoteConfig(AdRemoteConfig config) async {
    _config = config;
    _frequency.updateConfig(config);
    _native.updateConfig(config);
    _interstitial.updateConfig(config);
    notifyListeners();
  }

  bool shouldShowBanner(AdPlacement placement) {
    if (_suppressAds) return false;
    if (!placement.isTopBanner) return false;
    return _config.placementEnabled(placement);
  }

  bool shouldShowPlaceholder(AdPlacement placement, {int? feedItemIndex}) {
    if (_suppressAds) return false;
    if (!placement.isNativeSlot &&
        placement != AdPlacement.feedNative &&
        placement != AdPlacement.competitionsNative) {
      return false;
    }
    if (!_config.placementEnabled(placement)) return false;
    return _frequency.canShowPlacement(
      placement,
      feedItemIndex: feedItemIndex,
    );
  }

  bool shouldShowRealAd(AdPlacement placement) {
    if (_suppressAds) return false;
    return _config.allowsRealAds(placement);
  }

  void recordPlaceholderImpression(AdPlacement placement) {
    _frequency.recordImpression(placement);
  }

  /// Interstitial after meaningful main-tab navigation (not favorites / startup).
  Future<void> onMainTabChanged({required int from, required int to}) async {
    if (!_sdkReady || _suppressAds || !_config.interstitialEnabled) {
      return;
    }
    const favoritesIndex = 3;
    if (from == favoritesIndex || to == favoritesIndex) return;

    const majorTabs = {0, 1, 2, 4};
    if (!majorTabs.contains(from) || !majorTabs.contains(to) || from == to) {
      return;
    }

    await _interstitial.showIfAllowed();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _interstitial.markBackgrounded();
    }
  }

  Future<void> shutdown() async {
    if (_observerRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _observerRegistered = false;
    }
    await _interstitial.dispose();
    await _native.dispose();
    _configured = false;
    _sdkReady = false;
    _sdkInitStarted = false;
    _deferredScheduled = false;
  }
}
