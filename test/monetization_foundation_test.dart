import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/ads/ad_config.dart';
import 'package:kickora/ads/ad_placement.dart';
import 'package:kickora/ads/ad_remote_config.dart';
import 'package:kickora/ads/ad_service.dart';
import 'package:kickora/ads/ad_unit_ids.dart';
import 'package:kickora/subscription/premium_features.dart';
import 'package:kickora/subscription/premium_service.dart';
import 'package:kickora/subscription/premium_subscription_service.dart';
import 'package:kickora/subscription/subscription_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('AdRemoteConfig defaults keep all ads off', () {
    const config = AdRemoteConfig();
    expect(config.adsMasterEnabled, isFalse);
    expect(config.showPlaceholderSlots, isFalse);
    expect(config.nativeEnabled, isFalse);
    expect(config.interstitialEnabled, isFalse);
    expect(config.placementEnabled(AdPlacement.matchListNative), isFalse);
    expect(config.placementEnabled(AdPlacement.competitionListNative), isFalse);
    expect(config.placementEnabled(AdPlacement.scrollBottomNative), isFalse);
  });

  test('AdRemoteConfig production enables banner and interstitial', () {
    final config = AdRemoteConfig.production();
    expect(config.adsMasterEnabled, isTrue);
    expect(config.bannerEnabled, isTrue);
    expect(config.interstitialEnabled, isTrue);
    expect(config.placementEnabled(AdPlacement.matchesBanner), isTrue);
    expect(config.placementEnabled(AdPlacement.competitionsBanner), isTrue);
    expect(config.placementEnabled(AdPlacement.standingsBanner), isTrue);
  });

  test('production AdMob unit IDs are configured', () {
    expect(
      AdUnitIds.androidAppId,
      'ca-app-pub-2257421593045125~1218804789',
    );
    expect(AdUnitIds.banner, 'ca-app-pub-2257421593045125/4567326770');
    expect(
      AdUnitIds.interstitial,
      'ca-app-pub-2257421593045125/6590854884',
    );
    expect(AdConfig.bannerUnitId, AdUnitIds.banner);
    expect(AdConfig.interstitialUnitId, AdUnitIds.interstitial);
  });

  test('AdService shows no placeholders by default', () {
    final ads = AdService.instance;
    expect(
      ads.shouldShowPlaceholder(AdPlacement.matchListNative, feedItemIndex: 4),
      isFalse,
    );
    expect(
      ads.shouldShowPlaceholder(
        AdPlacement.competitionListNative,
        feedItemIndex: 4,
      ),
      isFalse,
    );
  });

  test('PremiumService payments disabled; yearly plan defined', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final subscription = PremiumSubscriptionService(prefs);
    await subscription.load();
    final premium = PremiumService(subscription);

    expect(PremiumService.paymentsEnabled, isFalse);
    expect(await premium.purchaseYearly(), isFalse);
    expect(premium.yearlyPlan?.productId, 'kickora_premium_yearly');
    expect(premium.hasFeature(PremiumFeature.removeAds), isFalse);

    await subscription.activateMockPlan(SubscriptionPlanType.yearly);
    expect(premium.isPremium, isTrue);
    expect(premium.removeAds, isTrue);
    expect(premium.fasterNotifications, isTrue);
    expect(premium.advancedStatistics, isTrue);
    expect(premium.favoriteTeamsFeatures, isTrue);
    expect(premium.adsEnabled, isFalse);

    premium.dispose();
  });
}
