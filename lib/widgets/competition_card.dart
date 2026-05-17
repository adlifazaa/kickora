import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../models/competition_model.dart';
import 'team_logo.dart';

class CompetitionCard extends StatelessWidget {
  const CompetitionCard({
    super.key,
    required this.competition,
    this.onTap,
    /// Tighter layout for grid cells on the Competitions screen.
    this.dense = false,
  });

  final CompetitionModel competition;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = AppText.of(context);
    final isFav = app.isCompetitionFavorite(competition.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = Theme.of(context).cardTheme.color ?? AppColors.darkCard;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final compact =
            dense || (maxH.isFinite && maxH > 0 && maxH < 155);
        final padH = compact ? 10.0 : 12.0;
        final padV = compact ? 9.0 : 11.0;
        final logoSize = dense ? 100.0 : (compact ? 40.0 : 44.0);
        final nameSize = compact ? 12.5 : 13.5;
        final metaSize = compact ? 10.0 : 10.5;
        final rowGap = compact ? 6.0 : 8.0;
        final metaGap = 2.0;

        final teamsLabel = text.competitionTeamsCount(competition.teamCount);
        final matchesLabel =
            text.competitionMatchesToday(competition.matchesToday);

        final bookmark = InkWell(
          onTap: () => app.toggleCompetitionFavorite(competition.id),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              size: compact ? 18 : 20,
              color: isFav
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).hintColor,
            ),
          ),
        );

        final nameRow = Row(
          children: [
            Expanded(
              child: Text(
                competition.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: nameSize,
                  letterSpacing: -0.2,
                  height: 1.12,
                ),
              ),
            ),
            if (competition.isFeatured) ...[
              const SizedBox(width: 5),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 5 : 6,
                  vertical: compact ? 2 : 2.5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.teal, AppColors.neonGreen],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  text.featuredBadge,
                  style: TextStyle(
                    fontSize: compact ? 7.5 : 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ],
        );

        final metaSection = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameRow,
            if (competition.teamCount > 0) ...[
              SizedBox(height: metaGap),
              Text(
                teamsLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: metaSize,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
            if (competition.matchesToday > 0) ...[
              SizedBox(height: metaGap),
              Text(
                matchesLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.9),
                  fontSize: metaSize,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ],
        );

        final Widget content;
        if (dense) {
          content = Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CompetitionBadge.fromCompetition(
                      competition,
                      size: logoSize,
                    ),
                  ),
                  SizedBox(height: rowGap),
                  metaSection,
                ],
              ),
              Positioned(top: 0, right: 0, child: bookmark),
            ],
          );
        } else {
          content = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CompetitionBadge.fromCompetition(
                    competition,
                    size: logoSize,
                  ),
                  const Spacer(),
                  bookmark,
                ],
              ),
              SizedBox(height: rowGap),
              metaSection,
            ],
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: dense ? double.infinity : 168,
              height: dense ? double.infinity : null,
              padding: EdgeInsets.fromLTRB(padH, padV, padH - 1, padV),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    base,
                    Color.alphaBlend(
                      AppColors.teal.withValues(alpha: 0.07),
                      base,
                    ),
                  ],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: dense
                  ? Align(
                      alignment: Alignment.center,
                      child: content,
                    )
                  : content,
            ),
          ),
        );
      },
    );
  }
}
