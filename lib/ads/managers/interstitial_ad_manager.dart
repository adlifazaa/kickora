import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_config.dart';
import '../ad_debug_log.dart';
import '../ad_remote_config.dart';
import '../ad_unit_ids.dart';

/// Full-screen interstitials with a strict 5-minute cooldown.
class InterstitialAdManager {
  InterstitialAdManager(AdRemoteConfig config) : _config = config;

  AdRemoteConfig _config;
  InterstitialAd? _ad;
  bool _loading = false;
  int _shownThisSession = 0;
  DateTime? _lastShownAt;
  DateTime? _lastBackgroundAt;

  static const Duration minInterval = Duration(minutes: 5);
  static const Duration resumeGrace = Duration(seconds: 45);

  void updateConfig(AdRemoteConfig config) => _config = config;

  String get unitId => AdUnitIds.interstitial;

  void markBackgrounded() {
    _lastBackgroundAt = DateTime.now();
  }

  Future<void> preload() async {
    if (!_config.adsMasterEnabled || !_config.interstitialEnabled) return;
    if (_ad != null || _loading) return;
    _loading = true;
    AdDebugLog.interstitialLoadRequested(AdConfig.interstitialUnitId);
    final completer = Completer<void>();
    await InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          AdDebugLog.interstitialLoaded();
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              unawaited(preload());
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              AdDebugLog.interstitialShowFailed(
                code: error.code,
                message: error.message,
              );
              ad.dispose();
              _ad = null;
              unawaited(preload());
            },
          );
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          AdDebugLog.interstitialLoadFailed(
            code: error.code,
            message: error.message,
            domain: error.domain,
          );
          _loading = false;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    await completer.future;
  }

  Future<bool> showIfAllowed() async {
    if (!_config.adsMasterEnabled || !_config.interstitialEnabled) {
      return false;
    }
    if (_shownThisSession >= _config.maxInterstitialsPerSession) {
      return false;
    }

    final now = DateTime.now();
    if (_lastBackgroundAt != null &&
        now.difference(_lastBackgroundAt!) < resumeGrace) {
      return false;
    }
    if (_lastShownAt != null &&
        now.difference(_lastShownAt!) < minInterval) {
      return false;
    }

    if (_ad == null) {
      await preload();
    }
    final ad = _ad;
    if (ad == null) return false;

    await ad.show();
    _ad = null;
    _lastShownAt = DateTime.now();
    _shownThisSession++;
    AdDebugLog.interstitialShown();
    return true;
  }

  Future<void> dispose() async {
    await _ad?.dispose();
    _ad = null;
    _loading = false;
  }
}
