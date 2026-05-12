import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../services/ad_service.dart';

/// Standard banner ad placeholder rendered inside feeds.
/// Swap [AdService.bannerAdUnitId] when wiring real AdMob.
class AdPlaceholder extends StatelessWidget {
  const AdPlaceholder({
    super.key,
    this.height = 70,
    this.label = 'AdMob Banner Placeholder',
  });

  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.28)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 6,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'AD',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: primary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Native ad placeholder that mimics a feed card layout.
class NativeAdPlaceholder extends StatelessWidget {
  const NativeAdPlaceholder({
    super.key,
    this.title = 'Sponsored content',
    this.subtitle = 'Premium football experience by Kickora',
    this.ctaLabel = 'Open',
  });

  final String title;
  final String subtitle;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.neonGreen],
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.sports_soccer_rounded,
                color: Colors.black, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'AD',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.tealDeep],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              ctaLabel,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Visual placeholder representing an interstitial slot in code.
/// Use [AdService.showInterstitialIfReady] at the matching tap point.
class InterstitialAdMarker extends StatelessWidget {
  const InterstitialAdMarker({super.key, this.label = 'Interstitial slot'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.movie_filter_outlined,
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

/// Marker to remind developers an App Open ad will run when activated.
class AppOpenAdMarker extends StatelessWidget {
  const AppOpenAdMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt_outlined,
              size: 14, color: Theme.of(context).hintColor),
          const SizedBox(width: 4),
          Text('App Open ad slot reserved',
              style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
