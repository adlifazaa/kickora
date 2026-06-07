import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_constants.dart';
import 'package:kickora/core/constants/api_mode.dart';
import 'package:kickora/core/constants/api_release_policy.dart';

void main() {
  test('default mode is backend proxy with production backend URL', () {
    expect(ApiConstants.apiMode, ApiMode.backendProxy);
    expect(ApiConstants.backendBaseUrl, ApiConstants.productionBackendUrl);
    expect(ApiReleasePolicy.effectiveMode, ApiMode.backendProxy);
    expect(ApiReleasePolicy.usesRemoteApi, isTrue);
    expect(ApiConstants.hasBackendUrl, isTrue);
  });
}
