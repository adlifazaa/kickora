import '../../core/cache/cache_manager.dart';
import '../providers/football_data_provider.dart';
import '../providers/football_data_provider_factory.dart';
import 'football_repository.dart';

/// Bundles repositories for dependency injection (UI → repository → provider).
class AppRepositories {
  AppRepositories({
    FootballDataProvider? dataProvider,
    FootballRepository? football,
    CacheManager? cache,
  }) : dataProvider =
            dataProvider ?? FootballDataProviderFactory.create(cache: cache),
       football = football ??
           FootballRepository(
             dataProvider: dataProvider,
             cache: cache,
           );

  final FootballDataProvider dataProvider;
  final FootballRepository football;
}
