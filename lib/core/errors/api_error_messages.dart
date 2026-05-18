import 'api_exception.dart';

/// User-facing API error copy (EN / AR). No secrets or technical payloads.
class ApiErrorMessages {
  ApiErrorMessages._();

  static const String rateLimitEn =
      'API limit reached. Please wait a few minutes and tap Retry.';
  static const String rateLimitAr =
      'تم الوصول إلى حد الطلبات. انتظر بضع دقائق ثم اضغط إعادة المحاولة.';

  static const String backendUnavailableEn =
      'Kickora servers are temporarily unavailable. Please try again shortly.';
  static const String backendUnavailableAr =
      'خوادم كيكورا غير متاحة مؤقتاً. حاول مرة أخرى بعد قليل.';

  static const String noInternetEn =
      'No internet connection. Check your network and try again.';
  static const String noInternetAr =
      'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.';

  static const String timeoutEn =
      'The request timed out. Check your connection and try again.';
  static const String timeoutAr =
      'انتهت مهلة الطلب. تحقق من الاتصال وحاول مرة أخرى.';

  static const String emptyResponseEn =
      'No data available right now. Pull to refresh or try again later.';
  static const String emptyResponseAr =
      'لا توجد بيانات متاحة حالياً. اسحب للتحديث أو حاول لاحقاً.';

  static const String unknownEn =
      'Something went wrong. Please try again.';
  static const String unknownAr =
      'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  static const String apiNotConfiguredEn =
      'Live API is not configured. Showing offline demo data.';
  static const String apiNotConfiguredAr =
      'وضع API المباشر غير مُعد. يتم عرض بيانات تجريبية محلية.';

  static String friendly(ApiException error, {required bool isArabic}) {
    if (error.isNotConfigured) {
      return isArabic ? apiNotConfiguredAr : apiNotConfiguredEn;
    }
    if (error.isRateLimited) {
      return isArabic ? rateLimitAr : rateLimitEn;
    }
    if (error.isBackendUnavailable) {
      return isArabic ? backendUnavailableAr : backendUnavailableEn;
    }
    if (error.isTimeout) {
      return isArabic ? timeoutAr : timeoutEn;
    }
    if (error.isNetwork) {
      return isArabic ? noInternetAr : noInternetEn;
    }
    if (error.isEmptyResponse) {
      return isArabic ? emptyResponseAr : emptyResponseEn;
    }
    return isArabic ? unknownAr : unknownEn;
  }

  static String friendlyFromObject(Object error, {bool isArabic = false}) {
    if (error is ApiException) return friendly(error, isArabic: isArabic);
    return isArabic ? unknownAr : unknownEn;
  }

  /// @deprecated Use [friendly] with [ApiException.isRateLimited].
  static String rateLimitMessage({required bool isArabic}) =>
      isArabic ? rateLimitAr : rateLimitEn;
}
