import 'package:flutter/material.dart';

import '../ads/ad_placement.dart';
import 'ad_placeholder.dart';
import 'native_ad_placeholder.dart';

/// Inserts premium native placeholders every [interval] feed items (3–5).
/// Skips the first [skipFirst] items so nothing sits under hero/featured blocks.
List<Widget> insertFeedSpotlights({
  required List<Widget> items,
  int interval = 4,
  int skipFirst = 0,
  AdPlacement placement = AdPlacement.feedNative,
  List<ContentSpotlightVariant> variants = const [
    ContentSpotlightVariant.matchSpotlight,
    ContentSpotlightVariant.matchInsights,
    ContentSpotlightVariant.matchPartner,
    ContentSpotlightVariant.featuredContent,
  ],
}) {
  if (items.isEmpty) return items;
  final out = <Widget>[];
  var variantIndex = 0;
  for (var i = 0; i < items.length; i++) {
    out.add(items[i]);
    final itemNumber = i + 1;
    if (itemNumber > skipFirst &&
        itemNumber % interval == 0 &&
        i < items.length - 1) {
      final variant = variants[variantIndex % variants.length];
      variantIndex++;
      out.add(const SizedBox(height: 14));
      out.add(
        NativeAdPlaceholder(
          placement: placement,
          variant: variant,
          feedItemIndex: itemNumber,
        ),
      );
      out.add(const SizedBox(height: 14));
    }
  }
  return out;
}
