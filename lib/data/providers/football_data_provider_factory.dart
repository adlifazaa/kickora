import '../../core/cache/cache_manager.dart';
import '../../core/constants/api_mode.dart';
import '../../core/constants/api_mode_service.dart';
import 'football_data_provider.dart';
import 'mock_football_data_provider.dart';
import 'remote_football_data_provider.dart';

/// Builds the active [FootballDataProvider] from compile-time [ApiMode].
///
/// Default: mock (no remote calls). Direct API requires
/// `--dart-define=KICKORA_API_MODE=direct --dart-define=KICKORA_API_KEY=...`
class FootballDataProviderFactory {
  FootballDataProviderFactory._();

  static FootballDataProvider create({CacheManager? cache}) {
    if (ApiModeService.isMock || !ApiModeService.usesRemoteApi) {
      return MockFootballDataProvider();
    }
    if (ApiModeService.isBackendProxy) {
      return RemoteFootballDataProvider.create(
        cache: cache,
        mode: ApiMode.backendProxy,
      );
    }
    return RemoteFootballDataProvider.create(
      cache: cache,
      mode: ApiMode.directApi,
    );
  }
}
