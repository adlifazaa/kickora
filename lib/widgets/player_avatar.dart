import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/player/player_photo_resolver.dart';
import '../data/models/player_model.dart';
import 'api_display_text.dart';

/// Player image for lineups: photo → shirt icon → initials circle.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.player,
    required this.size,
    this.jerseyTop,
    this.jerseyBottom,
    this.borderColor,
    this.borderWidth = 1.8,
    this.showJerseyNumber = true,
    this.fit = BoxFit.cover,
  });

  final PlayerModel player;
  final double size;
  final Color? jerseyTop;
  final Color? jerseyBottom;
  final Color? borderColor;
  final double borderWidth;
  final bool showJerseyNumber;
  final BoxFit fit;

  static const List<List<Color>> _palettes = [
    [Color(0xFF00D1C1), Color(0xFF008F86)],
    [Color(0xFF7CFF00), Color(0xFF2EA90E)],
    [Color(0xFFFFB020), Color(0xFFE0541A)],
    [Color(0xFF63D4FF), Color(0xFF1E78D4)],
    [Color(0xFFFF5A63), Color(0xFFB1213F)],
    [Color(0xFFBBA3FF), Color(0xFF6A4AE0)],
    [Color(0xFFFFE566), Color(0xFFFFA22A)],
    [Color(0xFFE0E6EE), Color(0xFF7A8290)],
  ];

  List<Color> _palette() {
    final seed = player.id > 0
        ? player.id
        : player.shortName.codeUnitAt(0) + player.shortName.length * 7;
    return _palettes[seed % _palettes.length];
  }

  String get _initials {
    final code = sanitizeApiDisplayText(player.shortName);
    if (code.isNotEmpty) {
      return code.substring(0, code.length.clamp(1, 3));
    }
    final name = sanitizeApiDisplayText(player.name);
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return name.length >= 2
          ? name.substring(0, 2).toUpperCase()
          : name.toUpperCase();
    }
    return parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(3)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = PlayerPhotoResolver.resolve(player);
    final border = borderColor ?? Colors.white.withValues(alpha: 0.95);

    Widget child;
    if (url != null) {
      child = _PhotoAvatar(
        playerId: player.id,
        url: url,
        size: size,
        fit: fit,
        onError: () => PlayerPhotoResolver.markLoadFailed(player.id),
        fallback: _fallbackAvatar(),
      );
    } else {
      child = _fallbackAvatar();
    }

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: border, width: borderWidth),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: size * 0.18,
              offset: Offset(0, size * 0.07),
            ),
          ],
        ),
        child: ClipOval(child: child),
      ),
    );
  }

  /// Photo → shirt icon → initials (optional numbered shirt for compact chips).
  Widget _fallbackAvatar() {
    if (showJerseyNumber && player.number > 0) {
      return _JerseyBadge(
        number: player.number,
        top: jerseyTop ?? const Color(0xFFF5F7FA),
        bottom: jerseyBottom ?? const Color(0xFFD7DDE8),
        isGoalkeeper: player.position.toUpperCase() == 'GK',
        showNumber: true,
        size: size,
      );
    }

    final hasName =
        player.name.trim().isNotEmpty || player.shortName.trim().isNotEmpty;
    if (!hasName) {
      return _InitialsBadge(
        initials: _initials,
        palette: _palette(),
        size: size,
      );
    }

    return _ShirtIconBadge(
      size: size,
      palette: _palette(),
      isGoalkeeper: player.position.toUpperCase() == 'GK',
    );
  }
}

class _PhotoAvatar extends StatelessWidget {
  const _PhotoAvatar({
    required this.playerId,
    required this.url,
    required this.size,
    required this.fit,
    required this.onError,
    required this.fallback,
  });

  final int playerId;
  final String url;
  final double size;
  final BoxFit fit;
  final VoidCallback onError;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final pixelSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: 'player-photo-$playerId',
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.medium,
      memCacheWidth: pixelSize,
      memCacheHeight: pixelSize,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) {
        onError();
        return fallback;
      },
    );
  }
}

class _JerseyBadge extends StatelessWidget {
  const _JerseyBadge({
    required this.number,
    required this.top,
    required this.bottom,
    required this.isGoalkeeper,
    required this.showNumber,
    required this.size,
  });

  final int number;
  final Color top;
  final Color bottom;
  final bool isGoalkeeper;
  final bool showNumber;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bottom],
        ),
      ),
      child: showNumber
          ? Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w900,
                  color: isGoalkeeper
                      ? Colors.black
                      : const Color(0xFF0E1822),
                  letterSpacing: -0.5,
                ),
              ),
            )
          : Icon(
              Icons.checkroom_outlined,
              size: size * 0.42,
              color: isGoalkeeper
                  ? Colors.black87
                  : const Color(0xFF0E1822),
            ),
    );
  }
}

class _ShirtIconBadge extends StatelessWidget {
  const _ShirtIconBadge({
    required this.size,
    required this.palette,
    required this.isGoalkeeper,
  });

  final double size;
  final List<Color> palette;
  final bool isGoalkeeper;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Icon(
        Icons.checkroom_outlined,
        size: size * 0.46,
        color: isGoalkeeper
            ? Colors.black.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.95),
      ),
    );
  }
}

class _InitialsBadge extends StatelessWidget {
  const _InitialsBadge({
    required this.initials,
    required this.palette,
    required this.size,
  });

  final String initials;
  final List<Color> palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
