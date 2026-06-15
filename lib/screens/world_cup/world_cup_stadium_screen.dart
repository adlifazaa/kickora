import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/world_cup/world_cup_stadiums.dart';
import '../../data/models/match_model.dart';
import '../../widgets/section_header.dart';
import '../../widgets/world_cup_match_card.dart';
import '../../widgets/world_cup_stadium_thumb.dart';

class WorldCupStadiumScreen extends StatelessWidget {
  const WorldCupStadiumScreen({
    super.key,
    required this.stadium,
    required this.matches,
    required this.isArabic,
  });

  final WorldCupStadium stadium;
  final List<MatchModel> matches;
  final bool isArabic;

  List<MatchModel> get _hosted {
    final key = stadium.name.toLowerCase();
    return matches
        .where((m) {
          final v = m.stadium.toLowerCase();
          return v.contains(key) || key.contains(v.split(' ').first);
        })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Widget build(BuildContext context) {
    final hosted = _hosted;
    final upcoming =
        hosted.where((m) => m.status == MatchStatus.upcoming).toList();
    final finished =
        hosted.where((m) => m.status == MatchStatus.finished).toList();
    final live = hosted.where((m) => m.status == MatchStatus.live).toList();

    return Scaffold(
      appBar: AppBar(title: Text(stadium.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            width: double.infinity,
            child: WorldCupStadiumThumb(stadium: stadium, size: 200, large: true),
          ),
          const SizedBox(height: 16),
          Text(
            '${stadium.city}, ${stadium.country}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isArabic
                ? 'السعة: ${stadium.capacity.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} متفرج'
                : 'Capacity: ${stadium.capacity}',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          if (stadium.surface.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              isArabic ? 'السطح: ${stadium.surface}' : 'Surface: ${stadium.surface}',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ],
          const SizedBox(height: 20),
          SectionHeader(
            title: isArabic
                ? 'مباريات كأس العالم (${hosted.length})'
                : 'World Cup matches (${hosted.length})',
            icon: Icons.stadium_outlined,
          ),
          const SizedBox(height: 10),
          if (hosted.isEmpty)
            Text(isArabic
                ? 'لا توجد مباريات مسجلة في هذا الملعب بعد.'
                : 'No matches listed for this venue yet.')
          else ...[
            if (live.isNotEmpty) ...[
              _section(context, isArabic ? 'مباشر' : 'Live', live),
            ],
            if (upcoming.isNotEmpty) ...[
              _section(context, isArabic ? 'قادمة' : 'Upcoming', upcoming),
            ],
            if (finished.isNotEmpty) ...[
              _section(context, isArabic ? 'منتهية' : 'Finished', finished),
            ],
          ],
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<MatchModel> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        const SizedBox(height: 8),
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
        const SizedBox(height: 12),
      ],
    );
  }
}
