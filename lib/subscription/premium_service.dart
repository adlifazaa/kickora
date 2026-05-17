import 'package:flutter/foundation.dart';

import 'premium_features.dart';
import 'premium_subscription_service.dart';
import 'subscription_plan.dart';

/// Kickora Premium facade — catalog + feature flags (payments off by default).
class PremiumService extends ChangeNotifier {
  PremiumService(this._subscription) {
    _subscription.addListener(_onSubscriptionChanged);
  }

  final PremiumSubscriptionService _subscription;

  /// Set `true` only after StoreKit / Play Billing is integrated and reviewed.
  static const bool paymentsEnabled = false;

  static const String yearlyProductId = 'kickora_premium_yearly';

  bool get isPremium => _subscription.isPremium;

  bool get adsEnabled => _subscription.adsEnabled;

  bool get trialAvailable => _subscription.trialAvailable;

  SubscriptionPlan? get yearlyPlan =>
      SubscriptionPlan.forType(SubscriptionPlanType.yearly);

  SubscriptionPlan? get monthlyPlan =>
      SubscriptionPlan.forType(SubscriptionPlanType.monthly);

  List<SubscriptionPlan> get availablePlans {
    if (!paymentsEnabled) {
      return const [];
    }
    return SubscriptionPlan.catalog;
  }

  PremiumSubscriptionService get subscription => _subscription;

  /// Whether a premium capability is active for the current user.
  bool hasFeature(PremiumFeature feature) {
    if (!isPremium) return false;
    return switch (feature) {
      PremiumFeature.removeAds => true,
      PremiumFeature.fasterNotifications => true,
      PremiumFeature.advancedStatistics => true,
      PremiumFeature.favoriteTeamsFeatures => true,
    };
  }

  bool get removeAds => hasFeature(PremiumFeature.removeAds);

  bool get fasterNotifications => hasFeature(PremiumFeature.fasterNotifications);

  bool get advancedStatistics => hasFeature(PremiumFeature.advancedStatistics);

  bool get favoriteTeamsFeatures =>
      hasFeature(PremiumFeature.favoriteTeamsFeatures);

  /// Future IAP entry — returns false while [paymentsEnabled] is false.
  Future<bool> purchaseYearly() async {
    if (!paymentsEnabled) {
      _logPaymentsDisabled('purchaseYearly');
      return false;
    }
    final plan = yearlyPlan;
    if (plan == null) return false;
    return _subscription.purchasePlan(plan);
  }

  Future<bool> restorePurchases() async {
    if (!paymentsEnabled) {
      _logPaymentsDisabled('restorePurchases');
      return false;
    }
    return _subscription.restorePurchases();
  }

  void _onSubscriptionChanged() => notifyListeners();

  void _logPaymentsDisabled(String operation) {
    if (kDebugMode) {
      debugPrint('[Kickora Premium] $operation skipped (payments disabled)');
    }
  }

  @override
  void dispose() {
    _subscription.removeListener(_onSubscriptionChanged);
    super.dispose();
  }
}
