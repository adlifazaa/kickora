import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// True when [value] looks like a remote image URL (API-Football logos, etc.).
bool isNetworkImageUrl(String? value) {
  if (value == null || value.isEmpty) return false;
  final trimmed = value.trim();
  return trimmed.startsWith('http://') || trimmed.startsWith('https://');
}

/// Loads remote, bundled asset, or [localVisual] with loading + error fallbacks.
class NetworkLogoImage extends StatelessWidget {
  const NetworkLogoImage({
    super.key,
    required this.size,
    this.imageUrl,
    this.assetPath,
    this.localVisual,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.clipOval = true,
  });

  final double size;
  final String? imageUrl;
  final String? assetPath;
  final Widget? localVisual;
  final Widget fallback;
  final BoxFit fit;
  final bool clipOval;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (isNetworkImageUrl(url)) {
      return _networkImage(context, url!);
    }

    final asset = assetPath?.trim();
    if (asset != null && asset.isNotEmpty) {
      return _assetImage(context, asset);
    }

    if (localVisual != null) {
      return SizedBox(width: size, height: size, child: localVisual);
    }

    return SizedBox(width: size, height: size, child: fallback);
  }

  Widget _networkImage(BuildContext context, String url) {
    final primary = Theme.of(context).colorScheme.primary;
    final pad = size * 0.12;

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.medium,
      placeholder: (_, _) => _LoadingPlaceholder(size: size, color: primary),
      errorWidget: (_, _, _) => fallback,
    );

    image = Padding(padding: EdgeInsets.all(pad), child: image);

    if (clipOval) {
      image = ClipOval(child: image);
    }

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: clipOval ? BoxShape.circle : BoxShape.rectangle,
          color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.35),
        ),
        child: image,
      ),
    );
  }

  Widget _assetImage(BuildContext context, String path) {
    final pad = size * 0.1;
    Widget image = Image.asset(
      path,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, _, _) => localVisual ?? fallback,
    );
    image = Padding(padding: EdgeInsets.all(pad), child: image);
    if (clipOval) {
      image = ClipOval(child: image);
    }
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: clipOval ? BoxShape.circle : BoxShape.rectangle,
          color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.35),
        ),
        child: image,
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size * 0.42,
        height: size * 0.42,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
