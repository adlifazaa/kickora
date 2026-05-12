import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../models/match_model.dart';
import 'live_badge.dart';
import 'team_logo.dart';

/// Premium match card with gradient surface, live pulse, and animated score.
class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, this.onTap});

  final MatchModel match;
  final VoidCallback? onTap;

  Color _statusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.live:
        return AppColors.goalGreen;
      case MatchStatus.upcoming:
        return AppColors.teal;
      case MatchStatus.finished:
        return Colors.white60;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = AppText.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLive = match.status == MatchStatus.live;
    final isFav = app.isMatchFavorite(match.id);

    final base = Theme.of(context).cardTheme.color ?? AppColors.darkCard;
    final overlay = isLive
        ? AppColors.liveRed.withValues(alpha: 0.06)
        : Theme.of(context).colorScheme.primary.withValues(alpha: 0.045);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, Color.alphaBlend(overlay, base)],
            ),
            border: Border.all(
              color: isLive
                  ? AppColors.liveRed.withValues(alpha: 0.35)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.lightBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      match.competition.logo,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.competition.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLive)
                    LiveBadge(label: text.live, dense: true)
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(match.status).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        match.timeLabel,
                        style: TextStyle(
                          color: _statusColor(match.status),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => app.toggleMatchFavorite(match.id),
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        isFav ? Icons.star_rounded : Icons.star_border_rounded,
                        key: ValueKey(isFav),
                        color: isFav ? Colors.amber : null,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TeamView(
                      name: match.homeTeam.name,
                      shortName: match.homeTeam.shortName,
                      teamId: match.homeTeam.id,
                    ),
                  ),
                  _ScoreBlock(match: match),
                  Expanded(
                    child: _TeamView(
                      name: match.awayTeam.name,
                      shortName: match.awayTeam.shortName,
                      teamId: match.awayTeam.id,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (match.stadium.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 12,
                          color: Theme.of(context).hintColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          match.stadium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = match.status == MatchStatus.upcoming;
    if (isUpcoming) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              match.timeLabel,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Text(
              'vs',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ScoreDigit(value: match.homeScore),
          const SizedBox(width: 6),
          Text(
            '-',
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          _ScoreDigit(value: match.awayScore),
        ],
      ),
    );
  }
}

class _ScoreDigit extends StatelessWidget {
  const _ScoreDigit({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Text(
          '$value',
          key: ValueKey<int>(value),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _TeamView extends StatelessWidget {
  const _TeamView(
      {required this.name, required this.shortName, required this.teamId});

  final String name;
  final String shortName;
  final int teamId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isFavorite = app.isTeamFavorite(teamId);
    return Column(
      children: [
        TeamLogo(shortName: shortName, size: 38),
        const SizedBox(height: 6),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: -0.2),
        ),
        const SizedBox(height: 2),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => app.toggleTeamFavorite(teamId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 16,
              color: isFavorite ? Colors.redAccent : Theme.of(context).hintColor,
            ),
          ),
        ),
      ],
    );
  }
}
