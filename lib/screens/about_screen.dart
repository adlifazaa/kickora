import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  void _snack(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label · coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(text.about)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _Logo(),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Kickora',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
            ),
          ),
          Center(
            child: Text(
              text.isArabic
                  ? 'صُمم لعشاق كرة القدم'
                  : 'Built for football fans',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'v$appVersion · build $buildNumber',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _Section(
            title: text.isArabic ? 'حول التطبيق' : 'About the app',
            child: Text(
              text.isArabic
                  ? 'Kickora هو رفيقك المباشر لمتابعة كرة القدم. ابقَ على اطلاع بكل المباريات المباشرة، النتائج، التشكيلات، الترتيب، والإحصاءات بتصميم فاخر سريع وخفيف.'
                  : 'Kickora is your live football companion. Follow real-time matches, scores, lineups, standings, and rich stats — wrapped in a premium, fast, and lightweight UI.',
              style: TextStyle(
                  color: Theme.of(context).hintColor,
                  height: 1.5,
                  fontSize: 13.5),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: text.isArabic ? 'المميزات' : 'Features',
            child: Column(
              children: [
                _featureTile(context, Icons.flash_on_rounded,
                    text.isArabic ? 'نتائج مباشرة' : 'Live scores'),
                _featureTile(context, Icons.emoji_events_rounded,
                    text.isArabic ? 'البطولات والترتيب' : 'Competitions & standings'),
                _featureTile(context, Icons.groups_2_rounded,
                    text.isArabic ? 'تشكيلات وملعب احترافي' : 'Premium lineup pitch'),
                _featureTile(context, Icons.translate_rounded,
                    text.isArabic ? 'عربي/إنجليزي مع RTL' : 'Arabic & English with RTL'),
                _featureTile(context, Icons.dark_mode_rounded,
                    text.isArabic ? 'وضع داكن فاخر' : 'Premium dark mode'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: text.isArabic ? 'تابعنا' : 'Follow us',
            child: Row(
              children: [
                _socialButton(context, Icons.public_rounded, 'Website',
                    () => _snack(context, 'Website')),
                const SizedBox(width: 10),
                _socialButton(context, Icons.tag_rounded, 'Twitter / X',
                    () => _snack(context, 'Twitter')),
                const SizedBox(width: 10),
                _socialButton(context, Icons.camera_alt_outlined, 'Instagram',
                    () => _snack(context, 'Instagram')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: text.isArabic ? 'تواصل ودعم' : 'Contact & support',
            child: Column(
              children: [
                _linkTile(
                  context,
                  icon: Icons.email_outlined,
                  title: text.isArabic ? 'البريد الإلكتروني' : 'Email',
                  subtitle: 'hello@kickora.live',
                  onTap: () => _snack(context, 'Email'),
                ),
                _linkTile(
                  context,
                  icon: Icons.support_agent_rounded,
                  title: text.isArabic ? 'الدعم' : 'Support',
                  subtitle: text.isArabic
                      ? 'تواصل مع فريق Kickora'
                      : 'Reach the Kickora team',
                  onTap: () => _snack(context, 'Support'),
                ),
                _linkTile(
                  context,
                  icon: Icons.star_border_rounded,
                  title: text.isArabic ? 'قيّم التطبيق' : 'Rate the app',
                  subtitle: text.isArabic
                      ? 'متجر التطبيقات'
                      : 'App store rating',
                  onTap: () => _snack(context, 'Rate'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: text.isArabic ? 'قانوني' : 'Legal',
            child: Column(
              children: [
                _linkTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: text.isArabic ? 'سياسة الخصوصية' : 'Privacy policy',
                  subtitle: text.isArabic
                      ? 'حماية بياناتك أولاً'
                      : 'Your data, protected',
                  onTap: () => _snack(context, 'Privacy'),
                ),
                _linkTile(
                  context,
                  icon: Icons.description_outlined,
                  title: text.isArabic ? 'شروط الاستخدام' : 'Terms of use',
                  subtitle: text.isArabic
                      ? 'القواعد التي تحكم استخدامك'
                      : 'Rules of using Kickora',
                  onTap: () => _snack(context, 'Terms'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              text.isArabic
                  ? '© 2025 Kickora · صُنع بشغف ⚽'
                  : '© 2025 Kickora · Made with passion ⚽',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureTile(BuildContext context, IconData icon, String label) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: primary),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13.5))),
          const Icon(Icons.check_circle, color: AppColors.goalGreen, size: 18),
        ],
      ),
    );
  }

  Widget _socialButton(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 6),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _linkTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: Theme.of(context).colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13.5)),
                    Text(subtitle,
                        style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 116,
        height: 116,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.teal, AppColors.neonGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.45),
              blurRadius: 32,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.sports_soccer_rounded,
            color: Colors.black87, size: 64),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardTheme.color,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14.5)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
