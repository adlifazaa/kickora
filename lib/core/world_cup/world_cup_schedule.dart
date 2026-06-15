import '../../data/models/match_model.dart';
import 'world_cup_round_classifier.dart';

/// Maps API-Football `league.round` strings into schedule sections.
class WorldCupScheduleSection {
  const WorldCupScheduleSection({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.order,
  });

  final String id;
  final String titleEn;
  final String titleAr;
  final int order;

  static const sections = [
    WorldCupScheduleSection(
      id: 'group',
      titleEn: 'Group Stage',
      titleAr: 'دور المجموعات',
      order: 0,
    ),
    WorldCupScheduleSection(
      id: 'r32',
      titleEn: 'Round of 32',
      titleAr: 'دور الـ32',
      order: 1,
    ),
    WorldCupScheduleSection(
      id: 'r16',
      titleEn: 'Round of 16',
      titleAr: 'دور الـ16',
      order: 2,
    ),
    WorldCupScheduleSection(
      id: 'quarter',
      titleEn: 'Quarter Finals',
      titleAr: 'ربع النهائي',
      order: 3,
    ),
    WorldCupScheduleSection(
      id: 'semi',
      titleEn: 'Semi Finals',
      titleAr: 'نصف النهائي',
      order: 4,
    ),
    WorldCupScheduleSection(
      id: 'third',
      titleEn: 'Third Place Match',
      titleAr: 'مباراة المركز الثالث',
      order: 5,
    ),
    WorldCupScheduleSection(
      id: 'final',
      titleEn: 'Final',
      titleAr: 'النهائي',
      order: 6,
    ),
    WorldCupScheduleSection(
      id: 'other',
      titleEn: 'Other',
      titleAr: 'أخرى',
      order: 7,
    ),
  ];

  static String sectionIdForRound(String round, {DateTime? matchDate}) =>
      WorldCupRoundClassifier.sectionIdForRound(round, matchDate: matchDate);

  static WorldCupScheduleSection sectionFor(String id) {
    return sections.firstWhere(
      (s) => s.id == id,
      orElse: () => sections.last,
    );
  }

  static Map<String, List<MatchModel>> groupMatchesBySection(
    List<MatchModel> matches,
  ) {
    final map = <String, List<MatchModel>>{};
    for (final m in matches) {
      final id = sectionIdForRound(m.round, matchDate: m.date);
      map.putIfAbsent(id, () => []).add(m);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.date.compareTo(b.date));
    }
    return map;
  }

  static List<WorldCupScheduleSection> orderedSectionsWithMatches(
    Map<String, List<MatchModel>> grouped,
  ) {
    return sections
        .where((s) => (grouped[s.id]?.isNotEmpty ?? false))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
