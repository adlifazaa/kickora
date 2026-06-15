import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_colors.dart';

/// App-safe gold trophy badge for FIFA World Cup (league id 1) — not FIFA branding.
class WorldCupTrophyBadge extends StatelessWidget {
  const WorldCupTrophyBadge({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
              blurRadius: size * 0.22,
              offset: Offset(0, size * 0.06),
            ),
          ],
        ),
        child: ClipOval(
          child: CustomPaint(
            painter: const _WorldCupTrophyPainter(),
            size: Size.square(size),
          ),
        ),
      ),
    );
  }
}

class _WorldCupTrophyPainter extends CustomPainter {
  const _WorldCupTrophyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0xFF1A6B55),
            AppColors.tealDeep,
            Color(0xFF0A3D32),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    final gold = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF7E7A3), Color(0xFFD4AF37), Color(0xFFB8860B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);

    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;

    // Pedestal
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, h * 0.84),
          width: w * 0.38,
          height: h * 0.1,
        ),
        Radius.circular(w * 0.03),
      ),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, h * 0.76),
          width: w * 0.52,
          height: h * 0.08,
        ),
        Radius.circular(w * 0.025),
      ),
      gold,
    );

    // Cup body
    final cup = Path()
      ..moveTo(cx - w * 0.22, h * 0.34)
      ..lineTo(cx - w * 0.16, h * 0.68)
      ..lineTo(cx + w * 0.16, h * 0.68)
      ..lineTo(cx + w * 0.22, h * 0.34)
      ..close();
    canvas.drawPath(cup, gold);

    // Cup rim highlight
    canvas.drawLine(
      Offset(cx - w * 0.22, h * 0.34),
      Offset(cx + w * 0.22, h * 0.34),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round,
    );

    // Handles
    final handle = Paint()
      ..color = const Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx - w * 0.24, h * 0.48), radius: w * 0.1),
      -0.4,
      2.8,
      false,
      handle,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx + w * 0.24, h * 0.48), radius: w * 0.1),
      0.4,
      -2.8,
      false,
      handle,
    );

    // Star accent (generic celebration, not FIFA mark)
    final starCx = cx;
    final starCy = h * 0.22;
    final starR = w * 0.07;
    canvas.drawCircle(
      Offset(starCx, starCy),
      starR,
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    _drawStar(canvas, Offset(starCx, starCy), starR * 0.72, gold);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.42;
      final angle = (i * 3.141592653589793 / points) - 3.141592653589793 / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
