import '../errors/api_exception.dart';

/// TTL and user-facing copy for football API caching.
class ApiCachePolicy {
  ApiCachePolicy._();

  static const Duration liveMatches = Duration(seconds: 60);
  static const Duration todayMatches = Duration(minutes: 5);
  static const Duration standings = Duration(minutes: 10);
  static const Duration competitions = Duration(hours: 24);
  static const Duration teams = Duration(hours: 24);
  static const Duration matchDetails = Duration(minutes: 2);
  static const Duration playerProfile = Duration(hours: 24);

  /// @deprecated Use [todayMatches].
  static const Duration fixturesByDate = todayMatches;

  static const Duration fixturesUpcoming = Duration(minutes: 5);
  static const Duration fixturesFinished = Duration(minutes: 15);

  // --- Friendly errors (EN) ---

  static const String rateLimitMessageEn =
      'API limit reached. Please wait a few minutes and tap Retry.';
  static const String rateLimitMessageAr =
      'تم الوصول إلى حد الطلبات. انتظر بضع دقائق ثم اضغط إعادة المحاولة.';

  static const String backendUnavailableEn =
      'Kickora servers are temporarily unavailable. Please try again shortly.';
  static const String backendUnavailableAr =
      'خوادم كيكورا غير متاحة مؤقتاً. حاول مرة أخرى بعد قليل.';

  static const String noInternetEn =
      'No internet connection. Check your network and try again.';
  static const String noInternetAr =
      'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.';

  static const String emptyResponseEn =
      'No data available right now. Pull to refresh or try again later.';
  static const String emptyResponseAr =
      'لا توجد بيانات متاحة حالياً. اسحب للتحديث أو حاول لاحقاً.';

  static String rateLimitMessage({required bool isArabic}) =>
      isArabic ? rateLimitMessageAr : rateLimitMessageEn;

  static String friendlyMessage(ApiException e, {required bool isArabic}) {
    if (e.isRateLimited) return rateLimitMessage(isArabic: isArabic);
    if (e.isBackendUnavailable) {
      return isArabic ? backendUnavailableAr : backendUnavailableEn;
    }
    if (e.isNetwork) return isArabic ? noInternetAr : noInternetEn;
    if (e.isEmptyResponse) {
      return isArabic ? emptyResponseAr : emptyResponseEn;
    }
    return e.message;
  }
}
