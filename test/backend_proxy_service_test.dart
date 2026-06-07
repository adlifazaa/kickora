import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_constants.dart';
import 'package:kickora/core/constants/api_mode.dart';
import 'package:kickora/core/constants/api_mode_service.dart';
import 'package:kickora/data/services/backend_proxy/backend_proxy_service.dart';

void main() {
  test('BackendProxyService is enabled with production defaults', () {
    final service = BackendProxyService();
    expect(ApiConstants.apiMode, ApiMode.backendProxy);
    expect(ApiConstants.hasBackendUrl, isTrue);
    expect(ApiModeService.isBackendProxy, isTrue);
    expect(service.isEnabled, isTrue);
  });

  test('production backend URL is configured by default', () {
    expect(ApiConstants.backendBaseUrl, ApiConstants.productionBackendUrl);
    expect(
      ApiConstants.productionBackendUrl,
      'https://kickora-aoi0.onrender.com',
    );
  });
}
