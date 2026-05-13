import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';
import '../data/mock_data.dart';
import '../models/player_model.dart';
import '../widgets/team_logo.dart';

class PlayerDetailsScreen extends StatelessWidget {
  const PlayerDetailsScreen({super.key, required this.player});

  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final recent = player.recentMatches.isEmpty
        ? MockData.players.first.recentMatches
        : player.recentMatches;
    final heroTag = 'player-avatar-${player.id}';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                stretch: true,
                title: Text(player.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: _HeroHeader(
                    player: player,
                    heroTag: heroTag,
                  ),
                ),
                bottom: TabBar(
                  tabs: [
                    Tab(text: text.stats),
                    Tab(text: text.recentMatches),
                    Tab(text: text.isArabic ? 'المسيرة' : 'Career'),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _StatsTab(player: player),
              _RecentTab(matches: recent),
              _CareerTab(player: player),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.player, required this.heroTag});

  final PlayerModel player;
  final String heroTag;

  Color _ratingColor(BuildContext context, double r) {
    if (r >= 7.5) return AppColors.goalGreen;
    if (r >= 6.5) return AppColors.teal;
    if (r >= 5.5) return AppColors.cardYellow;
    if (r > 0) return AppColors.cardRed;
    return Theme.of(context).hintColor;
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final ratingValue = player.matchRating > 0
        ? player.matchRating
        : (double.tryParse(player.seasonRating) ?? 7.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primary.withValues(alpha: 0.45),
            primary.withValues(alpha: 0.18),
            Theme.of(context).scaffoldBackgroundColor,
          ],
          stops: const [0, 0.55, 1],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(top: 56, start: 20, end: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Hero(
                tag: heroTag,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.95),
                          const Color(0xFFD0D5DD),
                        ],
                      ),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 2.4),
                      boxShadow: [
                        BoxShadow(
                            color: primary.withValues(alpha: 0.45),
                            blurRadius: 24,
                            spreadRadius: 2),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text('${player.number}',
                        style: const TextStyle(
                            fontSize: 38,
                            color: Color(0xFF0E1822),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(player.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3)),
                        ),
                        if (player.isCaptain) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                AppColors.teal,
                                AppColors.neonGreen,
                              ]),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('C',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        TeamLogo(
                            shortName: player.teamLogoShort.isEmpty
                                ? (player.team.isNotEmpty
                                    ? player.team.substring(0, 3)
                                    : '?')
                                : player.teamLogoShort,
                            size: 18),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(player.team,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(context, player.position, primary),
                        _chip(context, player.nationality,
                            Theme.of(context).colorScheme.onSurface),
                        _chip(
                            context,
                            '${player.age} ${text.isArabic ? 'سنة' : 'yrs'}',
                            Theme.of(context).colorScheme.onSurface),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RatingDial(
                  value: ratingValue,
                  color: _ratingColor(context, ratingValue)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bg.withValues(alpha: 0.45)),
      ),
      child: Text(label,
          style:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5)),
    );
  }
}

class _RatingDial extends StatelessWidget {
  const _RatingDial({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = (value / 10).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: t),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, anim, _) {
        return SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: anim,
                strokeWidth: 6,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Center(
                child: Text(value.toStringAsFixed(1),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.player});
  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _PremiumCard(
          child: Column(
            children: [
              _InfoRow(
                  label: text.isArabic ? 'الجنسية' : 'Nationality',
                  value: player.nationality),
              _InfoRow(
                  label: text.isArabic ? 'العمر' : 'Age',
                  value: '${player.age}'),
              _InfoRow(
                  label: text.isArabic ? 'الطول' : 'Height',
                  value: '${player.height} cm'),
              _InfoRow(
                  label: text.isArabic ? 'الوزن' : 'Weight',
                  value: '${player.weight} kg'),
              _InfoRow(
                  label: text.isArabic ? 'القدم المفضلة' : 'Preferred foot',
                  value: player.preferredFoot),
              _InfoRow(
                  label: text.isArabic ? 'رقم القميص' : 'Shirt number',
                  value: '${player.number}'),
              _InfoRow(
                  label: text.isArabic ? 'التقييم (موسم)' : 'Season rating',
                  value: player.seasonRating),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(text.isArabic ? 'إحصائيات' : 'Statistics',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            _StatTile(
              title: text.isArabic ? 'المشاركات' : 'Apps',
              value: '${player.appearances}',
              icon: Icons.event_available_rounded,
              color: AppColors.teal,
            ),
            _StatTile(
              title: text.isArabic ? 'الدقائق' : 'Minutes',
              value: '${player.minutesPlayed}',
              icon: Icons.timer_outlined,
              color: AppColors.subBlue,
            ),
            _StatTile(
              title: text.isArabic ? 'الأهداف' : 'Goals',
              value: '${player.goals}',
              icon: Icons.sports_soccer_rounded,
              color: AppColors.goalGreen,
            ),
            _StatTile(
              title: text.isArabic ? 'التمريرات' : 'Assists',
              value: '${player.assists}',
              icon: Icons.add_road_rounded,
              color: AppColors.neonGreen,
            ),
            _StatTile(
              title: text.isArabic ? 'صفراء' : 'Yellow',
              value: '${player.yellowCards}',
              icon: Icons.square_rounded,
              color: AppColors.cardYellow,
            ),
            _StatTile(
              title: text.isArabic ? 'حمراء' : 'Red',
              value: '${player.redCards}',
              icon: Icons.crop_square_rounded,
              color: AppColors.cardRed,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(text.isArabic ? 'خريطة الحرارة' : 'Heatmap',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _PremiumCard(
          padding: const EdgeInsets.all(10),
          child: _HeatmapPlaceholder(position: player.position),
        ),
      ],
    );
  }
}

class _HeatmapPlaceholder extends StatelessWidget {
  const _HeatmapPlaceholder({required this.position});
  final String position;

  /// Rough heat zone center based on position (vertical pitch, 0 → top).
  Offset _zone() {
    switch (position) {
      case 'GK':
        return const Offset(0.5, 0.95);
      case 'CB':
      case 'LB':
      case 'RB':
        return const Offset(0.5, 0.78);
      case 'LWB':
        return const Offset(0.15, 0.6);
      case 'RWB':
        return const Offset(0.85, 0.6);
      case 'DM':
        return const Offset(0.5, 0.65);
      case 'CM':
        return const Offset(0.5, 0.5);
      case 'AM':
        return const Offset(0.5, 0.36);
      case 'LW':
        return const Offset(0.2, 0.3);
      case 'RW':
        return const Offset(0.8, 0.3);
      case 'ST':
        return const Offset(0.5, 0.18);
      default:
        return const Offset(0.5, 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
                ),
              ),
            ),
            CustomPaint(painter: _SimplePitchPainter()),
            CustomPaint(painter: _HeatGridPainter(zone: _zone())),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Heatmap (demo)',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimplePitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(Offset.zero & size, line);
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), line);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.12, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeatGridPainter extends CustomPainter {
  _HeatGridPainter({required this.zone});
  final Offset zone;

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 7;
    const rows = 10;
    final cw = size.width / cols;
    final ch = size.height / rows;
    final cx = zone.dx * cols;
    final cy = zone.dy * rows;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final d = math.sqrt(math.pow(c + 0.5 - cx, 2) +
            math.pow(r + 0.5 - cy, 2));
        final intensity = (1 - (d / 4)).clamp(0.0, 1.0);
        if (intensity < 0.05) continue;
        final color = Color.lerp(
              const Color(0x55FFEC66),
              const Color(0xFFFF4D4D),
              intensity,
            )!
            .withValues(alpha: 0.32 + intensity * 0.5);
        final rect = Rect.fromLTWH(c * cw, r * ch, cw, ch).deflate(1.4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RecentTab extends StatelessWidget {
  const _RecentTab({required this.matches});
  final List<PlayerRecentMatch> matches;

  Color _ratingColor(String r) {
    final v = double.tryParse(r) ?? 0;
    if (v >= 7.5) return AppColors.goalGreen;
    if (v >= 6.5) return AppColors.teal;
    if (v >= 5.5) return AppColors.cardYellow;
    return AppColors.cardRed;
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    if (matches.isEmpty) {
      return Center(
          child: Text(text.isArabic ? 'لا توجد مباريات' : 'No matches'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final m = matches[i];
        final color = _ratingColor(m.rating);
        return _PremiumCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.65)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(m.rating,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.black87)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.opponent,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _miniChip(context,
                            Icons.sports_soccer_rounded, '${m.goals}',
                            color: AppColors.goalGreen),
                        const SizedBox(width: 6),
                        _miniChip(context, Icons.add_road_rounded,
                            '${m.assists}',
                            color: AppColors.neonGreen),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _miniChip(BuildContext context, IconData icon, String value,
      {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                  color: color)),
        ],
      ),
    );
  }
}

class _CareerTab extends StatelessWidget {
  const _CareerTab({required this.player});
  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final clubs = player.career.isEmpty ? <String>[player.team] : player.career;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _CareerSectionHeader(
          icon: Icons.swap_calls_rounded,
          title: text.isArabic ? 'تاريخ الانتقالات' : 'Transfer history',
          color: AppColors.teal,
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < clubs.length; i++)
          _TransferRow(
            club: clubs[i],
            isFirst: i == 0,
            isLast: i == clubs.length - 1,
          ),
        const SizedBox(height: 24),
        _CareerSectionHeader(
          icon: Icons.emoji_events_rounded,
          title: text.isArabic ? 'الإنجازات' : 'Achievements',
          color: AppColors.cardYellow,
        ),
        const SizedBox(height: 10),
        _AchievementsGrid(player: player),
      ],
    );
  }
}

class _CareerSectionHeader extends StatelessWidget {
  const _CareerSectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.55)],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
          ),
        ),
      ],
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.club,
    required this.isFirst,
    required this.isLast,
  });

  final String club;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [
                      AppColors.teal,
                      AppColors.neonGreen,
                    ]),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.4),
                          blurRadius: 6),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.35),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: isLast ? 0 : 12),
              child: _PremiumCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.shield_moon_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(club,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                              isFirst
                                  ? (text.isArabic ? 'البداية' : 'Start')
                                  : (isLast
                                      ? (text.isArabic ? 'الحالي' : 'Current')
                                      : (text.isArabic ? 'سابقًا' : 'Past')),
                              style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  const _AchievementsGrid({required this.player});
  final PlayerModel player;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final entries = <(IconData, String, String, Color)>[
      (
        Icons.emoji_events_rounded,
        text.isArabic ? 'بطولات' : 'Trophies',
        '${(player.appearances ~/ 12).clamp(0, 24)}',
        AppColors.cardYellow,
      ),
      (
        Icons.workspace_premium_rounded,
        text.isArabic ? 'جوائز فردية' : 'Awards',
        '${(player.goals ~/ 20).clamp(0, 18)}',
        AppColors.varPurple,
      ),
      (
        Icons.military_tech_rounded,
        text.isArabic ? 'ميداليات' : 'Medals',
        '${(player.assists ~/ 8).clamp(0, 22)}',
        AppColors.teal,
      ),
      (
        Icons.public_rounded,
        text.isArabic ? 'منتخب' : 'Caps',
        '${(player.appearances ~/ 6).clamp(0, 120)}',
        AppColors.subBlue,
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (context, i) {
        final (icon, label, value, color) = entries[i];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 380 + i * 60),
          curve: Curves.easeOutBack,
          builder: (context, t, child) {
            return Transform.scale(
              scale: 0.94 + 0.06 * t.clamp(0.0, 1.0),
              child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
            );
          },
          child: _PremiumCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(value,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 20)),
                      const SizedBox(height: 2),
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700)),
                    ],
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

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardTheme.color,
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        return Transform.scale(
          scale: 0.92 + 0.08 * t,
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).cardTheme.color ?? Colors.grey,
              Color.alphaBlend(
                color.withValues(alpha: 0.10),
                Theme.of(context).cardTheme.color ?? Colors.grey,
              ),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 2),
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
