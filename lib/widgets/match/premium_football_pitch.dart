import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_scope.dart';
import '../../app/app_text.dart';
import '../../app/routes.dart';
import '../../core/player/player_photo_resolver.dart';
import '../../models/lineup_model.dart';
import '../../models/player_model.dart';
import '../player_avatar.dart';
import '../team_logo.dart';

/// Full green pitch with home (bottom) and away (top) formations.
class DualTeamLineupPitch extends StatelessWidget {
  const DualTeamLineupPitch({
    super.key,
    this.homeLineup,
    this.awayLineup,
  });

  final LineupModel? homeLineup;
  final LineupModel? awayLineup;

  static const Color _homeJerseyTop = Color(0xFFFAFAFA);
  static const Color _homeJerseyBottom = Color(0xFFD7DDE8);
  static const Color _awayJerseyTop = Color(0xFF2B3D52);
  static const Color _awayJerseyBottom = Color(0xFF15202B);

  @override
  Widget build(BuildContext context) {
    final home = homeLineup?.forPitchDisplay();
    final away = awayLineup?.forPitchDisplay();
    final hasHome = home?.hasPitchPlayers ?? false;
    final hasAway = away?.hasPitchPlayers ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = (width / 0.58).clamp(340.0, 520.0);

        return SizedBox(
          width: width,
          height: height,
          child: LayoutBuilder(
            builder: (context, pitchConstraints) {
              final pitchW = pitchConstraints.maxWidth;
              final pitchH = pitchConstraints.maxHeight;
              final dotSize = (pitchW * 0.105).clamp(28.0, 42.0);
              final nodeWidth = dotSize + 8;

              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const _PitchSurface(),
                    CustomPaint(painter: _PitchMarkingsPainter()),
                    const IgnorePointer(child: _PitchVignette()),
                    if (!hasHome && !hasAway)
                      const _PitchAwaitingPlayers(),
                    if (hasAway)
                      ..._teamPlayers(
                        context: context,
                        lineup: away!,
                        width: pitchW,
                        height: pitchH,
                        dotSize: dotSize,
                        nodeWidth: nodeWidth,
                        half: PitchHalf.top,
                        jerseyTop: _awayJerseyTop,
                        jerseyBottom: _awayJerseyBottom,
                      ),
                    if (hasHome)
                      ..._teamPlayers(
                        context: context,
                        lineup: home!,
                        width: pitchW,
                        height: pitchH,
                        dotSize: dotSize,
                        nodeWidth: nodeWidth,
                        half: PitchHalf.bottom,
                        jerseyTop: _homeJerseyTop,
                        jerseyBottom: _homeJerseyBottom,
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Widget> _teamPlayers({
    required BuildContext context,
    required LineupModel lineup,
    required double width,
    required double height,
    required double dotSize,
    required double nodeWidth,
    required PitchHalf half,
    required Color jerseyTop,
    required Color jerseyBottom,
  }) {
    final layout = PitchPlayerLayout.compute(
      lineup: lineup,
      half: half,
      pitchWidth: width,
      pitchHeight: height,
      nodeWidth: nodeWidth,
      nodeHeight: dotSize + 20,
    );

    return layout.map((slot) {
      return Positioned(
        left: slot.left.clamp(2, width - nodeWidth - 2),
        top: slot.top.clamp(2, height - slot.nodeHeight - 2),
        child: Hero(
          tag: 'player-avatar-${slot.player.id}-${half.name}',
          child: Material(
            color: Colors.transparent,
            child: _PlayerPitchNode(
              player: slot.player,
              isGoalkeeper: slot.player.position == 'GK',
              jerseyTop: jerseyTop,
              jerseyBottom: jerseyBottom,
              avatarSize: dotSize,
              maxLabelWidth: nodeWidth + 12,
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _PitchAwaitingPlayers extends StatelessWidget {
  const _PitchAwaitingPlayers();

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          text.isArabic
              ? 'التشكيلة الأساسية ستظهر قريباً'
              : 'Starting XI will appear here soon',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

/// Legacy single-team pitch (kept for reuse elsewhere if needed).
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
    return DualTeamLineupPitch(
      homeLineup: invert ? null : lineup,
      awayLineup: invert ? lineup : null,
    );
  }
}

enum PitchHalf { top, bottom }

class PitchSlot {
  const PitchSlot({
    required this.player,
    required this.left,
    required this.top,
    required this.nodeHeight,
  });

  final PlayerModel player;
  final double left;
  final double top;
  final double nodeHeight;
}

/// Maps formation rows to normalized pitch coordinates.
class PitchPlayerLayout {
  PitchPlayerLayout._();

  static List<PitchSlot> compute({
    required LineupModel lineup,
    required PitchHalf half,
    required double pitchWidth,
    required double pitchHeight,
    required double nodeWidth,
    required double nodeHeight,
  }) {
    final bounds = _halfBounds(half);
    final horizontalPad = pitchWidth * 0.06;

    final rows = lineup.pitchLines;
    if (rows.isEmpty) return const [];

    final out = <PitchSlot>[];
    final rowCount = rows.length;

    for (var r = 0; r < rowCount; r++) {
      final row = rows[r];
      final rowIndex = rowCount == 1 ? 0.5 : r / (rowCount - 1);
      final normalizedY = half == PitchHalf.bottom
          ? bounds.maxY - rowIndex * (bounds.maxY - bounds.minY)
          : bounds.minY + rowIndex * (bounds.maxY - bounds.minY);
      final centerY = pitchHeight * normalizedY;

      for (var p = 0; p < row.length; p++) {
        final xRatio = (p + 1) / (row.length + 1);
        final centerX =
            horizontalPad + xRatio * (pitchWidth - horizontalPad * 2);
        out.add(
          PitchSlot(
            player: row[p],
            left: centerX - nodeWidth / 2,
            top: centerY - nodeHeight / 2,
            nodeHeight: nodeHeight,
          ),
        );
      }
    }
    return out;
  }

  static ({double minY, double maxY}) _halfBounds(PitchHalf half) {
    switch (half) {
      case PitchHalf.top:
        return (minY: 0.06, maxY: 0.46);
      case PitchHalf.bottom:
        return (minY: 0.54, maxY: 0.94);
    }
  }
}

class _PitchSurface extends StatelessWidget {
  const _PitchSurface();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
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
        CustomPaint(painter: _StripePainter(stripeCount: 14)),
      ],
    );
  }
}

class _PitchVignette extends StatelessWidget {
  const _PitchVignette();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.05,
          colors: [Color(0x00000000), Color(0x48000000)],
          stops: [0.55, 1.0],
        ),
      ),
    );
  }
}

class _PlayerPitchNode extends StatefulWidget {
  const _PlayerPitchNode({
    required this.player,
    required this.isGoalkeeper,
    required this.jerseyTop,
    required this.jerseyBottom,
    required this.avatarSize,
    required this.maxLabelWidth,
  });

  final PlayerModel player;
  final bool isGoalkeeper;
  final Color jerseyTop;
  final Color jerseyBottom;
  final double avatarSize;
  final double maxLabelWidth;

  @override
  State<_PlayerPitchNode> createState() => _PlayerPitchNodeState();
}

class _PlayerPitchNodeState extends State<_PlayerPitchNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
  );

  @override
  void dispose() {
    _press.dispose();
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
    final allowCdn = AppScope.footballRepositoryOf(context).usesLiveApi;
    final photoUrl =
        PlayerPhotoResolver.resolve(p, allowCdnFallback: allowCdn);
    final hasPhoto = photoUrl != null;
    final rating =
        p.matchRating > 0 ? p.matchRating.toStringAsFixed(1) : null;

    return GestureDetector(
      onTapDown: (_) => _press.forward(from: 0),
      onTapUp: (_) => _press.reverse(),
      onTapCancel: () => _press.reverse(),
      onTap: () =>
          Navigator.pushNamed(context, AppRoutes.playerDetails, arguments: p),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.92).animate(
          CurvedAnimation(parent: _press, curve: Curves.easeOut),
        ),
        child: SizedBox(
          width: widget.maxLabelWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  PlayerAvatar(
                    player: p,
                    size: widget.avatarSize,
                    jerseyTop: widget.jerseyTop,
                    jerseyBottom: widget.jerseyBottom,
                    showJerseyNumber: !hasPhoto,
                  ),
                  if (hasPhoto && p.number > 0)
                    Positioned(
                      bottom: 0,
                      child: _NumberPill(
                        number: p.number,
                        fontSize: widget.avatarSize * 0.2,
                      ),
                    ),
                  if (p.isCaptain)
                    Positioned(
                      top: -4,
                      right: -2,
                      child: _CaptainBadge(size: widget.avatarSize * 0.34),
                    ),
                  if (rating != null)
                    Positioned(
                      bottom: hasPhoto ? 14 : -3,
                      right: -4,
                      child: _RatingBadge(
                        rating: rating,
                        color: _ratingColor(p.matchRating),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: widget.maxLabelWidth,
                child: Text(
                  p.shortName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.15,
                    shadows: [
                      Shadow(
                        color: Color(0xAA000000),
                        blurRadius: 4,
                      ),
                    ],
                  ),
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

class _NumberPill extends StatelessWidget {
  const _NumberPill({required this.number, required this.fontSize});

  final int number;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white, width: 0.7),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CaptainBadge extends StatelessWidget {
  const _CaptainBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.teal, AppColors.tealDeep],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'C',
        style: TextStyle(
          fontSize: size * 0.55,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating, required this.color});

  final String rating;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white, width: 0.7),
      ),
      child: Text(
        rating,
        style: const TextStyle(
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
    );
  }
}

/// Header above the pitch: both teams, logos, and formation badges.
class LineupPitchHeader extends StatelessWidget {
  const LineupPitchHeader({
    super.key,
    required this.homeName,
    required this.awayName,
    required this.homeShort,
    required this.awayShort,
    this.homeLogoUrl,
    this.awayLogoUrl,
    this.homeFormation,
    this.awayFormation,
  });

  final String homeName;
  final String awayName;
  final String homeShort;
  final String awayShort;
  final String? homeLogoUrl;
  final String? awayLogoUrl;
  final String? homeFormation;
  final String? awayFormation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _teamRow(
          context,
          name: homeName,
          shortName: homeShort,
          logoUrl: homeLogoUrl,
          formation: homeFormation,
          alignEnd: false,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'VS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: Theme.of(context).hintColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        _teamRow(
          context,
          name: awayName,
          shortName: awayShort,
          logoUrl: awayLogoUrl,
          formation: awayFormation,
          alignEnd: true,
        ),
      ],
    );
  }

  Widget _teamRow(
    BuildContext context, {
    required String name,
    required String shortName,
    required String? logoUrl,
    required String? formation,
    required bool alignEnd,
  }) {
    final logo = TeamLogo(shortName: shortName, imageUrl: logoUrl, size: 32);
    final nameWidget = Expanded(
      child: Text(
        name,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: -0.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    final formationChip = formation != null && formation.isNotEmpty
        ? _FormationChip(label: formation)
        : const SizedBox.shrink();

    final children = alignEnd
        ? [formationChip, const SizedBox(width: 8), nameWidget, const SizedBox(width: 8), logo]
        : [logo, const SizedBox(width: 8), nameWidget, const SizedBox(width: 8), formationChip];

    return Row(children: children);
  }
}

class _FormationChip extends StatelessWidget {
  const _FormationChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.teal, AppColors.neonGreen],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter({required this.stripeCount});

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
      ..color = Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final softLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rect = Offset.zero & size;
    canvas.drawRect(rect.deflate(2), line);

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      line..strokeWidth = 2,
    );

    final cr = size.width * 0.12;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), cr, line);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      2.5,
      Paint()..color = Colors.white,
    );

    final boxW = size.width * 0.6;
    final boxH = size.height * 0.17;
    final boxLeft = (size.width - boxW) / 2;
    canvas.drawRect(Rect.fromLTWH(boxLeft, 0, boxW, boxH), line);
    canvas.drawRect(
      Rect.fromLTWH(boxLeft, size.height - boxH, boxW, boxH),
      line,
    );

    final sixW = size.width * 0.3;
    final sixH = size.height * 0.075;
    final sixLeft = (size.width - sixW) / 2;
    canvas.drawRect(Rect.fromLTWH(sixLeft, 0, sixW, sixH), line);
    canvas.drawRect(
      Rect.fromLTWH(sixLeft, size.height - sixH, sixW, sixH),
      line,
    );

    canvas.drawCircle(
      Offset(size.width / 2, boxH * 0.62),
      2,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height - boxH * 0.62),
      2,
      Paint()..color = Colors.white,
    );

    final arcR = size.width * 0.09;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, boxH * 0.85),
        radius: arcR,
      ),
      0.5,
      2.1,
      false,
      softLine,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height - boxH * 0.85),
        radius: arcR,
      ),
      3.6,
      2.1,
      false,
      softLine,
    );

    const cornerR = 7.0;
    for (final corner in [
      const Offset(2, 2),
      Offset(size.width - 2, 2),
      Offset(2, size.height - 2),
      Offset(size.width - 2, size.height - 2),
    ]) {
      canvas.drawCircle(corner, cornerR * 0.35, softLine);
    }

    final goalW = size.width * 0.16;
    final goalLeft = (size.width - goalW) / 2;
    canvas.drawLine(
      Offset(goalLeft, 0),
      Offset(goalLeft + goalW, 0),
      line..strokeWidth = 2.2,
    );
    canvas.drawLine(
      Offset(goalLeft, size.height),
      Offset(goalLeft + goalW, size.height),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
