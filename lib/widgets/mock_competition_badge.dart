import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../core/mock/mock_competition_key.dart';

/// Local league-style crest for mock/demo mode (shield shape, not text circles).
class MockCompetitionBadge extends StatelessWidget {
  const MockCompetitionBadge({
    super.key,
    required this.competitionKey,
    required this.size,
  });

  final MockCompetitionKey competitionKey;
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
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: size * 0.18,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: CustomPaint(
            painter: _MockCompetitionPainter(competitionKey),
            size: Size.square(size),
          ),
        ),
      ),
    );
  }
}

class _MockCompetitionPainter extends CustomPainter {
  _MockCompetitionPainter(this.key);

  final MockCompetitionKey key;

  @override
  void paint(Canvas canvas, Size size) {
    switch (key) {
      case MockCompetitionKey.worldCup:
        _worldCup(canvas, size);
      case MockCompetitionKey.premierLeague:
        _leagueShield(
          canvas,
          size,
          colors: const [Color(0xFF3D195B), Color(0xFF5A2A86)],
          accent: const Color(0xFFE8B4FF),
          symbol: _SymbolKind.crown,
        );
      case MockCompetitionKey.laLiga:
        _leagueShield(
          canvas,
          size,
          colors: const [Color(0xFFC60B1E), Color(0xFFFF6B35)],
          accent: Colors.white,
          symbol: _SymbolKind.ball,
        );
      case MockCompetitionKey.serieA:
        _leagueShield(
          canvas,
          size,
          colors: const [Color(0xFF009246), Color(0xFF007A3D)],
          accent: Colors.white,
          symbol: _SymbolKind.stripe,
        );
      case MockCompetitionKey.bundesliga:
        _leagueShield(
          canvas,
          size,
          colors: const [Color(0xFFD20515), Color(0xFF9B0000)],
          accent: const Color(0xFFFFCE00),
          symbol: _SymbolKind.bars,
        );
    }
  }

  void _worldCup(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.teal, AppColors.tealDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.52),
      size.width * 0.28,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.04,
    );
    final trophy = TextPainter(
      text: TextSpan(
        text: '🏆',
        style: TextStyle(fontSize: size.width * 0.44),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    trophy.paint(
      canvas,
      Offset(
        (size.width - trophy.width) / 2,
        (size.height - trophy.height) / 2 - size.height * 0.02,
      ),
    );
  }

  void _leagueShield(
    Canvas canvas,
    Size size, {
    required List<Color> colors,
    required Color accent,
    required _SymbolKind symbol,
  }) {
    final path = _shieldPath(size);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.04,
    );

    switch (symbol) {
      case _SymbolKind.crown:
        _drawCrown(canvas, size, accent);
      case _SymbolKind.ball:
        _drawBall(canvas, size, accent);
      case _SymbolKind.stripe:
        _drawVerticalStripe(canvas, size);
      case _SymbolKind.bars:
        _drawHorizontalBars(canvas, size);
    }
  }

  Path _shieldPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.9, h * 0.2)
      ..quadraticBezierTo(w * 0.94, h * 0.45, w * 0.86, h * 0.82)
      ..lineTo(w * 0.5, h * 0.96)
      ..lineTo(w * 0.14, h * 0.82)
      ..quadraticBezierTo(w * 0.06, h * 0.45, w * 0.1, h * 0.2)
      ..close();
  }

  void _drawCrown(Canvas canvas, Size size, Color color) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    final paint = Paint()..color = color;
    final r = size.width * 0.07;
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(Offset(cx + i * r * 2.2, cy + r * 0.2), r, paint);
    }
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, cy + r * 1.1),
        width: r * 5.2,
        height: r * 1.4,
      ),
      paint,
    );
  }

  void _drawBall(Canvas canvas, Size size, Color color) {
    final center = Offset(size.width * 0.5, size.height * 0.52);
    final r = size.width * 0.18;
    canvas.drawCircle(center, r, Paint()..color = color.withValues(alpha: 0.95));
    final line = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025;
    for (var i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5;
      canvas.drawLine(
        center,
        Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle)),
        line,
      );
    }
    canvas.drawCircle(center, r * 0.35, line);
  }

  void _drawVerticalStripe(Canvas canvas, Size size) {
    final w = size.width * 0.14;
    final left = size.width * 0.43;
    canvas.drawRect(
      Rect.fromLTWH(left, size.height * 0.28, w, size.height * 0.44),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    canvas.drawRect(
      Rect.fromLTWH(left + w, size.height * 0.28, w, size.height * 0.44),
      Paint()..color = const Color(0xFFCE2B37).withValues(alpha: 0.95),
    );
  }

  void _drawHorizontalBars(Canvas canvas, Size size) {
    final barH = size.height * 0.11;
    final top = size.height * 0.34;
    final colors = [
      const Color(0xFF000000),
      const Color(0xFFD20515),
      const Color(0xFFFFCE00),
    ];
    for (var i = 0; i < colors.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.28,
          top + barH * i,
          size.width * 0.44,
          barH,
        ),
        Paint()..color = colors[i].withValues(alpha: 0.95),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MockCompetitionPainter oldDelegate) =>
      oldDelegate.key != key;
}

enum _SymbolKind { crown, ball, stripe, bars }
