import 'package:flutter/material.dart';

/// True when [value] looks like a remote image URL (API-Football logos, etc.).
bool isNetworkImageUrl(String? value) {
  if (value == null || value.isEmpty) return false;
  final trimmed = value.trim();
  return trimmed.startsWith('http://') || trimmed.startsWith('https://');
}

/// Loads a remote logo with loading + error fallbacks — never shows the URL as text.
class NetworkLogoImage extends StatelessWidget {
  const NetworkLogoImage({
    super.key,
    required this.size,
    this.imageUrl,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.clipOval = true,
  });

  final double size;
  final String? imageUrl;
  final Widget fallback;
  final BoxFit fit;
  final bool clipOval;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (!isNetworkImageUrl(url)) {
      return SizedBox(width: size, height: size, child: fallback);
    }

    final primary = Theme.of(context).colorScheme.primary;
    Widget image = Image.network(
      url!,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return SizedBox(width: size, height: size, child: child);
        }
        return _LoadingPlaceholder(size: size, color: primary);
      },
      errorBuilder: (_, _, _) => fallback,
    );

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
