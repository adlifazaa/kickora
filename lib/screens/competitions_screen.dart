import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../data/mock_data.dart';
import '../models/competition_model.dart';
import '../services/app_controller.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/competition_card.dart';

/// Browse + search competitions. Includes a premium search field, category
/// chips, recent searches (persisted locally), and a clean empty state.
class CompetitionsScreen extends StatefulWidget {
  const CompetitionsScreen({super.key});

  @override
  State<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends State<CompetitionsScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String _category = 'all';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    setState(() => _query = value);
  }

  Future<void> _commitSearch(String value) async {
    final q = value.trim();
    if (q.isEmpty) return;
    await AppScope.of(context).addRecentSearch(q);
  }

  bool _categoryMatch(CompetitionModel c) {
    if (_category == 'all') return true;
    if (_category == 'favorites') {
      final app = AppScope.of(context);
      return app.isCompetitionFavorite(c.id);
    }
    return c.region.toLowerCase().contains(_category);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final all = MockData.competitions;
        final filtered = all.where((c) {
          final qOk = _query.isEmpty ||
              c.name.toLowerCase().contains(_query.toLowerCase()) ||
              c.region.toLowerCase().contains(_query.toLowerCase());
          return qOk && _categoryMatch(c);
        }).toList();
        return _buildScaffold(context, app, text, filtered);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, AppController app, AppText text,
      List<CompetitionModel> filtered) {
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
            child: _SearchField(
              controller: _controller,
              hint: text.searchCompetition,
              onChanged: _setQuery,
              onSubmitted: (v) {
                _commitSearch(v);
                _setQuery(v);
              },
              onClear: () {
                _controller.clear();
                _setQuery('');
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _CategoryChip(
                  label: text.isArabic ? 'الكل' : 'All',
                  selected: _category == 'all',
                  onTap: () => setState(() => _category = 'all'),
                ),
                _CategoryChip(
                  label: text.isArabic ? 'المفضلة' : 'Favorites',
                  icon: Icons.bookmark_rounded,
                  selected: _category == 'favorites',
                  onTap: () => setState(() => _category = 'favorites'),
                ),
                _CategoryChip(
                  label: 'Europe',
                  selected: _category == 'europe',
                  onTap: () => setState(() => _category = 'europe'),
                ),
                _CategoryChip(
                  label: 'England',
                  selected: _category == 'england',
                  onTap: () => setState(() => _category = 'england'),
                ),
                _CategoryChip(
                  label: 'Spain',
                  selected: _category == 'spain',
                  onTap: () => setState(() => _category = 'spain'),
                ),
                _CategoryChip(
                  label: 'Italy',
                  selected: _category == 'italy',
                  onTap: () => setState(() => _category = 'italy'),
                ),
                _CategoryChip(
                  label: 'Germany',
                  selected: _category == 'germany',
                  onTap: () => setState(() => _category = 'germany'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(context, app, text, filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppController app, AppText text,
      List<CompetitionModel> filtered) {
    final hasQuery = _query.trim().isNotEmpty;
    if (!hasQuery && _category == 'all' && filtered.isNotEmpty) {
      // Idle state: show recent searches + the catalog grid.
      return CustomScrollView(
        slivers: [
          if (app.recentSearches.isNotEmpty)
            SliverToBoxAdapter(
              child: _RecentSearches(
                items: app.recentSearches,
                onTap: (q) {
                  _controller.text = q;
                  _controller.selection = TextSelection.collapsed(offset: q.length);
                  _setQuery(q);
                },
                onRemove: (q) => app.removeRecentSearch(q),
                onClear: () => app.clearRecentSearches(),
                title: text.recentSearches,
                clearLabel: text.clearAll,
              ),
            ),
          _competitionsGrid(context, filtered),
        ],
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: AppEmptyState(
          icon: hasQuery
              ? Icons.search_off_rounded
              : Icons.travel_explore_rounded,
          title: hasQuery ? text.noSearchResultsTitle : text.searchEmptyTitle,
          subtitle:
              hasQuery ? text.noSearchResultsSubtitle : text.searchEmptySubtitle,
          detail: hasQuery
              ? (text.isArabic ? 'البحث عن: "$_query"' : 'Searched for: "$_query"')
              : null,
        ),
      );
    }

    return CustomScrollView(
      slivers: [_competitionsGrid(context, filtered)],
    );
  }

  SliverPadding _competitionsGrid(
      BuildContext context, List<CompetitionModel> items) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final competition = items[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 260 + index * 30),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) {
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 8),
                    child: child,
                  ),
                );
              },
              child: CompetitionCard(
                competition: competition,
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.competitionDetails,
                    arguments: competition),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: selected
                  ? LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.7)],
                    )
                  : null,
              color: selected
                  ? null
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.05),
              border: Border.all(
                color: selected
                    ? primary.withValues(alpha: 0.6)
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      size: 14,
                      color: selected
                          ? Colors.black
                          : Theme.of(context).hintColor),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: selected
                        ? Colors.black
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.items,
    required this.onTap,
    required this.onRemove,
    required this.onClear,
    required this.title,
    required this.clearLabel,
  });

  final List<String> items;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;
  final String title;
  final String clearLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded,
                  size: 16, color: Theme.of(context).hintColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5),
              ),
              const Spacer(),
              TextButton(
                onPressed: onClear,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  minimumSize: const Size(0, 28),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  clearLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 11.5),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((q) {
              return InputChip(
                label: Text(q,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
                onPressed: () => onTap(q),
                onDeleted: () => onRemove(q),
                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
