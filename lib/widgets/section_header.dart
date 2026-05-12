import 'package:flutter/material.dart';

import '../app/app_colors.dart';

/// Reusable section header with optional accent stripe and action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onTap,
    this.icon,
    this.accent,
  });

  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.teal;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.55)],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 10),
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (actionText != null)
          TextButton.icon(
            onPressed: onTap,
            icon: Icon(Icons.chevron_right_rounded,
                size: 18, color: Theme.of(context).colorScheme.primary),
            label: Text(
              actionText!,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
            iconAlignment: IconAlignment.end,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 32),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }
}
