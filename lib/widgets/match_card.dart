import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../data/models/team_model.dart';
import '../models/match_model.dart';
import 'api_display_text.dart';
import 'live_badge.dart';
import 'micro_interactions.dart';
import 'team_logo.dart';

/// Premium match card with gradient surface, live pulse, and animated score.
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
    /// Tighter vertical rhythm for fixed-height slots (e.g. home featured carousel).
    this.compact = false,
    /// Home featured carousel: no [TapScale] / animated transforms that widen layout.
    this.featuredSlot = false,
  });

  final MatchModel match;
  final VoidCallback? onTap;
  final bool compact;
  final bool featuredSlot;

  Color _statusColor(BuildContext context, MatchStatus status) {
    switch (status) {
      case MatchStatus.live:
        return AppColors.goalGreen;
      case MatchStatus.upcoming:
        return AppColors.teal;
      case MatchStatus.finished:
        // Theme-aware muted tone so the "finished" pill stays readable
        // in BOTH dark and light mode (was hardcoded white60 → invisible
        // on the white card in light mode).
        return Theme.of(context).brightness == Brightness.dark
            ? Colors.white60
            : const Color(0xFF5B6473);
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

    final pad = compact
        ? const EdgeInsets.fromLTRB(14, 10, 8, 10)
        : const EdgeInsets.fromLTRB(14, 12, 8, 12);
    final headerTeamGap = compact ? 8.0 : 10.0;
    final teamStadiumGap = compact ? 4.0 : 6.0;

    final card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: pad,
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
          child: SizedBox(
            width: double.infinity,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: compact ? 22 : 24,
                    height: compact ? 22 : 24,
                    child: CompetitionBadge.fromCompetition(
                      match.competition,
                      size: compact ? 22 : 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ApiDisplayText(
                      match.competition.name,
                      maxLines: 1,
                      style: (Theme.of(context).textTheme.bodySmall ??
                              const TextStyle(fontSize: 12))
                          .copyWith(
                            color: Theme.of(context).hintColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isLive)
                    Flexible(
                      fit: FlexFit.loose,
                      child: featuredSlot
                          ? _StaticLiveChip(label: text.live)
                          : ClipRect(
                              child: LiveBadge(label: text.live, dense: true),
                            ),
                    )
                  else
                    Flexible(
                      fit: FlexFit.loose,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(context, match.status)
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ApiDisplayText(
                          match.timeLabel,
                          maxLines: 1,
                          style: TextStyle(
                            color: _statusColor(context, match.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  FavoriteToggle(
                    value: isFav,
                    onChanged: (_) => app.toggleMatchFavorite(match.id),
                  ),
                ],
              ),
              SizedBox(height: headerTeamGap),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _TeamView(
                      team: match.homeTeam,
                      compact: compact,
                    ),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: _ScoreBlock(
                      match: match,
                      compact: compact,
                      staticDisplay: featuredSlot,
                    ),
                  ),
                  Expanded(
                    child: _TeamView(
                      team: match.awayTeam,
                      compact: compact,
                    ),
                  ),
                ],
              ),
              SizedBox(height: teamStadiumGap),
              if (sanitizeApiDisplayText(match.stadium).isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: compact ? 11 : 12,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ApiDisplayText(
                        match.stadium,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: compact ? 10.5 : 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          ),
        ),
        ),
      );

    if (featuredSlot) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: card,
      );
    }

    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: card,
    );
  }
}

/// Static LIVE pill for featured carousel (no [Transform.scale]).
class _StaticLiveChip extends StatelessWidget {
  const _StaticLiveChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.liveRed, AppColors.liveGlow],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({
    required this.match,
    required this.compact,
    this.staticDisplay = false,
  });

  final MatchModel match;
  final bool compact;
  final bool staticDisplay;

  @override
  Widget build(BuildContext context) {
    final isUpcoming = match.status == MatchStatus.upcoming;
    if (isUpcoming) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ApiDisplayText(
                match.timeLabel,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 16 : 18,
                ),
              ),
              SizedBox(height: compact ? 1 : 2),
              Text(
                'vs',
                style: TextStyle(
                  fontSize: compact ? 9 : 10,
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ScoreDigit(
              value: match.homeScore,
              compact: compact,
              staticDisplay: staticDisplay,
            ),
            SizedBox(width: compact ? 4 : 6),
            Text(
              '-',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
            _ScoreDigit(
              value: match.awayScore,
              compact: compact,
              staticDisplay: staticDisplay,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreDigit extends StatelessWidget {
  const _ScoreDigit({
    required this.value,
    required this.compact,
    this.staticDisplay = false,
  });

  final int value;
  final bool compact;
  final bool staticDisplay;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      '$value',
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: compact ? 22 : 26,
        letterSpacing: -0.5,
      ),
    );

    if (staticDisplay) return text;

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
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: compact ? 22 : 26,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _TeamView extends StatelessWidget {
  const _TeamView({
    required this.team,
    required this.compact,
  });

  final TeamModel team;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final isFavorite = app.isTeamFavorite(team.id);
    final logoSize = compact ? 34.0 : 38.0;
    final nameSize = compact ? 12.5 : 13.0;
    final logoNameGap = compact ? 4.0 : 6.0;
    final heartSize = compact ? 15.0 : 16.0;
    final heartPadV = compact ? 1.0 : 2.0;

    final nameStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: nameSize,
      letterSpacing: -0.2,
      height: compact ? 1.1 : 1.15,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TeamLogo.fromTeam(team, size: logoSize),
        ),
        SizedBox(height: logoNameGap),
        ApiDisplayText(
          team.name,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: nameStyle,
        ),
        SizedBox(height: compact ? 1 : 2),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => app.toggleTeamFavorite(team.id),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: heartPadV),
            child: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: heartSize,
              color: isFavorite ? Colors.redAccent : Theme.of(context).hintColor,
            ),
          ),
        ),
      ],
    );
  }
}
