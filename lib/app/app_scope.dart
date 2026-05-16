import 'package:flutter/material.dart';

import '../core/refresh/match_refresh_service.dart';
import '../data/repositories/football_repository.dart';
import '../services/app_controller.dart';

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope == null || scope.notifier == null) {
      throw StateError('AppScope is missing in widget tree.');
    }
    return scope.notifier!;
  }

  static FootballRepository footballRepositoryOf(BuildContext context) =>
      of(context).footballRepository;

  static MatchRefreshService matchRefreshServiceOf(BuildContext context) =>
      of(context).matchRefreshService;
}
