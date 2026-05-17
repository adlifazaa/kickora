import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_constants.dart';
import 'package:kickora/core/constants/api_mode.dart';
import 'package:kickora/core/errors/api_exception.dart';
import 'package:kickora/data/services/api_football/api_football_service.dart';

void main() {
  test('ApiFootballService is disabled without direct mode and API key', () {
    final service = ApiFootballService();
    expect(service.isEnabled, isFalse);
    expect(
      service.getLiveMatches(),
      throwsA(isA<ApiException>()),
    );
  });

  test('default app mode remains mock', () {
    expect(ApiConstants.apiMode, ApiMode.mock);
    expect(ApiConstants.isMock, isTrue);
  });
}
