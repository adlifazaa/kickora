import '../constants/api_cache_policy.dart';
import '../../data/models/player_model.dart';
import '../../data/repositories/repository_memory_cache.dart';
import '../../data/services/api_football_parser.dart';
import '../../widgets/network_logo_image.dart';

/// Resolves lineup/player photo URLs without per-player API calls.
///
/// Priority: explicit API photo → cached profile photo → CDN by player id.
class PlayerPhotoResolver {
  PlayerPhotoResolver._();

  static final RepositoryMemoryCache _cache = RepositoryMemoryCache();

  static String? resolve(
    PlayerModel player, {
    bool allowCdnFallback = true,
  }) {
    final explicit = player.photoUrl.trim();
    if (isNetworkImageUrl(explicit)) return explicit;

    if (player.id > 0) {
      final cached = _cache.get<String>(
        _key(player.id),
        ApiCachePolicy.playerProfile,
      );
      if (cached != null && cached.isNotEmpty && isNetworkImageUrl(cached)) {
        return cached;
      }
      if (allowCdnFallback) {
        return ApiFootballParser.playerCdnPhotoUrl(player.id);
      }
    }

    return null;
  }

  static void cacheProfilePhoto(int playerId, String? url) {
    if (playerId <= 0) return;
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) return;
    if (!isNetworkImageUrl(trimmed)) return;
    _cache.put(_key(playerId), trimmed);
  }

  static String _key(int id) => 'player_photo_$id';
}
