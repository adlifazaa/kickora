import '../../subscription/premium_product_offer.dart';

/// Safe store-query snapshot for Premium UI. No tokens or account data.
class PremiumProductQueryResult {
  const PremiumProductQueryResult({
    required this.storeAvailable,
    required this.requestedIds,
    required this.queryStatus,
    this.notFoundIds = const [],
    this.errorCode,
    this.offer,
  });

  final bool storeAvailable;
  final List<String> requestedIds;
  final String queryStatus;
  final List<String> notFoundIds;
  final String? errorCode;
  final PremiumProductOffer? offer;

  bool get hasOffer => offer != null;
  bool get productMissing =>
      storeAvailable && offer == null && notFoundIds.isNotEmpty;
}

enum PremiumStoreUiState {
  checking,
  storeUnavailable,
  queryError,
  unavailable,
  available,
  purchased,
}

class PremiumStoreStatusMapper {
  PremiumStoreStatusMapper._();

  static PremiumStoreUiState fromQuery({
    required bool paymentsEnabled,
    required bool loading,
    required bool isPremium,
    PremiumProductQueryResult? result,
  }) {
    if (isPremium) return PremiumStoreUiState.purchased;
    if (loading) return PremiumStoreUiState.checking;
    if (!paymentsEnabled || result?.storeAvailable == false) {
      return PremiumStoreUiState.storeUnavailable;
    }
    if (result?.errorCode != null && result?.offer == null) {
      return PremiumStoreUiState.queryError;
    }
    if (result?.offer != null) return PremiumStoreUiState.available;
    return PremiumStoreUiState.unavailable;
  }

  static String arabicMessage(PremiumStoreUiState state) {
    switch (state) {
      case PremiumStoreUiState.checking:
        return 'جاري التحقق من المتجر…';
      case PremiumStoreUiState.storeUnavailable:
        return 'تعذر الاتصال بمتجر Google Play. حاول مرة أخرى.';
      case PremiumStoreUiState.queryError:
      case PremiumStoreUiState.unavailable:
        return 'غير متوفر حاليًا';
      case PremiumStoreUiState.available:
        return 'اشترك سنويًا';
      case PremiumStoreUiState.purchased:
        return 'أنت مشترك مميز';
    }
  }

  static String englishMessage(PremiumStoreUiState state) {
    switch (state) {
      case PremiumStoreUiState.checking:
        return 'Checking the store…';
      case PremiumStoreUiState.storeUnavailable:
        return 'Could not connect to Google Play. Please try again.';
      case PremiumStoreUiState.queryError:
      case PremiumStoreUiState.unavailable:
        return 'Currently unavailable';
      case PremiumStoreUiState.available:
        return 'Subscribe yearly';
      case PremiumStoreUiState.purchased:
        return 'You are Premium';
    }
  }

  static String message(PremiumStoreUiState state, {required bool isArabic}) =>
      isArabic ? arabicMessage(state) : englishMessage(state);
}
