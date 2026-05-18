import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_subscription_bridge.dart';
import 'subscription_plan.dart';
import 'subscription_state.dart';

/// Local premium / ad-free state (mock persistence until IAP is live).
class PremiumSubscriptionService extends ChangeNotifier {
  PremiumSubscriptionService(
    this._preferences, {
    SubscriptionPaymentBridge? paymentBridge,
  }) : _paymentBridge = paymentBridge ?? const MockSubscriptionBridge();

  static const String premiumActiveKey = 'kickora_premium_active';
  static const String trialUsedKey = 'kickora_trial_used';
  static const String planKey = 'kickora_subscription_plan';
  static const String expiresKey = 'kickora_premium_expires_ms';

  static const Duration trialDuration = Duration(days: 7);
  static const Duration mockMonthlyDuration = Duration(days: 30);
  static const Duration mockYearlyDuration = Duration(days: 365);

  final SharedPreferences _preferences;
  final SubscriptionPaymentBridge _paymentBridge;

  bool _premiumActive = false;
  bool _trialUsed = false;
  SubscriptionPlanType? _activePlan;
  DateTime? _expiresAt;

  bool get isPremium => _isEntitlementActive();

  /// Whether ad slots may be shown for this user.
  bool get adsEnabled => !isPremium;

  /// Free trial not yet consumed and user is not premium.
  bool get trialAvailable => !_trialUsed && !isPremium;

  SubscriptionPlanType? get activePlan => _activePlan;
  DateTime? get expiresAt => _expiresAt;
  bool get trialUsed => _trialUsed;

  SubscriptionState get state => SubscriptionState(
        isPremium: isPremium,
        adsEnabled: adsEnabled,
        trialAvailable: trialAvailable,
        activePlan: _activePlan,
        expiresAt: _expiresAt,
        trialUsed: _trialUsed,
      );

  Future<void> load() async {
    _premiumActive = _preferences.getBool(premiumActiveKey) ?? false;
    _trialUsed = _preferences.getBool(trialUsedKey) ?? false;
    final planRaw = _preferences.getString(planKey);
    _activePlan = _parsePlan(planRaw);
    final expiresMs = _preferences.getInt(expiresKey);
    _expiresAt =
        expiresMs != null ? DateTime.fromMillisecondsSinceEpoch(expiresMs) : null;

    if (_premiumActive && !_isEntitlementActive()) {
      await _clearEntitlement();
    }
    notifyListeners();
  }

  /// Future IAP entry — shows UI only; returns false until billing is wired.
  Future<bool> purchasePlan(SubscriptionPlan plan) async {
    final ok = await _paymentBridge.purchase(plan);
    if (!ok) return false;
    await _grant(plan.type, _durationFor(plan.type));
    return true;
  }

  Future<bool> restorePurchases() async {
    final ok = await _paymentBridge.restorePurchases();
    if (!ok) return false;
    await _grant(SubscriptionPlanType.yearly, _durationFor(SubscriptionPlanType.yearly));
    return true;
  }

  /// Mock-only: activate trial without payment (Settings → Remove ads flow).
  Future<void> startMockTrial() async {
    if (!trialAvailable) return;
    _trialUsed = true;
    await _grant(SubscriptionPlanType.trial, trialDuration);
    await _preferences.setBool(trialUsedKey, true);
  }

  /// Mock-only: simulate subscription for QA (not exposed in production UI).
  Future<void> activateMockPlan(SubscriptionPlanType type) async {
    if (type == SubscriptionPlanType.trial) {
      await startMockTrial();
      return;
    }
    await _grant(type, _durationFor(type));
  }

  Future<void> clearMockPremium() async {
    await _clearEntitlement();
    _trialUsed = false;
    await _preferences.setBool(trialUsedKey, false);
    notifyListeners();
  }

  bool _isEntitlementActive() {
    if (!_premiumActive) return false;
    if (_expiresAt == null) return true;
    return _expiresAt!.isAfter(DateTime.now());
  }

  Future<void> _grant(SubscriptionPlanType type, Duration duration) async {
    _premiumActive = true;
    _activePlan = type;
    _expiresAt = DateTime.now().add(duration);
    await _persist();
    notifyListeners();
  }

  Future<void> _clearEntitlement() async {
    _premiumActive = false;
    _activePlan = null;
    _expiresAt = null;
    await _preferences.setBool(premiumActiveKey, false);
    await _preferences.remove(planKey);
    await _preferences.remove(expiresKey);
  }

  Future<void> _persist() async {
    await _preferences.setBool(premiumActiveKey, _premiumActive);
    if (_activePlan != null) {
      await _preferences.setString(planKey, _activePlan!.name);
    }
    if (_expiresAt != null) {
      await _preferences.setInt(expiresKey, _expiresAt!.millisecondsSinceEpoch);
    }
  }

  Duration _durationFor(SubscriptionPlanType type) {
    switch (type) {
      case SubscriptionPlanType.monthly:
        return mockMonthlyDuration;
      case SubscriptionPlanType.yearly:
        return mockYearlyDuration;
      case SubscriptionPlanType.trial:
        return trialDuration;
    }
  }

  SubscriptionPlanType? _parsePlan(String? raw) {
    if (raw == null) return null;
    for (final type in SubscriptionPlanType.values) {
      if (type.name == raw) return type;
    }
    return null;
  }
}
