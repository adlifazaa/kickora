import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_constants.dart';
import 'package:kickora/core/constants/api_mode.dart';
import 'package:kickora/core/constants/api_release_policy.dart';

void main() {
  test('default mode remains mock', () {
    expect(ApiConstants.apiMode, ApiMode.mock);
    expect(ApiReleasePolicy.effectiveMode, ApiMode.mock);
    expect(ApiReleasePolicy.usesRemoteApi, isFalse);
  });
}
