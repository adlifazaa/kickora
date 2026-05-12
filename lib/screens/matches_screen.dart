import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../data/mock_data.dart';
import '../models/match_model.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/app_error_placeholder.dart';
import '../widgets/match_card.dart';
import '../widgets/skeleton_box.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _load();
    if (mounted) setState(() => _error = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final all = MockData.matches();
    final byStatus = [
      all.where((m) => m.status == MatchStatus.live).toList(),
      all.where((m) => m.status == MatchStatus.upcoming).toList(),
      all.where((m) => m.status == MatchStatus.finished).toList(),
    ];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text.matches,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4)),
                      Text(text.homeSubtitle,
                          style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                _DateChip(
                  date: _selectedDate,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2028),
                      initialDate: _selectedDate,
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          _PremiumTabBar(
            controller: _tabController,
            tabs: [text.live, text.upcoming, text.finished],
          ),
          Expanded(
            child: _error
                ? AppErrorPlaceholder(
                    title: text.errorTitle,
                    message: text.errorSub,
                    retryLabel: text.retry,
                    onRetry: () {
                      setState(() => _error = false);
                      _load();
                    },
                  )
                : TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: List.generate(3, (index) {
                      return RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: _loading
                            ? ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: 5,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (_, _) =>
                                    const MatchCardSkeleton(),
                              )
                            : (byStatus[index].isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      const SizedBox(height: 80),
                                      AppEmptyState(
                                        icon: Icons.sports_soccer_outlined,
                                        title: text.noMatches,
                                        subtitle: text.noMatchesSub,
                                      ),
                                    ],
                                  )
                                : ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    children: _buildGrouped(
                                        byStatus[index], context, text),
                                  )),
                      );
                    }),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGrouped(
      List<MatchModel> matches, BuildContext context, AppText text) {
    final grouped = <String, List<MatchModel>>{};
    for (final match in matches) {
      grouped.putIfAbsent(match.competition.name, () => []).add(match);
    }
    final widgets = <Widget>[];
    grouped.forEach((competition, list) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.teal, AppColors.neonGreen],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(competition,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13.5)),
              ),
              Text('${list.length}',
                  style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
      widgets.addAll(list.map((match) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MatchCard(
                match: match,
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.matchDetails,
                    arguments: match)),
          )));
      widgets.add(const SizedBox(height: 6));
    });
    return widgets;
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_rounded, size: 16, color: primary),
              const SizedBox(width: 6),
              Text('${date.day}/${date.month}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumTabBar extends StatelessWidget {
  const _PremiumTabBar({required this.controller, required this.tabs});

  final TabController controller;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TabBar(
        controller: controller,
        labelColor: Colors.black,
        unselectedLabelColor: Theme.of(context).hintColor,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient:
              const LinearGradient(colors: [AppColors.teal, AppColors.neonGreen]),
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
        splashBorderRadius: BorderRadius.circular(10),
        dividerColor: Colors.transparent,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}
