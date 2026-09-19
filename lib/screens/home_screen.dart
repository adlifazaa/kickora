import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../core/competition/competition_priority_resolver.dart';
import '../core/match/featured_match_selector.dart';
import '../core/refresh/match_refresh_category.dart';
import '../core/refresh/match_refresh_service.dart';
import '../core/startup/startup_timing.dart';
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
import '../widgets/section_header.dart';
import '../widgets/skeleton_box.dart';
import '../utils/live_match_overlay.dart';
import '../widgets/top_competitions_module.dart';

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
  List<CompetitionModel> _topCompetitions = [];
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
        : (liveState.data ?? []);

    setState(() {
      _refreshing = false;
      _lastUpdated = DateTime.now();
      _liveMatches = liveMatches;
      _todayMatches = LiveMatchOverlay.overlay(_todayMatches, liveMatches);
      _featuredMatch = FeaturedMatchSelector.pick(
        liveMatches: liveMatches,
        upcomingMatches: _todayMatches,
        finishedMatches: _todayMatches,
      );
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

    final critical = await Future.wait([
      repo.getLiveMatches(forceRefresh: forceRefresh),
      repo.getMatches(date: today, forceRefresh: forceRefresh),
    ]);

    final liveState = critical[0];
    final allTodayState = critical[1];

    var liveMatches = liveState.hasError
        ? <MatchModel>[]
        : (liveState.data ?? []);
    final allToday = allTodayState.hasError ? <MatchModel>[] : (allTodayState.data ?? []);
    var todayMatches = allToday.where((m) => m.status != MatchStatus.finished).toList();
    todayMatches = LiveMatchOverlay.overlay(todayMatches, liveMatches);
    final featuredMatch = FeaturedMatchSelector.pick(
      liveMatches: liveMatches,
      upcomingMatches: allToday,
      finishedMatches: allToday,
    );

    if (repo.usesLiveApi) {
      if (liveState.hasError && liveMatches.isEmpty) {
        loadError = liveState.errorMessage;
      }
      if (allTodayState.hasError && todayMatches.isEmpty) {
        loadError ??= allTodayState.errorMessage;
      }
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _refreshing = false;
        _lastUpdated = DateTime.now();
        _loadError = repo.usesLiveApi ? loadError : null;
        _liveMatches = liveMatches;
        _todayMatches = todayMatches;
        _featuredMatch = featuredMatch;
      });
    }
    StartupTiming.mark('home_critical_loaded');
    StartupTiming.mark('backend_first_request');

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

    final featuredMatch = FeaturedMatchSelector.pick(
      liveMatches: _liveMatches,
      upcomingMatches: _todayMatches,
      finishedMatches: _todayMatches,
    );
    final topCompetitions = CompetitionPriorityResolver.topCompetitions(
      competitions: competitions,
      liveMatches: _liveMatches,
      todayMatches: _todayMatches,
      upcomingMatches: _todayMatches,
    );

    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _lastUpdated = DateTime.now();
      _featuredMatch = featuredMatch;
      _competitions = competitions;
      _topCompetitions = topCompetitions;
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
            TopCompetitionsModule(
              competitions: _topCompetitions,
              loading: _loading && _topCompetitions.isEmpty,
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
                          ? (text.isArabic ? 'المباراة القادمة' : 'Next featured match')
                          : (text.isArabic ? 'آخر نتيجة' : 'Latest result')),
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
