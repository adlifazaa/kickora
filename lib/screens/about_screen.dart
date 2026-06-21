import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_contact.dart';
import '../app/app_text.dart';
import '../app/app_version_info.dart';

/// "About Kickora" — explains what Kickora is, who it is for, and which
/// features it ships with. Legal and data handling content lives in
/// [PrivacyPolicyScreen] instead so these two pages never look duplicated.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _openEmail(BuildContext context, {required bool isArabic}) async {
    final opened = await AppContact.openEmail(subject: 'Kickora');
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isArabic
              ? 'تعذر فتح البريد. راسلنا على ${AppContact.email}'
              : 'Could not open email. Contact us at ${AppContact.email}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(text.about)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const _Logo(),
            const SizedBox(height: 18),
            Center(
              child: Text(
                text.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
              ),
            ),
            Center(
              child: Text(
                text.aboutTagline,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: _VersionPill()),
            const SizedBox(height: 22),
            _Section(
              title: text.isArabic ? 'ما هو Kickora؟' : 'What is Kickora?',
              child: Text(
                text.isArabic
                    ? 'Kickora هو رفيقك المباشر لمتابعة كرة القدم. يقدّم لك نتائج المباريات، التشكيلات، الإحصائيات، الترتيب، وملفات اللاعبين بتصميم أنيق ومريح، سواء كنت متابعًا عاديًا أو من محبي التفاصيل العميقة.'
                    : 'Kickora is your live football companion. It brings match scores, lineups, statistics, standings, and player profiles together in one fast, elegant experience — whether you are a casual viewer or a hardcore stats fan.',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  height: 1.55,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: text.isArabic ? 'المميزات الرئيسية' : 'Key features',
              child: Column(
                children: [
                  _featureTile(
                    context,
                    Icons.flash_on_rounded,
                    text.isArabic ? 'نتائج مباشرة لحظية' : 'Live scores in real time',
                  ),
                  _featureTile(
                    context,
                    Icons.sports_soccer_rounded,
                    text.isArabic
                        ? 'تفاصيل مباريات احترافية وأحداث لحظية'
                        : 'Rich match details with live events',
                  ),
                  _featureTile(
                    context,
                    Icons.leaderboard_rounded,
                    text.isArabic ? 'جداول الترتيب' : 'League standings',
                  ),
                  _featureTile(
                    context,
                    Icons.groups_2_rounded,
                    text.isArabic
                        ? 'ملعب تشكيلات بصري مع الخطط'
                        : 'Football pitch lineups with formations',
                  ),
                  _featureTile(
                    context,
                    Icons.person_pin_circle_rounded,
                    text.isArabic
                        ? 'ملفات اللاعبين وآخر المباريات'
                        : 'Player profiles & recent matches',
                  ),
                  _featureTile(
                    context,
                    Icons.star_rounded,
                    text.isArabic
                        ? 'المفضلة: فرق، بطولات، ومباريات'
                        : 'Favorites: teams, competitions & matches',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: text.isArabic ? 'لماذا Kickora؟' : 'Why Kickora?',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bullet(
                    context,
                    text.isArabic
                        ? 'خفيف وسريع — يفتح في ثوانٍ.'
                        : 'Lightweight and fast — opens in seconds.',
                  ),
                  _bullet(
                    context,
                    text.isArabic
                        ? 'تصميم فاخر بمظهر ملعب ليلي.'
                        : 'Premium design with a night-stadium feel.',
                  ),
                  _bullet(
                    context,
                    text.isArabic
                        ? 'يدعم العربية والإنجليزية مع RTL كامل.'
                        : 'Arabic & English with full RTL support.',
                  ),
                  _bullet(
                    context,
                    text.isArabic
                        ? 'لا حاجة لتسجيل دخول.'
                        : 'No sign-up required.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: text.contactUs,
              child: Column(
                children: [
                  _linkTile(
                    context,
                    icon: Icons.email_outlined,
                    title: text.isArabic ? 'البريد الإلكتروني' : 'Email',
                    subtitle: AppContact.email,
                    onTap: () => _openEmail(context, isArabic: text.isArabic),
                  ),
                  _linkTile(
                    context,
                    icon: Icons.support_agent_rounded,
                    title: text.isArabic ? 'الدعم الفني' : 'Support',
                    subtitle: AppContact.email,
                    onTap: () => _openEmail(context, isArabic: text.isArabic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: Text(
                text.aboutFooter,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.goalGreen, size: 18),
        ],
      ),
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 5, end: 8),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.teal,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                height: 1.5,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
              Icon(Icons.chevron_right_rounded,
                  color: Theme.of(context).hintColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AppVersionInfo.load(),
      builder: (context, snapshot) {
        final label = snapshot.hasData
            ? AppVersionInfo.fullLabel(snapshot.data!)
            : '…';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).cardTheme.color,
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.10 : 0.04),
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
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
