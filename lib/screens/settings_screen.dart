import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_contact.dart';
import '../app/app_locale.dart';
import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../app/routes.dart';
import '../services/app_controller.dart';
import '../widgets/section_header.dart';

Future<void> _onMasterNotificationsChanged(
  BuildContext context,
  AppController app,
  bool enabled,
) async {
  final granted = await app.setNotificationsEnabled(enabled);
  if (!context.mounted || !enabled || granted) return;
  final isArabic = app.isArabic;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        isArabic
            ? 'لم يتم منح إذن الإشعارات. يمكنك تفعيلها من إعدادات الجهاز.'
            : 'Notification permission was not granted. You can enable it in system settings.',
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _versionTapCount = 0;

  void _onVersionTileTap(AppController app) {
    if (app.showNotificationDiagnostics && !kDebugMode) return;
    _versionTapCount += 1;
    if (_versionTapCount >= 7) {
      _versionTapCount = 0;
      unawaited(app.unlockDeveloperMode().then((_) {
        if (!mounted) return;
        final isArabic = app.isArabic;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تم تفعيل وضع المطوّر'
                  : 'Developer mode enabled',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }));
      return;
    }
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) _versionTapCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = AppText.of(context);

    return SafeArea(
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          return ListView(
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
              _SettingsSwitchTile(
                icon: Icons.language_rounded,
                iconColor: AppColors.teal,
                title: '${text.language}: العربية / English',
                subtitle: text.isArabic
                    ? 'دعم كامل لاتجاه RTL'
                    : 'Full RTL & LTR support',
                value: app.isArabic,
                onChanged: (v) => app.setLocale(
                  Locale(v ? AppLocale.arabicCode : AppLocale.englishCode),
                ),
              ),
              const SizedBox(height: 12),
              _SettingsSwitchTile(
                icon: Icons.dark_mode_rounded,
                iconColor: AppColors.neonGreen,
                title: text.darkMode,
                subtitle: text.isArabic
                    ? 'مظهر ملعب ليلي فاخر'
                    : 'Premium night stadium look',
                value: app.themeMode == ThemeMode.dark,
                onChanged: (v) =>
                    app.setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
              ),
              const SizedBox(height: 12),
              _SettingsSwitchTile(
                icon: Icons.notifications_active_outlined,
                iconColor: Colors.amber,
                title: text.isArabic ? 'تفعيل الإشعارات' : 'Enable notifications',
                subtitle: text.notificationsPrefsBody,
                subtitleMaxLines: 3,
                value: app.notificationsEnabled,
                onChanged: (v) => _onMasterNotificationsChanged(context, app, v),
              ),
              const SizedBox(height: 16),
              SectionHeader(
                title: text.isArabic ? 'إشعارات المباريات' : 'Match notifications',
                icon: Icons.sports_soccer_rounded,
              ),
              const SizedBox(height: 12),
              _NotificationPrefTile(
                enabled: app.notificationsEnabled,
                title: text.isArabic ? 'الأهداف' : 'Goals',
                value: app.notifyGoalsEnabled,
                onChanged: app.setNotifyGoalsEnabled,
              ),
              const SizedBox(height: 12),
              _NotificationPrefTile(
                enabled: app.notificationsEnabled,
                title: text.isArabic ? 'بداية المباراة' : 'Match started',
                value: app.notifyMatchStartedEnabled,
                onChanged: app.setNotifyMatchStartedEnabled,
              ),
              const SizedBox(height: 12),
              _NotificationPrefTile(
                enabled: app.notificationsEnabled,
                title: text.isArabic ? 'البطاقات الحمراء' : 'Red cards',
                value: app.notifyRedCardsEnabled,
                onChanged: app.setNotifyRedCardsEnabled,
              ),
              const SizedBox(height: 12),
              _NotificationPrefTile(
                enabled: app.notificationsEnabled,
                title: text.isArabic ? 'نهاية المباراة' : 'Match finished',
                value: app.notifyMatchFinishedEnabled,
                onChanged: app.setNotifyMatchFinishedEnabled,
              ),
              const SizedBox(height: 16),
              SectionHeader(
                title: text.isArabic ? 'المفضلة' : 'Favorites',
                icon: Icons.star_rounded,
              ),
              const SizedBox(height: 12),
              _NotificationPrefTile(
                enabled: app.notificationsEnabled,
                title: text.isArabic
                    ? 'تحديثات الفرق المفضلة'
                    : 'Favorite team updates',
                value: app.notifyFavoriteTeamUpdatesEnabled,
                onChanged: app.setNotifyFavoriteTeamUpdatesEnabled,
              ),
              const SizedBox(height: 12),
              _NotificationPrefTile(
                enabled: app.notificationsEnabled,
                title: text.isArabic
                    ? 'تحديثات البطولات المفضلة'
                    : 'Favorite competition updates',
                value: app.notifyFavoriteCompetitionUpdatesEnabled,
                onChanged: app.setNotifyFavoriteCompetitionUpdatesEnabled,
              ),
              const SizedBox(height: 12),
              _NotificationPrefTile(
                enabled: app.notificationsEnabled,
                title: text.isArabic
                    ? 'تحديثات المباريات المفضلة'
                    : 'Favorite match updates',
                value: app.notifyFavoriteMatchUpdatesEnabled,
                onChanged: app.setNotifyFavoriteMatchUpdatesEnabled,
              ),
              if (app.showNotificationDiagnostics) ...[
                const SizedBox(height: 12),
                _SettingsTile(
                  icon: Icons.bug_report_outlined,
                  iconColor: Colors.amber,
                  title: text.isArabic
                      ? 'تشخيص الإشعارات'
                      : 'Notification diagnostics',
                  subtitle: text.isArabic
                      ? 'الحالة، الاشتراكات، وخادم Render'
                      : 'Status, subscriptions, and Render backend',
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.notificationDiagnostics,
                  ),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: Theme.of(context).hintColor),
                ),
              ],
              const SizedBox(height: 26),
              SectionHeader(
                title: text.isArabic ? 'Kickora Premium' : 'Kickora Premium',
                icon: Icons.workspace_premium_rounded,
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.block_rounded,
                iconColor: AppColors.neonGreen,
                title: text.removeAdsTitle,
                subtitle: app.isPremium
                    ? text.premiumActiveSubtitle
                    : text.removeAdsSettingsSubtitle,
                onTap: () => Navigator.pushNamed(context, AppRoutes.premium),
                trailing: app.isPremium
                    ? Icon(Icons.verified_rounded,
                        color: Theme.of(context).colorScheme.primary)
                    : Icon(Icons.chevron_right_rounded,
                        color: Theme.of(context).hintColor),
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
                trailing: Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.verified_outlined,
                iconColor: Theme.of(context).hintColor,
                title: text.appVersion,
                subtitle: 'v1.0.0 · Kickora',
                onTap: () => _onVersionTileTap(app),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.mail_outline_rounded,
                iconColor: AppColors.teal,
                title: text.contactUs,
                subtitle: AppContact.email,
                onTap: () => Navigator.pushNamed(context, AppRoutes.about),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).hintColor),
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
                trailing: Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.description_outlined,
                iconColor: AppColors.varPurple,
                title: text.terms,
                subtitle: text.isArabic
                    ? 'القواعد التي تحكم الاستخدام'
                    : 'Rules of using Kickora',
                onTap: () => Navigator.pushNamed(context, AppRoutes.terms),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: Theme.of(context).hintColor),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Switch row with no [InkWell] over the control (reliable on real Android).
class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.subtitleMaxLines = 2,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int subtitleMaxLines;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SettingsLeadingIcon(icon: icon, iconColor: iconColor),
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
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: subtitleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _KickoraSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Settings row switch — uses [ThemeData.switchTheme] for premium contrast.
class _KickoraSwitch extends StatelessWidget {
  const _KickoraSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 48,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _NotificationPrefTile extends StatelessWidget {
  const _NotificationPrefTile({
    required this.enabled,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final bool enabled;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: _SettingsSwitchTile(
      icon: Icons.tune_rounded,
      iconColor: Theme.of(context).colorScheme.primary,
      title: title,
      subtitle: enabled
          ? (app.isArabic ? 'تنبيهات هذا النوع' : 'Alerts for this category')
          : (app.isArabic
              ? 'فعّل الإشعارات أولاً'
              : 'Turn on notifications first'),
      value: value,
      onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class _SettingsLeadingIcon extends StatelessWidget {
  const _SettingsLeadingIcon({
    required this.icon,
    required this.iconColor,
  });

  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
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
  static const int _subtitleMaxLines = 2;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _SettingsLeadingIcon(icon: icon, iconColor: iconColor),
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
                            maxLines: _subtitleMaxLines,
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
                  ],
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
