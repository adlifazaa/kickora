/// Kickora Premium capabilities (inactive until IAP is wired).
enum PremiumFeature {
  /// Hides all ad placements.
  removeAds,

  /// Priority / faster push delivery (future backend).
  fasterNotifications,

  /// Extended match stats and insights.
  advancedStatistics,

  /// Extra favorite-team tooling (alerts, pinning).
  favoriteTeamsFeatures,
}

extension PremiumFeatureX on PremiumFeature {
  String get wireValue {
    switch (this) {
      case PremiumFeature.removeAds:
        return 'remove_ads';
      case PremiumFeature.fasterNotifications:
        return 'faster_notifications';
      case PremiumFeature.advancedStatistics:
        return 'advanced_statistics';
      case PremiumFeature.favoriteTeamsFeatures:
        return 'favorite_teams_features';
    }
  }
}
