import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../data/mock_data.dart';
import '../models/competition_model.dart';
import '../models/match_model.dart';
import '../widgets/ad_placeholder.dart';
import '../widgets/competition_card.dart';
import '../widgets/match_card.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/team_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fakeLoad();
  }

  Future<void> _fakeLoad() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _onRefresh() async {
    setState(() => _loading = true);
    await _fakeLoad();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final matches = MockData.matches();
    final liveMatches =
        matches.where((m) => m.status == MatchStatus.live).toList();
    final todayMatches =
        matches.where((m) => m.status != MatchStatus.finished).toList();
    final featuredCompetition =
        MockData.competitions.firstWhere((c) => c.isFeatured);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _HomeHeader(text: text),
            const SizedBox(height: 18),
            if (_loading) ...[
              const SkeletonBox(height: 150),
              const SizedBox(height: 14),
              const MatchCardSkeleton(),
              const SizedBox(height: 10),
              const MatchCardSkeleton(),
            ] else ...[
              if (liveMatches.isNotEmpty) ...[
                SectionHeader(
                  title: text.featuredMatch,
                  subtitle: text.isArabic
                      ? 'أبرز ما يحدث الآن'
                      : 'The top live action',
                  icon: Icons.star_rounded,
                ),
                const SizedBox(height: 10),
                MatchCard(
                  match: liveMatches.first,
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.matchDetails,
                      arguments: liveMatches.first),
                ),
                const SizedBox(height: 20),
                SectionHeader(
                  title: text.liveNow,
                  subtitle: '${liveMatches.length} ${text.isArabic ? 'مباراة' : 'matches'}',
                  icon: Icons.flash_on_rounded,
                  actionText: text.all,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.matches),
                ),
                const SizedBox(height: 10),
                ...liveMatches.map((match) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MatchCard(
                          match: match,
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.matchDetails,
                              arguments: match)),
                    )),
              ],
              const SizedBox(height: 4),
              SectionHeader(
                title: text.todayMatches,
                subtitle:
                    '${todayMatches.length} ${text.isArabic ? 'مباراة' : 'matches'}',
                icon: Icons.today_rounded,
              ),
              const SizedBox(height: 10),
              ...todayMatches.map((match) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MatchCard(
                        match: match,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.matchDetails,
                            arguments: match)),
                  )),
            ],
            const SizedBox(height: 6),
            _FeaturedCompetitionStrip(competition: featuredCompetition),
            const SizedBox(height: 20),
            SectionHeader(
              title: text.competitions,
              icon: Icons.emoji_events_rounded,
              actionText: text.more,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.competitions),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 158,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockData.competitions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final competition = MockData.competitions[index];
                  return CompetitionCard(
                    competition: competition,
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.competitionDetails,
                        arguments: competition),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            const NativeAdPlaceholder(),
            const SizedBox(height: 12),
            const AdPlaceholder(label: 'Home feed ad slot'),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.text});
  final AppText text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.teal, AppColors.neonGreen],
            ),
            boxShadow: [
              BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.4),
                  blurRadius: 14),
            ],
          ),
          child:
              const Icon(Icons.sports_soccer_rounded, color: Colors.black87),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      )),
              Text(text.homeSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        IconButton(
          tooltip: text.about,
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.about),
          icon: const Icon(Icons.info_outline_rounded),
        ),
      ],
    );
  }
}

class _FeaturedCompetitionStrip extends StatelessWidget {
  const _FeaturedCompetitionStrip({required this.competition});

  final CompetitionModel competition;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
            context, AppRoutes.competitionDetails,
            arguments: competition),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withValues(alpha: 0.28),
                primary.withValues(alpha: 0.07),
              ],
            ),
            border: Border.all(color: primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              CompetitionBadge(logo: competition.logo, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.isArabic ? 'بطولة مميزة' : 'Featured competition',
                      style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(competition.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15.5,
                            letterSpacing: -0.2)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}
