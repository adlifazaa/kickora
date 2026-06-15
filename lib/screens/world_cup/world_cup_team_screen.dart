import 'package:flutter/material.dart';

import '../../app/app_text.dart';
import '../../app/routes.dart';
import '../../core/world_cup/world_cup_hub_loader.dart';
import '../../data/models/competition_model.dart';
import '../../data/models/match_model.dart';
import '../../data/models/team_model.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/world_cup_match_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/team_logo.dart';

class WorldCupTeamScreen extends StatelessWidget {
  const WorldCupTeamScreen({
    super.key,
    required this.team,
    required this.loader,
    required this.competition,
  });

  final TeamModel team;
  final WorldCupHubLoader loader;
  final CompetitionModel competition;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final matches = loader.matchesForTeam(team.id);
    final upcoming =
        matches.where((m) => m.status == MatchStatus.upcoming).toList();
    final finished =
        matches.where((m) => m.status == MatchStatus.finished).toList();
    final live = matches.where((m) => m.status == MatchStatus.live).toList();
    final group = loader.groupForTeam(team.id);
    final standing =
        group?.rows.where((r) => r.team.id == team.id).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(team.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: TeamLogo.fromTeam(team, size: 88)),
          const SizedBox(height: 12),
          Center(
            child: Text(
              team.countryName.isNotEmpty ? team.countryName : team.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          if (group != null && standing != null) ...[
            const SizedBox(height: 20),
            SectionHeader(
              title: '${group.name} · ${text.isArabic ? 'الترتيب' : 'Standing'}',
              icon: Icons.leaderboard_rounded,
            ),
            const SizedBox(height: 8),
            Text(
              text.isArabic
                  ? 'المركز ${standing.position} · ${standing.points} نقطة · لعب ${standing.played}'
                  : 'Pos ${standing.position} · ${standing.points} pts · P${standing.played}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 20),
          SectionHeader(
            title: text.isArabic ? 'القادمة' : 'Upcoming',
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 10),
          if (upcoming.isEmpty && live.isEmpty)
            Text(text.isArabic ? 'لا توجد مباريات قادمة.' : 'No upcoming fixtures.')
          else ...[
            for (final m in live) _match(context, m),
            for (final m in upcoming) _match(context, m),
          ],
          const SizedBox(height: 20),
          SectionHeader(
            title: text.isArabic ? 'النتائج' : 'Results',
            icon: Icons.history_rounded,
          ),
          const SizedBox(height: 10),
          if (finished.isEmpty)
            Text(text.isArabic ? 'لا توجد نتائج بعد.' : 'No results yet.')
          else
            for (final m in finished) _match(context, m),
          const SizedBox(height: 20),
          SectionHeader(
            title: text.isArabic ? 'التشكيلة' : 'Squad',
            icon: Icons.groups_rounded,
          ),
          const SizedBox(height: 10),
          AppEmptyState(
            icon: Icons.person_outline_rounded,
            title: text.isArabic
                ? 'التشكيلة غير متوفرة حالياً'
                : 'Squad not available',
            subtitle: text.isArabic
                ? 'ستظهر عند توفر بيانات اللاعبين من المصدر.'
                : 'Will appear when player data is available from the API.',
          ),
        ],
      ),
    );
  }

  Widget _match(BuildContext context, MatchModel m) {
    final isArabic = AppText.of(context).isArabic;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WorldCupMatchCard(
        match: m,
        isArabic: isArabic,
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.matchDetails,
          arguments: m,
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
