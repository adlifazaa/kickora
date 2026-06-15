import 'package:flutter/material.dart';

import '../../app/app_colors.dart';
import '../../app/app_scope.dart';
import '../../app/app_text.dart';
import '../../app/routes.dart';
import '../../core/world_cup/world_cup_hub_loader.dart';
import '../../core/world_cup/world_cup_schedule_view.dart';
import 'world_cup_schedule_tab.dart';
import '../../core/world_cup/world_cup_stadiums.dart';
import '../../data/models/competition_model.dart';
import '../../data/models/match_model.dart';
import '../../data/models/standing_group_model.dart';
import '../../data/models/standing_model.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/network_logo_image.dart';
import '../../widgets/section_header.dart';
import '../../widgets/world_cup_match_card.dart';
import '../../widgets/team_logo.dart';
import '../../widgets/world_cup_countdown.dart';
import '../../widgets/world_cup_logo.dart';
import '../../widgets/world_cup_stadium_thumb.dart';
import 'world_cup_arab_teams_section.dart';
import 'world_cup_hub_search_screen.dart';
import 'world_cup_news_tab.dart';
import 'world_cup_match_list_screen.dart';
import 'world_cup_stadium_screen.dart';
import 'world_cup_team_screen.dart';

/// Dedicated World Cup hub — lazy-loaded; does not affect app startup.
class WorldCupHubScreen extends StatefulWidget {
  const WorldCupHubScreen({super.key, required this.competition});

  final CompetitionModel competition;

  @override
  State<WorldCupHubScreen> createState() => _WorldCupHubScreenState();
}

class _WorldCupHubScreenState extends State<WorldCupHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final WorldCupHubLoader _loader;
  final Set<int> _visitedTabs = {1};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 7, vsync: this, initialIndex: 1);
    _loader = WorldCupHubLoader(AppScope.footballRepositoryOf(context));
    _tabs.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loader.loadSchedule();
    });
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging) _loadTab(_tabs.index);
  }

  void _loadTab(int index) {
    setState(() => _visitedTabs.add(index));
    switch (index) {
      case 0:
        _loader.loadOverview();
        _loader.loadGroups();
      case 1:
        _loader.loadSchedule();
      case 2:
        _loader.loadGroups();
      case 3:
        _loader.loadTeams();
      case 4:
        _loader.loadScorers();
      case 6:
        _loader.loadNews();
      default:
        break;
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final labels = text.isArabic
        ? const [
            'نظرة عامة',
            'جدول المباريات',
            'المجموعات',
            'الفرق',
            'الهدافون',
            'الملاعب',
            'الأخبار',
          ]
        : const [
            'Overview',
            'Schedule',
            'Groups',
            'Teams',
            'Scorers',
            'Stadiums',
            'News',
          ];

    return ListenableBuilder(
      listenable: _loader,
      builder: (context, _) {
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                pinned: true,
                expandedHeight: 210,
                backgroundColor: const Color(0xFF0A0C10),
                foregroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  text.isArabic ? 'كأس العالم 2026' : widget.competition.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: text.isArabic ? 'بحث' : 'Search',
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorldCupHubSearchScreen(
                          loader: _loader,
                          competition: widget.competition,
                          isArabic: text.isArabic,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _HubHero(isArabic: text.isArabic),
                ),
                bottom: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: [for (final l in labels) Tab(text: l)],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabs,
              children: [
                _OverviewTab(
                  loader: _loader,
                  isArabic: text.isArabic,
                  competition: widget.competition,
                ),
                WorldCupScheduleTab(loader: _loader, isArabic: text.isArabic),
                _GroupsTab(loader: _loader, isArabic: text.isArabic),
                _TeamsTab(
                  loader: _loader,
                  isArabic: text.isArabic,
                  competition: widget.competition,
                ),
                _ScorersTab(loader: _loader, isArabic: text.isArabic),
                _StadiumsTab(loader: _loader, isArabic: text.isArabic),
                WorldCupNewsTab(loader: _loader, isArabic: text.isArabic),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HubHero extends StatelessWidget {
  const _HubHero({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.55),
            const Color(0xFF0A3D32),
            const Color(0xFF0A0C10),
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
        20,
        16,
      ),
      child: Row(
        children: [
          const WorldCupLogo(size: 72),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isArabic ? 'كأس العالم' : 'FIFA World Cup',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isArabic ? 'العدّ التنازلي للنهائي' : 'Final countdown',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                WorldCupFinalCountdown(isArabic: isArabic),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.loader,
    required this.isArabic,
    required this.competition,
  });

  final WorldCupHubLoader loader;
  final bool isArabic;
  final CompetitionModel competition;

  @override
  Widget build(BuildContext context) {
    if (loader.overviewLoading && !loader.overviewLoaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final featured = loader.featuredMatch;
    return RefreshIndicator(
      onRefresh: loader.refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (featured != null) ...[
            SectionHeader(
              title: isArabic ? 'المباراة المميزة' : 'Featured match',
              icon: Icons.star_rounded,
            ),
            const SizedBox(height: 10),
            WorldCupMatchCard(
              match: featured,
              isArabic: isArabic,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.matchDetails,
                arguments: featured,
              ),
            ),
            const SizedBox(height: 20),
          ],
          WorldCupArabTeamsSection(
            loader: loader,
            competition: competition,
            isArabic: isArabic,
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: isArabic ? 'ملخص سريع' : 'Quick summary',
            icon: Icons.insights_rounded,
          ),
          const SizedBox(height: 10),
          _StatRow(
            isArabic: isArabic,
            loader: loader,
            live: loader.matches
                .where((m) => m.status == MatchStatus.live)
                .length,
            upcoming: loader.matches
                .where((m) => m.status == MatchStatus.upcoming)
                .length,
            finished: loader.matches
                .where((m) => m.status == MatchStatus.finished)
                .length,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.isArabic,
    required this.loader,
    required this.live,
    required this.upcoming,
    required this.finished,
  });

  final bool isArabic;
  final WorldCupHubLoader loader;
  final int live;
  final int upcoming;
  final int finished;

  void _open(BuildContext context, WorldCupMatchListFilter filter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorldCupMatchListScreen(
          filter: filter,
          matches: loader.matches,
          isArabic: isArabic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _chip(
            context,
            isArabic ? 'مباشر' : 'Live',
            live,
            AppColors.liveRed,
            () => _open(context, WorldCupMatchListFilter.live),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chip(
            context,
            isArabic ? 'قادمة' : 'Upcoming',
            upcoming,
            Theme.of(context).colorScheme.primary,
            () => _open(context, WorldCupMatchListFilter.upcoming),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _chip(
            context,
            isArabic ? 'منتهية' : 'Finished',
            finished,
            Theme.of(context).hintColor,
            () => _open(context, WorldCupMatchListFilter.finished),
          ),
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    String label,
    int count,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Text('$count',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: color)),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab({required this.loader, required this.isArabic});

  final WorldCupHubLoader loader;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    if (loader.groupsLoading && !loader.groupsLoaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (loader.groups.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.grid_view_rounded,
          title: isArabic ? 'لا يوجد جدول مجموعات' : 'No groups yet',
          subtitle: isArabic
              ? 'سيظهر عند توفر البيانات.'
              : 'Groups will appear when data is available.',
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: loader.groups.length,
      itemBuilder: (context, i) => _GroupCard(
        group: loader.groups[i],
        isArabic: isArabic,
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.isArabic});

  final StandingGroupModel group;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 8),
            _GroupHeader(isArabic: isArabic),
            for (final row in group.rows) _GroupRow(row: row, isArabic: isArabic),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.isArabic});

  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final h = WorldCupGroupTableLabels.headers(isArabic: isArabic);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 22, child: Text(h[0], style: _style)),
          Expanded(child: Text(h[1], style: _style)),
          for (var i = 2; i < h.length; i++)
            SizedBox(
              width: WorldCupGroupTableLabels.statWidth(i, isArabic: isArabic),
              child: Text(
                h[i],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _style,
              ),
            ),
        ],
      ),
    );
  }

  TextStyle get _style => TextStyle(
        fontSize: isArabic ? 9 : 7.5,
        fontWeight: FontWeight.w800,
        height: 1.15,
      );
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.row, required this.isArabic});

  final StandingModel row;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
              width: 22,
              child: Text('${row.position}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
          TeamLogo.fromTeam(row.team, size: 20),
          const SizedBox(width: 4),
          Expanded(
            child: Text(row.team.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 11)),
          ),
          _cell('${row.played}',
              width: WorldCupGroupTableLabels.statWidth(2, isArabic: isArabic)),
          _cell('${row.wins}',
              width: WorldCupGroupTableLabels.statWidth(3, isArabic: isArabic)),
          _cell('${row.draws}',
              width: WorldCupGroupTableLabels.statWidth(4, isArabic: isArabic)),
          _cell('${row.losses}',
              width: WorldCupGroupTableLabels.statWidth(5, isArabic: isArabic)),
          _cell('${row.goalDifference > 0 ? '+' : ''}${row.goalDifference}',
              width: WorldCupGroupTableLabels.statWidth(6, isArabic: isArabic)),
          _cell('${row.points}',
              width: WorldCupGroupTableLabels.statWidth(7, isArabic: isArabic),
              bold: true),
        ],
      ),
    );
  }

  Widget _cell(String v, {bool bold = false, double width = 28}) {
    return SizedBox(
      width: width,
      child: Text(v,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              fontSize: 11)),
    );
  }
}

class _TeamsTab extends StatelessWidget {
  const _TeamsTab({
    required this.loader,
    required this.isArabic,
    required this.competition,
  });

  final WorldCupHubLoader loader;
  final bool isArabic;
  final CompetitionModel competition;

  @override
  Widget build(BuildContext context) {
    if (loader.teamsLoading && !loader.teamsLoaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (loader.teams.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.flag_rounded,
          title: isArabic ? 'لا توجد فرق' : 'No teams',
          subtitle: isArabic
              ? 'ستظهر عند توفر البيانات.'
              : 'Teams will appear when data is available.',
        ),
      );
    }
    return ListenableBuilder(
      listenable: AppScope.of(context),
      builder: (context, _) {
        final app = AppScope.of(context);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: loader.teams.length,
          itemBuilder: (context, i) {
            final team = loader.teams[i];
            final group = loader.groupNameForTeam(team.id);
            final isFavorite = app.isTeamFavorite(team.id);
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorldCupTeamScreen(
                    team: team,
                    loader: loader,
                    competition: competition,
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        TeamLogo.fromTeam(team, size: 40),
                        Positioned(
                          top: -4,
                          right: -4,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            iconSize: 18,
                            onPressed: () => app.toggleTeamFavorite(team.id),
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? Colors.redAccent
                                  : Theme.of(context).hintColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        team.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                    if (group != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        group,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ScorersTab extends StatelessWidget {
  const _ScorersTab({required this.loader, required this.isArabic});

  final WorldCupHubLoader loader;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    if (loader.scorersLoading && !loader.scorersLoaded) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (loader.scorers.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: Icons.sports_soccer_rounded,
          title: isArabic ? 'لم تتوفر بيانات الهدافين بعد.' : 'No scorers yet',
          subtitle: isArabic
              ? 'ستظهر القائمة عند توفر البيانات من البطولة.'
              : 'The list will appear when tournament data is available.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: loader.scorers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = loader.scorers[i];
        return Card(
          child: ListTile(
            leading: SizedBox(
              width: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (p.photoUrl.isNotEmpty)
                    NetworkLogoImage(
                      size: 40,
                      imageUrl: p.photoUrl,
                      fallback: CircleAvatar(
                        child: Text('${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    )
                  else
                    CircleAvatar(
                      child: Text('${i + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                ],
              ),
            ),
            title: Text(p.name,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
              p.assists > 0
                  ? '${p.team} · ${isArabic ? 'تمريرات حاسمة' : 'Assists'}: ${p.assists}'
                  : p.team,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${p.goals}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
                Text(isArabic ? 'هدف' : 'Goals',
                    style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StadiumsTab extends StatelessWidget {
  const _StadiumsTab({required this.loader, required this.isArabic});

  final WorldCupHubLoader loader;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final venues = loader.matches.map((m) => m.stadium).where((s) => s.isNotEmpty);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: WorldCupStadiums.venues.length,
      itemBuilder: (context, i) {
        final s = WorldCupStadiums.venues[i];
        final hosted = WorldCupStadiums.matchCountFor(s.name, venues);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WorldCupStadiumScreen(
                  stadium: s,
                  matches: loader.matches,
                  isArabic: isArabic,
                ),
              ),
            ),
            leading: WorldCupStadiumThumb(stadium: s, size: 52),
            title: Text(s.name,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${s.city}, ${s.country} · ${s.capacity}'),
            trailing: hosted > 0
                ? Text(isArabic ? '$hosted مباراة' : '$hosted matches',
                    style: const TextStyle(fontWeight: FontWeight.w700))
                : null,
          ),
        );
      },
    );
  }
}
