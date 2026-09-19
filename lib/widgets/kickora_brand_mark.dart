import 'package:flutter/material.dart';

import '../app/app_colors.dart';

/// Original Kickora mark — teal monogram placeholder until final icon art ships.
///
/// Does not use trophy imagery or tournament branding assets.
class KickoraBrandMark extends StatelessWidget {
  const KickoraBrandMark({
    super.key,
    required this.size,
    this.borderRadius,
    this.showPulse = true,
  });

  final double size;
  final BorderRadius? borderRadius;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkBackground,
            Color(0xFF0E3D38),
            AppColors.tealDeep,
          ],
        ),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.55),
          width: size * 0.03,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.28),
            blurRadius: size * 0.16,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'K',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.46,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          if (showPulse)
            Positioned(
              right: size * 0.2,
              top: size * 0.2,
              child: Container(
                width: size * 0.14,
                height: size * 0.14,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
