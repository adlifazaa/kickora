import '../constants/api_cache_policy.dart';
import '../../data/models/player_model.dart';
import '../../data/repositories/repository_memory_cache.dart';
import '../../data/services/api_football_parser.dart';
import '../../widgets/network_logo_image.dart';

/// Resolves lineup/player photo URLs without per-player API calls.
///
/// Priority: explicit API photo → memory cache → API-Sports CDN (no quota).
class PlayerPhotoResolver {
  PlayerPhotoResolver._();

  static final RepositoryMemoryCache _cache = RepositoryMemoryCache();
  static final Set<int> _failedCdnIds = {};

  /// Kickora mock roster id → API-Sports player id (CDN, no quota).
  static const Map<int, int> _mockToApiSportsPhotoId = {
    1: 19528, // Emiliano Martinez
    2: 37381, // Cristian Romero
    3: 5863, // Tagliafico
    4: 37283, // Nahuel Molina
    5: 583, // Paredes
    6: 2468, // Lisandro Martinez
    7: 30430, // De Paul
    8: 286473, // Enzo Fernandez
    9: 601342, // Julian Alvarez
    10: 154, // Messi
    11: 10329, // Nicolas Gonzalez
    30: 278, // Mbappe
    31: 215844, // Thuram
    32: 523, // Dembele
    33: 2724, // Rabiot
    34: 22000, // Camavinga
    35: 73147, // Tchouameni
    36: 22194, // Theo Hernandez
    37: 22224, // Saliba
    38: 72, // Upamecano
    39: 21694, // Kounde
    40: 22009, // Maignan
  };

  static String? resolve(PlayerModel player) {
    final explicit = player.photoUrl.trim();
    if (isNetworkImageUrl(explicit)) {
      _rememberGood(player.id, explicit);
      return explicit;
    }

    if (player.id > 0) {
      final cached = _cache.get<String>(
        _key(player.id),
        ApiCachePolicy.playerProfile,
      );
      if (cached != null && cached.isNotEmpty) {
        if (cached == _failedMarker) return null;
        if (isNetworkImageUrl(cached)) return cached;
      }

      if (!_failedCdnIds.contains(player.id)) {
        final cdnId = _cdnPlayerId(player);
        if (cdnId != null) {
          return ApiFootballParser.playerCdnPhotoUrl(cdnId);
        }
      }
    }

    return null;
  }

  static int? _cdnPlayerId(PlayerModel player) {
    final mapped = _mockToApiSportsPhotoId[player.id];
    if (mapped != null) return mapped;
    // Live API lineups use real API-Football ids (typically 3+ digits).
    if (player.id >= 100) return player.id;
    return null;
  }

  static void cacheProfilePhoto(int playerId, String? url) {
    if (playerId <= 0) return;
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) return;
    if (!isNetworkImageUrl(trimmed)) return;
    _rememberGood(playerId, trimmed);
  }

  /// Call when CDN/profile image fails to load (avoids repeat 404s).
  static void markLoadFailed(int playerId) {
    if (playerId <= 0) return;
    _failedCdnIds.add(playerId);
    _cache.put(_key(playerId), _failedMarker);
  }

  static void _rememberGood(int playerId, String url) {
    if (playerId <= 0) return;
    _failedCdnIds.remove(playerId);
    _cache.put(_key(playerId), url);
  }

  static String _key(int id) => 'player_photo_$id';

  static const String _failedMarker = '__failed__';
}
