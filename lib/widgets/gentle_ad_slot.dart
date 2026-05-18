import 'package:flutter/material.dart';

import '../ads/ad_placement.dart';
import '../ads/ad_service.dart';
import '../app/app_scope.dart';
import 'ad_placeholder.dart';

/// In-feed or scroll-footer ad slot — [AdPlaceholder] only, never real AdMob UI.
///
/// Returns zero height when ads are off, user is premium, or remote config disables
/// the placement (default: hidden).
class GentleAdSlot extends StatelessWidget {
  const GentleAdSlot({
    super.key,
    this.placement = AdPlacement.feedNative,
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
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppScope.of(context),
      builder: (context, _) {
        if (!AppScope.of(context).adsEnabled) {
          return const SizedBox.shrink();
        }
        final ads = AdService.instance;
        if (!ads.shouldShowPlaceholder(
          placement,
          feedItemIndex: feedItemIndex,
        )) {
          return const SizedBox.shrink();
        }

        ads.recordPlaceholderImpression(placement);
        return Padding(
          padding: padding,
          child: AdPlaceholder(height: height, variant: variant),
        );
      },
    );
  }
}
