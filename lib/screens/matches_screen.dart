import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../core/refresh/match_refresh_service.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../models/match_model.dart';
import '../widgets/ad_placeholder.dart';
import '../widgets/native_ad_placeholder.dart';
import '../widgets/async_content_view.dart';
import '../widgets/live_update_indicator.dart';
import '../widgets/match_card.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  List<MatchModel> _live = [];
  List<MatchModel> _upcoming = [];
  List<MatchModel> _finished = [];
  MatchRefreshService? _refresh;
  DateTime? _lastUpdated;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh = AppScope.matchRefreshServiceOf(context);
      _refresh!.addListener(_onAutoRefresh);
      _load();
    });
  }

  @override
  void dispose() {
    _refresh?.removeListener(_onAutoRefresh);
    _tabController.dispose();
    super.dispose();
  }

  void _onAutoRefresh() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _loading = true);
    } else if (mounted) {
      setState(() => _refreshing = true);
    }

    final repo = AppScope.footballRepositoryOf(context);
    final refresh = AppScope.matchRefreshServiceOf(context);
    refresh.setSelectedDate(_selectedDate);
    final force = silent;
    final results = await Future.wait([
      repo.getLiveMatches(date: _selectedDate, forceRefresh: force),
      repo.getUpcomingMatches(date: _selectedDate, forceRefresh: force),
      repo.getFinishedMatches(date: _selectedDate, forceRefresh: force),
    ]);

    if (mounted) {
      setState(() {
        _loading = false;
        _refreshing = false;
        _lastUpdated = DateTime.now();
        _live = results[0].data ?? [];
        _upcoming = results[1].data ?? [];
        _finished = results[2].data ?? [];
      });
    }
  }

  DateTime? get _displayLastUpdated =>
      _lastUpdated ?? _refresh?.lastRefreshedAt;

  Future<void> _onRefresh() async {
    final refresh = AppScope.matchRefreshServiceOf(context);
    refresh.setSelectedDate(_selectedDate);
    await refresh.refreshAll(force: true);
    await _load(silent: true);
  }

  List<MatchModel> _matchesForTab(int index) {
    switch (index) {
      case 0:
        return _live;
      case 1:
        return _upcoming;
      default:
        return _finished;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text.matches,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4)),
                      Text(text.homeSubtitle,
                          style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                _DateChip(
                  date: _selectedDate,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2028),
                      initialDate: _selectedDate,
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() => _selectedDate = picked);
                      await _load();
                    }
                  },
                ),
              ],
            ),
          ),
          _PremiumTabBar(
            controller: _tabController,
            tabs: [text.live, text.upcoming, text.finished],
          ),
          if (!_loading)
            LiveUpdateIndicator(
              lastUpdated: _displayLastUpdated,
              refreshing: _refreshing || (_refresh?.isRefreshing ?? false),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: List.generate(3, (index) {
                final matches = _matchesForTab(index);
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: Theme.of(context).colorScheme.primary,
                  child: AsyncContentView(
                    loading: _loading,
                    isEmpty: !_loading && matches.isEmpty,
                    onRetry: _load,
                    skeleton: const MatchListSkeleton(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: _buildGrouped(matches, context, text),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGrouped(
      List<MatchModel> matches, BuildContext context, AppText text) {
    final grouped = <String, List<MatchModel>>{};
    for (final match in matches) {
      grouped.putIfAbsent(match.competition.name, () => []).add(match);
    }
    final widgets = <Widget>[];
    var matchIndex = 0;
    const variants = [
      ContentSpotlightVariant.matchInsights,
      ContentSpotlightVariant.matchSpotlight,
      ContentSpotlightVariant.matchPartner,
    ];
    grouped.forEach((competition, list) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.teal, AppColors.neonGreen],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(competition,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13.5)),
              ),
              Text('${list.length}',
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
      for (final match in list) {
        matchIndex++;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MatchCard(
              match: match,
              onTap: () => Navigator.pushNamed(
                  context, AppRoutes.matchDetails, arguments: match),
            ),
          ),
        );
        if (matchIndex % 4 == 0) {
          widgets.addAll([
            NativeAdPlaceholder(
              variant: variants[(matchIndex ~/ 4 - 1) % variants.length],
              feedItemIndex: matchIndex,
            ),
            const SizedBox(height: 10),
          ]);
        }
      }
      widgets.add(const SizedBox(height: 6));
    });
    return widgets;
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_rounded, size: 16, color: primary),
              const SizedBox(width: 6),
              Text('${date.day}/${date.month}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumTabBar extends StatelessWidget {
  const _PremiumTabBar({required this.controller, required this.tabs});

  final TabController controller;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: TabBar(
        controller: controller,
        labelColor: Colors.black,
        unselectedLabelColor: Theme.of(context).hintColor,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient:
              const LinearGradient(colors: [AppColors.teal, AppColors.neonGreen]),
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
        splashBorderRadius: BorderRadius.circular(10),
        dividerColor: Colors.transparent,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}
