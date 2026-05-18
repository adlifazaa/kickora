import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../core/debug/match_details_log.dart';
import '../core/state/data_state.dart';
import '../core/refresh/match_refresh_category.dart';
import '../core/refresh/match_refresh_service.dart';
import '../app/routes.dart';
import '../data/mock_data.dart';
import '../data/repositories/football_repository.dart';
import '../models/lineup_model.dart';
import '../models/match_model.dart';
import '../models/standing_model.dart';
import '../widgets/async_content_view.dart';
import '../widgets/live_badge.dart';
import '../widgets/live_update_indicator.dart';
import '../widgets/match_timeline.dart';
import '../widgets/match/premium_football_pitch.dart';
import '../widgets/player_avatar.dart';
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
  int _bodyTabIndex = 0;
  Timer? _minuteTimer;
  Timer? _commentaryTimer;
  int _displayMinute = 0;
  int _commentaryIndex = 0;
  late MatchModel _match;
  bool _refreshingDetails = false;
  DateTime? _lastUpdated;
  String? _detailsError;
  MatchRefreshService? _refresh;

  MatchModel get m => _match;

  int get _fixtureId => _match.resolvedFixtureId;

  bool get _isApiFixture => _match.isApiFixture;

  @override
  void initState() {
    super.initState();
    _match = displayMatchFor(
      widget.match,
      allowMockFill: !widget.match.isApiFixture,
    );
    logMatchDetails(
      'open match id=${widget.match.id} fixtureId=$_fixtureId '
      'apiFixture=$_isApiFixture '
      '${widget.match.homeTeam.name} vs ${widget.match.awayTeam.name}',
    );
    _tabController = TabController(
      length: 4,
      vsync: this,
      animationDuration: const Duration(milliseconds: 280),
    );
    _tabController.addListener(_onTabChanged);
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

  void _onTabChanged() {
    if (!mounted) return;
    final index = _tabController.index;
    if (index != _bodyTabIndex) {
      setState(() => _bodyTabIndex = index);
    }
  }

  void _selectTab(int index) {
    if (_bodyTabIndex == index) return;
    setState(() => _bodyTabIndex = index);
  }

  bool _allowMockFill(FootballRepository repo) =>
      !repo.usesLiveApi || MockData.isMockMatchId(_fixtureId);

  void _noteDetailsError<T>(DataState<T> state, FootballRepository repo) {
    if (!repo.usesLiveApi || !_isApiFixture) return;
    if (!state.hasError) return;
    _detailsError = state.errorMessage;
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

  bool _acceptRepositoryResult<T>(DataState<T> state) {
    if (!_isApiFixture) return true;
    return !state.fromMock;
  }

  Future<void> _loadDetails({bool silent = false}) async {
    if (mounted) {
      setState(() {
        _refreshingDetails = true;
        if (!silent) _detailsError = null;
      });
    }

    final repo = AppScope.footballRepositoryOf(context);
    final fixtureId = _fixtureId;
    final matchId = _match.id;
    final leagueId = _match.competition.id;

    var base = _match;
    var events = _match.events;
    var stats = _match.stats;
    LineupModel? homeLineup = _match.homeLineup;
    LineupModel? awayLineup = _match.awayLineup;
    var standings = _match.standings;

    try {
      final matchState =
          await repo.getMatchById(matchId, fixtureId: fixtureId);
      logMatchDetails(
        'fixture=$fixtureId match=${matchState.fromMock ? "mock-fallback" : "api"} '
        'hasData=${matchState.data != null}',
      );
      if (_acceptRepositoryResult(matchState)) {
        final refreshed = matchState.data;
        if (refreshed != null) {
          base = _match.copyWith(
            fixtureId: fixtureId,
            homeTeam: refreshed.homeTeam,
            awayTeam: refreshed.awayTeam,
            homeScore: refreshed.homeScore,
            awayScore: refreshed.awayScore,
            status: refreshed.status,
            timeLabel: refreshed.timeLabel,
            competition: refreshed.competition,
            date: refreshed.date,
            stadium: refreshed.stadium.isNotEmpty
                ? refreshed.stadium
                : _match.stadium,
            liveCommentary: _isApiFixture
                ? const []
                : refreshed.liveCommentary,
          );
        }
      }
    } catch (e) {
      logMatchDetails('fixture fetch error: $e');
    }

    try {
      final eventsState = await repo.getMatchEvents(
        matchId,
        fixtureId: fixtureId,
        leagueId: leagueId,
      );
      logMatchDetails(
        'events fixture=$fixtureId source=${eventsState.fromMock ? "mock-fallback" : "api"} '
        'count=${eventsState.data?.length ?? 0}',
      );
      _noteDetailsError(eventsState, repo);
      if (_acceptRepositoryResult(eventsState)) {
        final data = eventsState.data;
        if (data != null) events = data;
      }
    } catch (e) {
      logMatchDetails('events error: $e');
    }

    try {
      final statsState = await repo.getMatchStatistics(
        matchId,
        fixtureId: fixtureId,
        leagueId: leagueId,
      );
      logMatchDetails(
        'stats fixture=$fixtureId source=${statsState.fromMock ? "mock-fallback" : "api"} '
        'count=${statsState.data?.length ?? 0}',
      );
      _noteDetailsError(statsState, repo);
      if (_acceptRepositoryResult(statsState)) {
        final data = statsState.data;
        if (data != null) stats = data;
      }
    } catch (e) {
      logMatchDetails('stats error: $e');
    }

    try {
      final lineupsState = await repo.getMatchLineups(
        matchId,
        fixtureId: fixtureId,
        leagueId: leagueId,
      );
      logMatchDetails(
        'lineups fixture=$fixtureId source=${lineupsState.fromMock ? "mock-fallback" : "api"} '
        'home=${lineupsState.data?.home != null} away=${lineupsState.data?.away != null}',
      );
      _noteDetailsError(lineupsState, repo);
      if (_acceptRepositoryResult(lineupsState)) {
        final data = lineupsState.data;
        if (data != null) {
          if (data.home != null) {
            homeLineup = data.home;
          }
          if (data.away != null) {
            awayLineup = data.away;
          }
        }
      }
    } catch (e) {
      logMatchDetails('lineups error: $e');
    }

    try {
      final homeFormation = await repo.getFormation(
        matchId,
        fixtureId: fixtureId,
        isHome: true,
      );
      final awayFormation = await repo.getFormation(
        matchId,
        fixtureId: fixtureId,
        isHome: false,
      );
      if (_acceptRepositoryResult(homeFormation) &&
          homeFormation.data != null &&
          homeLineup != null) {
        homeLineup = _mergeFormation(homeLineup, homeFormation.data!);
      }
      if (_acceptRepositoryResult(awayFormation) &&
          awayFormation.data != null &&
          awayLineup != null) {
        awayLineup = _mergeFormation(awayLineup, awayFormation.data!);
      }
    } catch (e) {
      logMatchDetails('formations error: $e');
    }

    try {
      final standingsState = await repo.getStandings(
        leagueId: _match.competition.id,
        allowMockFallback: !_isApiFixture,
      );
      logMatchDetails(
        'standings league=${_match.competition.id} '
        'source=${standingsState.fromMock ? "mock-fallback" : "api"} '
        'count=${standingsState.data?.length ?? 0}',
      );
      _noteDetailsError(standingsState, repo);
      if (_acceptRepositoryResult(standingsState)) {
        final data = standingsState.data;
        if (data != null) standings = data;
      }
    } catch (e) {
      logMatchDetails('standings error: $e');
    }

    final allowMock = _allowMockFill(repo);
    final momentum = _momentumFromStats(stats) ??
        (_isApiFixture ? 0.5 : base.momentumHome);

    if (!mounted) return;
    setState(() {
      _refreshingDetails = false;
      _lastUpdated = DateTime.now();
      _match = displayMatchFor(
        base.copyWith(
          fixtureId: fixtureId,
          events: events,
          stats: stats,
          homeLineup: homeLineup,
          awayLineup: awayLineup,
          standings: standings,
          momentumHome: momentum,
          liveCommentary:
              _isApiFixture && base.liveCommentary.isEmpty
                  ? const []
                  : base.liveCommentary,
        ),
        allowMockFill: allowMock,
      );
      _displayMinute = _parseMinute(_match);
    });
    _startLiveTimers();
  }

  LineupModel _mergeFormation(LineupModel lineup, FormationModel formation) {
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

  double? _momentumFromStats(List<MatchStatisticModel> stats) {
    for (final stat in stats) {
      if (!stat.title.toLowerCase().contains('possession')) continue;
      final total = stat.home + stat.away;
      if (total <= 0) continue;
      return (stat.home / total).clamp(0.05, 0.95);
    }
    return null;
  }

  @override
  void dispose() {
    _refresh?.removeListener(_onAutoRefresh);
    _minuteTimer?.cancel();
    _commentaryTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
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

  Widget _buildSelectedTabBody(
    BuildContext context,
    MatchModel match,
    bool allowMock,
  ) {
    switch (_bodyTabIndex) {
      case 0:
        return _buildOverviewBody(match);
      case 1:
        return _buildStatsBody(context, match, allowMock: allowMock);
      case 2:
        return _buildLineupsBody(context, match, allowMock: allowMock);
      case 3:
        return _buildStandingsBody(context, match, allowMock: allowMock);
      default:
        return _buildOverviewBody(match);
    }
  }

  Widget _tabEmptyScroll(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        AsyncContentView(
          loading: false,
          isEmpty: true,
          onRetry: _onPullRefresh,
          emptyIcon: icon,
          emptyTitle: title,
          emptySubtitle: subtitle ?? _detailsError,
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Overview — timeline + live momentum (unchanged behaviour).
  Widget _buildOverviewBody(MatchModel match) {
    final text = AppText.of(context);
    return _OverviewTab(
      match: match,
      showMomentum: match.status == MatchStatus.live,
      commentaryIndex: _commentaryIndex,
      eventsEmptyTitle: _isApiFixture
          ? (text.isArabic
              ? 'الأحداث غير متوفرة بعد'
              : 'Events are not available yet')
          : null,
      eventsEmptySubtitle: _isApiFixture ? null : null,
    );
  }

  List<MatchStatisticModel> _guaranteedStats(
    MatchModel match, {
    required bool allowMockFill,
  }) {
    const requiredTitles = [
      'Possession',
      'Shots',
      'Shots on target',
      'Corners',
      'Fouls',
      'Yellow cards',
    ];
    final all = allowMockFill
        ? displayMatchFor(match, allowMockFill: true).stats
        : match.stats;
    final picked = <MatchStatisticModel>[];
    for (final title in requiredTitles) {
      for (final stat in all) {
        if (stat.title.toLowerCase().contains(title.toLowerCase()) &&
            !picked.any((p) => p.title == stat.title)) {
          picked.add(stat);
          break;
        }
      }
    }
    if (picked.length >= 6 || !allowMockFill) return picked;
    final seedStats = MockData.matches().first.stats;
    for (final title in requiredTitles) {
      if (picked.length >= 6) break;
      final found = seedStats.where(
        (s) => s.title.toLowerCase().contains(title.toLowerCase()),
      );
      if (found.isNotEmpty && !picked.any((p) => p.title == found.first.title)) {
        picked.add(found.first);
      }
    }
    return picked.isNotEmpty ? picked : seedStats.take(6).toList();
  }

  /// Stats — mock-filled offline; real API data when configured.
  Widget _buildStatsBody(
    BuildContext context,
    MatchModel match, {
    required bool allowMock,
  }) {
    final text = AppText.of(context);
    final display =
        allowMock ? displayMatchFor(match, allowMockFill: true) : match;
    final stats = _guaranteedStats(match, allowMockFill: allowMock);

    if (stats.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onPullRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: _tabEmptyScroll(
          context,
          icon: Icons.bar_chart_rounded,
          title: text.isArabic
              ? 'الإحصائيات غير متوفرة بعد'
              : 'Statistics are not available yet',
          subtitle: _isApiFixture ? null : _detailsError,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onPullRefresh,
      color: Theme.of(context).colorScheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _TeamComparisonCard(match: display),
          const SizedBox(height: 14),
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _MatchStatBarCard(stat: stats[i]),
          ],
        ],
      ),
    );
  }

  /// Lineups — green pitch; mock XI when offline.
  Widget _buildLineupsBody(
    BuildContext context,
    MatchModel match, {
    required bool allowMock,
  }) {
    final text = AppText.of(context);
    final display =
        allowMock ? displayMatchFor(match, allowMockFill: true) : match;
    final homeLineup =
        _effectiveLineup(display, home: true, allowMockFill: allowMock);
    final awayLineup =
        _effectiveLineup(display, home: false, allowMockFill: allowMock);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPitch =
        homeLineup.hasPitchPlayers || awayLineup.hasPitchPlayers;

    if (!hasPitch) {
      return RefreshIndicator(
        onRefresh: _onPullRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: _tabEmptyScroll(
          context,
          icon: Icons.groups_rounded,
          title: text.isArabic
              ? 'التشكيلات غير متوفرة بعد'
              : 'Lineups are not available yet',
          subtitle: _isApiFixture ? null : _detailsError,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onPullRefresh,
      color: Theme.of(context).colorScheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LineupPitchHeader(
                  homeName: display.homeTeam.name,
                  awayName: display.awayTeam.name,
                  homeShort: display.homeTeam.shortName,
                  awayShort: display.awayTeam.shortName,
                  homeLogoUrl: display.homeTeam.logo,
                  awayLogoUrl: display.awayTeam.logo,
                  homeFormation: homeLineup.formation,
                  awayFormation: awayLineup.formation,
                ),
                const SizedBox(height: 12),
                DualTeamLineupPitch(
                  homeLineup: homeLineup,
                  awayLineup: awayLineup,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _TeamLineupExtras(
            teamName: display.homeTeam.name,
            shortName: display.homeTeam.shortName,
            logoUrl: display.homeTeam.logo,
            lineup: homeLineup,
          ),
          const SizedBox(height: 10),
          _TeamLineupExtras(
            teamName: display.awayTeam.name,
            shortName: display.awayTeam.shortName,
            logoUrl: display.awayTeam.logo,
            lineup: awayLineup,
          ),
        ],
      ),
    );
  }

  List<StandingModel> _guaranteedStandings(
    MatchModel match, {
    required bool allowMockFill,
  }) {
    final fromMatch = allowMockFill
        ? displayMatchFor(match, allowMockFill: true).standings
        : match.standings;
    if (fromMatch.isNotEmpty) return fromMatch;
    if (!allowMockFill) return const [];
    return MockData.standings;
  }

  /// Standings — table with position / team / played / points.
  Widget _buildStandingsBody(
    BuildContext context,
    MatchModel match, {
    required bool allowMock,
  }) {
    final text = AppText.of(context);
    final standings = _guaranteedStandings(match, allowMockFill: allowMock);

    if (standings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onPullRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: _tabEmptyScroll(
          context,
          icon: Icons.leaderboard_rounded,
          title: text.isArabic
              ? 'الترتيب غير متوفر بعد'
              : 'Standings not available yet',
          subtitle: _detailsError,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onPullRefresh,
      color: Theme.of(context).colorScheme.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    text.isArabic ? 'الفريق' : 'Team',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    text.isArabic ? 'لعب' : 'P',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    text.isArabic ? 'نقاط' : 'Pts',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < standings.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _StandingsRowCard(item: standings[i], rank: i),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final repo = AppScope.footballRepositoryOf(context);
    final allowMock = _allowMockFill(repo);
    final match = displayMatchFor(m, allowMockFill: allowMock);
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
          isScrollable: false,
          onTap: _selectTab,
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
            match: match,
            statusLabel: _statusLabel(text),
            minuteLabel: _minuteOrStatus(text),
          ),
          LiveUpdateIndicator(
            lastUpdated: _lastUpdated ?? _refresh?.lastRefreshedAt,
            refreshing:
                _refreshingDetails || (_refresh?.isRefreshing ?? false),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          ),
          Expanded(
            child: _buildSelectedTabBody(context, match, allowMock),
          ),
        ],
      ),
    );
  }
}

LineupModel? _lineupOrSeed(LineupModel? value, LineupModel? seed, LineupModel fallback) {
  if (value != null && value.hasPitchPlayers) return value;
  if (seed != null && seed.hasPitchPlayers) return seed;
  return fallback;
}

/// Fills missing tab data from mock seeds when [allowMockFill] is true (demo/offline).
MatchModel displayMatchFor(
  MatchModel source, {
  bool allowMockFill = true,
}) {
  if (!allowMockFill) return source;

  final seed = MockData.matchById(source.id) ?? MockData.matches().first;

  var momentum = source.momentumHome;
  if (momentum <= 0.01 || momentum >= 0.99) {
    momentum = seed.momentumHome;
  }

  return source.copyWith(
    events: source.events.isNotEmpty ? source.events : seed.events,
    stats: source.stats.isNotEmpty ? source.stats : seed.stats,
    standings:
        source.standings.isNotEmpty ? source.standings : seed.standings,
    homeLineup: _lineupOrSeed(
      source.homeLineup,
      seed.homeLineup,
      MockData.argentinaLineup(),
    ),
    awayLineup: _lineupOrSeed(
      source.awayLineup,
      seed.awayLineup,
      MockData.franceLineup(),
    ),
    liveCommentary: source.liveCommentary.isNotEmpty
        ? source.liveCommentary
        : seed.liveCommentary,
    momentumHome: momentum,
  );
}

/// Single stat bar used by the Stats tab body (always visible).
class _MatchStatBarCard extends StatelessWidget {
  const _MatchStatBarCard({required this.stat});

  final MatchStatisticModel stat;

  @override
  Widget build(BuildContext context) {
    final total = (stat.home + stat.away).clamp(0.001, double.infinity);
    final homeRate = (stat.home / total).clamp(0.0, 1.0);
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatValuePill(value: stat.homeValue, color: primary),
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
              _StatValuePill(value: stat.awayValue, color: secondary),
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
                    flex: (homeRate * 1000).round().clamp(1, 999),
                    child: ColoredBox(color: primary),
                  ),
                  Expanded(
                    flex: ((1 - homeRate) * 1000).round().clamp(1, 999),
                    child: ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatValuePill extends StatelessWidget {
  const _StatValuePill({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
      ),
    );
  }
}

class _StandingsRowCard extends StatelessWidget {
  const _StandingsRowCard({required this.item, required this.rank});

  final StandingModel item;
  final int rank;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${item.position}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
            ),
            TeamLogo(shortName: item.team.shortName, imageUrl: item.team.logo, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${item.played}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${item.points}',
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overview tab only — live momentum strip belongs here, not on other tabs.
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.match,
    required this.showMomentum,
    required this.commentaryIndex,
    this.eventsEmptyTitle,
    this.eventsEmptySubtitle,
  });

  final MatchModel match;
  final bool showMomentum;
  final int commentaryIndex;
  final String? eventsEmptyTitle;
  final String? eventsEmptySubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMomentum)
          _LiveFeelStrip(
            momentumHome: match.momentumHome,
            commentary: match.liveCommentary,
            commentaryIndex: commentaryIndex,
            homeShort: match.homeTeam.shortName,
            awayShort: match.awayTeam.shortName,
          ),
        Expanded(
          child: PrimaryScrollController.none(
            child: MatchTimeline(
              match: match,
              emptyTitle: eventsEmptyTitle,
              emptySubtitle: eventsEmptySubtitle,
            ),
          ),
        ),
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
                  CompetitionBadge.fromCompetition(
                    match.competition,
                    size: 36,
                  ),
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
                      logoUrl: match.homeTeam.logoUrl.isNotEmpty
                          ? match.homeTeam.logoUrl
                          : match.homeTeam.logo,
                      flagUrl: match.homeTeam.flagUrl,
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
                      logoUrl: match.awayTeam.logoUrl.isNotEmpty
                          ? match.awayTeam.logoUrl
                          : match.awayTeam.logo,
                      flagUrl: match.awayTeam.flagUrl,
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
  const _TeamBlock({
    required this.name,
    required this.shortName,
    this.logoUrl,
    this.flagUrl,
  });

  final String name;
  final String shortName;
  final String? logoUrl;
  final String? flagUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TeamLogo(
            shortName: shortName,
            imageUrl: logoUrl,
            flagUrl: flagUrl,
            size: 58,
          ),
        ),
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

LineupModel _effectiveLineup(
  MatchModel match, {
  required bool home,
  bool allowMockFill = true,
}) {
  final fromMatch = home ? match.homeLineup : match.awayLineup;
  if (fromMatch != null && fromMatch.hasPitchPlayers) {
    return fromMatch.forPitchDisplay();
  }

  if (!allowMockFill) {
    return LineupModel(
      formation: fromMatch?.formation ?? '',
      coach: fromMatch?.coach ?? '',
      lines: const [],
      substitutes: fromMatch?.substitutes ?? const [],
      injured: fromMatch?.injured ?? const [],
      missing: fromMatch?.missing ?? const [],
    );
  }

  for (final mock in MockData.matches()) {
    if (mock.id != match.id) continue;
    final mockLineup = home ? mock.homeLineup : mock.awayLineup;
    if (mockLineup != null && mockLineup.hasPitchPlayers) {
      return mockLineup.forPitchDisplay();
    }
  }

  return (home ? MockData.argentinaLineup() : MockData.franceLineup())
      .forPitchDisplay();
}

class _TeamLineupExtras extends StatelessWidget {
  const _TeamLineupExtras({
    required this.teamName,
    required this.shortName,
    required this.lineup,
    this.logoUrl,
  });

  final String teamName;
  final String shortName;
  final String? logoUrl;
  final LineupModel lineup;

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
              TeamLogo(shortName: shortName, imageUrl: logoUrl, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  teamName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: -0.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                        PlayerAvatar(
                          player: p,
                          size: 22,
                          borderWidth: 1,
                        ),
                        if (p.number > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${p.number}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 96),
                          child: Text(
                            p.shortName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
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
