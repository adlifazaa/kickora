import 'package:flutter/material.dart';

import '../app/app_text.dart';
import 'app_empty_state.dart';
import 'skeleton_box.dart';

/// Graceful loading / empty / retry wrapper — never uses harsh error colors.
class AsyncContentView extends StatelessWidget {
  const AsyncContentView({
    super.key,
    required this.loading,
    required this.isEmpty,
    required this.child,
    this.onRetry,
    this.skeleton,
    this.emptyIcon = Icons.inbox_rounded,
    this.emptyTitle,
    this.emptySubtitle,
    this.showLoadingIndicator = true,
  });

  final bool loading;
  final bool isEmpty;
  final Widget child;
  final VoidCallback? onRetry;
  final Widget? skeleton;
  final IconData emptyIcon;
  final String? emptyTitle;
  final String? emptySubtitle;
  final bool showLoadingIndicator;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return skeleton ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showLoadingIndicator) ...[
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: MatchCardSkeleton(),
                ),
              ],
            ),
          );
    }

    if (isEmpty) {
      final text = AppText.of(context);
      return AppEmptyState(
        icon: emptyIcon,
        title: emptyTitle ?? text.noMatches,
        subtitle: emptySubtitle ?? text.noMatchesSub,
        actionLabel: onRetry != null ? text.retry : null,
        onAction: onRetry,
      );
    }

    return child;
  }
}

/// Inline soft retry strip (teal, not red) for list footers.
class SoftRetryBanner extends StatelessWidget {
  const SoftRetryBanner({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Material(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh_rounded, size: 18, color: primary),
                const SizedBox(width: 8),
                Text(
                  text.pullRefreshHint,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer list for match feeds.
class MatchListSkeleton extends StatelessWidget {
  const MatchListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const MatchCardSkeleton(),
    );
  }
}

/// Shimmer block for competition details hero area.
class CompetitionDetailsSkeleton extends StatelessWidget {
  const CompetitionDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SkeletonBox(height: 130),
          SizedBox(height: 12),
          MatchCardSkeleton(),
          SizedBox(height: 12),
          MatchCardSkeleton(),
        ],
      ),
    );
  }
}
