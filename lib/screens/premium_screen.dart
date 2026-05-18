import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../subscription/premium_service.dart';
import '../subscription/subscription_plan.dart';

/// Kickora Premium paywall — structure only; payments disabled until IAP ships.
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final app = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(text.isArabic ? 'Kickora Premium' : 'Kickora Premium'),
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final premium = app.premiumService;
            final isPremium = app.isPremium;
            final yearly = premium.yearlyPlan;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _HeaderSection(isPremium: isPremium, text: text),
                const SizedBox(height: 22),
                _BenefitsSection(text: text),
                const SizedBox(height: 22),
                if (isPremium) ...[
                  _ActiveBanner(text: text),
                  const SizedBox(height: 16),
                ] else if (yearly != null) ...[
                  _YearlyPlanCard(plan: yearly, text: text),
                  const SizedBox(height: 14),
                  _ComingSoonButton(
                    text: text,
                    onPressed: () => _onComingSoon(context, text, premium),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _onRestore(context, text, premium),
                  child: Text(text.restorePurchases),
                ),
                const SizedBox(height: 8),
                Text(
                  text.subscriptionLegalNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onComingSoon(BuildContext context, AppText text, PremiumService premium) {
    if (PremiumService.paymentsEnabled) {
      premium.purchaseYearly();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text.paymentsComingSoonMessage)),
    );
  }

  Future<void> _onRestore(
    BuildContext context,
    AppText text,
    PremiumService premium,
  ) async {
    if (!PremiumService.paymentsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text.paymentsComingSoonMessage)),
      );
      return;
    }
    final restored = await premium.restorePurchases();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored ? text.restoreSuccessMessage : text.restoreUnavailableMessage,
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.isPremium, required this.text});

  final bool isPremium;
  final AppText text;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.38),
            primary.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPremium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
            color: primary,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Kickora Premium',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            isPremium ? text.premiumActiveSubtitle : text.removeAdsSubtitle,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsSection extends StatelessWidget {
  const _BenefitsSection({required this.text});

  final AppText text;

  @override
  Widget build(BuildContext context) {
    final benefits = text.isArabic
        ? const [
            'إزالة الإعلانات',
            'إشعارات أسرع',
            'إحصائيات متقدمة',
            'رؤى الفرق المفضلة',
            'ميزات مميزة قادمة',
          ]
        : const [
            'Remove ads',
            'Faster notifications',
            'Advanced statistics',
            'Favorite teams insights',
            'Future premium features',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text.isArabic ? 'المميزات' : 'Benefits',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...benefits.map(
          (label) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.neonGreen,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.text});

  final AppText text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        text.premiumActiveTitle,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
      ),
    );
  }
}

class _YearlyPlanCard extends StatelessWidget {
  const _YearlyPlanCard({required this.plan, required this.text});

  final SubscriptionPlan plan;
  final AppText text;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final title = text.isArabic ? plan.titleAr : plan.titleEn;
    final price = text.isArabic ? plan.priceLabelAr : plan.priceLabelEn;
    final subtitle = text.isArabic ? plan.subtitleAr : plan.subtitleEn;
    final badge = text.isArabic ? plan.savingsBadgeAr : plan.savingsBadgeEn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neonGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ComingSoonButton extends StatelessWidget {
  const _ComingSoonButton({required this.text, required this.onPressed});

  final AppText text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(text.isArabic ? 'قريبًا' : 'Coming Soon'),
      ),
    );
  }
}
