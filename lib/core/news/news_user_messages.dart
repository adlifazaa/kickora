import 'package:flutter/foundation.dart';

/// User-facing news copy. Technical diagnostics stay in debug logs.
class NewsUserMessages {
  NewsUserMessages._();

  static const englishUnavailable =
      'News is temporarily unavailable. Please try again later.';
  static const arabicUnavailable =
      'الأخبار غير متاحة مؤقتًا، حاول مرة أخرى لاحقًا.';

  static String unavailable({required bool isArabic}) =>
      isArabic ? arabicUnavailable : englishUnavailable;

  static void logTechnical(Object? reason, [StackTrace? stackTrace]) {
    if (!kDebugMode) return;
    debugPrint('[Kickora News] $reason');
    if (stackTrace != null) {
      debugPrint('$stackTrace');
    }
  }

  static bool looksTechnical(String? message) {
    if (message == null || message.trim().isEmpty) return false;
    final lower = message.toLowerCase();
    return lower.contains('news_api_key') ||
        lower.contains('environment') ||
        lower.contains('backend') ||
        lower.contains('stack') ||
        lower.contains('exception') ||
        lower.contains('http://') ||
        lower.contains('https://') ||
        lower.contains('dart-define');
  }
}
