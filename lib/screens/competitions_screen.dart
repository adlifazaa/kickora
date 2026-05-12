import 'package:flutter/material.dart';

import '../app/app_text.dart';
import '../app/routes.dart';
import '../data/mock_data.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/competition_card.dart';

class CompetitionsScreen extends StatefulWidget {
  const CompetitionsScreen({super.key});

  @override
  State<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends State<CompetitionsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final competitions = MockData.competitions
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text.competitions,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4)),
                const SizedBox(height: 2),
                Text(
                  text.isArabic
                      ? 'اكتشف أهم البطولات حول العالم'
                      : 'Discover top leagues around the world',
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: text.searchCompetition,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: competitions.isEmpty
                ? AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: text.isArabic
                        ? 'لا توجد نتائج'
                        : 'No matches',
                    subtitle: text.isArabic
                        ? 'جرب كلمة بحث مختلفة.'
                        : 'Try a different keyword.',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: competitions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0),
                    itemBuilder: (context, index) {
                      final competition = competitions[index];
                      return CompetitionCard(
                        competition: competition,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.competitionDetails,
                            arguments: competition),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
