import 'package:flutter/material.dart';

import '../ads/ad_placement.dart';
import '../ads/ad_service.dart';
import '../app/app_scope.dart';
import 'ad_placeholder.dart';

/// In-feed native-style slot (match lists, competitions, match details).
class NativeAdPlaceholder extends StatelessWidget {
  const NativeAdPlaceholder({
    super.key,
    this.placement = AdPlacement.feedNative,
    this.variant = ContentSpotlightVariant.matchSpotlight,
    this.feedItemIndex,
  });

  final AdPlacement placement;
  final ContentSpotlightVariant variant;

  /// When set, [AdFrequencyController] gates occasional insertions.
  final int? feedItemIndex;

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
        return ContentSpotlightPlaceholder(variant: variant);
      },
    );
  }
}
