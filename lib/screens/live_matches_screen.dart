import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../core/constants/api_cache_policy.dart';
import '../core/refresh/match_refresh_service.dart';
import '../models/match_model.dart';
import '../widgets/ad_placeholder.dart';
import '../widgets/async_content_view.dart';
import '../widgets/live_badge.dart';
import '../widgets/live_update_indicator.dart';
import '../widgets/match_card.dart';
import '../widgets/native_ad_placeholder.dart';

/// Full list of live matches (Home → Live now → See all).
class LiveMatchesScreen extends StatefulWidget {
  const LiveMatchesScreen({super.key, this.seedMatches});

  final List<MatchModel>? seedMatches;

  @override
  State<LiveMatchesScreen> createState() => _LiveMatchesScreenState();
}

class _LiveMatchesScreenState extends State<LiveMatchesScreen> {
  bool _loading = true;
  bool _refreshing = false;
  String? _loadError;
  List<MatchModel> _matches = [];
  String _query = '';
  MatchRefreshService? _refresh;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    if (widget.seedMatches != null && widget.seedMatches!.isNotEmpty) {
      _matches = List<MatchModel>.from(widget.seedMatches!);
      _loading = false;
      _lastUpdated = DateTime.now();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh = AppScope.matchRefreshServiceOf(context);
      _refresh!.addListener(_onAutoRefresh);
      _load(silent: _matches.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _refresh?.removeListener(_onAutoRefresh);
    super.dispose();
  }

  void _onAutoRefresh() => _load(silent: true);

  Future<void> _load({bool silent = false, bool forceRefresh = false}) async {
    if (!silent && mounted) {
      setState(() => _loading = true);
    } else if (mounted) {
      setState(() => _refreshing = true);
    }

    final repo = AppScope.footballRepositoryOf(context);
    final state = await repo.getLiveMatches(forceRefresh: forceRefresh);

    final matches = state.hasError ? <MatchModel>[] : (state.data ?? []);

    if (mounted) {
      final text = AppText.of(context);
      String? loadError;
      if (repo.usesLiveApi && state.hasError && matches.isEmpty) {
        loadError = state.errorMessage ??
            ApiCachePolicy.rateLimitMessage(isArabic: text.isArabic);
      }
      setState(() {
        _loading = false;
        _refreshing = false;
        _matches = matches;
        _loadError = loadError;
        _lastUpdated = DateTime.now();
      });
    }
  }

  List<MatchModel> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _matches;
    return _matches.where((m) {
      return m.homeTeam.name.toLowerCase().contains(q) ||
          m.awayTeam.name.toLowerCase().contains(q) ||
          m.competition.name.toLowerCase().contains(q);
    }).toList();
  }

  Map<String, List<MatchModel>> get _grouped {
    final map = <String, List<MatchModel>>{};
    for (final match in _filtered) {
      map.putIfAbsent(match.competition.name, () => []).add(match);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final theme = Theme.of(context);
    final filtered = _filtered;
    final grouped = _grouped;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          text.liveMatchesSeeAllTitle,
          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.3),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const LiveBadge(dense: true),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text.matchesCountLabel(_matches.length),
                          style: TextStyle(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: text.liveMatchesSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded, size: 22),
                      isDense: true,
                      filled: true,
                      fillColor: theme.cardTheme.color,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_loading)
              LiveUpdateIndicator(
                lastUpdated: _lastUpdated ?? _refresh?.lastRefreshedAt,
                refreshing: _refreshing || (_refresh?.isRefreshing ?? false),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final refresh = AppScope.matchRefreshServiceOf(context);
                  await refresh.refreshAll(force: true);
                  await _load(silent: true, forceRefresh: true);
                },
                color: theme.colorScheme.primary,
                child: AsyncContentView(
                  loading: _loading,
                  isEmpty: !_loading && filtered.isEmpty,
                  onRetry: () => _load(forceRefresh: true),
                  emptyIcon: Icons.sports_soccer_outlined,
                  emptyTitle: _loadError != null
                      ? (text.isArabic
                          ? 'تعذر تحميل المباريات الحية'
                          : 'Could not load live matches')
                      : (_query.isNotEmpty
                          ? text.liveMatchesSearchEmpty
                          : text.noMatches),
                  emptySubtitle: _loadError ?? text.noMatchesSub,
                  skeleton: const MatchListSkeleton(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: _buildGroupedList(context, text, grouped),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedList(
    BuildContext context,
    AppText text,
    Map<String, List<MatchModel>> grouped,
  ) {
    if (grouped.isEmpty) return const [];

    final widgets = <Widget>[];
    var matchIndex = 0;
    final variants = [
      ContentSpotlightVariant.matchInsights,
      ContentSpotlightVariant.matchSpotlight,
      ContentSpotlightVariant.matchPartner,
    ];

    for (final entry in grouped.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
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
                child: Text(
                  entry.key,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Text(
                '${entry.value.length}',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );

      for (final match in entry.value) {
        matchIndex++;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
        if (matchIndex % 5 == 0) {
          widgets.addAll([
            NativeAdPlaceholder(
              variant: variants[(matchIndex ~/ 5 - 1) % variants.length],
              feedItemIndex: matchIndex,
            ),
            const SizedBox(height: 10),
          ]);
        }
      }
    }
    return widgets;
  }
}
