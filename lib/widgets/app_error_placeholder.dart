import 'package:flutter/material.dart';

import '../app/app_colors.dart';

/// Premium error placeholder with retry button.
class AppErrorPlaceholder extends StatelessWidget {
  const AppErrorPlaceholder({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.wifi_off_rounded,
    this.onRetry,
    this.retryLabel,
  });

  final String? title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.cardRed.withValues(alpha: 0.22),
                    AppColors.cardRed.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardRed.withValues(alpha: 0.18),
                    blurRadius: 24,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 40, color: AppColors.cardRed),
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
