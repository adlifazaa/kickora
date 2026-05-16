import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/mock/mock_flag_key.dart';

/// Local painted country flag for mock/demo mode (circular clip).
class MockFlagBadge extends StatelessWidget {
  const MockFlagBadge({
    super.key,
    required this.flagKey,
    required this.size,
  });

  final MockFlagKey flagKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: size * 0.2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: CustomPaint(
            painter: _MockFlagPainter(flagKey),
            size: Size.square(size),
          ),
        ),
      ),
    );
  }
}

class _MockFlagPainter extends CustomPainter {
  _MockFlagPainter(this.key);

  final MockFlagKey key;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    switch (key) {
      case MockFlagKey.argentina:
        _horizontalTricolor(
          canvas,
          rect,
          const [Color(0xFF6CB4EE), Colors.white, Color(0xFF6CB4EE)],
        );
        canvas.drawCircle(
          rect.center.translate(0, size.height * 0.06),
          size.width * 0.11,
          Paint()..color = const Color(0xFFF6B800),
        );
      case MockFlagKey.brazil:
        canvas.drawRect(rect, Paint()..color = const Color(0xFF009C3B));
        final diamond = Path()
          ..moveTo(size.width * 0.5, size.height * 0.08)
          ..lineTo(size.width * 0.92, size.height * 0.5)
          ..lineTo(size.width * 0.5, size.height * 0.92)
          ..lineTo(size.width * 0.08, size.height * 0.5)
          ..close();
        canvas.drawPath(diamond, Paint()..color = const Color(0xFFFFDF00));
        canvas.drawCircle(
          rect.center,
          size.width * 0.18,
          Paint()..color = const Color(0xFF002776),
        );
      case MockFlagKey.france:
        _verticalTricolor(
          canvas,
          rect,
          const [Color(0xFF002395), Colors.white, Color(0xFFED2939)],
        );
      case MockFlagKey.spain:
        _horizontalTricolor(
          canvas,
          rect,
          const [Color(0xFFC60B1E), Color(0xFFFFC400), Color(0xFFC60B1E)],
          flex: const [1, 2, 1],
        );
      case MockFlagKey.morocco:
        canvas.drawRect(rect, Paint()..color = const Color(0xFFC1272D));
        _drawStar(canvas, rect.center, size.width * 0.16, const Color(0xFF006233));
      case MockFlagKey.germany:
        _horizontalTricolor(
          canvas,
          rect,
          const [Color(0xFF000000), Color(0xFFDD0000), Color(0xFFFFCE00)],
        );
      case MockFlagKey.england:
        canvas.drawRect(rect, Paint()..color = Colors.white);
        final cross = Paint()..color = const Color(0xFFCF142B);
        canvas.drawRect(
          Rect.fromLTWH(size.width * 0.42, 0, size.width * 0.16, size.height),
          cross,
        );
        canvas.drawRect(
          Rect.fromLTWH(0, size.height * 0.42, size.width, size.height * 0.16),
          cross,
        );
      case MockFlagKey.italy:
        _verticalTricolor(
          canvas,
          rect,
          const [Color(0xFF009246), Colors.white, Color(0xFFCE2B37)],
        );
    }
  }

  void _horizontalTricolor(
    Canvas canvas,
    Rect rect,
    List<Color> colors, {
    List<int>? flex,
  }) {
    final weights = flex ?? List.filled(colors.length, 1);
    final total = weights.fold<int>(0, (a, b) => a + b);
    var top = rect.top;
    for (var i = 0; i < colors.length; i++) {
      final h = rect.height * weights[i] / total;
      canvas.drawRect(
        Rect.fromLTWH(rect.left, top, rect.width, h),
        Paint()..color = colors[i],
      );
      top += h;
    }
  }

  void _verticalTricolor(Canvas canvas, Rect rect, List<Color> colors) {
    final w = rect.width / colors.length;
    for (var i = 0; i < colors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(rect.left + w * i, rect.top, w, rect.height),
        Paint()..color = colors[i],
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.42;
      final angle = (i * math.pi / points) - math.pi / 2;
      final offset = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MockFlagPainter oldDelegate) =>
      oldDelegate.key != key;
}
