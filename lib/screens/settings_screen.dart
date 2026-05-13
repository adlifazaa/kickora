import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = AppText.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Text(text.settings,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  )),
          const SizedBox(height: 4),
          Text(
            text.isArabic
                ? 'خصص تجربة Kickora'
                : 'Customize your Kickora experience',
            style: TextStyle(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: text.isArabic ? 'التفضيلات' : 'Preferences',
            icon: Icons.tune_rounded,
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.language_rounded,
            iconColor: AppColors.teal,
            title: '${text.language}: العربية / English',
            subtitle: text.isArabic
                ? 'دعم كامل لاتجاه RTL'
                : 'Full RTL & LTR support',
            trailing: Switch.adaptive(
              value: app.isArabic,
              onChanged: (v) => app.setLocale(Locale(v ? 'ar' : 'en')),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.dark_mode_rounded,
            iconColor: AppColors.neonGreen,
            title: text.darkMode,
            subtitle: text.isArabic
                ? 'مظهر ملعب ليلي فاخر'
                : 'Premium night stadium look',
            trailing: Switch.adaptive(
              value: app.themeMode == ThemeMode.dark,
              onChanged: (v) =>
                  app.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
            ),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.notifications_active_outlined,
            iconColor: Colors.amber,
            title: text.notifications,
            subtitle: text.isArabic
                ? 'تنبيهات الأهداف والجولات (وهمي)'
                : 'Goals & kick-off alerts (placeholder)',
            trailing: Switch.adaptive(value: false, onChanged: (_) {}),
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: text.isArabic ? 'معلومات Kickora' : 'About Kickora',
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.sports_soccer_rounded,
            iconColor: Theme.of(context).colorScheme.primary,
            title: text.about,
            subtitle: text.isArabic
                ? 'قصة التطبيق، المميزات، والروابط'
                : 'Story, features, and links',
            onTap: () => Navigator.pushNamed(context, AppRoutes.about),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.verified_outlined,
            iconColor: Theme.of(context).hintColor,
            title: text.appVersion,
            subtitle: 'v1.0.0 · Kickora',
            onTap: () => Navigator.pushNamed(context, AppRoutes.about),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: text.isArabic ? 'الخصوصية والقانون' : 'Privacy & legal',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: AppColors.subBlue,
            title: text.privacy,
            subtitle: text.isArabic
                ? 'كيف نتعامل مع بياناتك'
                : 'How we handle your data',
            onTap: () => Navigator.pushNamed(context, AppRoutes.privacy),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.description_outlined,
            iconColor: AppColors.varPurple,
            title: text.terms,
            subtitle: text.isArabic
                ? 'القواعد التي تحكم الاستخدام'
                : 'Rules of using Kickora',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    text.isArabic
                        ? 'شروط الاستخدام قريبًا'
                        : 'Terms of use coming soon',
                  ),
                ),
              );
            },
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withValues(alpha: 0.28),
                      iconColor.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(color: iconColor.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
