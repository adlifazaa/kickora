import '../../../core/constants/api_mode_service.dart';
import 'football_remote_client.dart';

/// Selects direct API vs backend proxy client from compile-time mode.
class FootballRemoteClientFactory {
  FootballRemoteClientFactory._();

  static FootballRemoteClient create() {
    if (ApiModeService.isBackendProxy) {
      return BackendProxyFootballClient();
    }
    return DirectApiFootballClient();
  }
}
