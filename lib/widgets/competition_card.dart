import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../models/competition_model.dart';
import 'team_logo.dart';

class CompetitionCard extends StatelessWidget {
  const CompetitionCard({super.key, required this.competition, this.onTap});

  final CompetitionModel competition;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isFav = app.isCompetitionFavorite(competition.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = Theme.of(context).cardTheme.color ?? AppColors.darkCard;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 160,
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CompetitionBadge(logo: competition.logo, size: 40),
                  const Spacer(),
                  InkWell(
                    onTap: () =>
                        app.toggleCompetitionFavorite(competition.id),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isFav
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 20,
                        color: isFav
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).hintColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                competition.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.public_rounded,
                    size: 12,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      competition.region,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (competition.isFeatured) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.teal, AppColors.neonGreen],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
