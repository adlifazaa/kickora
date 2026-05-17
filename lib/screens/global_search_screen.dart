import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../data/mock_data.dart';
import '../models/competition_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/team_model.dart';
import '../widgets/async_content_view.dart';
import '../widgets/micro_interactions.dart';
import '../widgets/player_avatar.dart';
import '../widgets/team_logo.dart';

enum _SearchFilter { all, teams, players, competitions, matches }

enum GlobalSearchKind { team, player, competition, match }

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.payload,
  });

  final GlobalSearchKind kind;
  final String title;
  final String subtitle;
  final Object payload;
}

/// Global search across teams, players, competitions, and matches.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  _SearchFilter _filter = _SearchFilter.all;
  bool _loadingIndex = true;
  List<GlobalSearchResult> _index = const [];
  List<GlobalSearchResult> _visible = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildIndex());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _query = _controller.text.trim();
        _visible = _filterResults(_query, _filter);
      });
    });
  }

  Future<void> _buildIndex() async {
    final repo = AppScope.footballRepositoryOf(context);
    final teams = <TeamModel>[...MockData.teams];
    final players = <PlayerModel>[...MockData.players];
    final competitions = <CompetitionModel>[...MockData.competitions];
    final matches = <MatchModel>[...MockData.matches()];

    if (repo.usesLiveApi) {
      final compState = await repo.getCompetitions();
      if (!compState.hasError && compState.data != null) {
        competitions
          ..clear()
          ..addAll(compState.data!);
      }

      final today = DateTime.now();
      final seenMatchIds = <int>{};
      for (final state in [
        await repo.getLiveMatches(),
        await repo.getMatches(date: today),
        await repo.getUpcomingMatches(date: today),
        await repo.getFinishedMatches(date: today),
      ]) {
        if (state.hasError || state.data == null) continue;
        for (final m in state.data!) {
          if (seenMatchIds.add(m.id)) matches.add(m);
        }
      }
    }

    final teamIds = <int>{};
    final mergedTeams = <TeamModel>[];
    void addTeam(TeamModel t) {
      if (teamIds.add(t.id)) mergedTeams.add(t);
    }

    for (final t in teams) {
      addTeam(t);
    }
    for (final m in matches) {
      addTeam(m.homeTeam);
      addTeam(m.awayTeam);
    }

    final results = <GlobalSearchResult>[
      for (final t in mergedTeams)
        GlobalSearchResult(
          kind: GlobalSearchKind.team,
          title: t.name,
          subtitle: t.countryName.isNotEmpty ? t.countryName : t.nationality,
          payload: t,
        ),
      for (final p in players)
        GlobalSearchResult(
          kind: GlobalSearchKind.player,
          title: p.name,
          subtitle: '${p.team} · ${p.position}',
          payload: p,
        ),
      for (final c in competitions)
        GlobalSearchResult(
          kind: GlobalSearchKind.competition,
          title: c.name,
          subtitle: c.region,
          payload: c,
        ),
      for (final m in matches)
        GlobalSearchResult(
          kind: GlobalSearchKind.match,
          title: '${m.homeTeam.name} vs ${m.awayTeam.name}',
          subtitle: '${m.competition.name} · ${m.timeLabel}',
          payload: m,
        ),
    ];

    if (!mounted) return;
    setState(() {
      _loadingIndex = false;
      _index = results;
      _visible = _filterResults(_query, _filter);
    });
  }

  List<GlobalSearchResult> _filterResults(String query, _SearchFilter filter) {
    Iterable<GlobalSearchResult> list = _index;
    switch (filter) {
      case _SearchFilter.teams:
        list = list.where((r) => r.kind == GlobalSearchKind.team);
        break;
      case _SearchFilter.players:
        list = list.where((r) => r.kind == GlobalSearchKind.player);
        break;
      case _SearchFilter.competitions:
        list = list.where((r) => r.kind == GlobalSearchKind.competition);
        break;
      case _SearchFilter.matches:
        list = list.where((r) => r.kind == GlobalSearchKind.match);
        break;
      case _SearchFilter.all:
        break;
    }

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list.take(24).toList();

    return list
        .where((r) {
          final haystack = '${r.title} ${r.subtitle}'.toLowerCase();
          return haystack.contains(q);
        })
        .take(40)
        .toList();
  }

  void _onFilterTap(_SearchFilter filter) {
    setState(() {
      _filter = filter;
      _visible = _filterResults(_query, _filter);
    });
  }

  void _openResult(GlobalSearchResult result) {
    switch (result.kind) {
      case GlobalSearchKind.match:
        Navigator.pushNamed(
          context,
          AppRoutes.matchDetails,
          arguments: result.payload as MatchModel,
        );
        break;
      case GlobalSearchKind.competition:
        Navigator.pushNamed(
          context,
          AppRoutes.competitionDetails,
          arguments: result.payload as CompetitionModel,
        );
        break;
      case GlobalSearchKind.player:
        Navigator.pushNamed(
          context,
          AppRoutes.playerDetails,
          arguments: result.payload as PlayerModel,
        );
        break;
      case GlobalSearchKind.team:
        _showTeamSheet(context, result.payload as TeamModel);
        break;
    }
  }

  void _showTeamSheet(BuildContext context, TeamModel team) {
    final text = AppText.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TeamLogo.fromTeam(team, size: 72),
                const SizedBox(height: 14),
                Text(
                  team.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  team.countryName.isNotEmpty
                      ? team.countryName
                      : team.nationality,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(ctx).hintColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  text.isArabic
                      ? 'تفاصيل الفريق الكاملة قريبًا.'
                      : 'Full team profile coming soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(ctx).hintColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final hasQuery = _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          text.globalSearchTitle,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: text.globalSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _query = '';
                            _visible = _filterResults('', _filter);
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: text.categoryAll,
                  selected: _filter == _SearchFilter.all,
                  onTap: () => _onFilterTap(_SearchFilter.all),
                ),
                _FilterChip(
                  label: text.teams,
                  selected: _filter == _SearchFilter.teams,
                  onTap: () => _onFilterTap(_SearchFilter.teams),
                ),
                _FilterChip(
                  label: text.searchFilterPlayers,
                  selected: _filter == _SearchFilter.players,
                  onTap: () => _onFilterTap(_SearchFilter.players),
                ),
                _FilterChip(
                  label: text.competitions,
                  selected: _filter == _SearchFilter.competitions,
                  onTap: () => _onFilterTap(_SearchFilter.competitions),
                ),
                _FilterChip(
                  label: text.matches,
                  selected: _filter == _SearchFilter.matches,
                  onTap: () => _onFilterTap(_SearchFilter.matches),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingIndex
                ? const Center(child: CircularProgressIndicator())
                : AsyncContentView(
                    loading: false,
                    isEmpty: _visible.isEmpty,
                    emptyIcon: Icons.search_rounded,
                    emptyTitle: hasQuery
                        ? text.noSearchResultsTitle
                        : text.searchEmptyTitle,
                    emptySubtitle: hasQuery
                        ? text.noSearchResultsSubtitle
                        : text.globalSearchEmptySubtitle,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _visible[index];
                        return _SearchResultTile(
                          result: item,
                          typeLabel: _typeLabel(text, item.kind),
                          onTap: () => _openResult(item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(AppText text, GlobalSearchKind kind) {
    switch (kind) {
      case GlobalSearchKind.team:
        return text.searchTypeTeam;
      case GlobalSearchKind.player:
        return text.searchTypePlayer;
      case GlobalSearchKind.competition:
        return text.searchTypeCompetition;
      case GlobalSearchKind.match:
        return text.searchTypeMatch;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: selected
                  ? LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.7)],
                    )
                  : null,
              color: selected
                  ? null
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.05),
              border: Border.all(
                color: selected
                    ? primary.withValues(alpha: 0.6)
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                height: 1.2,
                color: selected
                    ? Colors.black
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.result,
    required this.typeLabel,
    required this.onTap,
  });

  final GlobalSearchResult result;
  final String typeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _LeadingVisual(result: result),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).hintColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadingVisual extends StatelessWidget {
  const _LeadingVisual({required this.result});

  final GlobalSearchResult result;

  @override
  Widget build(BuildContext context) {
    switch (result.kind) {
      case GlobalSearchKind.team:
        final team = result.payload as TeamModel;
        return TeamLogo.fromTeam(team, size: 40);
      case GlobalSearchKind.player:
        final player = result.payload as PlayerModel;
        return PlayerAvatar(player: player, size: 40, showJerseyNumber: true);
      case GlobalSearchKind.competition:
        final competition = result.payload as CompetitionModel;
        return CompetitionBadge.fromCompetition(competition, size: 40);
      case GlobalSearchKind.match:
        final match = result.payload as MatchModel;
        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                child: TeamLogo.fromTeam(match.homeTeam, size: 26),
              ),
              Positioned(
                right: 0,
                child: TeamLogo.fromTeam(match.awayTeam, size: 26),
              ),
            ],
          ),
        );
    }
  }
}
