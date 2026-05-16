import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../core/refresh/match_refresh_category.dart';
import '../core/refresh/match_refresh_service.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../data/mock_data.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  List<MatchModel> _liveMatches = [];
  List<MatchModel> _todayMatches = [];
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
    if (category == null ||
        category == MatchRefreshCategory.live ||
        category == MatchRefreshCategory.all) {
      _load(silent: true);
    }
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

    var liveMatches = <MatchModel>[];
    final liveState = await repo.getLiveMatches(forceRefresh: forceRefresh);
    if (liveState.hasError) {
      liveMatches = [];
    } else {
      liveMatches = liveState.data ?? [];
    }

    var todayMatches = <MatchModel>[];
    final allState = await repo.getMatches(date: today, forceRefresh: forceRefresh);
    if (allState.hasError) {
      todayMatches = [];
    } else {
      final all = allState.data ?? [];
      todayMatches =
          all.where((m) => m.status != MatchStatus.finished).toList();
    }

    final compState = await repo.getCompetitions(forceRefresh: forceRefresh);
    List<CompetitionModel> competitions;
    if (compState.hasError) {
      competitions = [];
    } else if (repo.usesLiveApi) {
      competitions = compState.data ?? [];
    } else {
      competitions = compState.data ?? MockData.competitions;
    }

    if (repo.usesLiveApi) {
      if (liveState.hasError && liveMatches.isEmpty) {
        loadError = liveState.errorMessage;
      }
      if (allState.hasError && todayMatches.isEmpty) {
        loadError ??= allState.errorMessage;
      }
    }

    CompetitionModel? featured;
    for (final c in competitions) {
      if (c.isFeatured) {
        featured = c;
        break;
      }
    }
    featured ??= competitions.isNotEmpty ? competitions.first : null;

    if (mounted) {
      setState(() {
        _loading = false;
        _refreshing = false;
        _lastUpdated = DateTime.now();
        _loadError = repo.usesLiveApi ? loadError : null;
        _liveMatches = liveMatches;
        _todayMatches = todayMatches;
        _competitions = competitions;
        _featuredCompetition = featured;
      });
    }
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
              if (_liveMatches.isNotEmpty) ...[
                SectionHeader(
                  title: text.featuredMatch,
                  subtitle: text.homeFeaturedLiveSubtitle,
                  icon: Icons.star_rounded,
                ),
                const SizedBox(height: 10),
                _FeaturedMatchSlot(match: _liveMatches.first),
                const SizedBox(height: 20),
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
                ...insertFeedSpotlights(
                  context: context,
                  skipFirst: 0,
                  interval: 4,
                  items: [
                    for (var i = 0; i < _liveMatches.length; i++)
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
              ] else if (_loadError == null) ...[
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
            if (featuredCompetition != null) ...[
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
          tooltip: text.about,
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.about),
          icon: const Icon(Icons.info_outline_rounded),
        ),
      ],
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
