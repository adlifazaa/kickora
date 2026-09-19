import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/news/news_user_messages.dart';

void main() {
  test('exposes the required friendly English news message', () {
    expect(
      NewsUserMessages.unavailable(isArabic: false),
      'News is temporarily unavailable. Please try again later.',
    );
  });

  test('exposes the required friendly Arabic news message', () {
    expect(
      NewsUserMessages.unavailable(isArabic: true),
      'الأخبار غير متاحة مؤقتًا، حاول مرة أخرى لاحقًا.',
    );
  });

  test('detects technical configuration details', () {
    expect(NewsUserMessages.looksTechnical('NEWS_API_KEY missing'), isTrue);
    expect(
      NewsUserMessages.looksTechnical(
        'News is temporarily unavailable. Please try again later.',
      ),
      isFalse,
    );
  });
}
