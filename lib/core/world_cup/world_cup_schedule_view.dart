import '../../data/models/match_model.dart';
import 'world_cup_round_classifier.dart';
import 'world_cup_schedule.dart';

/// Filters for the World Cup fixture schedule.
enum WorldCupScheduleFilter {
  all,
  live,
  upcoming,
  finished,
  groupStage,
}

extension WorldCupScheduleFilterLabels on WorldCupScheduleFilter {
  String label({required bool isArabic}) {
    switch (this) {
      case WorldCupScheduleFilter.all:
        return isArabic ? 'الكل' : 'All';
      case WorldCupScheduleFilter.live:
        return isArabic ? 'مباشر' : 'Live';
      case WorldCupScheduleFilter.upcoming:
        return isArabic ? 'قادمة' : 'Upcoming';
      case WorldCupScheduleFilter.finished:
        return isArabic ? 'منتهية' : 'Finished';
      case WorldCupScheduleFilter.groupStage:
        return isArabic ? 'دور المجموعات' : 'Group Stage';
    }
  }
}

/// Sorting, filtering, and date grouping for World Cup schedule UI.
class WorldCupScheduleView {
  WorldCupScheduleView._();

  static List<MatchModel> filterMatches(
    List<MatchModel> matches,
    WorldCupScheduleFilter filter,
  ) {
    final list = matches.where((m) {
      switch (filter) {
        case WorldCupScheduleFilter.all:
          return true;
        case WorldCupScheduleFilter.live:
          return m.status == MatchStatus.live;
        case WorldCupScheduleFilter.upcoming:
          return m.status == MatchStatus.upcoming;
        case WorldCupScheduleFilter.finished:
          return m.status == MatchStatus.finished;
        case WorldCupScheduleFilter.groupStage:
          return WorldCupRoundClassifier.isGroupStageMatch(m);
      }
    }).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// Chronological groups keyed by yyyy-MM-dd (stable sort order preserved).
  static List<WorldCupDateGroup> groupByDate(List<MatchModel> matches) {
    final sorted = List<MatchModel>.from(matches)
      ..sort((a, b) => a.date.compareTo(b.date));
    final groups = <WorldCupDateGroup>[];
    String? currentKey;
    List<MatchModel>? bucket;

    for (final m in sorted) {
      final key = _dateKey(m.date);
      if (key != currentKey) {
        if (bucket != null && bucket.isNotEmpty) {
          groups.add(WorldCupDateGroup(date: bucket.first.date, matches: bucket));
        }
        currentKey = key;
        bucket = [m];
      } else {
        bucket!.add(m);
      }
    }
    if (bucket != null && bucket.isNotEmpty) {
      groups.add(WorldCupDateGroup(date: bucket.first.date, matches: bucket));
    }
    return groups;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Human-readable stage from API round string.
  static String stageLabel(String round, {required bool isArabic}) {
    if (round.trim().isEmpty) {
      return isArabic ? '—' : '—';
    }
    final id = WorldCupScheduleSection.sectionIdForRound(round);
    final section = WorldCupScheduleSection.sectionFor(id);
    if (id != 'other') {
      return isArabic ? section.titleAr : section.titleEn;
    }
    return round;
  }
}

class WorldCupDateGroup {
  const WorldCupDateGroup({required this.date, required this.matches});

  final DateTime date;
  final List<MatchModel> matches;
}

/// English group table column headers (readable full words).
class WorldCupGroupTableLabels {
  WorldCupGroupTableLabels._();

  static List<String> headers({required bool isArabic}) {
    if (isArabic) {
      return ['#', 'الفريق', 'لعب', 'فاز', 'تعادل', 'خسر', 'فرق', 'نقاط'];
    }
    return ['#', 'Team', 'Played', 'Won', 'Drawn', 'Lost', 'GD', 'Points'];
  }

  /// Stat column width for layout (English needs slightly wider cells).
  static double statWidth(int columnIndex, {required bool isArabic}) {
    if (columnIndex <= 1) return 0;
    if (!isArabic) {
      switch (columnIndex) {
        case 2:
        case 4:
        case 7:
          return 36;
        case 3:
        case 5:
          return 30;
        default:
          return 28;
      }
    }
    return columnIndex == 7 ? 34 : 30;
  }
}
