import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/world_cup/world_cup_hub_loader.dart';
import '../../core/world_cup/world_cup_schedule_view.dart';
import '../../utils/world_cup_match_date_formatter.dart';
import '../../widgets/async_content_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton_box.dart';
import '../../widgets/world_cup_match_card.dart';

/// Full World Cup fixture schedule — grouped by date with filters.
class WorldCupScheduleTab extends StatefulWidget {
  const WorldCupScheduleTab({
    super.key,
    required this.loader,
    required this.isArabic,
  });

  final WorldCupHubLoader loader;
  final bool isArabic;

  @override
  State<WorldCupScheduleTab> createState() => _WorldCupScheduleTabState();
}

class _WorldCupScheduleTabState extends State<WorldCupScheduleTab> {
  WorldCupScheduleFilter _filter = WorldCupScheduleFilter.all;

  Future<void> _refresh() async {
    widget.loader.scheduleLoaded = false;
    await widget.loader.loadSchedule();
  }

  @override
  Widget build(BuildContext context) {
    final loader = widget.loader;
    final isArabic = widget.isArabic;

    if (loader.scheduleLoading && loader.matches.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonBox(height: 44),
          SizedBox(height: 10),
          SkeletonBox(height: 100),
        ],
      );
    }

    final filtered = WorldCupScheduleView.filterMatches(loader.matches, _filter);
    final dateGroups = WorldCupScheduleView.groupByDate(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'جدول المباريات' : 'Schedule',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                isArabic
                    ? '${filtered.length} مباراة'
                    : '${filtered.length} matches',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final f in WorldCupScheduleFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.label(isArabic: isArabic)),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: _filter == f
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).hintColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: dateGroups.isEmpty
              ? RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.35,
                        child: AsyncContentView(
                          loading: loader.scheduleLoading,
                          isEmpty: true,
                          onRetry: () => loader.loadSchedule(),
                          emptyIcon: Icons.calendar_month_outlined,
                          emptyTitle: isArabic ? 'لا توجد مباريات' : 'No matches',
                          emptySubtitle: isArabic
                              ? 'جرّب فلتراً آخر أو اسحب للتحديث.'
                              : 'Try another filter or pull to refresh.',
                          child: const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: Theme.of(context).colorScheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: dateGroups.length,
                    itemBuilder: (context, gi) {
                      final group = dateGroups[gi];
                      final header = WorldCupMatchDateFormatter.formatDateHeader(
                        group.date,
                        isArabic: isArabic,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: header,
                            icon: Icons.calendar_today_rounded,
                          ),
                          const SizedBox(height: 8),
                          for (final m in group.matches)
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
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
