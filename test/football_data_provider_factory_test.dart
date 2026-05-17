import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_mode.dart';
import 'package:kickora/data/providers/football_data_provider_factory.dart';
import 'package:kickora/data/providers/mock_football_data_provider.dart';

void main() {
  test('default build uses mock provider when no dart-define credentials', () {
    final provider = FootballDataProviderFactory.create();
    expect(provider, isA<MockFootballDataProvider>());
    expect(provider.mode, ApiMode.mock);
    expect(provider.isMock, isTrue);
    expect(provider.isRemote, isFalse);
  });
}
