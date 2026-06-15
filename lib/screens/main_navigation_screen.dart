import 'package:flutter/material.dart';

import '../ads/ad_service.dart';
import '../app/app_colors.dart';
import '../app/app_text.dart';
import 'competitions_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'matches_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  int _tabNavigationCount = 0;
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    AdService.instance.scheduleDeferredInitialize();
  }

  static final _screenBuilders = <Widget Function()>[
    () => const HomeScreen(),
    () => const MatchesScreen(),
    () => const CompetitionsScreen(),
    () => const FavoritesScreen(),
    () => const SettingsScreen(),
  ];

  static const _icons = [
    Icons.home_rounded,
    Icons.sports_soccer_rounded,
    Icons.emoji_events_rounded,
    Icons.star_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final labels = [
      text.home,
      text.matches,
      text.competitions,
      text.favorites,
      text.settings,
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_screenBuilders.length, (index) {
          if (!_visitedTabs.contains(index)) {
            return const SizedBox.shrink();
          }
          return _screenBuilders[index]();
        }),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                  blurRadius: isDark ? 12 : 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_icons.length, (i) {
                  final isSelected = _currentIndex == i;
                  return Expanded(
                    child: _NavItem(
                      icon: _icons[i],
                      label: labels[i],
                      selected: isSelected,
                      onTap: () => _onTabSelected(i),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    if (index != _currentIndex) {
      if (_tabNavigationCount > 0) {
        AdService.instance.onMainTabChanged(
          from: _currentIndex,
          to: index,
        );
      }
      _tabNavigationCount++;
      setState(() {
        _visitedTabs.add(index);
        _currentIndex = index;
      });
    }
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    // Pull the unselected color from the active theme so it reads correctly
    // in BOTH light and dark mode (was hardcoded white60 → invisible on white
    // in light mode).
    final unselected = theme.bottomNavigationBarTheme.unselectedItemColor ??
        theme.hintColor;
    final color = selected ? primary : unselected;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    primary.withValues(alpha: isDark ? 0.16 : 0.20),
                    primary.withValues(alpha: isDark ? 0.06 : 0.08),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? primary.withValues(alpha: isDark ? 0.28 : 0.38)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
