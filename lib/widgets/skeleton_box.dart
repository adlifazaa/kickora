import 'package:flutter/material.dart';

/// Animated shimmering skeleton block. Uses a moving gradient highlight,
/// closer to FotMob/SofaScore look.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = 14,
  });

  final double height;
  final double width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final hi = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.12);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(color: base),
                Align(
                  alignment: Alignment(-1.0 + t * 2.4, 0),
                  child: FractionallySizedBox(
                    widthFactor: 0.6,
                    heightFactor: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [base, hi, base],
                          stops: const [0.1, 0.5, 0.9],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Pre-built skeleton that mimics a match card while loading.
class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(child: SkeletonBox(height: 12, radius: 6)),
              SizedBox(width: 12),
              SkeletonBox(height: 18, width: 48, radius: 8),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Column(
                children: [
                  SkeletonBox(height: 36, width: 36, radius: 18),
                  SizedBox(height: 8),
                  SkeletonBox(height: 10, width: 60, radius: 4),
                ],
              ),
              SkeletonBox(height: 28, width: 64, radius: 6),
              Column(
                children: [
                  SkeletonBox(height: 36, width: 36, radius: 18),
                  SizedBox(height: 8),
                  SkeletonBox(height: 10, width: 60, radius: 4),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
