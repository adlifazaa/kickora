import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../models/competition_model.dart';
import 'competition_card.dart';
import 'section_header.dart';
import 'skeleton_box.dart';

/// Compact home module for currently relevant popular competitions.
class TopCompetitionsModule extends StatelessWidget {
  const TopCompetitionsModule({
    super.key,
    required this.competitions,
    required this.loading,
  });

  final List<CompetitionModel> competitions;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    if (loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: text.topCompetitions,
            icon: Icons.emoji_events_rounded,
          ),
          const SizedBox(height: 10),
          const SizedBox(
            height: 118,
            child: Row(
              children: [
                Expanded(child: SkeletonBox(height: 118)),
                SizedBox(width: 10),
                Expanded(child: SkeletonBox(height: 118)),
                SizedBox(width: 10),
                Expanded(child: SkeletonBox(height: 118)),
              ],
            ),
          ),
        ],
      );
    }

    if (competitions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: text.topCompetitions,
          icon: Icons.emoji_events_rounded,
          actionText: text.more,
          onTap: () => Navigator.pushNamed(context, AppRoutes.competitions),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: competitions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final competition = competitions[index];
              return SizedBox(
                width: 148,
                child: Material(
                  color: Theme.of(context).cardTheme.color ??
                      (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkCard
                          : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  child: CompetitionCard(
                    competition: competition,
                    dense: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.competitionDetails,
                      arguments: competition,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
