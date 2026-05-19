import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'mock_subscription_bridge.dart';
import 'premium_product_offer.dart';
import 'subscription_plan.dart';

/// Google Play / App Store billing via [in_app_purchase] (no fake unlocks).
class PlayBillingBridge implements SubscriptionPaymentBridge {
  PlayBillingBridge._(this._iap);

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _updatesSub;
  final _purchaseCompleter = <String, Completer<bool>>{};

  static Future<PlayBillingBridge?> create() async {
    try {
      final iap = InAppPurchase.instance;
      final available = await iap.isAvailable();
      if (!available) return null;
      final bridge = PlayBillingBridge._(iap);
      bridge._listen();
      return bridge;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Kickora Premium] billing unavailable: $e');
      }
      return null;
    }
  }

  void _listen() {
    _updatesSub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('[Kickora Premium] purchase stream error: $e');
        }
      },
    );
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      final productId = purchase.productID;
      final completer = _purchaseCompleter.remove(productId);
      final ok = purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored;
      completer?.complete(ok);
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<PremiumProductOffer?> queryYearlyOffer() async {
    try {
      final response = await _iap.queryProductDetails(
        {PremiumServiceProductIds.yearly},
      );
      if (response.error != null || response.productDetails.isEmpty) {
        return null;
      }
      final product = response.productDetails.first;
      return PremiumProductOffer(
        productId: product.id,
        priceLabel: product.price,
        isAvailable: true,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> purchase(SubscriptionPlan plan) async {
    try {
      final response = await _iap.queryProductDetails({plan.productId});
      if (response.error != null || response.productDetails.isEmpty) {
        return false;
      }
      final product = response.productDetails.first;
      final completer = Completer<bool>();
      _purchaseCompleter[plan.productId] = completer;
      final param = PurchaseParam(productDetails: product);
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) {
        _purchaseCompleter.remove(plan.productId);
        return false;
      }
      return completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          _purchaseCompleter.remove(plan.productId);
          return false;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Kickora Premium] purchase failed: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    try {
      final completer = Completer<bool>();
      late final StreamSubscription<List<PurchaseDetails>> sub;
      sub = _iap.purchaseStream.listen((purchases) {
        for (final purchase in purchases) {
          if (purchase.productID != PremiumServiceProductIds.yearly) continue;
          if (purchase.status == PurchaseStatus.restored ||
              purchase.status == PurchaseStatus.purchased) {
            if (!completer.isCompleted) completer.complete(true);
          }
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
        }
      });
      await _iap.restorePurchases();
      final restored = await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => false,
      );
      await sub.cancel();
      return restored;
    } catch (_) {
      return false;
    }
  }

  Future<void> dispose() async {
    await _updatesSub?.cancel();
  }
}

/// Product IDs for Play Console (no secrets).
class PremiumServiceProductIds {
  PremiumServiceProductIds._();
  static const String yearly = 'kickora_premium_yearly';
}
