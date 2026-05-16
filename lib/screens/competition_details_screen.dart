import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../data/mock_data.dart';
import '../models/competition_model.dart';
import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/standing_model.dart';
import '../models/team_model.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/feed_spotlight.dart';
import '../widgets/match_card.dart';
import '../widgets/section_header.dart';
import '../widgets/skeleton_box.dart';
import '../widgets/team_logo.dart';

class CompetitionDetailsScreen extends StatefulWidget {
  const CompetitionDetailsScreen({super.key, required this.competition});

  final CompetitionModel competition;

  @override
  State<CompetitionDetailsScreen> createState() =>
      _CompetitionDetailsScreenState();
}

class _CompetitionDetailsScreenState extends State<CompetitionDetailsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final app = AppScope.of(context);
    final matches = MockData.matches()
        .where((m) => m.competition.id == widget.competition.id)
        .toList();
    final teams = MockData.competitionTeams(widget.competition.id);
    final scorers = MockData.topScorers(widget.competition.id);
    final featured = matches.isNotEmpty ? matches.first : null;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, inner) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 196,
              stretch: true,
              centerTitle: false,
              titleSpacing: 0,
              // The flexibleSpace below is ALWAYS a dark gradient hero,
              // therefore we lock the AppBar foreground to white so the
              // back arrow, favorite icon and title stay readable in both
              // light and dark themes.
              backgroundColor: const Color(0xFF0A0C10),
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              iconTheme: const IconThemeData(color: Colors.white),
              actionsIconTheme: const IconThemeData(color: Colors.white),
              title: Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Text(
                  widget.competition.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  tooltip: text.favorites,
                  onPressed: () =>
                      app.toggleCompetitionFavorite(widget.competition.id),
                  icon: Icon(
                    app.isCompetitionFavorite(widget.competition.id)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background:
                    _CompetitionHeader(competition: widget.competition),
              ),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.1),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12.5),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 2.6,
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStatePropertyAll(
                    Colors.white.withValues(alpha: 0.06)),
                tabs: [
                  Tab(text: text.matches),
                  Tab(text: text.standings),
                  Tab(text: text.teams),
                  Tab(text: text.topScorers),
                  Tab(text: text.news),
                ],
              ),
            ),
          ],
          body: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              _MatchesTab(
                loading: _loading,
                featured: featured,
                matches: matches,
                refresh: () async {
                  setState(() => _loading = true);
                  await _load();
                },
              ),
              _StandingsTab(loading: _loading, standings: MockData.standings),
              _TeamsTab(loading: _loading, teams: teams),
              _ScorersTab(loading: _loading, scorers: scorers),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppEmptyState(
                    icon: Icons.article_outlined,
                    title: text.isArabic ? 'الأخبار قريبًا' : 'News coming soon',
                    subtitle: text.isArabic
                        ? 'نعمل على جلب أبرز أخبار البطولات.'
                        : 'We are working on bringing top competition news.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompetitionHeader extends StatelessWidget {
  const _CompetitionHeader({required this.competition});
  final CompetitionModel competition;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final text = AppText.of(context);
    // Reserve room for the AppBar (toolbar + status bar) at the top so our
    // hero content (badge + region) never slides under the back/favorite icons
    // or the competition title. Bottom padding leaves a breathing strip above
    // the TabBar.
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight + 8;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.55),
            primary.withValues(alpha: 0.22),
            const Color(0xFF0A0C10),
          ],
        ),
      ),
      child: Padding(
        padding:
            EdgeInsetsDirectional.fromSTEB(18, topPad, 18, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CompetitionBadge(logo: competition.logo, size: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.public_rounded,
                          size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          competition.region,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (competition.isFeatured) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.teal, AppColors.neonGreen],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        text.featuredBadge,
                        style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


List<Widget> _matchesWithSpotlights(
    BuildContext context, List<MatchModel> matches) {
  return insertFeedSpotlights(
    interval: 4,
    items: [
      for (final match in matches)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MatchCard(
            match: match,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.matchDetails,
              arguments: match,
            ),
          ),
        ),
    ],
  );
}

class _MatchesTab extends StatelessWidget {
  const _MatchesTab({
    required this.loading,
    required this.featured,
    required this.matches,
    required this.refresh,
  });

  final bool loading;
  final MatchModel? featured;
  final List<MatchModel> matches;
  final Future<void> Function() refresh;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (loading) ...[
            const SkeletonBox(height: 130),
            const SizedBox(height: 12),
            const MatchCardSkeleton(),
            const SizedBox(height: 12),
            const MatchCardSkeleton(),
          ] else if (matches.isEmpty) ...[
            const SizedBox(height: 60),
            AppEmptyState(
              icon: Icons.sports_soccer_outlined,
              title: text.noMatches,
              subtitle: text.noMatchesSub,
              detail: text.noMatchesEmptyDetail,
            ),
          ] else ...[
            if (featured != null) ...[
              SectionHeader(
                title: text.isArabic
                    ? 'المباراة المميزة'
                    : 'Featured match',
                icon: Icons.star_rounded,
              ),
              const SizedBox(height: 10),
              MatchCard(
                match: featured!,
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.matchDetails, arguments: featured),
              ),
              const SizedBox(height: 18),
            ],
            SectionHeader(
              title: text.isArabic ? 'كل المباريات' : 'All matches',
              icon: Icons.sports_soccer_rounded,
            ),
            const SizedBox(height: 10),
            ..._matchesWithSpotlights(context, matches),
          ],
        ],
      ),
    );
  }
}

class _StandingsTab extends StatelessWidget {
  const _StandingsTab({required this.loading, required this.standings});

  final bool loading;
  final List<StandingModel> standings;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, _) => const SkeletonBox(height: 56, radius: 14),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: standings.length + 2,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == 0) return const _StandingsLegend();
        if (i == 1) return const _StandingsTableHeader();
        final idx = i - 2;
        final item = standings[idx];
        return _StandingsRow(
          item: item,
          isUcl: idx < 4,
          isRel: idx >= standings.length - 1,
        );
      },
    );
  }
}

class _StandingsRow extends StatelessWidget {
  const _StandingsRow({
    required this.item,
    required this.isUcl,
    required this.isRel,
  });

  final StandingModel item;
  final bool isUcl;
  final bool isRel;

  @override
  Widget build(BuildContext context) {
    Color? rowAccent;
    if (isUcl) {
      rowAccent =
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);
    }
    if (isRel) rowAccent = AppColors.cardRed.withValues(alpha: 0.08);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: rowAccent ?? Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isUcl
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                : (isRel
                    ? AppColors.cardRed.withValues(alpha: 0.25)
                    : Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUcl
                    ? LinearGradient(colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.55),
                      ])
                    : null,
                color: isUcl
                    ? null
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.08),
              ),
              child: Text('${item.position}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                TeamLogo(shortName: item.team.shortName, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ],
            ),
          ),
          _ColCell(value: '${item.played}'),
          _ColCell(value: '${item.wins}', color: AppColors.formWin),
          _ColCell(value: '${item.draws}', color: AppColors.formDraw),
          _ColCell(value: '${item.losses}', color: AppColors.formLoss),
          _ColCell(
            value:
                '${item.goalDifference > 0 ? '+' : ''}${item.goalDifference}',
          ),
          Container(
            margin: const EdgeInsetsDirectional.only(start: 4),
            width: 38,
            padding: const EdgeInsets.symmetric(vertical: 4),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${item.points}',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ColCell extends StatelessWidget {
  const _ColCell({required this.value, this.color});
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _StandingsTableHeader extends StatelessWidget {
  const _StandingsTableHeader();

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;
    TextStyle s(String _) => TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: hint,
        letterSpacing: 0.4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: s('#'))),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: Text('TEAM', style: s('TEAM'))),
          SizedBox(width: 24, child: Text('P', style: s('P'), textAlign: TextAlign.center)),
          SizedBox(width: 24, child: Text('W', style: s('W'), textAlign: TextAlign.center)),
          SizedBox(width: 24, child: Text('D', style: s('D'), textAlign: TextAlign.center)),
          SizedBox(width: 24, child: Text('L', style: s('L'), textAlign: TextAlign.center)),
          SizedBox(width: 24, child: Text('GD', style: s('GD'), textAlign: TextAlign.center)),
          const SizedBox(width: 4),
          SizedBox(width: 38, child: Text('PTS', style: s('PTS'), textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _StandingsLegend extends StatelessWidget {
  const _StandingsLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          _legend(context, Theme.of(context).colorScheme.primary,
              'Champions League'),
          const SizedBox(width: 10),
          _legend(context, AppColors.cardRed, 'Relegation'),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, Color c, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TeamsTab extends StatelessWidget {
  const _TeamsTab({required this.loading, required this.teams});
  final bool loading;
  final List<TeamModel> teams;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    if (loading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => const SkeletonBox(height: 90),
      );
    }
    if (teams.isEmpty) {
      return AppEmptyState(
        icon: Icons.shield_outlined,
        title: text.isArabic ? 'لا توجد فرق' : 'No teams',
        subtitle: text.isArabic
            ? 'لم نعثر على فرق لهذه البطولة بعد.'
            : 'We could not find teams for this competition yet.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: teams.length,
      itemBuilder: (context, i) {
        final team = teams[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TeamLogo(shortName: team.shortName, size: 44),
              const SizedBox(height: 10),
              Text(team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              Text(team.nationality,
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}

class _ScorersTab extends StatelessWidget {
  const _ScorersTab({required this.loading, required this.scorers});
  final bool loading;
  final List<PlayerModel> scorers;

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    if (loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const SkeletonBox(height: 64),
      );
    }
    if (scorers.isEmpty) {
      return AppEmptyState(
        icon: Icons.scoreboard_outlined,
        title: text.isArabic ? 'لا يوجد هدافون' : 'No top scorers',
        subtitle: text.isArabic
            ? 'سيظهر الهدافون فور توفر البيانات.'
            : 'Top scorers will appear once data is available.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: scorers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final player = scorers[i];
        return Material(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.pushNamed(
                context, AppRoutes.playerDetails, arguments: player),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: i < 3
                          ? const LinearGradient(colors: [
                              AppColors.teal,
                              AppColors.neonGreen,
                            ])
                          : null,
                      color: i < 3
                          ? null
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.08),
                    ),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  TeamLogo(
                      shortName: player.teamLogoShort.isEmpty
                          ? player.team.substring(0, 3)
                          : player.teamLogoShort,
                      size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        Text(
                            '${player.team} · ${text.isArabic ? 'التقييم' : 'Rating'} ${player.seasonRating}',
                            style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.goalGreen.withValues(alpha: 0.32),
                        AppColors.goalGreen.withValues(alpha: 0.1),
                      ]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_soccer_rounded,
                            size: 14, color: AppColors.goalGreen),
                        const SizedBox(width: 4),
                        Text('${player.goals}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppColors.goalGreen)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
