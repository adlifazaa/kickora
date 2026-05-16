/// Billing period for future StoreKit / Play Billing integration.
enum SubscriptionPlanType {
  monthly,
  yearly,
  trial,
}

/// Catalog plan — prices are placeholders until real IAP is wired.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.type,
    required this.productId,
    required this.titleEn,
    required this.titleAr,
    required this.priceLabelEn,
    required this.priceLabelAr,
    this.subtitleEn,
    this.subtitleAr,
    this.savingsBadgeEn,
    this.savingsBadgeAr,
  });

  final SubscriptionPlanType type;
  final String productId;
  final String titleEn;
  final String titleAr;
  final String priceLabelEn;
  final String priceLabelAr;
  final String? subtitleEn;
  final String? subtitleAr;
  final String? savingsBadgeEn;
  final String? savingsBadgeAr;

  static const List<SubscriptionPlan> catalog = [
    SubscriptionPlan(
      type: SubscriptionPlanType.monthly,
      productId: 'kickora_premium_monthly',
      titleEn: 'Monthly',
      titleAr: 'شهري',
      priceLabelEn: '\$4.99 / month',
      priceLabelAr: '٤٫٩٩ \$ / شهر',
      subtitleEn: 'Cancel anytime',
      subtitleAr: 'إلغاء في أي وقت',
    ),
    SubscriptionPlan(
      type: SubscriptionPlanType.yearly,
      productId: 'kickora_premium_yearly',
      titleEn: 'Yearly',
      titleAr: 'سنوي',
      priceLabelEn: '\$29.99 / year',
      priceLabelAr: '٢٩٫٩٩ \$ / سنة',
      subtitleEn: 'Best value for fans',
      subtitleAr: 'أفضل قيمة لعشاق الكرة',
      savingsBadgeEn: 'Save 50%',
      savingsBadgeAr: 'وفر ٥٠٪',
    ),
  ];

  static SubscriptionPlan? forType(SubscriptionPlanType type) {
    for (final plan in catalog) {
      if (plan.type == type) return plan;
    }
    return null;
  }
}
