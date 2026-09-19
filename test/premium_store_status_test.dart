import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/subscription/premium_service.dart';
import 'package:kickora/subscription/premium_store_status.dart';
import 'package:kickora/subscription/premium_subscription_service.dart';
import 'package:kickora/subscription/subscription_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('checking state maps to the required Arabic loading copy', () {
    expect(
      PremiumStoreStatusMapper.arabicMessage(PremiumStoreUiState.checking),
      'جاري التحقق من المتجر…',
    );
  });

  test('store unavailable maps to the Google Play retry copy', () {
    expect(
      PremiumStoreStatusMapper.arabicMessage(
        PremiumStoreUiState.storeUnavailable,
      ),
      'تعذر الاتصال بمتجر Google Play. حاول مرة أخرى.',
    );
  });

  test('empty product and notFoundIDs map to currently unavailable', () {
    const result = PremiumProductQueryResult(
      storeAvailable: true,
      requestedIds: ['kickora_premium_yearly'],
      queryStatus: 'empty',
      notFoundIds: ['kickora_premium_yearly'],
    );
    expect(
      PremiumStoreStatusMapper.fromQuery(
        paymentsEnabled: true,
        loading: false,
        isPremium: false,
        result: result,
      ),
      PremiumStoreUiState.unavailable,
    );
    expect(
      PremiumStoreStatusMapper.arabicMessage(PremiumStoreUiState.unavailable),
      'غير متوفر حاليًا',
    );
  });

  test('query errors do not invent a successful offer', () {
    const result = PremiumProductQueryResult(
      storeAvailable: true,
      requestedIds: ['kickora_premium_yearly'],
      queryStatus: 'error',
      errorCode: 'billing_unavailable',
    );
    expect(
      PremiumStoreStatusMapper.fromQuery(
        paymentsEnabled: true,
        loading: false,
        isPremium: false,
        result: result,
      ),
      PremiumStoreUiState.queryError,
    );
    expect(result.hasOffer, isFalse);
  });

  test('purchase mapping never grants premium from a failed store result', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final subscription = PremiumSubscriptionService(prefs);
    await subscription.load();
    final premium = PremiumService(subscription);
    expect(premium.isPremium, isFalse);
    expect(await premium.purchaseYearly(), isFalse);
    expect(premium.isPremium, isFalse);
    premium.dispose();
  });

  test('yearly product remains a subscription catalog SKU', () {
    expect(PremiumService.yearlyProductId, 'kickora_premium_yearly');
    expect(
      SubscriptionPlan.forType(SubscriptionPlanType.yearly)?.productId,
      'kickora_premium_yearly',
    );
  });

  test('retry-friendly loading state is distinct from purchased', () {
    expect(
      PremiumStoreStatusMapper.fromQuery(
        paymentsEnabled: true,
        loading: true,
        isPremium: false,
        result: null,
      ),
      PremiumStoreUiState.checking,
    );
    expect(
      PremiumStoreStatusMapper.fromQuery(
        paymentsEnabled: true,
        loading: false,
        isPremium: true,
        result: null,
      ),
      PremiumStoreUiState.purchased,
    );
  });
}
