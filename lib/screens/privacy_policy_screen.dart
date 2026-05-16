import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_contact.dart';
import '../app/app_text.dart';

/// A dedicated, app-store-friendly Privacy Policy. Intentionally separate
/// from [AboutScreen] so the two pages never look like duplicates.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String lastUpdated = 'May 2026';

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final ar = text.isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(text.privacy)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            _Header(isArabic: ar),
            const SizedBox(height: 18),
            _IntroCard(ar: ar),
            const SizedBox(height: 14),
            _Section(
              icon: Icons.dataset_outlined,
              title: ar ? 'البيانات التي نجمعها' : 'Data we collect',
              child: _Paragraph(
                ar
                    ? 'لا يطلب Kickora حاليًا تسجيل دخول أو حسابًا. لا نجمع اسمك، بريدك الإلكتروني، أو معرّفات شخصية. التطبيق يعرض بيانات تجريبية (Mock Data) لأغراض العرض فقط.'
                    : 'Kickora does not require sign-in or an account. We do not collect your name, email, or personal identifiers. The app currently displays mock/demo data for showcase purposes only.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.sd_storage_outlined,
              title: ar ? 'التخزين المحلي' : 'Local storage',
              child: _Paragraph(
                ar
                    ? 'يتم حفظ تفضيلاتك (اللغة، الوضع الداكن، وقوائم المفضلة للفرق والبطولات والمباريات) محليًا على جهازك فقط. لا تُرسَل هذه البيانات إلى خوادمنا، ويمكنك مسحها بإلغاء تثبيت التطبيق أو مسح بيانات التطبيق من إعدادات النظام.'
                    : 'Your preferences (language, dark mode, and lists of favorite teams, competitions, and matches) are stored locally on your device only. None of it leaves your device, and you can clear it by uninstalling Kickora or clearing app data from system settings.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.campaign_outlined,
              title: ar ? 'الإعلانات' : 'Ads',
              child: _Paragraph(
                ar
                    ? 'لا توجد إعلانات حقيقية مفعّلة حاليًا — نعرض فقط مواضع وهمية (Placeholders) لأغراض التصميم. عند تفعيل الإعلانات مستقبلاً (مثل Google AdMob)، قد يستخدم مزوّد الإعلانات معرّفات إعلانية لعرض إعلانات مخصصة. سيتم تحديث هذه السياسة وتوفير خيار في الإعدادات قبل تفعيل أي إعلانات حقيقية.'
                    : 'No real ads are active right now — only design placeholders are shown. When ads (e.g. Google AdMob) are enabled later, the ad provider may use advertising identifiers to serve personalised ads. This policy will be updated and a setting will be provided before any real ad goes live.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.cloud_outlined,
              title: ar
                  ? 'واجهات برمجة طرف ثالث'
                  : 'Third-party APIs',
              child: _Paragraph(
                ar
                    ? 'في الإصدارات القادمة قد نستخدم خدمات بيانات كرة قدم من جهات خارجية (مثل API-Football أو غيرها) لجلب المباريات والفرق واللاعبين. هذه الخدمات تتلقى فقط الطلبات اللازمة لإحضار البيانات، ولا يتم مشاركة معلومات شخصية تخصّك معها.'
                    : 'Future versions may use third-party football data providers (such as API-Football or similar) to fetch matches, teams, and players. These services only receive the queries needed to fetch data — no personal information about you is shared with them.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.notifications_none_rounded,
              title: ar ? 'الإشعارات' : 'Notifications',
              child: _Paragraph(
                ar
                    ? 'الإشعارات معطلة افتراضيًا. إذا تم تفعيل تنبيهات المباريات لاحقًا، فسيُطلب منك أولاً الإذن، ويمكنك إيقافها في أي وقت من إعدادات التطبيق أو من إعدادات نظام جهازك.'
                    : 'Notifications are disabled by default. If match alerts are enabled in a future update, you will be asked for permission first, and you can turn them off any time from the in-app settings or your system settings.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.analytics_outlined,
              title: ar ? 'التحليلات' : 'Analytics',
              child: _Paragraph(
                ar
                    ? 'لا نستخدم حاليًا أي أدوات تحليل. في حال إضافتها مستقبلاً، ستكون مجمّعة ومجهولة الهوية (لا تتضمن بياناتك الشخصية) ولن يتم تفعيلها إلا إذا منحت موافقتك.'
                    : 'We currently do not use any analytics tooling. If it is added later, the data will be aggregated and anonymous (no personal data) and will only be enabled when you opt in.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.child_care_rounded,
              title: ar ? 'خصوصية الأطفال' : 'Children\u2019s privacy',
              child: _Paragraph(
                ar
                    ? 'Kickora ليس موجهًا للأطفال دون 13 عامًا. لا نجمع عن قصد أي بيانات من الأطفال. إذا كنت ولي أمر وتعتقد أن بيانات طفلك قد تمت معالجتها، يرجى التواصل معنا لإزالتها.'
                    : 'Kickora is not directed to children under 13. We do not knowingly collect data from children. If you are a parent and believe your child\u2019s data has been processed, please contact us so we can remove it.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.history_rounded,
              title: ar ? 'تحديثات السياسة' : 'Policy updates',
              child: _Paragraph(
                ar
                    ? 'قد نقوم بتحديث هذه السياسة لتعكس تحسينات التطبيق أو متطلبات قانونية. سيتم نشر النسخة الحالية في هذه الشاشة دائمًا، وسيظهر تاريخ آخر تحديث في الأعلى.'
                    : 'We may update this policy to reflect product changes or legal requirements. The current version is always available on this screen, and the last-updated date appears at the top.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.mail_outline_rounded,
              title: ar ? 'تواصل' : 'Contact',
              child: _ContactBlock(ar: ar),
            ),
            const SizedBox(height: 22),
            Center(
              child: Text(
                ar
                    ? 'هذه السياسة مكتوبة بلغة بسيطة لتسهيل الفهم.'
                    : 'This policy is written in plain language for clarity.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isArabic});
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    AppColors.subBlue.withValues(alpha: 0.85),
                    AppColors.teal.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child:
                  const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'سياسة الخصوصية' : 'Privacy policy',
                    style:
                        const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                  Text(
                    isArabic
                        ? 'آخر تحديث: ${PrivacyPolicyScreen.lastUpdated}'
                        : 'Last updated: ${PrivacyPolicyScreen.lastUpdated}',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.ar});
  final bool ar;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.16),
            primary.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ar
                  ? 'نحترم خصوصيتك. هذه الصفحة توضح ما يجمعه Kickora فعليًا وما قد يجمعه مستقبلاً، بلغة واضحة ومباشرة.'
                  : 'We respect your privacy. This page explains what Kickora actually collects today and what it may collect in the future — in plain, direct language.',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBlock extends StatelessWidget {
  const _ContactBlock({required this.ar});
  final bool ar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Paragraph(
          ar
              ? 'إذا كان لديك أي سؤال حول الخصوصية أو طلب يتعلق ببياناتك، تواصل معنا:'
              : 'If you have any privacy questions or a data-related request, contact us:',
        ),
        const SizedBox(height: 8),
        _row(context, Icons.email_outlined, AppContact.email),
      ],
    );
  }

  Widget _row(BuildContext context, IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.10
                    : 0.05),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).hintColor,
        height: 1.55,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
