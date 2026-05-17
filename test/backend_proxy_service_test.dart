import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_constants.dart';
import 'package:kickora/core/constants/api_mode.dart';
import 'package:kickora/core/errors/api_exception.dart';
import 'package:kickora/data/services/backend_proxy/backend_proxy_service.dart';

void main() {
  test('BackendProxyService is disabled without backend mode and URL', () {
    final service = BackendProxyService();
    expect(service.isEnabled, isFalse);
    expect(
      service.getLiveMatches(),
      throwsA(isA<ApiException>()),
    );
  });

  test('default app mode remains mock', () {
    expect(ApiConstants.apiMode, ApiMode.mock);
    expect(ApiConstants.isMock, isTrue);
    expect(ApiConstants.hasBackendUrl, isFalse);
  });
}
