import 'package:flutter/material.dart';

/// World Cup / international competition section badge.
///
/// Displays the approved raster badge exactly as provided — no vector redraw.
class WorldCupLogo extends StatelessWidget {
  const WorldCupLogo({super.key, required this.size, this.borderRadius});

  static const String assetPath = 'assets/images/world_cup_badge.png';

  final double size;

  /// Kept for call-site compatibility; the PNG is shown without extra clipping.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}
