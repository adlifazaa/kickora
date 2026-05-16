import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_scope.dart';
import '../app/app_text.dart';
import '../subscription/subscription_plan.dart';
import '../widgets/section_header.dart';

/// Placeholder paywall — structure only; real payments not enabled.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final app = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(text.removeAdsTitle)),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            final premium = app.premiumSubscriptionService;
            final isPremium = app.isPremium;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _HeroCard(
                  isPremium: isPremium,
                  text: text,
                ),
                const SizedBox(height: 22),
                if (isPremium) ...[
                  _ActivePlanCard(
                    plan: premium.activePlan,
                    expiresAt: premium.expiresAt,
                    text: text,
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  SectionHeader(
                    title: text.subscriptionPlansTitle,
                    icon: Icons.workspace_premium_rounded,
                  ),
                  const SizedBox(height: 12),
                  for (final plan in SubscriptionPlan.catalog) ...[
                    _PlanCard(
                      plan: plan,
                      text: text,
                      onSelect: () => _onPlanTap(context, text, plan),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (app.trialAvailable) ...[
                    const SizedBox(height: 6),
                    _TrialCard(
                      text: text,
                      onStartTrial: () async {
                        await premium.startMockTrial();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(text.trialStartedMessage)),
                          );
                        }
                      },
                    ),
                  ],
                ],
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () async {
                    final restored = await premium.restorePurchases();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          restored
                              ? text.restoreSuccessMessage
                              : text.restoreUnavailableMessage,
                        ),
                      ),
                    );
                  },
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

  void _onPlanTap(BuildContext context, AppText text, SubscriptionPlan plan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text.paymentsComingSoonMessage)),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.isPremium, required this.text});

  final bool isPremium;
  final AppText text;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.35),
            primary.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPremium ? Icons.verified_rounded : Icons.block_rounded,
            color: primary,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            isPremium ? text.premiumActiveTitle : text.removeAdsHeadline,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
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

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({
    required this.plan,
    required this.expiresAt,
    required this.text,
  });

  final SubscriptionPlanType? plan;
  final DateTime? expiresAt;
  final AppText text;

  @override
  Widget build(BuildContext context) {
    final catalog = plan != null ? SubscriptionPlan.forType(plan!) : null;
    final planName = catalog != null
        ? (text.isArabic ? catalog.titleAr : catalog.titleEn)
        : text.premiumActiveTitle;
    final expires = expiresAt != null ? text.premiumExpiresLabel(expiresAt!) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.neonGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(planName,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          if (expires != null) ...[
            const SizedBox(height: 6),
            Text(
              expires,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.text,
    required this.onSelect,
  });

  final SubscriptionPlan plan;
  final AppText text;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final title = text.isArabic ? plan.titleAr : plan.titleEn;
    final price = text.isArabic ? plan.priceLabelAr : plan.priceLabelEn;
    final subtitle = text.isArabic ? plan.subtitleAr : plan.subtitleEn;
    final badge = text.isArabic ? plan.savingsBadgeAr : plan.savingsBadgeEn;

    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 15)),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
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
                    const SizedBox(height: 4),
                    Text(price,
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        )),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrialCard extends StatelessWidget {
  const _TrialCard({required this.text, required this.onStartTrial});

  final AppText text;
  final VoidCallback onStartTrial;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onStartTrial,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [AppColors.teal, AppColors.neonGreen],
            ),
          ),
          child: Text(
            text.startFreeTrial,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
