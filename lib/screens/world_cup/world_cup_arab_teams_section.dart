import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/world_cup/world_cup_hub_features.dart';
import '../../core/world_cup/world_cup_hub_loader.dart';
import '../../data/models/competition_model.dart';
import '../../data/models/match_model.dart';
import '../../data/models/team_model.dart';
import '../../widgets/section_header.dart';
import '../../widgets/team_logo.dart';
import 'world_cup_team_screen.dart';

/// Horizontal Arab national teams section for World Cup overview.
class WorldCupArabTeamsSection extends StatelessWidget {
  const WorldCupArabTeamsSection({
    super.key,
    required this.loader,
    required this.competition,
    required this.isArabic,
  });

  final WorldCupHubLoader loader;
  final CompetitionModel competition;
  final bool isArabic;

  static const _previewCount = 4;

  @override
  Widget build(BuildContext context) {
    final teams = WorldCupArabTeams.fromLoader(loader);
    if (teams.isEmpty) return const SizedBox.shrink();

    final preview = teams.take(_previewCount).toList();
    final hasMore = teams.length > _previewCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: isArabic ? 'المنتخبات العربية' : 'Arab teams',
          icon: Icons.flag_circle_outlined,
        ),
        const SizedBox(height: 4),
        Text(
          isArabic
              ? 'تابع مباريات ونتائج المنتخبات العربية في كأس العالم'
              : 'Follow Arab teams in the World Cup',
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: preview.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _ArabTeamCard(
              team: preview[i],
              loader: loader,
              competition: competition,
              isArabic: isArabic,
              width: MediaQuery.sizeOf(context).width * 0.72,
            ),
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => _showAll(context, teams),
              child: Text(isArabic ? 'عرض الكل' : 'View all'),
            ),
          ),
        ],
      ],
    );
  }

  void _showAll(BuildContext context, List<TeamModel> teams) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text(
              isArabic ? 'المنتخبات العربية' : 'Arab teams',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 12),
            for (final team in teams)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ArabTeamCard(
                  team: team,
                  loader: loader,
                  competition: competition,
                  isArabic: isArabic,
                  width: double.infinity,
                  horizontal: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArabTeamCard extends StatelessWidget {
  const _ArabTeamCard({
    required this.team,
    required this.loader,
    required this.competition,
    required this.isArabic,
    required this.width,
    this.horizontal = false,
  });

  final TeamModel team;
  final WorldCupHubLoader loader;
  final CompetitionModel competition;
  final bool isArabic;
  final double width;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppScope.of(context),
      builder: (context, _) {
        final app = AppScope.of(context);
        final isFavorite = app.isTeamFavorite(team.id);
        final notificationsOn = app.notificationsEnabled;
        final group = loader.groupNameForTeam(team.id);
        final next = WorldCupArabTeams.nextMatch(loader, team.id);
        final last = WorldCupArabTeams.lastFinished(loader, team.id);

        return SizedBox(
          width: width,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorldCupTeamScreen(
                    team: team,
                    loader: loader,
                    competition: competition,
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                  color: Theme.of(context).cardTheme.color,
                ),
                child: horizontal
                    ? Row(
                        children: [
                          TeamLogo.fromTeam(team, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _body(context, group, next, last,
                                isFavorite, notificationsOn),
                          ),
                        ],
                      )
                    : _body(context, group, next, last, isFavorite,
                        notificationsOn),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    String? group,
    MatchModel? next,
    MatchModel? last,
    bool isFavorite,
    bool notificationsOn,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!horizontal) TeamLogo.fromTeam(team, size: 40),
            if (!horizontal) const SizedBox(width: 10),
            Expanded(
              child: Text(
                team.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => AppScope.of(context).toggleTeamFavorite(team.id),
              icon: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? Colors.redAccent : Theme.of(context).hintColor,
                size: 20,
              ),
            ),
          ],
        ),
        if (group != null) ...[
          const SizedBox(height: 4),
          Text(
            group,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (next != null)
          _line(
            context,
            isArabic ? 'التالي' : 'Next',
            _matchLine(next),
          ),
        if (last != null)
          _line(
            context,
            isArabic ? 'الأخير' : 'Last',
            _matchLine(last, finished: true),
          ),
        if (notificationsOn && isFavorite) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isArabic ? 'التنبيهات مفعّلة' : 'Alerts on',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).hintColor,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _matchLine(MatchModel m, {bool finished = false}) {
    final score = finished || m.status != MatchStatus.upcoming
        ? '${m.homeScore}-${m.awayScore} · '
        : '';
    return '$score${m.homeTeam.shortName} vs ${m.awayTeam.shortName}';
  }
}
