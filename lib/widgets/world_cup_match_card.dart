import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';
import '../core/world_cup/world_cup_schedule_view.dart';
import '../data/models/match_model.dart';
import '../data/models/team_model.dart';
import '../utils/world_cup_match_date_formatter.dart';
import 'api_display_text.dart';
import 'live_badge.dart';
import 'micro_interactions.dart';
import 'team_logo.dart';

/// World Cup fixture row — always shows date, time, stage, stadium, score.
class WorldCupMatchCard extends StatelessWidget {
  const WorldCupMatchCard({
    super.key,
    required this.match,
    this.onTap,
    this.isArabic,
  });

  final MatchModel match;
  final VoidCallback? onTap;
  final bool? isArabic;

  @override
  Widget build(BuildContext context) {
    final bool arabic;
    final String liveLabel;
    if (isArabic != null) {
      arabic = isArabic!;
      liveLabel = arabic ? 'مباشر' : 'Live';
    } else {
      final text = AppText.of(context);
      arabic = text.isArabic;
      liveLabel = text.live;
    }
    final isLive = match.status == MatchStatus.live;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = Theme.of(context).cardTheme.color ?? AppColors.darkCard;
    final dateLine = WorldCupMatchDateFormatter.formatMatchDate(
      match.date,
      isArabic: arabic,
    );
    final timeLine = WorldCupMatchDateFormatter.formatKickoffTime(
      MatchDateTimeInput(date: match.date, timeLabel: match.timeLabel),
    );
    final stage = WorldCupScheduleView.stageLabel(match.round, isArabic: arabic);

    Widget scoreWidget() {
      if (match.status == MatchStatus.upcoming) {
        return Text(
          timeLine.isNotEmpty ? timeLine : '—',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      }
      return Text(
        '${match.homeScore} - ${match.awayScore}',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
      );
    }

    Widget statusChip() {
      switch (match.status) {
        case MatchStatus.live:
          return LiveBadge(label: liveLabel, dense: true);
        case MatchStatus.finished:
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).hintColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              arabic ? 'انتهت' : 'FT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).hintColor,
              ),
            ),
          );
        case MatchStatus.upcoming:
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              arabic ? 'قادمة' : 'Upcoming',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
      }
    }

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: base,
            border: Border.all(
              color: isLive
                  ? AppColors.liveRed.withValues(alpha: 0.35)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.lightBorder),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateLine.isNotEmpty
                          ? dateLine
                          : WorldCupMatchDateFormatter.formatNumericDate(
                              match.date,
                            ),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (timeLine.isNotEmpty &&
                      match.status != MatchStatus.upcoming) ...[
                    Text(
                      timeLine,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  statusChip(),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _teamRow(match.homeTeam, arabic)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: scoreWidget(),
                  ),
                  Expanded(child: _teamRow(match.awayTeam, arabic, alignEnd: true)),
                ],
              ),
              if (stage.isNotEmpty && stage != '—') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        size: 14, color: Theme.of(context).hintColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ApiDisplayText(
                        stage,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (match.stadium.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.stadium_outlined,
                        size: 14, color: Theme.of(context).hintColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ApiDisplayText(
                        match.stadium,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (onTap == null) return card;
    return TapScale(borderRadius: BorderRadius.circular(16), onTap: onTap, child: card);
  }

  Widget _teamRow(TeamModel team, bool arabic, {bool alignEnd = false}) {
    final children = alignEnd
        ? [
            Flexible(
              child: ApiDisplayText(
                team.name,
                maxLines: 2,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            TeamLogo.fromTeam(team, size: 28),
          ]
        : [
            TeamLogo.fromTeam(team, size: 28),
            const SizedBox(width: 6),
            Flexible(
              child: ApiDisplayText(
                team.name,
                maxLines: 2,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ];

    return Row(
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: children,
    );
  }
}
