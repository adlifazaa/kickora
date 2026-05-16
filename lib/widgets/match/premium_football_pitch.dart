import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/routes.dart';
import '../../app/app_scope.dart';
import '../../core/player/player_photo_resolver.dart';
import '../../models/lineup_model.dart';
import '../../models/player_model.dart';
import '../player_avatar.dart';

/// Premium football pitch with realistic gradient turf, mowed stripes,
/// regulation markings, vignette lighting, and tappable jersey-style dots.
class PremiumFootballPitch extends StatelessWidget {
  const PremiumFootballPitch({
    super.key,
    required this.lineup,
    required this.invert,
    this.homeColor = const Color(0xFFFAFAFA),
    this.homeAccent = const Color(0xFFD7DDE8),
  });

  final LineupModel lineup;
  final bool invert;
  final Color homeColor;
  final Color homeAccent;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.68,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.pitchTop,
                        AppColors.pitchMid,
                        AppColors.pitchBottom,
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                CustomPaint(painter: _StripePainter(stripeCount: 11)),
                CustomPaint(painter: _PitchMarkingsPainter()),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.1,
                        colors: [
                          Color(0x00000000),
                          Color(0x55000000),
                        ],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                ..._playerWidgets(context, width, height),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _playerWidgets(
      BuildContext context, double width, double height) {
    final out = <Widget>[];
    final rows = lineup.lines.length;
    final topPad = height * 0.04;
    final bottomPad = height * 0.04;
    final usableH = height - topPad - bottomPad;

    for (var r = 0; r < rows; r++) {
      final row = lineup.lines[r];
      final yIndex = rows == 1 ? 0.5 : r / (rows - 1);
      final y = invert ? (1 - yIndex) : yIndex;

      for (var p = 0; p < row.length; p++) {
        final player = row[p];
        final x = (p + 1) / (row.length + 1);
        final isGk = player.position == 'GK';
        const dotSize = 44.0;
        final left = x * width - dotSize / 2;
        final top = topPad + y * usableH - dotSize / 2;

        out.add(
          Positioned(
            left: left.clamp(2, width - dotSize - 2),
            top: top.clamp(2, height - dotSize - 6),
            child: Hero(
              tag: 'player-avatar-${player.id}',
              child: Material(
                color: Colors.transparent,
                child: _PlayerPitchDot(
                  player: player,
                  isGoalkeeper: isGk,
                  jerseyTop: isGk ? const Color(0xFFFFE566) : homeColor,
                  jerseyBottom:
                      isGk ? const Color(0xFFFFB020) : homeAccent,
                  size: dotSize,
                ),
              ),
            ),
          ),
        );
      }
    }
    return out;
  }
}

class _PlayerPitchDot extends StatefulWidget {
  const _PlayerPitchDot({
    required this.player,
    required this.isGoalkeeper,
    required this.jerseyTop,
    required this.jerseyBottom,
    required this.size,
  });

  final PlayerModel player;
  final bool isGoalkeeper;
  final Color jerseyTop;
  final Color jerseyBottom;
  final double size;

  @override
  State<_PlayerPitchDot> createState() => _PlayerPitchDotState();
}

class _PlayerPitchDotState extends State<_PlayerPitchDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Color _ratingColor(double r) {
    if (r >= 7.5) return AppColors.goalGreen;
    if (r >= 6.5) return AppColors.teal;
    if (r >= 5.5) return AppColors.cardYellow;
    if (r > 0) return AppColors.cardRed;
    return Colors.white60;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    final rating = p.matchRating > 0 ? p.matchRating.toStringAsFixed(1) : '—';
    final allowCdn =
        AppScope.footballRepositoryOf(context).usesLiveApi;
    final photoUrl = PlayerPhotoResolver.resolve(
      p,
      allowCdnFallback: allowCdn,
    );

    return GestureDetector(
      onTapDown: (_) => _c.forward(from: 0),
      onTapUp: (_) => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.playerDetails, arguments: p),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.9)
            .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
        child: SizedBox(
          width: widget.size + 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  PlayerAvatar(
                    player: p,
                    size: widget.size,
                    jerseyTop: widget.jerseyTop,
                    jerseyBottom: widget.jerseyBottom,
                    showJerseyNumber: true,
                  ),
                  if (photoUrl != null && p.number > 0)
                    Positioned(
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.white, width: 0.7),
                        ),
                        child: Text(
                          '${p.number}',
                          style: TextStyle(
                            fontSize: widget.size * 0.22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (p.isCaptain)
                    Positioned(
                      top: -5,
                      right: -3,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.teal, AppColors.tealDeep],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'C',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (p.matchRating > 0)
                    Positioned(
                      bottom: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _ratingColor(p.matchRating),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.white, width: 0.8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4),
                          ],
                        ),
                        child: Text(
                          rating,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.shortName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  _StripePainter({required this.stripeCount});

  final int stripeCount;

  @override
  void paint(Canvas canvas, Size size) {
    final stripeH = size.height / stripeCount;
    final paintLight = Paint()..color = Colors.white.withValues(alpha: 0.05);
    final paintShade = Paint()..color = Colors.black.withValues(alpha: 0.07);
    for (var i = 0; i < stripeCount; i++) {
      final p = i.isOdd ? paintLight : paintShade;
      canvas.drawRect(Rect.fromLTWH(0, i * stripeH, size.width, stripeH), p);
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter old) =>
      old.stripeCount != stripeCount;
}

class _PitchMarkingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final softLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rect = Offset.zero & size;
    canvas.drawRect(rect.deflate(2), line);

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      line,
    );

    final cr = size.width * 0.13;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), cr, line);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      2.4,
      Paint()..color = Colors.white,
    );

    final boxW = size.width * 0.62;
    final boxH = size.height * 0.18;
    final boxLeft = (size.width - boxW) / 2;
    canvas.drawRect(Rect.fromLTWH(boxLeft, 0, boxW, boxH), line);
    canvas.drawRect(
        Rect.fromLTWH(boxLeft, size.height - boxH, boxW, boxH), line);

    final sixW = size.width * 0.32;
    final sixH = size.height * 0.08;
    final sixLeft = (size.width - sixW) / 2;
    canvas.drawRect(Rect.fromLTWH(sixLeft, 0, sixW, sixH), line);
    canvas.drawRect(
        Rect.fromLTWH(sixLeft, size.height - sixH, sixW, sixH), line);

    canvas.drawCircle(Offset(size.width / 2, boxH * 0.62), 1.8,
        Paint()..color = Colors.white);
    canvas.drawCircle(Offset(size.width / 2, size.height - boxH * 0.62), 1.8,
        Paint()..color = Colors.white);

    final arcR = size.width * 0.10;
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width / 2, boxH * 0.85), radius: arcR),
      0.5,
      2.1,
      false,
      softLine,
    );
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width / 2, size.height - boxH * 0.85),
          radius: arcR),
      3.6,
      2.1,
      false,
      softLine,
    );

    const cornerR = 8.0;
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(2, 2), radius: cornerR),
      0,
      1.6,
      false,
      softLine,
    );
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width - 2, 2), radius: cornerR),
      1.6,
      1.6,
      false,
      softLine,
    );
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(2, size.height - 2), radius: cornerR),
      -1.6,
      1.6,
      false,
      softLine,
    );
    canvas.drawArc(
      Rect.fromCircle(
          center: Offset(size.width - 2, size.height - 2), radius: cornerR),
      3.14,
      1.6,
      false,
      softLine,
    );

    final goalW = size.width * 0.18;
    final goalLeft = (size.width - goalW) / 2;
    canvas.drawLine(
        Offset(goalLeft, 0), Offset(goalLeft + goalW, 0), line..strokeWidth = 2);
    canvas.drawLine(Offset(goalLeft, size.height),
        Offset(goalLeft + goalW, size.height), line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
