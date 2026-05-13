import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';
import '../data/mock_data.dart';
import '../widgets/team_logo.dart';

class StandingsScreen extends StatelessWidget {
  const StandingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final standings = MockData.standings;

    return Scaffold(
      appBar: AppBar(title: Text(text.standings)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: standings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final item = standings[i];
          final isTop = i < 3;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isTop
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isTop
                        ? const LinearGradient(colors: [
                            AppColors.teal,
                            AppColors.neonGreen,
                          ])
                        : null,
                    color: isTop
                        ? null
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.08),
                  ),
                  child: Text('${item.position}',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 10),
                TeamLogo(shortName: item.team.shortName, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                _cell(context, '${item.played}'),
                _cell(context, '${item.wins}', color: AppColors.formWin),
                _cell(context, '${item.draws}', color: AppColors.formDraw),
                _cell(context, '${item.losses}', color: AppColors.formLoss),
                _cell(context,
                    '${item.goalDifference > 0 ? '+' : ''}${item.goalDifference}'),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${item.points}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cell(BuildContext context, String value, {Color? color}) {
    return SizedBox(
      width: 22,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color ?? Theme.of(context).hintColor,
        ),
      ),
    );
  }
}
