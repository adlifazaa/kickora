import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_debug_log.dart';
import '../ads/ad_placement.dart';
import '../ads/ad_service.dart';
import '../ads/ad_unit_ids.dart';

/// Native AdMob slot — returns zero height when ads are disabled or user is premium.
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({
    super.key,
    required this.placement,
    this.height = 72,
  });

  final AdPlacement placement;
  final double height;

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ads = AdService.instance;
    if (!ads.shouldShowRealAd(widget.placement)) {
      return;
    }

    final ad = NativeAd(
      adUnitId: AdUnitIds.nativeFor(widget.placement),
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() => _loaded = true);
          AdDebugLog.nativeLoaded(widget.placement);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          AdDebugLog.nativeLoadFailed(widget.placement, error.message);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.transparent,
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: widget.height,
      child: AdWidget(ad: _ad!),
    );
  }
}
