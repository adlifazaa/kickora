import 'package:flutter/material.dart';

/// Lightweight wrapper that scales its child down briefly on tap, then snaps
/// back. Used to add a subtle press feedback on premium cards/buttons without
/// reaching for any heavy animation packages.
class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 120),
    this.borderRadius,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;
  final BorderRadius? borderRadius;
  final HitTestBehavior behavior;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onTapDown: (_) => _c.forward(from: 0),
      onTapUp: (_) => _c.reverse(),
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = Curves.easeOut.transform(_c.value);
          return Transform.scale(
            scale: 1 - (1 - widget.scale) * t,
            child: child,
          );
        },
        child: widget.borderRadius != null
            ? ClipRRect(borderRadius: widget.borderRadius!, child: widget.child)
            : widget.child,
      ),
    );
  }
}

/// Animated heart/star favorite toggle with a small "burst" pulse on press.
/// Lightweight: single controller, no packages, safe to use in lists.
class FavoriteToggle extends StatefulWidget {
  const FavoriteToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeIcon = Icons.star_rounded,
    this.inactiveIcon = Icons.star_border_rounded,
    this.activeColor,
    this.inactiveColor,
    this.size = 22,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;

  @override
  State<FavoriteToggle> createState() => _FavoriteToggleState();
}

class _FavoriteToggleState extends State<FavoriteToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onChanged(!widget.value);
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.activeColor ?? Colors.amber;
    final inactive = widget.inactiveColor ?? Theme.of(context).hintColor;
    return IconButton(
      tooltip: widget.value ? 'Remove' : 'Add',
      visualDensity: VisualDensity.compact,
      onPressed: _handleTap,
      icon: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final pulse = Curves.elasticOut.transform(_c.value.clamp(0.0, 1.0));
          final scale = 1 + (pulse * 0.25);
          return Transform.scale(
            scale: scale,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                widget.value ? widget.activeIcon : widget.inactiveIcon,
                key: ValueKey<bool>(widget.value),
                color: widget.value ? active : inactive,
                size: widget.size,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Premium page route: short fade + tiny rise from below, with a light cubic
/// ease. Matches FotMob/SofaScore feel. Use `Navigator.of(context).push(
/// PremiumPageRoute(builder: ...))`.
class PremiumPageRoute<T> extends PageRouteBuilder<T> {
  PremiumPageRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
