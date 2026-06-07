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
                    ? 'لا يطلب Kickora تسجيل دخول أو حسابًا. لا نجمع اسمك أو بريدك الإلكتروني أو رقم هاتفك. قد يعرض التطبيق بيانات كرة قدم تجريبية (Mock) لأغراض العرض ما لم يتم تهيئة مزود بيانات حي عند البناء.'
                    : 'Kickora does not require sign-in or an account. We do not collect your name, email, or phone number. The app may display mock/demo football data for showcase unless live data providers are configured at build time.',
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
                    ? 'لا تُعرض إعلانات حقيقية في هذا الإصدار. تم دمج Google Mobile Ads (AdMob) لمواضع native مستقبلية. عند تفعيل الإعلانات، قد يستخدم AdMob معرّفات إعلانية ويعالج بيانات وفق سياسات Google. مشتركو Premium لا يرون إعلانات. سنحدّث هذه السياسة قبل تفعيل إعلانات حقيقية في الإنتاج.'
                    : 'Real ads are not shown in the current release. Google Mobile Ads (AdMob) is integrated for future native placements. When ads are enabled, AdMob may use advertising identifiers and process data per Google\'s AdMob policies. Premium subscribers do not see ads. We will update this policy before enabling real ads in production.',
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
                    ? 'افتراضيًا، يستخدم التطبيق بيانات كرة قدم تجريبية. عند تهيئة بيانات حية، قد تُرسَل طلبات إلى مزودي بيانات خارجيين (مثل API-Football). تتلقى هذه الخدمات فقط الطلبات اللازمة لجلب البيانات — دون مشاركة معلومات شخصية عنك.'
                    : 'By default, the app uses mock/demo football data. When live data is configured, requests may be sent to third-party football data providers (such as API-Football). Those services receive only the queries needed to fetch data — no personal information about you is shared with them.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.notifications_none_rounded,
              title: ar ? 'الإشعارات' : 'Notifications',
              child: _Paragraph(
                ar
                    ? 'تستخدم الإشعارات Firebase Cloud Messaging (FCM) وهي معطّلة افتراضيًا. عند تفعيل تنبيهات المباريات من الإعدادات، نطلب الإذن ونسجّل جهازك في Firebase للمواضيع التي تختارها (مثل فرقك المفضلة). يمكنك إيقاف الإشعارات في أي وقت من التطبيق أو إعدادات النظام.'
                    : 'Push notifications use Firebase Cloud Messaging (FCM) and are off by default. If you enable match alerts in Settings, we request permission and register your device with Firebase for the topics you choose (e.g. favourite teams). You can turn notifications off any time in the app or system settings.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.analytics_outlined,
              title: ar ? 'التحليلات وتقارير الأعطال' : 'Analytics & crash reports',
              child: _Paragraph(
                ar
                    ? 'نستخدم Firebase Analytics (Google) لفهم استخدام التطبيق — مثل مشاهدات الشاشات، فتح المباريات أو البطولات، إضافة المفضلة، وطول استعلام البحث (وليس نص البحث). لا نسجّل مفاتيح API أو رموز FCM في التحليلات. نستخدم Firebase Crashlytics (Google) لجمع سجلات الأعطال وبيانات الجهاز لإصلاح مشاكل الاستقرار. هذه البيانات مجمّعة أو تشخيصية ولا تتضمن اسمك أو بريدك.'
                    : 'We use Firebase Analytics (Google) to understand app usage — such as screen views, matches or competitions opened, favorites added, and search length (not query text). We do not log API keys or FCM tokens in analytics. We use Firebase Crashlytics (Google) to collect crash logs and device metadata to fix stability issues. This data is aggregated or diagnostic and does not include your name or email.',
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
                  ? 'نحترم خصوصيتك. توضّح هذه الصفحة ما يجمعه Kickora وكيف قد تعالج خدمات الطرف الثالث (Firebase وAdMob) البيانات — بلغة واضحة ومباشرة.'
                  : 'We respect your privacy. This page explains what Kickora collects and how third-party services (Firebase, AdMob) may process data — in plain, direct language.',
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
