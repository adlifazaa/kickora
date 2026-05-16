import 'package:flutter/material.dart';

import '../ads/ad_placement.dart';
import '../ads/ad_service.dart';
import 'ad_placeholder.dart';

/// Home (and other) banner slot — premium placeholder until AdMob banner is enabled.
class BannerPlaceholder extends StatelessWidget {
  const BannerPlaceholder({
    super.key,
    this.height = 64,
    this.placement = AdPlacement.homeBanner,
    this.variant = ContentSpotlightVariant.featuredContent,
    this.useFeaturedCardStyle = true,
  });

  final double height;
  final AdPlacement placement;
  final ContentSpotlightVariant variant;

  /// When true, uses the existing large featured card at the bottom of Home.
  final bool useFeaturedCardStyle;

  @override
  Widget build(BuildContext context) {
    final ads = AdService.instance;
    if (!ads.shouldShowPlaceholder(placement)) {
      return const SizedBox.shrink();
    }

    ads.recordPlaceholderImpression(placement);

    if (useFeaturedCardStyle) {
      return ContentSpotlightPlaceholder(variant: variant);
    }

    return AdPlaceholder(height: height, variant: variant);
  }
}
