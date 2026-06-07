import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../models/competition_model.dart';
import '../models/team_model.dart';
import '../services/app_controller.dart';
import '../services/favorites_resolver.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/feed_spotlight.dart';
import '../widgets/match_card.dart';
import '../widgets/section_header.dart';
import '../widgets/team_logo.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loadingItems = true;
  FavoritesSnapshot _snapshot = const FavoritesSnapshot();
  AppController? _app;
  Set<int> _trackedTeamIds = const {};
  Set<int> _trackedCompetitionIds = const {};
  Set<int> _trackedMatchIds = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (!identical(_app, app)) {
      _app?.removeListener(_onAppChanged);
      _app = app;
      _app!.addListener(_onAppChanged);
    }
  }

  @override
  void dispose() {
    _app?.removeListener(_onAppChanged);
    super.dispose();
  }

  void _onAppChanged() {
    final app = _app;
    if (app == null || _favoriteIdsUnchanged(app)) return;
    _refresh(silent: true);
  }

  bool _favoriteIdsUnchanged(AppController app) {
    return setEquals(_trackedTeamIds, app.favoriteTeamIds) &&
        setEquals(_trackedCompetitionIds, app.favoriteCompetitionIds) &&
        setEquals(_trackedMatchIds, app.favoriteMatchIds);
  }

  Future<void> _refresh({bool silent = false}) async {
    final app = AppScope.of(context);
    if (!silent && mounted) {
      setState(() => _loadingItems = true);
    }

    await app.favoriteManager.load();

    final snapshot = await FavoritesResolver(app.footballRepository).resolve(
      teamIds: app.favoriteTeamIds,
      competitionIds: app.favoriteCompetitionIds,
      matchIds: app.favoriteMatchIds,
    );

    if (!mounted) return;
    setState(() {
      _loadingItems = false;
      _snapshot = snapshot;
      _trackedTeamIds = Set<int>.from(app.favoriteTeamIds);
      _trackedCompetitionIds = Set<int>.from(app.favoriteCompetitionIds);
      _trackedMatchIds = Set<int>.from(app.favoriteMatchIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = AppText.of(context);

    if (app.favoritesLoading || _loadingItems) {
      return const SafeArea(
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
        ),
      );
    }

    final teams = _snapshot.teams;
    final competitions = _snapshot.competitions;
    final matches = _snapshot.matches;

    if (_snapshot.isEmpty) {
      return SafeArea(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) {
              return Opacity(
                  opacity: t,
                  child: Transform.scale(scale: 0.96 + 0.04 * t, child: child));
            },
            child: AppEmptyState(
              title: text.noFavoritesTitle,
              subtitle: text.noFavoritesSubtitle,
              detail: text.noFavoritesDetail,
              icon: Icons.star_border_rounded,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Text(text.favorites,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    )),
            const SizedBox(height: 14),
            if (matches.isNotEmpty) ...[
              SectionHeader(
                title: text.isArabic
                    ? 'المباريات المفضلة'
                    : 'Favorite matches',
                icon: Icons.sports_soccer_rounded,
              ),
              const SizedBox(height: 10),
              ...insertFeedSpotlights(
                context: context,
                interval: 4,
                items: [
                  for (final match in matches)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MatchCard(
                        match: match,
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.matchDetails,
                            arguments: match),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (teams.isNotEmpty) ...[
              SectionHeader(
                title: text.isArabic ? 'الفرق المفضلة' : 'Favorite teams',
                icon: Icons.shield_rounded,
              ),
              const SizedBox(height: 8),
              ...teams.map((team) => _TeamTile(team: team)),
              const SizedBox(height: 8),
            ],
            if (competitions.isNotEmpty) ...[
              SectionHeader(
                title: text.isArabic
                    ? 'البطولات المفضلة'
                    : 'Favorite competitions',
                icon: Icons.emoji_events_rounded,
              ),
              const SizedBox(height: 8),
              ...competitions.map(
                  (competition) => _CompetitionTile(competition: competition)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({required this.team});

  final TeamModel team;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TeamCrestTile.fromTeam(
        team,
        subtitle: team.countryName,
        trailing: IconButton(
          onPressed: () => app.toggleTeamFavorite(team.id),
          icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _CompetitionTile extends StatelessWidget {
  const _CompetitionTile({required this.competition});

  final CompetitionModel competition;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).cardTheme.color,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: () => Navigator.pushNamed(
              context, AppRoutes.competitionDetails,
              arguments: competition),
          leading: CompetitionBadge.fromCompetition(competition, size: 36),
          title: Text(competition.name,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(competition.region,
              style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
          trailing: IconButton(
            onPressed: () => app.toggleCompetitionFavorite(competition.id),
            icon: Icon(Icons.bookmark_rounded,
                color: Theme.of(context).colorScheme.primary),
          ),
        ),
      ),
    );
  }
}
