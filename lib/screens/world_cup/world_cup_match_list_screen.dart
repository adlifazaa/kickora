import 'package:flutter/material.dart';

import '../../data/models/match_model.dart';
import '../../app/routes.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/world_cup_match_card.dart';

enum WorldCupMatchListFilter { live, upcoming, finished }

class WorldCupMatchListScreen extends StatelessWidget {
  const WorldCupMatchListScreen({
    super.key,
    required this.filter,
    required this.matches,
    required this.isArabic,
  });

  final WorldCupMatchListFilter filter;
  final List<MatchModel> matches;
  final bool isArabic;

  String get _title {
    switch (filter) {
      case WorldCupMatchListFilter.live:
        return isArabic ? 'مباريات كأس العالم المباشرة' : 'Live World Cup matches';
      case WorldCupMatchListFilter.upcoming:
        return isArabic ? 'مباريات كأس العالم القادمة' : 'Upcoming World Cup matches';
      case WorldCupMatchListFilter.finished:
        return isArabic ? 'نتائج كأس العالم' : 'Finished World Cup matches';
    }
  }

  List<MatchModel> get _filtered {
    final list = matches.where((m) {
      switch (filter) {
        case WorldCupMatchListFilter.live:
          return m.status == MatchStatus.live;
        case WorldCupMatchListFilter.upcoming:
          return m.status == MatchStatus.upcoming;
        case WorldCupMatchListFilter.finished:
          return m.status == MatchStatus.finished;
      }
    }).toList()
      ..sort((a, b) {
        if (filter == WorldCupMatchListFilter.finished) {
          return b.date.compareTo(a.date);
        }
        return a.date.compareTo(b.date);
      });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: list.isEmpty
          ? Center(
              child: AppEmptyState(
                icon: Icons.sports_soccer_outlined,
                title: isArabic ? 'لا توجد مباريات' : 'No matches',
                subtitle: isArabic
                    ? 'لا توجد مباريات في هذه الفئة حالياً.'
                    : 'No matches in this category right now.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SectionHeader(
                  title: isArabic ? '${list.length} مباراة' : '${list.length} matches',
                  icon: Icons.sports_soccer_rounded,
                ),
                const SizedBox(height: 10),
                for (final m in list)
                  Padding(
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
                  ),
              ],
            ),
    );
  }
}
