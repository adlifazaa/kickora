import 'package:flutter/material.dart';

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

  static const _screens = [
    HomeScreen(),
    MatchesScreen(),
    CompetitionsScreen(),
    FavoritesScreen(),
    SettingsScreen(),
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
    final labels = [
      text.home,
      text.matches,
      text.competitions,
      text.favorites,
      text.settings,
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
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
                      onTap: () => setState(() => _currentIndex = i),
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
    final color =
        selected ? Theme.of(context).colorScheme.primary : Colors.white60;
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
                    AppColors.teal.withValues(alpha: 0.22),
                    AppColors.neonGreen.withValues(alpha: 0.12),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected
                  ? AppColors.teal.withValues(alpha: 0.4)
                  : Colors.transparent),
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
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
