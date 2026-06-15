import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../core/constants/world_cup_config.dart';
import '../core/refresh/match_refresh_category.dart';
import '../core/refresh/match_refresh_service.dart';
import '../core/startup/startup_timing.dart';
import '../core/world_cup/world_cup_priority.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../data/mock_data.dart';
import '../data/repositories/football_repository.dart';
import '../models/competition_model.dart';
import '../models/match_model.dart';
import '../widgets/banner_placeholder.dart';
import '../widgets/live_update_indicator.dart';
import '../widgets/async_content_view.dart';
import '../widgets/competition_card.dart';
import '../widgets/feed_spotlight.dart';
import '../widgets/match_card.dart';
import '../widgets/micro_interactions.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/team_logo.dart';
import '../widgets/world_cup_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  List<MatchModel> _liveMatches = [];
  List<MatchModel> _todayMatches = [];
  MatchModel? _featuredMatch;
  List<CompetitionModel> _competitions = [];
  CompetitionModel? _featuredCompetition;
  MatchRefreshService? _refresh;
  DateTime? _lastUpdated;
  bool _refreshing = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh = AppScope.matchRefreshServiceOf(context);
      _refresh!.addListener(_onAutoRefresh);
      _load();
    });
  }

  @override
  void dispose() {
    _refresh?.removeListener(_onAutoRefresh);
    super.dispose();
  }

  void _onAutoRefresh() {
    final category = _refresh?.lastRefreshCategory;
    if (category == MatchRefreshCategory.all) {
      _load(silent: true);
    } else if (category == MatchRefreshCategory.live) {
      _refreshLiveOnly(silent: true);
    }
  }

  Future<void> _refreshLiveOnly({bool silent = false}) async {
    if (mounted && !silent) {
      setState(() => _refreshing = true);
    } else if (mounted) {
      setState(() => _refreshing = true);
    }

    final repo = AppScope.footballRepositoryOf(context);
    final liveState = await repo.getLiveMatches();
    if (!mounted) return;

    final liveMatches = liveState.hasError
        ? _liveMatches
        : WorldCupPriority.sortMatches(liveState.data ?? []);
    final featuredMatch = WorldCupPriority.pickFeaturedMatch(
      liveMatches: liveState.data ?? _liveMatches,
      wcDayMatches: _todayMatches,
    );

    setState(() {
      _refreshing = false;
      _lastUpdated = DateTime.now();
      _liveMatches = liveMatches;
      _featuredMatch = featuredMatch;
    });
  }

  Future<void> _load({bool silent = false, bool forceRefresh = false}) async {
    if (!silent && mounted) {
      setState(() => _loading = true);
    } else if (mounted) {
      setState(() => _refreshing = true);
    }

    final repo = AppScope.footballRepositoryOf(context);
    final today = DateTime.now();
    String? loadError;

    unawaited(repo.ensureWorldCupReady());

    final critical = await Future.wait([
      repo.getLiveMatches(forceRefresh: forceRefresh),
      repo.getMatches(date: today, forceRefresh: forceRefresh),
    ]);

    final liveState = critical[0];
    final allTodayState = critical[1];

    var liveMatches = liveState.hasError
        ? <MatchModel>[]
        : WorldCupPriority.sortMatches(liveState.data ?? []);
    final allToday = allTodayState.hasError ? <MatchModel>[] : (allTodayState.data ?? []);
    final wcDayPool =
        allToday.where(WorldCupPriority.isWorldCupMatch).toList();
    var todayMatches = WorldCupPriority.sortMatches(
      allToday.where((m) => m.status != MatchStatus.finished).toList(),
    );
    final featuredMatch = WorldCupPriority.pickFeaturedMatch(
      liveMatches: liveState.data ?? [],
      wcDayMatches: wcDayPool,
    );

    if (repo.usesLiveApi) {
      if (liveState.hasError && liveMatches.isEmpty) {
        loadError = liveState.errorMessage;
      }
      if (allTodayState.hasError && todayMatches.isEmpty) {
        loadError ??= allTodayState.errorMessage;
      }
    }

    CompetitionModel? featured = WorldCupPriority.findWorldCup(_competitions);

    if (mounted) {
      setState(() {
        _loading = false;
        _refreshing = false;
        _lastUpdated = DateTime.now();
        _loadError = repo.usesLiveApi ? loadError : null;
        _liveMatches = liveMatches;
        _todayMatches = todayMatches;
        _featuredMatch = featuredMatch;
        _featuredCompetition = featured;
      });
    }
    StartupTiming.mark('home_critical_loaded');
    StartupTiming.mark('backend_first_request');
    unawaited(_refresh?.start());

    unawaited(_loadHomeSecondary(
      repo: repo,
      today: today,
      forceRefresh: forceRefresh,
      silent: silent,
    ));
  }

  Future<void> _loadHomeSecondary({
    required FootballRepository repo,
    required DateTime today,
    required bool forceRefresh,
    required bool silent,
  }) async {
    final secondary = await repo.getCompetitions(forceRefresh: forceRefresh);
    final compState = secondary;

    List<CompetitionModel> competitions;
    if (compState.hasError) {
      competitions = _competitions;
    } else if (repo.usesLiveApi) {
      competitions = compState.data ?? [];
    } else {
      competitions = compState.data ?? MockData.competitions;
    }

    final mergedToday = WorldCupPriority.sortMatches(_todayMatches);
    final liveMerged = WorldCupPriority.sortMatches(_liveMatches);
    final wcDayPool = mergedToday.where(WorldCupPriority.isWorldCupMatch).toList();
    final featuredMatch = WorldCupPriority.pickFeaturedMatch(
      liveMatches: liveMerged,
      wcDayMatches: wcDayPool,
    );

    final featured =
        WorldCupPriority.findWorldCup(competitions) ??
            (competitions.isNotEmpty ? competitions.first : null);

    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _lastUpdated = DateTime.now();
      _liveMatches = liveMerged;
      _todayMatches = mergedToday;
      _featuredMatch = featuredMatch;
      _competitions = competitions;
      _featuredCompetition = featured;
    });
    StartupTiming.mark('home_data_loaded');
  }

  Future<void> _onRefresh() async {
    final refresh = AppScope.matchRefreshServiceOf(context);
    await refresh.refreshAll(force: true);
    await _load(silent: true, forceRefresh: true);
  }

  DateTime? get _displayLastUpdated =>
      _lastUpdated ?? _refresh?.lastRefreshedAt;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final featuredCompetition = _featuredCompetition;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _HomeHeader(text: text),
            const SizedBox(height: 12),
            _WorldCupShortcutCard(
              competition: featuredCompetition ?? WorldCupConfig.fallbackCompetition(),
            ),
            const SizedBox(height: 14),
            if (!_loading)
              LiveUpdateIndicator(
                lastUpdated: _displayLastUpdated,
                refreshing: _refreshing || (_refresh?.isRefreshing ?? false),
              ),
            const SizedBox(height: 10),
            if (_loadError != null) ...[
              AsyncContentView(
                loading: false,
                isEmpty: true,
                onRetry: _onRefresh,
                emptyIcon: Icons.cloud_off_rounded,
                emptyTitle: text.isArabic
                    ? 'تعذر تحميل البيانات الحية'
                    : 'Could not load live data',
                emptySubtitle: _loadError!,
                child: const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
            ],
            if (_loading) ...[
              const _FeaturedMatchSlotSkeleton(),
              const SizedBox(height: 14),
              const MatchCardSkeleton(),
              const SizedBox(height: 10),
              const MatchCardSkeleton(),
            ] else ...[
              if (_featuredMatch != null) ...[
                SectionHeader(
                  title: text.featuredMatch,
                  subtitle: _featuredMatch!.status == MatchStatus.live
                      ? text.homeFeaturedLiveSubtitle
                      : (_featuredMatch!.status == MatchStatus.upcoming
                          ? (text.isArabic ? 'مباراة كأس العالم القادمة' : 'Next World Cup match')
                          : (text.isArabic ? 'آخر نتيجة كأس العالم' : 'Latest World Cup result')),
                  icon: Icons.star_rounded,
                ),
                const SizedBox(height: 10),
                _FeaturedMatchSlot(match: _featuredMatch!),
                const SizedBox(height: 20),
              ],
              if (_liveMatches.isNotEmpty) ...[
                if (_featuredMatch == null ||
                    _featuredMatch!.status != MatchStatus.live) ...[
                  SectionHeader(
                    title: text.liveNow,
                    subtitle: text.matchesCountLabel(_liveMatches.length),
                    icon: Icons.flash_on_rounded,
                    actionText: text.all,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.liveMatches,
                      arguments: _liveMatches,
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  SectionHeader(
                    title: text.liveNow,
                    subtitle: text.matchesCountLabel(_liveMatches.length),
                    icon: Icons.flash_on_rounded,
                    actionText: text.all,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.liveMatches,
                      arguments: _liveMatches,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                ...insertFeedSpotlights(
                  context: context,
                  skipFirst: 0,
                  interval: 4,
                  items: [
                    for (var i = 0; i < _liveMatches.length; i++)
                      if (_featuredMatch?.id != _liveMatches[i].id)
                        _StaggeredItem(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: MatchCard(
                              match: _liveMatches[i],
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.matchDetails,
                                  arguments: _liveMatches[i]),
                            ),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 20),
              ] else if (_loadError == null && _featuredMatch == null) ...[
                SectionHeader(
                  title: text.liveNow,
                  subtitle: text.matchesCountLabel(0),
                  icon: Icons.flash_on_rounded,
                ),
                const SizedBox(height: 10),
                AsyncContentView(
                  loading: false,
                  isEmpty: true,
                  onRetry: _load,
                  emptyIcon: Icons.sports_soccer_outlined,
                  emptyTitle: text.noMatches,
                  emptySubtitle: text.noMatchesSub,
                  child: const SizedBox.shrink(),
                ),
              ],
              const SizedBox(height: 4),
              SectionHeader(
                title: text.todayMatches,
                subtitle: text.matchesCountLabel(_todayMatches.length),
                icon: Icons.today_rounded,
              ),
              const SizedBox(height: 10),
              if (_todayMatches.isEmpty)
                AsyncContentView(
                  loading: false,
                  isEmpty: true,
                  onRetry: _load,
                  emptyIcon: Icons.today_rounded,
                  emptyTitle: text.noMatches,
                  emptySubtitle: text.noMatchesSub,
                  child: const SizedBox.shrink(),
                )
              else
                ...insertFeedSpotlights(
                  context: context,
                  interval: 4,
                  items: [
                    for (var i = 0; i < _todayMatches.length; i++)
                      _StaggeredItem(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: MatchCard(
                            match: _todayMatches[i],
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.matchDetails,
                                arguments: _todayMatches[i]),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
            if (featuredCompetition != null &&
                !WorldCupPriority.isWorldCupCompetition(featuredCompetition)) ...[
              const SizedBox(height: 6),
              _FeaturedCompetitionStrip(competition: featuredCompetition),
            ],
            const SizedBox(height: 20),
            SectionHeader(
              title: text.competitions,
              icon: Icons.emoji_events_rounded,
              actionText: text.more,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.competitions),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const SizedBox(
                height: 156,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_competitions.isEmpty)
              AsyncContentView(
                loading: false,
                isEmpty: true,
                onRetry: _load,
                emptyIcon: Icons.emoji_events_outlined,
                emptyTitle: text.noSearchResultsTitle,
                emptySubtitle: text.searchEmptySubtitle,
                child: const SizedBox.shrink(),
              )
            else
              SizedBox(
                height: 156,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemCount: _competitions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final competition = _competitions[index];
                    return CompetitionCard(
                      competition: competition,
                      onTap: () => Navigator.pushNamed(
                          context, AppRoutes.competitionDetails,
                          arguments: competition),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            const BannerPlaceholder(),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.text});
  final AppText text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.teal, AppColors.neonGreen],
            ),
            boxShadow: [
              BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.4),
                  blurRadius: 14),
            ],
          ),
          child:
              const Icon(Icons.sports_soccer_rounded, color: Colors.black87),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      )),
              Text(text.homeSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        IconButton(
          tooltip: text.globalSearchTitle,
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.globalSearch),
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: text.about,
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.about),
          icon: const Icon(Icons.info_outline_rounded),
        ),
      ],
    );
  }
}

class _WorldCupShortcutCard extends StatelessWidget {
  const _WorldCupShortcutCard({required this.competition});

  final CompetitionModel competition;

  void _open(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.competitionDetails,
      arguments: competition,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TapScale(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _open(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFD4AF37).withValues(alpha: 0.28),
                  primary.withValues(alpha: 0.22),
                  isDark
                      ? const Color(0xFF0A3D32)
                      : primary.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: isDark ? 0.25 : 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const WorldCupLogo(size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.isArabic ? 'كأس العالم' : 'World Cup',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        text.isArabic
                            ? '2026 • المباريات والنتائج والترتيب'
                            : '2026 • Matches, results & standings',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.teal, AppColors.neonGreen],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    text.isArabic ? 'افتح' : 'Open',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedCompetitionStrip extends StatelessWidget {
  const _FeaturedCompetitionStrip({required this.competition});

  final CompetitionModel competition;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return TapScale(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(
          context, AppRoutes.competitionDetails,
          arguments: competition),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
              context, AppRoutes.competitionDetails,
              arguments: competition),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.28),
                  primary.withValues(alpha: 0.07),
                ],
              ),
              border: Border.all(color: primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                CompetitionBadge.fromCompetition(competition, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.featuredCompetitionTitle,
                        style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(competition.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                              letterSpacing: -0.2)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single featured live match — no PageView, transforms, or carousel peek.
class _FeaturedMatchSlot extends StatelessWidget {
  const _FeaturedMatchSlot({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: MatchCard(
          match: match,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.matchDetails,
            arguments: match,
          ),
        ),
      ),
    );
  }
}

class _FeaturedMatchSlotSkeleton extends StatelessWidget {
  const _FeaturedMatchSlotSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: MatchCardSkeleton(),
      ),
    );
  }
}

class _StaggeredItem extends StatelessWidget {
  const _StaggeredItem({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
