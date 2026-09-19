import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'mock_subscription_bridge.dart';
import 'premium_product_offer.dart';
import 'premium_store_status.dart';
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
      if (kDebugMode) {
        debugPrint('[Kickora Premium] store available=$available');
      }
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
      if (purchase.status == PurchaseStatus.error && kDebugMode) {
        debugPrint(
          '[Kickora Premium] purchase state=error code=${purchase.error?.code}',
        );
      }
      if (completer != null && !completer.isCompleted) {
        completer.complete(ok);
      }
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<PremiumProductQueryResult> queryYearlyProduct() async {
    const requested = {PremiumServiceProductIds.yearly};
    try {
      final available = await _iap.isAvailable();
      if (kDebugMode) {
        debugPrint(
          '[Kickora Premium] query start store=$available ids=$requested',
        );
      }
      if (!available) {
        return const PremiumProductQueryResult(
          storeAvailable: false,
          requestedIds: [PremiumServiceProductIds.yearly],
          queryStatus: 'store_unavailable',
        );
      }
      final response = await _iap.queryProductDetails(requested);
      if (kDebugMode) {
        debugPrint(
          '[Kickora Premium] query status=${response.error?.code ?? 'ok'} '
          'found=${response.productDetails.length} '
          'notFound=${response.notFoundIDs}',
        );
      }
      if (response.error != null) {
        return PremiumProductQueryResult(
          storeAvailable: true,
          requestedIds: requested.toList(),
          queryStatus: 'error',
          notFoundIds: response.notFoundIDs.toList(),
          errorCode: response.error!.code,
        );
      }
      if (response.productDetails.isEmpty) {
        return PremiumProductQueryResult(
          storeAvailable: true,
          requestedIds: requested.toList(),
          queryStatus: 'empty',
          notFoundIds: response.notFoundIDs.toList(),
        );
      }
      final product = response.productDetails.first;
      return PremiumProductQueryResult(
        storeAvailable: true,
        requestedIds: requested.toList(),
        queryStatus: 'success',
        notFoundIds: response.notFoundIDs.toList(),
        offer: PremiumProductOffer(
          productId: product.id,
          priceLabel: product.price,
          isAvailable: true,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Kickora Premium] query failed: $e');
      }
      return const PremiumProductQueryResult(
        storeAvailable: false,
        requestedIds: [PremiumServiceProductIds.yearly],
        queryStatus: 'error',
        errorCode: 'query_failed',
      );
    }
  }

  Future<PremiumProductOffer?> queryYearlyOffer() async {
    final result = await queryYearlyProduct();
    return result.offer;
  }

  PurchaseParam _purchaseParam(ProductDetails product) {
    if (product is GooglePlayProductDetails) {
      return GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: product.offerToken,
      );
    }
    return PurchaseParam(productDetails: product);
  }

  @override
  Future<bool> purchase(SubscriptionPlan plan) async {
    try {
      final response = await _iap.queryProductDetails({plan.productId});
      if (kDebugMode) {
        debugPrint(
          '[Kickora Premium] purchase query notFound=${response.notFoundIDs}',
        );
      }
      if (response.error != null || response.productDetails.isEmpty) {
        return false;
      }
      final product = response.productDetails.first;
      final completer = Completer<bool>();
      _purchaseCompleter[plan.productId] = completer;
      final started = await _iap.buyNonConsumable(
        purchaseParam: _purchaseParam(product),
      );
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Kickora Premium] restore failed: $e');
      }
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
