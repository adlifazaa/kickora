import 'dart:async';

import 'package:flutter/material.dart';

import '../app/app_text.dart';

/// Subtle last-updated label with optional inline refresh spinner.
class LiveUpdateIndicator extends StatefulWidget {
  const LiveUpdateIndicator({
    super.key,
    this.lastUpdated,
    this.refreshing = false,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 8),
  });

  final DateTime? lastUpdated;
  final bool refreshing;
  final EdgeInsetsGeometry padding;

  @override
  State<LiveUpdateIndicator> createState() => _LiveUpdateIndicatorState();
}

class _LiveUpdateIndicatorState extends State<LiveUpdateIndicator> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final hint = Theme.of(context).hintColor;
    final primary = Theme.of(context).colorScheme.primary;
    final label = widget.refreshing
        ? text.refreshingLabel
        : text.updatedLabel(widget.lastUpdated);

    return Padding(
      padding: widget.padding,
      child: Row(
        children: [
          if (widget.refreshing)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primary.withValues(alpha: 0.85),
                ),
              ),
            )
          else
            Icon(Icons.update_rounded, size: 14, color: hint.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: hint,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
