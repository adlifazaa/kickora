import 'package:flutter/material.dart';

/// Kickora World Cup identity — uses the Play Store app icon locally (no FIFA assets).
class WorldCupLogo extends StatelessWidget {
  const WorldCupLogo({super.key, required this.size, this.borderRadius});

  static const assetPath = 'assets/icon/app_icon.png';

  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.06),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
          width: size * 0.03,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.emoji_events_rounded,
            size: size * 0.55,
            color: const Color(0xFFD4AF37),
          ),
        ),
      ),
    );
  }
}
