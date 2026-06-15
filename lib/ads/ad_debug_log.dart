import 'package:flutter/foundation.dart';



import 'ad_placement.dart';



/// AdMob verification logs — debug builds only (filter logcat: Kickora Ads).

class AdDebugLog {

  AdDebugLog._();



  static const _tag = '[Kickora Ads]';



  static void _log(String message) {

    if (!kDebugMode) return;

    debugPrint('$_tag $message');

  }



  static void initialized({

    required bool adsEnabled,

    required bool nativeOnly,

    required bool placeholders,

    required bool sdkEnabled,

    required bool sdkReady,

  }) {

    _log(

      'AdMob configured enabled=$adsEnabled sdkEnabled=$sdkEnabled '

      'sdkReady=$sdkReady nativeOnly=$nativeOnly placeholders=$placeholders',

    );

  }



  static void mobileAdsInitStarted() {

    _log('AdMob initialized: MobileAds.initialize() requested');

  }



  static void mobileAdsInitComplete() {

    _log('AdMob initialized: MobileAds.initialize() complete');

  }



  static void mobileAdsInitSkipped({

    required bool adsMasterEnabled,

    required bool sdkEnabled,

    required bool suppressAds,

  }) {

    _log(

      'AdMob init skipped master=$adsMasterEnabled sdkEnabled=$sdkEnabled '

      'suppressAds=$suppressAds',

    );

  }



  static void initFailed(String message) {

    _log('AdMob initialized: FAILED — $message');

  }



  static void placementPrepared(AdPlacement placement) {

    _log('placement prepared → ${placement.name}');

  }



  static void nativeLoadSkipped(AdPlacement placement, {String? reason}) {

    final extra = reason != null ? ' ($reason)' : '';

    _log('native load skipped ${placement.name}$extra');

  }



  static void nativeLoaded(AdPlacement placement) {

    _log('native loaded → ${placement.name}');

  }



  static void nativeLoadFailed(AdPlacement placement, String message) {

    _log('native failed ${placement.name}: $message');

  }



  static void bannerSkipped(AdPlacement placement, String reason) {

    _log('Banner load skipped ${placement.name}: $reason');

  }



  static void bannerRequestStarted(AdPlacement placement, String unitId) {

    _log('Banner load requested → ${placement.name} unit=$unitId');

  }



  static void bannerLoaded(AdPlacement placement) {

    _log('Banner loaded → ${placement.name}');

  }



  static void bannerFailed(

    AdPlacement placement, {

    required int code,

    required String message,

    String? domain,

  }) {

    _log(

      'Banner failed → ${placement.name} code=$code '

      'domain=${domain ?? "?"} message=$message',

    );

  }



  static void interstitialLoadRequested(String unitId) {

    _log('Interstitial load requested unit=$unitId');

  }



  static void interstitialLoaded() {

    _log('Interstitial loaded');

  }



  static void interstitialLoadFailed({

    required int code,

    required String message,

    String? domain,

  }) {

    _log(

      'Interstitial failed code=$code domain=${domain ?? "?"} message=$message',

    );

  }



  static void interstitialShown() {

    _log('Interstitial shown');

  }



  static void interstitialShowFailed({

    required int code,

    required String message,

  }) {

    _log('Interstitial show failed code=$code message=$message');

  }

}


