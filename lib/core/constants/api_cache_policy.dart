/// TTL and user-facing copy for API-Football free-tier caching.
class ApiCachePolicy {
  ApiCachePolicy._();

  static const Duration liveMatches = Duration(seconds: 60);
  static const Duration standings = Duration(minutes: 10);
  static const Duration competitions = Duration(hours: 24);
  static const Duration teams = Duration(hours: 24);
  static const Duration matchDetails = Duration(minutes: 5);
  static const Duration playerProfile = Duration(hours: 24);

  /// Fixtures by date / status (non-live lists).
  static const Duration fixturesByDate = Duration(minutes: 3);
  static const Duration fixturesUpcoming = Duration(minutes: 5);
  static const Duration fixturesFinished = Duration(minutes: 15);

  static const String rateLimitMessageEn =
      'API-Football free plan limit reached. Please wait a few minutes and tap Retry.';
  static const String rateLimitMessageAr =
      'تم الوصول إلى حد الخطة المجانية. انتظر بضع دقائق ثم اضغط إعادة المحاولة.';

  static String rateLimitMessage({required bool isArabic}) =>
      isArabic ? rateLimitMessageAr : rateLimitMessageEn;
}
