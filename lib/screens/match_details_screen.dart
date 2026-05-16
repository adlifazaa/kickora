import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../core/refresh/match_refresh_category.dart';
import '../core/refresh/match_refresh_service.dart';
import '../app/routes.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/standing_model.dart';
import '../widgets/async_content_view.dart';
import '../widgets/live_badge.dart';
import '../widgets/live_update_indicator.dart';
import '../widgets/match_timeline.dart';
import '../widgets/skeleton_box.dart';
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
  late MatchModel _match;
  bool _loadingDetails = true;
  bool _refreshingDetails = false;
  DateTime? _lastUpdated;
  MatchRefreshService? _refresh;

  MatchModel get m => _match;

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _tabController = TabController(
      length: 4,
      vsync: this,
      animationDuration: const Duration(milliseconds: 280),
    );
    _displayMinute = _parseMinute(m);
    _startLiveTimers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh = AppScope.matchRefreshServiceOf(context);
      _refresh!.addListener(_onAutoRefresh);
      _loadDetails();
    });
  }

  void _onAutoRefresh() {
    if (m.status == MatchStatus.live) {
      _loadDetails(silent: true);
    }
  }

  void _startLiveTimers() {
    _minuteTimer?.cancel();
    _commentaryTimer?.cancel();
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

  Future<void> _loadDetails({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _loadingDetails = true);
    } else if (mounted) {
      setState(() => _refreshingDetails = true);
    }

    final repo = AppScope.footballRepositoryOf(context);
    final id = _match.id;

    final matchState = await repo.getMatchById(id);
    final eventsState = await repo.getMatchEvents(id);
    final statsState = await repo.getMatchStatistics(id);
    final lineupsState = await repo.getMatchLineups(id);
    final standingsState =
        await repo.getStandings(leagueId: _match.competition.id);

    final base = matchState.data ?? _match;
    final events = eventsState.data;
    final stats = statsState.data;
    final lineups = lineupsState.data;
    final standings = standingsState.data;

    var homeLineup = lineups?.home ?? base.homeLineup ?? _match.homeLineup;
    var awayLineup = lineups?.away ?? base.awayLineup ?? _match.awayLineup;

    final homeFormation = await repo.getFormation(id, isHome: true);
    final awayFormation = await repo.getFormation(id, isHome: false);
    homeLineup = _lineupWithFormation(homeLineup, homeFormation.data);
    awayLineup = _lineupWithFormation(awayLineup, awayFormation.data);

    if (!mounted) return;
    setState(() {
      _loadingDetails = false;
      _refreshingDetails = false;
      _lastUpdated = DateTime.now();
      _match = base.copyWith(
        events: (events != null && events.isNotEmpty) ? events : base.events,
        stats: (stats != null && stats.isNotEmpty) ? stats : base.stats,
        homeLineup: homeLineup,
        awayLineup: awayLineup,
        standings: (standings != null && standings.isNotEmpty)
            ? standings
            : (base.standings.isNotEmpty ? base.standings : _match.standings),
      );
    });
    _startLiveTimers();
  }

  LineupModel? _lineupWithFormation(
    LineupModel? lineup,
    FormationModel? formation,
  ) {
    if (lineup == null || formation == null) return lineup;
    return LineupModel(
      formation: lineup.formation,
      coach: lineup.coach,
      lines: lineup.lines,
      substitutes: lineup.substitutes,
      injured: lineup.injured,
      missing: lineup.missing,
      formationDetail: formation,
    );
  }

  @override
  void dispose() {
    _refresh?.removeListener(_onAutoRefresh);
    _minuteTimer?.cancel();
    _commentaryTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onPullRefresh() async {
    final refresh = AppScope.matchRefreshServiceOf(context);
    await refresh.refresh(MatchRefreshCategory.live, force: true);
    await _loadDetails(silent: true);
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
          if (!_loadingDetails)
            LiveUpdateIndicator(
              lastUpdated: _lastUpdated ?? _refresh?.lastRefreshedAt,
              refreshing:
                  _refreshingDetails || (_refresh?.isRefreshing ?? false),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _MatchDetailTabShell(
                  loading: _loadingDetails,
                  onRetry: _onPullRefresh,
                  child: MatchTimeline(match: m),
                ),
                _MatchDetailTabShell(
                  loading: _loadingDetails,
                  onRetry: _onPullRefresh,
                  child: _StatsTab(match: m),
                ),
                _MatchDetailTabShell(
                  loading: _loadingDetails,
                  onRetry: _onPullRefresh,
                  skeleton: const _LineupsTabSkeleton(),
                  child: _LineupsTab(match: m),
                ),
                _MatchDetailTabShell(
                  loading: _loadingDetails,
                  onRetry: _onPullRefresh,
                  child: _StandingsTab(standings: m.standings),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchDetailTabShell extends StatelessWidget {
  const _MatchDetailTabShell({
    required this.loading,
    required this.onRetry,
    required this.child,
    this.skeleton,
  });

  final bool loading;
  final Future<void> Function() onRetry;
  final Widget child;
  final Widget? skeleton;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return skeleton ??
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SkeletonBox(height: 72),
                SizedBox(height: 10),
                SkeletonBox(height: 72),
                SizedBox(height: 10),
                SkeletonBox(height: 72),
              ],
            ),
          );
    }
    return RefreshIndicator(
      onRefresh: onRetry,
      color: Theme.of(context).colorScheme.primary,
      child: child is ScrollView
          ? child
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [child],
            ),
    );
  }
}

class _LineupsTabSkeleton extends StatelessWidget {
  const _LineupsTabSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        SkeletonBox(height: 280, radius: 20),
        SizedBox(height: 14),
        SkeletonBox(height: 280, radius: 20),
      ],
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

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    if (match.stats.isEmpty) {
      return AsyncContentView(
        loading: false,
        isEmpty: true,
        emptyIcon: Icons.bar_chart_rounded,
        emptyTitle: text.isArabic ? 'لا توجد إحصائيات' : 'No statistics',
        emptySubtitle: text.isArabic
            ? 'سوف تتوفر الإحصائيات أثناء أو بعد المباراة.'
            : 'Statistics will be available during or after the match.',
        child: const SizedBox.shrink(),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
      itemCount: match.stats.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _TeamComparisonCard(match: match);
        }
        final stat = match.stats[index - 1];
        final total = (stat.home + stat.away).clamp(0.001, double.infinity);
        final homeRate = (stat.home / total).clamp(0.0, 1.0);
        final primary = Theme.of(context).colorScheme.primary;
        final secondary = Theme.of(context).colorScheme.secondary;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: homeRate),
          duration: Duration(milliseconds: 650 + (index - 1) * 40),
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

/// Header card on the Stats tab that shows both teams + score + a "recent
/// form" strip (last 5 results), giving the page a strong anchor before the
/// individual stat bars.
class _TeamComparisonCard extends StatelessWidget {
  const _TeamComparisonCard({required this.match});

  final MatchModel match;

  List<_FormResult> _recentForm(int seed) {
    // Deterministic pseudo-form derived from the team id so it stays stable
    // between rebuilds. Demo only – will be replaced by API "form: WWDLW".
    const pool = <_FormResult>[
      _FormResult.win,
      _FormResult.draw,
      _FormResult.win,
      _FormResult.loss,
      _FormResult.win,
      _FormResult.draw,
      _FormResult.win,
      _FormResult.loss,
    ];
    final out = <_FormResult>[];
    for (var i = 0; i < 5; i++) {
      out.add(pool[(seed + i) % pool.length]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardTheme.color ?? AppColors.darkCard,
            Color.alphaBlend(
              primary.withValues(alpha: 0.07),
              Theme.of(context).cardTheme.color ?? AppColors.darkCard,
            ),
          ],
        ),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ComparisonSide(
                  name: match.homeTeam.name,
                  short: match.homeTeam.shortName,
                  alignEnd: false,
                  accent: primary,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (match.status == MatchStatus.upcoming)
                      Text(
                        match.timeLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 18),
                      )
                    else
                      Text(
                        '${match.homeScore} - ${match.awayScore}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -0.5),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      match.status == MatchStatus.live
                          ? text.live
                          : (match.status == MatchStatus.finished
                              ? 'FT'
                              : text.upcoming),
                      style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _ComparisonSide(
                  name: match.awayTeam.name,
                  short: match.awayTeam.shortName,
                  alignEnd: true,
                  accent: secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FormStrip(
                  label: text.isArabic ? 'آخر 5' : 'Last 5',
                  results: _recentForm(match.homeTeam.id),
                  alignEnd: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FormStrip(
                  label: text.isArabic ? 'آخر 5' : 'Last 5',
                  results: _recentForm(match.awayTeam.id + 1),
                  alignEnd: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonSide extends StatelessWidget {
  const _ComparisonSide({
    required this.name,
    required this.short,
    required this.alignEnd,
    required this.accent,
  });

  final String name;
  final String short;
  final bool alignEnd;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final children = [
      Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.32),
              accent.withValues(alpha: 0.12),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Text(
          short,
          style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 13, color: accent),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              letterSpacing: -0.2),
        ),
      ),
    ];
    return Row(
      children: alignEnd ? children.reversed.toList() : children,
    );
  }
}

enum _FormResult { win, draw, loss }

class _FormStrip extends StatelessWidget {
  const _FormStrip({
    required this.label,
    required this.results,
    required this.alignEnd,
  });

  final String label;
  final List<_FormResult> results;
  final bool alignEnd;

  Color _c(_FormResult r) {
    switch (r) {
      case _FormResult.win:
        return AppColors.formWin;
      case _FormResult.draw:
        return AppColors.formDraw;
      case _FormResult.loss:
        return AppColors.formLoss;
    }
  }

  String _letter(_FormResult r) {
    switch (r) {
      case _FormResult.win:
        return 'W';
      case _FormResult.draw:
        return 'D';
      case _FormResult.loss:
        return 'L';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pips = results
        .map(
          (r) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _c(r).withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: _c(r).withValues(alpha: 0.7)),
            ),
            child: Text(
              _letter(r),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: _c(r),
              ),
            ),
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment:
              alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: pips,
        ),
      ],
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
      return AsyncContentView(
        loading: false,
        isEmpty: true,
        emptyIcon: Icons.groups_2_outlined,
        emptyTitle:
            text.isArabic ? 'التشكيلات غير متوفرة' : 'Lineups not available',
        emptySubtitle: text.isArabic
            ? 'تظهر التشكيلات عادةً قبل ساعة من المباراة.'
            : 'Lineups are typically published about an hour before kick-off.',
        child: const SizedBox.shrink(),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor),
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
    final surfaceTint =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.14),
            surfaceTint,
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
      return AsyncContentView(
        loading: false,
        isEmpty: true,
        emptyIcon: Icons.leaderboard_outlined,
        emptyTitle: text.isArabic ? 'لا يوجد جدول ترتيب' : 'No standings',
        emptySubtitle: text.isArabic
            ? 'سيظهر الترتيب عند توفر البيانات.'
            : 'The table will appear once data is available.',
        child: const SizedBox.shrink(),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
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
