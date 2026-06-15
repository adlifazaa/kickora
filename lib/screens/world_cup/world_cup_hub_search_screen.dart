import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/world_cup/world_cup_hub_features.dart';
import '../../core/world_cup/world_cup_hub_loader.dart';
import '../../core/world_cup/world_cup_stadiums.dart';
import '../../data/models/competition_model.dart';
import '../../data/models/match_model.dart';
import '../../data/models/player_model.dart';
import '../../data/models/team_model.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/team_logo.dart';
import 'world_cup_stadium_screen.dart';
import 'world_cup_team_screen.dart';

/// Hub-scoped search over teams, matches, stadiums, and scorers.
class WorldCupHubSearchScreen extends StatefulWidget {
  const WorldCupHubSearchScreen({
    super.key,
    required this.loader,
    required this.competition,
    required this.isArabic,
  });

  final WorldCupHubLoader loader;
  final CompetitionModel competition;
  final bool isArabic;

  @override
  State<WorldCupHubSearchScreen> createState() =>
      _WorldCupHubSearchScreenState();
}

class _WorldCupHubSearchScreenState extends State<WorldCupHubSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<WorldCupSearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
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
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _query = _controller.text.trim();
        _results = WorldCupHubSearch.grouped(widget.loader, _query);
      });
    });
  }

  void _openResult(WorldCupSearchResult result) {
    switch (result.kind) {
      case WorldCupSearchKind.team:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorldCupTeamScreen(
              team: result.payload as TeamModel,
              loader: widget.loader,
              competition: widget.competition,
            ),
          ),
        );
      case WorldCupSearchKind.match:
        Navigator.pushNamed(
          context,
          AppRoutes.matchDetails,
          arguments: result.payload as MatchModel,
        );
      case WorldCupSearchKind.stadium:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorldCupStadiumScreen(
              stadium: result.payload as WorldCupStadium,
              matches: widget.loader.matches,
              isArabic: widget.isArabic,
            ),
          ),
        );
      case WorldCupSearchKind.player:
        final player = result.payload as PlayerModel;
        if (player.id > 0) {
          Navigator.pushNamed(
            context,
            AppRoutes.playerDetails,
            arguments: player,
          );
        } else {
          _showPlayerInfo(player);
        }
    }
  }

  void _showPlayerInfo(PlayerModel player) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              player.name,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              player.team,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (player.goals > 0) ...[
              const SizedBox(height: 8),
              Text(
                widget.isArabic
                    ? '${player.goals} أهداف'
                    : '${player.goals} goals',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;
    final grouped = <WorldCupSearchKind, List<WorldCupSearchResult>>{};
    for (final r in _results) {
      grouped.putIfAbsent(r.kind, () => []).add(r);
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isArabic
                ? 'ابحث عن منتخب، مباراة، ملعب أو لاعب'
                : 'Search team, match, stadium or player',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? Center(
              child: Text(
                isArabic
                    ? 'ابحث داخل بيانات كأس العالم'
                    : 'Search World Cup hub data',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : _results.isEmpty
              ? AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: isArabic ? 'لا توجد نتائج' : 'No results',
                  subtitle: isArabic
                      ? 'جرّب كلمة مختلفة.'
                      : 'Try a different search term.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    for (final kind in WorldCupSearchKind.values)
                      if (grouped[kind]?.isNotEmpty ?? false) ...[
                        _SectionTitle(
                          label: _kindLabel(kind, isArabic),
                        ),
                        for (final result in grouped[kind]!)
                          _ResultTile(
                            result: result,
                            onTap: () => _openResult(result),
                          ),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
    );
  }

  String _kindLabel(WorldCupSearchKind kind, bool isArabic) {
    if (isArabic) {
      return switch (kind) {
        WorldCupSearchKind.team => 'المنتخبات',
        WorldCupSearchKind.match => 'المباريات',
        WorldCupSearchKind.stadium => 'الملاعب',
        WorldCupSearchKind.player => 'اللاعبون',
      };
    }
    return switch (kind) {
      WorldCupSearchKind.team => 'Teams',
      WorldCupSearchKind.match => 'Matches',
      WorldCupSearchKind.stadium => 'Stadiums',
      WorldCupSearchKind.player => 'Players',
    };
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result, required this.onTap});

  final WorldCupSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget? leading;
    if (result.kind == WorldCupSearchKind.team) {
      leading = TeamLogo.fromTeam(result.payload as TeamModel, size: 36);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: leading,
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: Text(result.subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
