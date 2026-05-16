import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';

/// Reserved banner slot — subtle, content-first wording (future AdMob).
class AdPlaceholder extends StatelessWidget {
  const AdPlaceholder({
    super.key,
    this.height = 64,
    this.variant = ContentSpotlightVariant.matchInsights,
  });

  final double height;
  final ContentSpotlightVariant variant;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final copy = variant.copy(text);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_rounded, size: 20, color: primary.withValues(alpha: 0.85)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  copy.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: -0.15,
                  ),
                ),
                Text(
                  copy.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum ContentSpotlightVariant {
  matchSpotlight,
  matchInsights,
  matchPartner,
  featuredContent,
}

extension on ContentSpotlightVariant {
  ({String title, String subtitle}) copy(AppText text) {
    final ar = text.isArabic;
    switch (this) {
      case ContentSpotlightVariant.matchSpotlight:
        return (
          title: ar ? 'أضواء المباراة' : 'Match Spotlight',
          subtitle: ar ? 'محتوى مميز من عالم كرة القدم' : 'Premium football highlights',
        );
      case ContentSpotlightVariant.matchInsights:
        return (
          title: ar ? 'رؤى المباراة' : 'Match Insights',
          subtitle: ar ? 'تحليلات وإحصائيات سريعة' : 'Quick stats & analysis',
        );
      case ContentSpotlightVariant.matchPartner:
        return (
          title: ar ? 'شريك المباراة' : 'Match Partner',
          subtitle: ar ? 'محتوى مختار لعشاق الكرة' : 'Curated for football fans',
        );
      case ContentSpotlightVariant.featuredContent:
        return (
          title: ar ? 'محتوى مميز' : 'Featured Content',
          subtitle: ar ? 'اكتشف المزيد حول مباريات اليوم' : 'Discover more from today\'s fixtures',
        );
    }
  }
}

/// Native-style feed card — premium partner slot (future AdMob native).
class ContentSpotlightPlaceholder extends StatelessWidget {
  const ContentSpotlightPlaceholder({
    super.key,
    this.variant = ContentSpotlightVariant.matchSpotlight,
  });

  final ContentSpotlightVariant variant;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final copy = variant.copy(text);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  primary.withValues(alpha: 0.35),
                  primary.withValues(alpha: 0.12),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.sports_soccer_rounded,
              color: primary.withValues(alpha: 0.9),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  copy.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Theme.of(context).hintColor.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }
}

/// @deprecated Use [ContentSpotlightPlaceholder] — kept for gradual migration.
typedef NativeAdPlaceholder = ContentSpotlightPlaceholder;

/// Visual marker for a future interstitial slot (dev reference only).
class InterstitialAdMarker extends StatelessWidget {
  const InterstitialAdMarker({super.key, this.label = 'Match Insights'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights_outlined,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 11.5)),
        ],
      ),
    );
  }
}

/// Marker for a future app-open slot (dev reference only).
class AppOpenAdMarker extends StatelessWidget {
  const AppOpenAdMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer_outlined,
              size: 14, color: Theme.of(context).hintColor),
          const SizedBox(width: 4),
          Text(
            text.isArabic ? 'محتوى مميز عند الفتح' : 'Featured content on launch',
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
