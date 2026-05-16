import 'subscription_plan.dart';

/// Placeholder for App Store / Google Play billing.
///
/// Replace with real IAP when payments go live.
abstract class SubscriptionPaymentBridge {
  Future<bool> purchase(SubscriptionPlan plan);
  Future<bool> restorePurchases();
}

/// Mock bridge — never charges; used until billing SDK is integrated.
class MockSubscriptionBridge implements SubscriptionPaymentBridge {
  const MockSubscriptionBridge();

  @override
  Future<bool> purchase(SubscriptionPlan plan) async {
    // Real payments are not active yet.
    return false;
  }

  @override
  Future<bool> restorePurchases() async => false;
}
