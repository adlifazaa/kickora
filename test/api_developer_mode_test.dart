import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_constants.dart';
import 'package:kickora/core/constants/api_developer_config.dart';
import 'package:kickora/core/constants/api_mode.dart';
import 'package:kickora/core/constants/api_mode_service.dart';
import 'package:kickora/core/errors/api_error_messages.dart';
import 'package:kickora/core/errors/api_exception.dart';
import 'package:kickora/data/providers/football_data_provider_factory.dart';
import 'package:kickora/data/providers/remote_football_data_provider.dart';
import 'package:kickora/data/services/api_football/api_football_service.dart';

void main() {
  test('backend mode is default without dart-define', () {
    expect(ApiConstants.apiMode, ApiMode.backendProxy);
    expect(ApiConstants.isMock, isFalse);
    expect(ApiDeveloperConfig.isMockDefault, isFalse);
    expect(ApiModeService.effectiveDataSource, 'backendProxy');
    expect(ApiModeService.remoteActive, isTrue);
    expect(ApiConstants.backendBaseUrl, ApiConstants.productionBackendUrl);
  });

  test('default factory uses remote backend provider', () {
    expect(ApiConstants.isDirectApi, isFalse);
    expect(ApiConstants.hasApiKey, isFalse);
    expect(ApiDeveloperConfig.configurationWarnings, isEmpty);

    final provider = FootballDataProviderFactory.create();
    expect(provider, isA<RemoteFootballDataProvider>());
    expect(ApiModeService.usesRemoteApi, isTrue);
  });

  test('ApiFootballService does not crash when disabled', () async {
    final service = ApiFootballService();
    expect(service.isEnabled, isFalse);
    await expectLater(
      service.getLiveMatches(),
      throwsA(
        isA<ApiException>().having((e) => e.isNotConfigured, 'notConfigured', true),
      ),
    );
  });

  test('notConfigured maps to friendly message', () {
    const error = ApiException.notConfigured();
    expect(
      ApiErrorMessages.friendly(error, isArabic: false),
      ApiErrorMessages.apiNotConfiguredEn,
    );
  });
}
