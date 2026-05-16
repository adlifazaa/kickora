import 'subscription_plan.dart';

/// Snapshot of local premium state (mock / future billing sync).
class SubscriptionState {
  const SubscriptionState({
    required this.isPremium,
    required this.adsEnabled,
    required this.trialAvailable,
    this.activePlan,
    this.expiresAt,
    this.trialUsed = false,
  });

  final bool isPremium;
  final bool adsEnabled;
  final bool trialAvailable;
  final SubscriptionPlanType? activePlan;
  final DateTime? expiresAt;
  final bool trialUsed;

  static const SubscriptionState free = SubscriptionState(
    isPremium: false,
    adsEnabled: true,
    trialAvailable: true,
  );
}
