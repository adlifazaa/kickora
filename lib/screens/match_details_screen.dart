import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/standing_model.dart';
import '../widgets/live_badge.dart';
import '../widgets/match/premium_football_pitch.dart';
import '../widgets/team_logo.dart';

class MatchDetailsScreen extends StatefulWidget {
  const MatchDetailsScreen({super.key, required this.match});

  final MatchModel match;

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _minuteTimer;
  Timer? _commentaryTimer;
  int _displayMinute = 0;
  int _commentaryIndex = 0;

  MatchModel get m => widget.match;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      animationDuration: const Duration(milliseconds: 280),
    );
    _displayMinute = _parseMinute(m);
    if (m.status == MatchStatus.live && m.timeLabel != 'HT') {
      _minuteTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        if (!mounted) return;
        setState(() => _displayMinute = (_displayMinute + 1).clamp(1, 120));
      });
    }
    if (m.liveCommentary.isNotEmpty) {
      _commentaryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        setState(() => _commentaryIndex =
            (_commentaryIndex + 1) % m.liveCommentary.length);
      });
    }
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    _commentaryTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  int _parseMinute(MatchModel match) {
    if (match.timeLabel == 'HT') return 45;
    if (match.timeLabel == 'FT') return 90;
    final raw = RegExp(r'^(\d+)').firstMatch(match.timeLabel)?.group(1);
    return int.tryParse(raw ?? '') ?? 0;
  }

  String _statusLabel(AppText text) {
    if (m.status == MatchStatus.live) {
      if (m.timeLabel == 'HT') return 'HT';
      return text.live;
    }
    if (m.status == MatchStatus.finished) return 'FT';
    return text.upcoming;
  }

  String _minuteOrStatus(AppText text) {
    if (m.status == MatchStatus.upcoming) return m.timeLabel;
    if (m.status == MatchStatus.live && m.timeLabel != 'HT') {
      return "$_displayMinute'";
    }
    return m.timeLabel;
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(text.matchDetails),
        actions: [
          IconButton(
            tooltip: text.isArabic ? 'مشاركة' : 'Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(text.isArabic
                        ? 'مشاركة قريبًا'
                        : 'Share coming soon')),
              );
            },
            icon: const Icon(Icons.ios_share_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          physics: const BouncingScrollPhysics(),
          tabs: [
            Tab(text: text.overview),
            Tab(text: text.stats),
            Tab(text: text.lineups),
            Tab(text: text.standings),
          ],
        ),
      ),
      body: Column(
        children: [
          _GlowMatchHeader(
            match: m,
            statusLabel: _statusLabel(text),
            minuteLabel: _minuteOrStatus(text),
          ),
          if (m.status == MatchStatus.live)
            _LiveFeelStrip(
              momentumHome: m.momentumHome,
              commentary: m.liveCommentary,
              commentaryIndex: _commentaryIndex,
              homeShort: m.homeTeam.shortName,
              awayShort: m.awayTeam.shortName,
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _OverviewTab(match: m),
                _StatsTab(match: m),
                _LineupsTab(match: m),
                _StandingsTab(standings: m.standings),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowMatchHeader extends StatelessWidget {
  const _GlowMatchHeader({
    required this.match,
    required this.statusLabel,
    required this.minuteLabel,
  });

  final MatchModel match;
  final String statusLabel;
  final String minuteLabel;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = AppText.of(context);
    final isLive =
        match.status == MatchStatus.live && match.timeLabel != 'HT';
    final primary = Theme.of(context).colorScheme.primary;

    // Hero card stays visually dark in BOTH themes so that the white/teal
    // foreground always reads correctly. (In light mode the previous gradient
    // faded to white at the bottom-right, swallowing the team names.)
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.white),
      child: IconTheme(
        data: const IconThemeData(color: Colors.white),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withValues(alpha: 0.55),
                const Color(0xFF0E1218),
                const Color(0xFF11151D),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.22),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CompetitionBadge(logo: match.competition.logo, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.competition.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${match.stadium} • ${match.date.day}/${match.date.month}/${match.date.year}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => app.toggleMatchFavorite(match.id),
                    icon: Icon(
                      app.isMatchFavorite(match.id)
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: app.isMatchFavorite(match.id)
                          ? Colors.amber
                          : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TeamBlock(
                      name: match.homeTeam.name,
                      shortName: match.homeTeam.shortName,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AnimatedScoreRow(
                        homeScore: match.homeScore,
                        awayScore: match.awayScore,
                      ),
                      const SizedBox(height: 8),
                      if (isLive)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LiveBadge(label: text.live, dense: true),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                minuteLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: _TeamBlock(
                      name: match.awayTeam.name,
                      shortName: match.awayTeam.shortName,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedScoreRow extends StatelessWidget {
  const _AnimatedScoreRow({required this.homeScore, required this.awayScore});

  final int homeScore;
  final int awayScore;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BigScore(value: homeScore),
        const SizedBox(width: 14),
        const Text('—',
            style:
                TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(width: 14),
        _BigScore(value: awayScore),
      ],
    );
  }
}

class _BigScore extends StatelessWidget {
  const _BigScore({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, anim) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1).animate(
              CurvedAnimation(parent: anim, curve: Curves.elasticOut)),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      child: Text(
        '$value',
        key: ValueKey<int>(value),
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.5,
        ),
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  const _TeamBlock({required this.name, required this.shortName});

  final String name;
  final String shortName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamLogo(shortName: shortName, size: 58),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          // Always white because this block sits inside the dark hero
          // gradient regardless of the active app theme.
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _LiveFeelStrip extends StatelessWidget {
  const _LiveFeelStrip({
    required this.momentumHome,
    required this.commentary,
    required this.commentaryIndex,
    required this.homeShort,
    required this.awayShort,
  });

  final double momentumHome;
  final List<String> commentary;
  final int commentaryIndex;
  final String homeShort;
  final String awayShort;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final homePct = (momentumHome * 100).round();
    final awayPct = 100 - homePct;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: primary),
              const SizedBox(width: 4),
              Text(
                text.isArabic ? 'زخم المباراة' : 'Match momentum',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 12),
              ),
              const Spacer(),
              Text('$homeShort $homePct% · $awayPct% $awayShort',
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: momentumHome.clamp(0.05, 0.95)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.10),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: t,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primary,
                                  secondary.withValues(alpha: 0.85),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(alpha: 0.45),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment(t * 2 - 1, 0),
                        child: Container(
                          width: 3,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (commentary.isNotEmpty) ...[
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.15), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                );
              },
              child: Container(
                key: ValueKey(commentaryIndex),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.graphic_eq_rounded,
                          size: 16, color: primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        commentary[commentaryIndex % commentary.length],
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.match});

  final MatchModel match;

  IconData _icon(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal:
        return Icons.sports_soccer_rounded;
      case MatchEventType.ownGoal:
        return Icons.sports_soccer_rounded;
      case MatchEventType.penalty:
        return Icons.adjust_rounded;
      case MatchEventType.yellowCard:
        return Icons.square_rounded;
      case MatchEventType.redCard:
        return Icons.crop_square_rounded;
      case MatchEventType.substitution:
        return Icons.swap_horiz_rounded;
      case MatchEventType.varDecision:
        return Icons.ondemand_video_rounded;
    }
  }

  Color _color(MatchEventType type) {
    switch (type) {
      case MatchEventType.goal:
        return AppColors.goalGreen;
      case MatchEventType.ownGoal:
        return AppColors.ownGoalOrange;
      case MatchEventType.penalty:
        return AppColors.penaltyTeal;
      case MatchEventType.yellowCard:
        return AppColors.cardYellow;
      case MatchEventType.redCard:
        return AppColors.cardRed;
      case MatchEventType.substitution:
        return AppColors.subBlue;
      case MatchEventType.varDecision:
        return AppColors.varPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    if (match.events.isEmpty) {
      return Center(
          child: Text(
              text.isArabic ? 'لا توجد أحداث بعد.' : 'No match events yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: match.events.length + 1,
      itemBuilder: (context, index) {
        if (index == match.events.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  text.isArabic ? 'بداية المباراة' : 'Kick-off',
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11),
                ),
              ),
            ),
          );
        }
        final event = match.events[index];
        final align = event.isHome ? Alignment.centerRight : Alignment.centerLeft;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 320 + (index * 45)),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) {
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset:
                    Offset(event.isHome ? (1 - t) * 28 : -(1 - t) * 28, 0),
                child: child,
              ),
            );
          },
          child: Align(
            alignment: align,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.86),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).cardTheme.color ?? AppColors.darkCard,
                      Color.alphaBlend(
                        _color(event.type).withValues(alpha: 0.08),
                        Theme.of(context).cardTheme.color ?? AppColors.darkCard,
                      ),
                    ],
                  ),
                  border: Border.all(
                      color: _color(event.type).withValues(alpha: 0.45)),
                  boxShadow: [
                    BoxShadow(
                      color: _color(event.type).withValues(alpha: 0.15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (event.isHome) _minuteChip(context, event.minute),
                    if (event.isHome) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _color(event.type).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_icon(event.type),
                          color: _color(event.type), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _eventTitle(text, event),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                          if (event.assistName != null &&
                              event.assistName!.isNotEmpty)
                            Text(
                              text.isArabic
                                  ? 'تمريرة حاسمة: ${event.assistName}'
                                  : 'Assist: ${event.assistName}',
                              style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600),
                            ),
                          if (event.description.isNotEmpty)
                            Text(event.description,
                                style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: 11.5)),
                        ],
                      ),
                    ),
                    if (!event.isHome) const SizedBox(width: 8),
                    if (!event.isHome) _minuteChip(context, event.minute),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _minuteChip(BuildContext context, String minute) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(minute,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
    );
  }

  String _eventTitle(AppText text, MatchEvent e) {
    final suffix = e.playerName;
    switch (e.type) {
      case MatchEventType.goal:
        return text.isArabic ? 'هدف — $suffix' : 'Goal — $suffix';
      case MatchEventType.ownGoal:
        return text.isArabic ? 'هدف ذاتي — $suffix' : 'Own goal — $suffix';
      case MatchEventType.penalty:
        return text.isArabic ? 'ركلة جزاء — $suffix' : 'Penalty — $suffix';
      case MatchEventType.yellowCard:
        return text.isArabic
            ? 'بطاقة صفراء — $suffix'
            : 'Yellow card — $suffix';
      case MatchEventType.redCard:
        return text.isArabic
            ? 'بطاقة حمراء — $suffix'
            : 'Red card — $suffix';
      case MatchEventType.substitution:
        return text.isArabic ? 'تبديل — $suffix' : 'Substitution — $suffix';
      case MatchEventType.varDecision:
        return text.isArabic ? 'قرار VAR — $suffix' : 'VAR — $suffix';
    }
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    if (match.stats.isEmpty) {
      return Center(
          child: Text(text.isArabic ? 'لا توجد إحصائيات.' : 'No statistics.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      itemCount: match.stats.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final stat = match.stats[index];
        final total = (stat.home + stat.away).clamp(0.001, double.infinity);
        final homeRate = (stat.home / total).clamp(0.0, 1.0);
        final primary = Theme.of(context).colorScheme.primary;
        final secondary = Theme.of(context).colorScheme.secondary;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: homeRate),
          duration: Duration(milliseconds: 650 + index * 40),
          curve: Curves.easeOutCubic,
          builder: (context, animatedHome, child) {
            final awayPart = (1 - animatedHome).clamp(0.0, 1.0);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.18
                            : 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _valuePill(context, stat.homeValue, primary),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            stat.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      _valuePill(context, stat.awayValue, secondary),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: [
                          Expanded(
                            flex: (animatedHome * 1000).round().clamp(1, 999),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  primary,
                                  primary.withValues(alpha: 0.65)
                                ]),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: (awayPart * 1000).round().clamp(1, 999),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  secondary.withValues(alpha: 0.5),
                                  Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.12),
                                ]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (stat.title.toLowerCase().contains('possession')) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: animatedHome,
                            strokeWidth: 7,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.10),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(primary),
                          ),
                          Center(
                            child: Text('${(animatedHome * 100).round()}%',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _valuePill(BuildContext context, String v, Color color) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.08)
            ],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          v,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ),
    );
  }
}

class _LineupsTab extends StatelessWidget {
  const _LineupsTab({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    if (match.homeLineup == null || match.awayLineup == null) {
      return Center(
          child: Text(
              text.isArabic ? 'التشكيلات غير متوفرة.' : 'Lineups not available.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
      children: [
        _TeamLineupCard(
          teamName: match.homeTeam.name,
          shortName: match.homeTeam.shortName,
          lineup: match.homeLineup!,
          invert: false,
        ),
        const SizedBox(height: 14),
        _TeamLineupCard(
          teamName: match.awayTeam.name,
          shortName: match.awayTeam.shortName,
          lineup: match.awayLineup!,
          invert: true,
        ),
      ],
    );
  }
}

class _TeamLineupCard extends StatelessWidget {
  const _TeamLineupCard({
    required this.teamName,
    required this.shortName,
    required this.lineup,
    required this.invert,
  });

  final String teamName;
  final String shortName;
  final LineupModel lineup;
  final bool invert;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TeamLogo(shortName: shortName, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  teamName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.teal, AppColors.neonGreen],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lineup.formation,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PremiumFootballPitch(lineup: lineup, invert: invert),
          const SizedBox(height: 14),
          _coachCard(context, text, lineup.coach),
          const SizedBox(height: 12),
          _benchSection(context, text),
          if (lineup.injured.isNotEmpty) ...[
            const SizedBox(height: 12),
            _statusBadge(
              context,
              icon: Icons.healing_rounded,
              color: AppColors.cardRed,
              title: text.isArabic ? 'الإصابات' : 'Injured',
              items: lineup.injured,
            ),
          ],
          if (lineup.missing.isNotEmpty) ...[
            const SizedBox(height: 8),
            _statusBadge(
              context,
              icon: Icons.person_off_outlined,
              color: AppColors.cardYellow,
              title: text.isArabic ? 'غياب' : 'Missing',
              items: lineup.missing,
            ),
          ],
        ],
      ),
    );
  }

  Widget _benchSection(BuildContext context, AppText text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_seat_rounded,
                size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Text(text.substitutes,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: lineup.substitutes
              .map(
                (p) => InkWell(
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.playerDetails, arguments: p),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [
                              Color(0xFFF5F7FA),
                              Color(0xFFD7DDE8),
                            ]),
                          ),
                          child: Text('${p.number}',
                              style: const TextStyle(
                                  color: Color(0xFF0E1822),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10)),
                        ),
                        const SizedBox(width: 6),
                        Text(p.shortName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(width: 6),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _coachCard(BuildContext context, AppText text, String coach) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  primary.withValues(alpha: 0.45),
                  primary.withValues(alpha: 0.18),
                ],
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.sports_rounded, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text.coach,
                    style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                Text(coach,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
          ),
          Icon(Icons.flag_rounded,
              size: 16, color: Theme.of(context).hintColor),
        ],
      ),
    );
  }

  Widget _statusBadge(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title,
                style:
                    TextStyle(fontWeight: FontWeight.w800, color: color)),
          ]),
          const SizedBox(height: 4),
          ...items.map((s) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('• $s',
                    style: const TextStyle(fontSize: 12.5)),
              )),
        ],
      ),
    );
  }
}

class _StandingsTab extends StatelessWidget {
  const _StandingsTab({required this.standings});

  final List<StandingModel> standings;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    if (standings.isEmpty) {
      return Center(
          child: Text(text.isArabic ? 'لا يوجد جدول.' : 'No standings.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: standings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final item = standings[i];
        final isTop = i < 3;
        return Material(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isTop
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3)
                    : Theme.of(context).dividerColor,
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: isTop
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.25)
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.08),
              child: Text('${item.position}',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            title: Text(item.team.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14)),
            subtitle: Text(
                '${item.played} ${text.isArabic ? 'لعب' : 'P'} · GD ${item.goalDifference}'),
            trailing: Text('${item.points}',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 18)),
          ),
        );
      },
    );
  }
}
