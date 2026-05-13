import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text.dart';

/// Standalone Terms of Use — legal/usage terms, distinct from [PrivacyPolicyScreen].
class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  static const String lastUpdated = 'May 2026';

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final ar = text.isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(text.terms)),
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
              icon: Icons.handshake_outlined,
              title: ar ? 'قبول الشروط' : 'Acceptance of terms',
              child: _Paragraph(
                ar
                    ? 'باستخدامك لتطبيق Kickora، فإنك تقر بأنك قد قرأت هذه الشروط وتوافق على الالتزام بها. إذا لم توافق، يرجى عدم استخدام التطبيق.'
                    : 'By using Kickora, you confirm that you have read these Terms of Use and agree to be bound by them. If you do not agree, please do not use the app.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.smartphone_outlined,
              title: ar ? 'استخدام التطبيق' : 'App usage',
              child: _Paragraph(
                ar
                    ? 'يُمنح لك ترخيصًا شخصيًا غير حصري وغير قابل للتحويل لاستخدام Kickora على أجهزتك لأغراضك الشخصية وغير التجارية. لا يجوز لك إعادة إنتاج التطبيق أو هندسته عكسيًا أو محاولة الوصول غير المصرح به إلى أنظمته.'
                    : 'You are granted a personal, non-exclusive, non-transferable licence to use Kickora on your devices for your own personal, non-commercial purposes. You may not copy, reverse engineer, or attempt to gain unauthorised access to the app or its systems.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.info_outline_rounded,
              title: ar ? 'إخلاء مسؤولية المحتوى' : 'Content disclaimer',
              child: _Paragraph(
                ar
                    ? 'يعرض Kickora حاليًا بيانات تجريبية (Mock) لأغراض العرض والتصميم. الأسماء والشعارات والنتائج المعروضة قد لا تعكس أحداثًا حقيقية أو حالية.'
                    : 'Kickora currently displays mock/demo data for design and demonstration purposes. Names, crests, scores, and other content may not reflect real-world events or current reality.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.analytics_outlined,
              title: ar ? 'دقة بيانات المباريات' : 'Match data accuracy',
              child: _Paragraph(
                ar
                    ? 'عند الانتقال لاحقًا إلى بيانات حية من مزودين خارجيين، لا نضمن أن تكون جميع النتائج أو الأوقات أو الإحصائيات خالية من الأخطاء أو التأخير. المعلومات مقدمة "كما هي" دون أي ضمان صريح أو ضمني.'
                    : 'When live data from third-party providers is introduced later, we do not warrant that scores, times, or statistics will always be complete, timely, or error-free. Information is provided on an "as is" basis without warranties of any kind.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.copyright_outlined,
              title: ar ? 'الملكية الفكرية' : 'Intellectual property',
              child: _Paragraph(
                ar
                    ? 'تصميم Kickora والعلامة والكود الخاص بالتطبيق محميون. قد تنتمي شعارات الأندية والبطولات وأسماء اللاعبين لأطراف ثالثة. لا يمنحك استخدام التطبيق أي حقوق على هذه المواد.'
                    : 'Kickora’s branding, UI design, and app code are protected. Club crests, competition names, and player likenesses may belong to third parties. Use of the app does not grant you rights in such materials.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.campaign_outlined,
              title: ar ? 'الإعلانات المستقبلية' : 'Future advertisements',
              child: _Paragraph(
                ar
                    ? 'قد يتضمن الإصدار المستقبلي إعلانات (مثل Google AdMob). سيتم توضيح ذلك في التطبيق وفي سياسة الخصوصية قبل التفعيل. يمكنك اختيار عدم المشاركة حيثما يسمح النظام بذلك.'
                    : 'Future versions may include advertising (for example Google AdMob). We will explain this in-app and in the Privacy Policy before activation. Where the platform allows, you may be able to limit certain ad personalisation.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.verified_user_outlined,
              title: ar ? 'مسؤوليات المستخدم' : 'User responsibilities',
              child: _Paragraph(
                ar
                    ? 'تلتزم بعدم إساءة استخدام التطبيق أو محاولة تعطيله أو إلحاق الضرر بالمستخدمين الآخرين أو بأي بنية تحتية. يجب أن تلتزم بالقوانين المحلية المعمول بها.'
                    : 'You agree not to misuse Kickora, interfere with its operation, harm other users, or attack any infrastructure. You must comply with applicable local laws.',
              ),
            ),
            const SizedBox(height: 10),
            _Section(
              icon: Icons.balance_outlined,
              title: ar ? 'حدود المسؤولية' : 'Limitation of liability',
              child: _Paragraph(
                ar
                    ? 'إلى أقصى حد يسمح به القانون، لا تتحمل Kickora أو مطوروها المسؤولية عن أي أضرار غير مباشرة أو عرضية أو تبعية ناتجة عن استخدامك للتطبيق أو عدم قدرتك على استخدامه، بما في ذلك الاعتماد على البيانات المعروضة.'
                    : 'To the fullest extent permitted by law, Kickora and its developers shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of or inability to use the app, including reliance on displayed data.',
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
                    ? 'قد يتم تحديث هذه الشروط. تابع هذه الصفحة للحصول على النسخة الحالية.'
                    : 'These terms may be updated. Check this page for the current version.',
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
                    AppColors.varPurple.withValues(alpha: 0.9),
                    AppColors.tealDeep.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: const Icon(Icons.description_outlined,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? 'شروط الاستخدام' : 'Terms of use',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 20),
                  ),
                  Text(
                    isArabic
                        ? 'آخر تحديث: ${TermsOfUseScreen.lastUpdated}'
                        : 'Last updated: ${TermsOfUseScreen.lastUpdated}',
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
          Icon(Icons.gavel_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ar
                  ? 'تحدد هذه الصفحة القواعد التي تحكم استخدامك لـ Kickora. هي مختلفة عن سياسة الخصوصية — الرجاء قراءة كليهما.'
                  : 'This page sets the rules for using Kickora. It is separate from the Privacy Policy — please read both.',
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
              ? 'للأسئلة القانونية أو طلبات الترخيص:'
              : 'For legal questions or licensing requests:',
        ),
        const SizedBox(height: 8),
        _row(context, Icons.email_outlined, 'legal@kickora.live'),
        _row(context, Icons.alternate_email_rounded, 'support@kickora.live'),
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
    final border = Theme.of(context).dividerColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.10
                    : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
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
