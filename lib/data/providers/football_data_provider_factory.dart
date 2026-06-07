import 'package:flutter/foundation.dart';

import '../../core/cache/cache_manager.dart';
import '../../core/constants/api_mode.dart';
import '../../core/constants/api_release_policy.dart';
import '../../core/network/api_debug_log.dart';
import '../sources/remote_football_source.dart';
import 'football_data_provider.dart';
import 'mock_football_data_provider.dart';
import 'remote_football_data_provider.dart';

/// Builds the active [FootballDataProvider] from compile-time [ApiMode].
///
/// Default: backend proxy (production). Mock requires
/// `--dart-define=KICKORA_API_MODE=mock`. Direct API requires
/// `--dart-define=KICKORA_API_MODE=direct --dart-define=KICKORA_API_KEY=...`
class FootballDataProviderFactory {
  FootballDataProviderFactory._();

  static FootballDataProvider create({CacheManager? cache}) {
    final FootballDataProvider provider;
    final mode = ApiReleasePolicy.effectiveMode;
    if (mode == ApiMode.mock || !ApiReleasePolicy.usesRemoteApi) {
      provider = MockFootballDataProvider();
    } else if (mode == ApiMode.backendProxy) {
      provider = RemoteFootballDataProvider.create(
        cache: cache,
        mode: ApiMode.backendProxy,
      );
    } else {
      provider = RemoteFootballDataProvider.create(
        cache: cache,
        mode: ApiMode.directApi,
      );
    }
    if (kDebugMode) {
      ApiDebugLog.providerSelected(
        provider: provider.isMock ? 'MockFootballDataProvider' : provider.mode.name,
        remoteActive: RemoteFootballSource.isRemoteActive,
      );
    }
    return provider;
  }
}
