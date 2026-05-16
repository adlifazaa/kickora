import '../../core/cache/cache_manager.dart';
import '../services/football_api_service.dart';
import 'football_repository.dart';

/// Bundles repositories for dependency injection (UI → repository → service).
class AppRepositories {
  AppRepositories({
    FootballApiService? api,
    FootballRepository? football,
    CacheManager? cache,
  }) : api = api ?? FootballApiService(),
       football = football ??
           FootballRepository(
             api: api,
             cache: cache,
           );

  final FootballApiService api;
  final FootballRepository football;
}
