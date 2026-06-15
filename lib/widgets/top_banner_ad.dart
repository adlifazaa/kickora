import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';



import '../ads/ad_config.dart';

import '../ads/ad_debug_log.dart';

import '../ads/ad_placement.dart';

import '../ads/ad_service.dart';

import '../app/app_scope.dart';



/// Anchored adaptive banner below the screen header, above scrollable content.

class TopBannerAd extends StatefulWidget {

  const TopBannerAd({super.key, required this.placement});



  final AdPlacement placement;



  @override

  State<TopBannerAd> createState() => _TopBannerAdState();

}



class _TopBannerAdState extends State<TopBannerAd> {

  BannerAd? _bannerAd;

  bool _loaded = false;

  bool _failed = false;

  double _height = 0;

  bool _requestStarted = false;



  @override

  void initState() {

    super.initState();

    AdService.instance.addListener(_onAdsChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoadBanner());

  }



  @override

  void dispose() {

    AdService.instance.removeListener(_onAdsChanged);

    _bannerAd?.dispose();

    super.dispose();

  }



  void _onAdsChanged() {

    if (!_requestStarted && AdService.instance.sdkReady) {

      _tryLoadBanner();

    }

  }



  Future<void> _tryLoadBanner() async {

    if (!mounted) return;



    if (_requestStarted) {

      return;

    }

    if (!AppScope.of(context).adsEnabled) {

      AdDebugLog.bannerSkipped(widget.placement, 'user ads disabled (premium)');

      return;

    }

    if (!AdService.instance.shouldShowBanner(widget.placement)) {

      AdDebugLog.bannerSkipped(widget.placement, 'placement disabled in config');

      return;

    }

    if (!AdConfig.adsSdkEnabled) {

      AdDebugLog.bannerSkipped(widget.placement, 'adsSdkEnabled=false');

      return;

    }

    if (!AdService.instance.sdkReady) {

      AdDebugLog.bannerSkipped(widget.placement, 'waiting for MobileAds SDK');

      return;

    }



    _requestStarted = true;

    AdDebugLog.bannerRequestStarted(widget.placement, AdConfig.bannerUnitId);



    final width = MediaQuery.sizeOf(context).width.truncate();

    if (width <= 0) {

      _requestStarted = false;

      AdDebugLog.bannerSkipped(widget.placement, 'invalid layout width');

      return;

    }



    final size =

        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (!mounted) return;

    if (size == null) {

      _requestStarted = false;

      AdDebugLog.bannerSkipped(widget.placement, 'adaptive size unavailable');

      return;

    }



    final banner = BannerAd(

      adUnitId: AdConfig.bannerUnitId,

      size: size,

      request: const AdRequest(),

      listener: BannerAdListener(

        onAdLoaded: (ad) {

          if (!mounted) {

            ad.dispose();

            return;

          }

          setState(() {

            _loaded = true;

            _failed = false;

            _height = size.height.toDouble();

          });

          AdDebugLog.bannerLoaded(widget.placement);

        },

        onAdFailedToLoad: (ad, error) {

          ad.dispose();

          AdDebugLog.bannerFailed(

            widget.placement,

            code: error.code,

            message: error.message,

            domain: error.domain,

          );

          if (mounted) {

            setState(() => _failed = true);

          }

        },

      ),

    );



    _bannerAd = banner;

    await banner.load();

  }



  @override

  Widget build(BuildContext context) {

    return ListenableBuilder(

      listenable: Listenable.merge([

        AppScope.of(context),

        AdService.instance,

      ]),

      builder: (context, _) {

        if (!AppScope.of(context).adsEnabled) {

          return const SizedBox.shrink();

        }



        if (_loaded && _bannerAd != null && _height > 0) {

          return Padding(

            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),

            child: SizedBox(

              width: double.infinity,

              height: _height,

              child: AdWidget(ad: _bannerAd!),

            ),

          );

        }



        if (kDebugMode && _failed) {

          return const _DebugAdSpacePlaceholder();

        }



        return const SizedBox.shrink();

      },

    );

  }

}



/// Debug APK only — marks banner slot when load fails (e.g. no fill).

class _DebugAdSpacePlaceholder extends StatelessWidget {

  const _DebugAdSpacePlaceholder();



  static const double height = 50;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),

      child: Container(

        width: double.infinity,

        height: height,

        alignment: Alignment.center,

        decoration: BoxDecoration(

          color: Theme.of(context).colorScheme.surfaceContainerHighest,

          borderRadius: BorderRadius.circular(8),

          border: Border.all(

            color: Theme.of(context).dividerColor,

          ),

        ),

        child: Text(

          'Ad space',

          style: TextStyle(

            color: Theme.of(context).hintColor,

            fontSize: 12,

            fontWeight: FontWeight.w600,

          ),

        ),

      ),

    );

  }

}


