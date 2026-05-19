import 'package:flutter/material.dart';

import '../ads/ad_placement.dart';
import '../ads/ad_service.dart';
import '../app/app_scope.dart';
import 'ad_placeholder.dart';
import 'native_ad_widget.dart';

/// Native ad with safe placeholder fallback when load fails (never crashes).
class NativeAdSlot extends StatefulWidget {
  const NativeAdSlot({
    super.key,
    required this.placement,
    this.variant = ContentSpotlightVariant.matchInsights,
    this.feedItemIndex,
    this.height = 56,
    this.padding = const EdgeInsets.only(bottom: 10),
  });

  final AdPlacement placement;
  final ContentSpotlightVariant variant;
  final int? feedItemIndex;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  State<NativeAdSlot> createState() => _NativeAdSlotState();
}

class _NativeAdSlotState extends State<NativeAdSlot> {
  bool _adFailed = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppScope.of(context),
      builder: (context, _) {
        if (!AppScope.of(context).adsEnabled) {
          return const SizedBox.shrink();
        }
        final ads = AdService.instance;
        if (!ads.shouldShowPlaceholder(
          widget.placement,
          feedItemIndex: widget.feedItemIndex,
        )) {
          return const SizedBox.shrink();
        }

        final useReal = ads.shouldShowRealAd(widget.placement) && !_adFailed;

        if (useReal) {
          return Padding(
            padding: widget.padding,
            child: NativeAdWidget(
              placement: widget.placement,
              height: widget.height,
              onLoadFailed: () {
                if (mounted) setState(() => _adFailed = true);
              },
            ),
          );
        }

        ads.recordPlaceholderImpression(widget.placement);
        return Padding(
          padding: widget.padding,
          child: AdPlaceholder(
            height: widget.height,
            variant: widget.variant,
          ),
        );
      },
    );
  }
}
