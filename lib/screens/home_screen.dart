import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../data/mock_data.dart';
import '../models/competition_model.dart';
import '../models/match_model.dart';
import '../widgets/ad_placeholder.dart';
import '../widgets/competition_card.dart';
import '../widgets/feed_spotlight.dart';
import '../widgets/match_card.dart';
import '../widgets/micro_interactions.dart';
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
              const SkeletonBox(height: 176),
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
                _FeaturedCarousel(matches: liveMatches),
                const SizedBox(height: 20),
                SectionHeader(
                  title: text.liveNow,
                  subtitle:
                      '${liveMatches.length} ${text.isArabic ? 'مباراة' : 'matches'}',
                  icon: Icons.flash_on_rounded,
                  actionText: text.all,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.matches),
                ),
                const SizedBox(height: 10),
                ...insertFeedSpotlights(
                  skipFirst: 0,
                  interval: 4,
                  items: [
                    for (var i = 0; i < liveMatches.length; i++)
                      _StaggeredItem(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: MatchCard(
                            match: liveMatches[i],
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.matchDetails,
                                arguments: liveMatches[i]),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              SectionHeader(
                title: text.todayMatches,
                subtitle:
                    '${todayMatches.length} ${text.isArabic ? 'مباراة' : 'matches'}',
                icon: Icons.today_rounded,
              ),
              const SizedBox(height: 10),
              ...insertFeedSpotlights(
                interval: 4,
                items: [
                  for (var i = 0; i < todayMatches.length; i++)
                    _StaggeredItem(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MatchCard(
                          match: todayMatches[i],
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.matchDetails,
                              arguments: todayMatches[i]),
                        ),
                      ),
                    ),
                ],
              ),
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
              height: 178,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 2),
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
            const SizedBox(height: 20),
            const ContentSpotlightPlaceholder(
              variant: ContentSpotlightVariant.featuredContent,
            ),
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
    return TapScale(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(
          context, AppRoutes.competitionDetails,
          arguments: competition),
      child: Material(
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
                        text.isArabic
                            ? 'بطولة مميزة'
                            : 'Featured competition',
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
      ),
    );
  }
}

/// [PageView] needs a fixed extent; this tracks compact [MatchCard] layout
/// plus a little headroom for live-badge scale and taller script metrics.
double _featuredCarouselPageHeight(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(context).scale(1.0);
  const base = 178.0;
  return (base * textScale.clamp(0.95, 1.55)).clamp(172.0, 280.0);
}

/// Horizontal PageView showing the top live matches with a subtle peek of the
/// next card on either side — gives the home screen a real "carousel" feel.
class _FeaturedCarousel extends StatefulWidget {
  const _FeaturedCarousel({required this.matches});

  final List<MatchModel> matches;

  @override
  State<_FeaturedCarousel> createState() => _FeaturedCarouselState();
}

class _FeaturedCarouselState extends State<_FeaturedCarousel> {
  static const _edgeInset = 2.0;
  static const _pageGap = 8.0;

  late final PageController _ctrl;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    final multi = widget.matches.length > 1;
    _ctrl = PageController(
      viewportFraction: multi ? 0.88 : 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = widget.matches;
    final pageHeight = _featuredCarouselPageHeight(context);
    final multi = matches.length > 1;

    return Column(
      children: [
        SizedBox(
          height: pageHeight,
          child: PageView.builder(
            controller: _ctrl,
            padEnds: true,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: matches.length,
            itemBuilder: (context, i) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: multi ? _pageGap / 2 : _edgeInset,
                ),
                child: MatchCard(
                  compact: true,
                  match: matches[i],
                  onTap: () => Navigator.pushNamed(
                      context, AppRoutes.matchDetails,
                      arguments: matches[i]),
                ),
              );
            },
          ),
        ),
        if (matches.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(matches.length, (i) {
              final selected = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: selected ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Subtle slide+fade-in for list items, indexed by [index] so a stack of cards
/// staggers naturally on first paint.
class _StaggeredItem extends StatelessWidget {
  const _StaggeredItem({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + index * 50),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
