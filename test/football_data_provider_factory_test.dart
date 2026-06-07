import 'package:flutter_test/flutter_test.dart';
import 'package:kickora/core/constants/api_mode.dart';
import 'package:kickora/data/providers/football_data_provider_factory.dart';
import 'package:kickora/data/providers/mock_football_data_provider.dart';
import 'package:kickora/data/providers/remote_football_data_provider.dart';

void main() {
  test('default build uses backend remote provider', () {
    final provider = FootballDataProviderFactory.create();
    expect(provider, isA<RemoteFootballDataProvider>());
    expect(provider.mode, ApiMode.backendProxy);
    expect(provider.isMock, isFalse);
    expect(provider.isRemote, isTrue);
  });

  test('mock provider remains available for explicit development use', () {
    final provider = MockFootballDataProvider();
    expect(provider.isMock, isTrue);
    expect(provider.isRemote, isFalse);
    expect(provider.mode, ApiMode.mock);
  });
}
