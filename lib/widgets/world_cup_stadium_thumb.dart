import 'package:flutter/material.dart';

import '../core/world_cup/world_cup_stadiums.dart';

/// Stadium thumbnail — verified bundled photo only; otherwise premium gradient.
class WorldCupStadiumThumb extends StatelessWidget {
  const WorldCupStadiumThumb({
    super.key,
    required this.stadium,
    this.size = 56,
    this.large = false,
  });

  final WorldCupStadium stadium;
  final double size;

  /// Larger hero layout for stadium detail (gradient card, no fake photo).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(large ? 20 : size * 0.18);
    final asset = stadium.assetPath;

    if (asset != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(radius),
        ),
      );
    }
    return _fallback(radius);
  }

  Widget _fallback(BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(stadium.accentColor),
            Color(stadium.accentColor).withValues(alpha: 0.45),
            const Color(0xFF0A0C10).withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: large
            ? [
                BoxShadow(
                  color: Color(stadium.accentColor).withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (large)
            Positioned(
              top: size * 0.12,
              child: Icon(
                Icons.stadium_rounded,
                size: size * 0.28,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          Icon(
            Icons.stadium_rounded,
            size: large ? size * 0.22 : size * 0.42,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ],
      ),
    );
  }
}

/// True when a verified bundled stadium image is configured.
bool worldCupStadiumAssetExists(WorldCupStadium stadium) {
  return stadium.hasVerifiedBundledPhoto;
}
