import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';
import '../models/match_model.dart';
import 'async_content_view.dart';

enum _TimelinePhase { kickOff, halftime, fulltime }

class _TimelineRow {
  const _TimelineRow({
    required this.sortMinute,
    this.event,
    this.phase,
  });

  final int sortMinute;
  final MatchEvent? event;
  final _TimelinePhase? phase;

  bool get isPhase => phase != null;
}

/// Chronological match timeline with goals, cards, subs, and phase markers.
class MatchTimeline extends StatelessWidget {
  const MatchTimeline({super.key, required this.match});

  final MatchModel match;

  static int _parseMinute(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'HT') return 45;
    if (normalized == 'FT') return 90;
    final match = RegExp(r'(\d+)').firstMatch(normalized);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static List<_TimelineRow> _buildRows(MatchModel match) {
    final rows = <_TimelineRow>[
      for (final e in match.events)
        _TimelineRow(sortMinute: _parseMinute(e.minute), event: e),
    ];

    final currentMinute = _parseMinute(match.timeLabel);
    final showHalftime = match.status == MatchStatus.finished ||
        match.timeLabel == 'HT' ||
        (match.status == MatchStatus.live && currentMinute >= 45);
    final showFulltime = match.status == MatchStatus.finished;

    rows.add(const _TimelineRow(sortMinute: 0, phase: _TimelinePhase.kickOff));
    if (showHalftime) {
      rows.add(const _TimelineRow(sortMinute: 45, phase: _TimelinePhase.halftime));
    }
    if (showFulltime) {
      rows.add(const _TimelineRow(sortMinute: 90, phase: _TimelinePhase.fulltime));
    }

    rows.sort((a, b) {
      final cmp = a.sortMinute.compareTo(b.sortMinute);
      if (cmp != 0) return cmp;
      if (a.isPhase && !b.isPhase) return -1;
      if (!a.isPhase && b.isPhase) return 1;
      return 0;
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    if (match.events.isEmpty) {
      return AsyncContentView(
        loading: false,
        isEmpty: true,
        emptyIcon: Icons.timeline_rounded,
        emptyTitle: text.timelineEmptyTitle,
        emptySubtitle: text.timelineEmptySubtitle,
        child: const SizedBox.shrink(),
      );
    }

    final rows = _buildRows(match);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        if (row.isPhase) {
          return _PhaseMarker(phase: row.phase!, text: text);
        }
        return _EventRow(
          event: row.event!,
          text: text,
          index: index,
        );
      },
    );
  }
}

class _PhaseMarker extends StatelessWidget {
  const _PhaseMarker({required this.phase, required this.text});

  final _TimelinePhase phase;
  final AppText text;

  @override
  Widget build(BuildContext context) {
    final label = switch (phase) {
      _TimelinePhase.kickOff => text.timelineKickOff,
      _TimelinePhase.halftime => text.timelineHalftime,
      _TimelinePhase.fulltime => text.timelineFulltime,
    };
    final icon = switch (phase) {
      _TimelinePhase.kickOff => Icons.sports_soccer_outlined,
      _TimelinePhase.halftime => Icons.pause_circle_outline_rounded,
      _TimelinePhase.fulltime => Icons.flag_rounded,
    };
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                    color: primary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.text,
    required this.index,
  });

  final MatchEvent event;
  final AppText text;
  final int index;

  @override
  Widget build(BuildContext context) {
    final isHome = event.isHome;
    final card = _EventCard(event: event, text: text);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index * 40)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 10),
            child: child,
          ),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: isHome ? card : const SizedBox.shrink(),
              ),
            ),
            _CenterAxis(minute: event.minute, type: event.type),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: !isHome ? card : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterAxis extends StatelessWidget {
  const _CenterAxis({required this.minute, required this.type});

  final String minute;
  final MatchEventType type;

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(type);
    return SizedBox(
      width: 52,
      child: Column(
        children: [
          Container(
            width: 34,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              minute,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10.5),
            ),
          ),
          Expanded(
            child: Container(
              width: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.05),
                    color.withValues(alpha: 0.45),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.text});

  final MatchEvent event;
  final AppText text;

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.type);
    final icon = _eventIcon(event.type);
    final title = _eventTitle(text, event);
    final subLines = <String>[];

    if (event.assistName != null && event.assistName!.isNotEmpty) {
      subLines.add(text.timelineAssist(event.assistName!));
    }
    if (event.type == MatchEventType.substitution) {
      final subDetail = _substitutionDetail(text, event);
      if (subDetail != null) subLines.add(subDetail);
    }
    if (event.description.isNotEmpty &&
        event.type != MatchEventType.substitution) {
      subLines.add(event.description);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(maxWidth: 168),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                for (final line in subLines)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _substitutionDetail(AppText text, MatchEvent event) {
  final desc = event.description;
  final replaces = RegExp(
    r'(?:replaces|Replaces|يحل محل)\s+(.+)$',
    caseSensitive: false,
  ).firstMatch(desc);
  if (replaces != null) {
    return text.timelineSubstitution(
      playerIn: event.playerName,
      playerOut: replaces.group(1)!.trim(),
    );
  }
  if (desc.isNotEmpty) return desc;
  return null;
}

IconData _eventIcon(MatchEventType type) {
  switch (type) {
    case MatchEventType.goal:
      return Icons.sports_soccer_rounded;
    case MatchEventType.ownGoal:
      return Icons.sports_soccer_rounded;
    case MatchEventType.penalty:
      return Icons.adjust_rounded;
    case MatchEventType.yellowCard:
      return Icons.square_rounded;
    case MatchEventType.redCard:
      return Icons.crop_square_rounded;
    case MatchEventType.substitution:
      return Icons.swap_horiz_rounded;
    case MatchEventType.varDecision:
      return Icons.ondemand_video_rounded;
  }
}

Color _eventColor(MatchEventType type) {
  switch (type) {
    case MatchEventType.goal:
      return AppColors.goalGreen;
    case MatchEventType.ownGoal:
      return AppColors.ownGoalOrange;
    case MatchEventType.penalty:
      return AppColors.penaltyTeal;
    case MatchEventType.yellowCard:
      return AppColors.cardYellow;
    case MatchEventType.redCard:
      return AppColors.cardRed;
    case MatchEventType.substitution:
      return AppColors.subBlue;
    case MatchEventType.varDecision:
      return AppColors.varPurple;
  }
}

String _eventTitle(AppText text, MatchEvent e) {
  final name = e.playerName;
  switch (e.type) {
    case MatchEventType.goal:
      return text.timelineGoal(name);
    case MatchEventType.ownGoal:
      return text.timelineOwnGoal(name);
    case MatchEventType.penalty:
      return text.timelinePenalty(name);
    case MatchEventType.yellowCard:
      return text.timelineYellowCard(name);
    case MatchEventType.redCard:
      return text.timelineRedCard(name);
    case MatchEventType.substitution:
      return text.timelineSubstitutionIn(name);
    case MatchEventType.varDecision:
      return text.timelineVar(name);
  }
}
