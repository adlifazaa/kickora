import 'package:flutter/material.dart';

import '../app/app_colors.dart';

/// Pulsing LIVE badge with red dot and glow halo.
/// Used in match headers, cards, and live strips.
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key, this.label = 'LIVE', this.dense = false});

  final String label;
  final bool dense;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hPad = widget.dense ? 8.0 : 11.0;
    final vPad = widget.dense ? 4.0 : 6.0;
    final fontSize = widget.dense ? 10.0 : 11.5;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = 0.96 + (t * 0.06);
        final glow = 6 + (t * 14);

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.liveRed, AppColors.liveGlow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.liveGlow.withValues(alpha: 0.35 + t * 0.25),
                  blurRadius: glow,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85 + t * 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
