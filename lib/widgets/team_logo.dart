import 'package:flutter/material.dart';

import '../app/app_colors.dart';

/// Deterministic gradient "crest" placeholder for a team based on its short name.
/// Will be replaced by real logo URLs when the API is wired in.
class TeamLogo extends StatelessWidget {
  const TeamLogo({super.key, required this.shortName, this.size = 36});

  final String shortName;
  final double size;

  static const List<List<Color>> _palettes = [
    [Color(0xFF00D1C1), Color(0xFF008F86)],
    [Color(0xFF7CFF00), Color(0xFF2EA90E)],
    [Color(0xFFFFB020), Color(0xFFE0541A)],
    [Color(0xFF63D4FF), Color(0xFF1E78D4)],
    [Color(0xFFFF5A63), Color(0xFFB1213F)],
    [Color(0xFFBBA3FF), Color(0xFF6A4AE0)],
    [Color(0xFFFFE566), Color(0xFFFFA22A)],
    [Color(0xFFE0E6EE), Color(0xFF7A8290)],
  ];

  List<Color> _palette() {
    if (shortName.isEmpty) return _palettes[0];
    final code = shortName.codeUnitAt(0) + shortName.length * 7;
    return _palettes[code % _palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = _palette();
    final initials = shortName.isEmpty
        ? '?'
        : shortName.substring(0, shortName.length.clamp(1, 3));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.32,
          letterSpacing: 0.4,
          shadows: const [
            Shadow(blurRadius: 4, color: Color(0x88000000)),
          ],
        ),
      ),
    );
  }
}

/// Compact horizontally-laid out crest used in lists and headers.
class TeamCrestTile extends StatelessWidget {
  const TeamCrestTile({
    super.key,
    required this.shortName,
    required this.name,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String shortName;
  final String name;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          child: Row(
            children: [
              TeamLogo(shortName: shortName, size: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Small icon-only "competition" badge using initials/logo string.
class CompetitionBadge extends StatelessWidget {
  const CompetitionBadge({super.key, required this.logo, this.size = 40});

  final String logo;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.teal, AppColors.tealDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.25),
            blurRadius: size * 0.4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        logo,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.34,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
