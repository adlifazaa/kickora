/// Reserved ad slots for Kickora.
enum AdPlacement {
  /// Top banner on the matches tab (below header, above list).
  matchesBanner,

  /// Top banner on the competitions tab (below search, above grid).
  competitionsBanner,

  /// Top banner on standings views (below header, above table).
  standingsBanner,

  /// Between rows on live / today / finished match lists (placeholder only).
  matchListNative,

  /// Between competition cards on the competitions grid (placeholder only).
  competitionListNative,

  /// Optional anchored area after scrolling a long feed (placeholder only).
  scrollBottomNative,

  /// @deprecated Banner slot — not used.
  homeBanner,

  /// @deprecated Use [matchListNative] for in-feed match promos.
  feedNative,

  /// @deprecated Use [competitionListNative].
  competitionsNative,

  /// Match details supplementary native slot (future).
  matchDetailsNative,
}

extension AdPlacementX on AdPlacement {
  static const List<AdPlacement> nativePlacements = [
    AdPlacement.matchListNative,
    AdPlacement.competitionListNative,
    AdPlacement.scrollBottomNative,
  ];

  static const List<AdPlacement> topBannerPlacements = [
    AdPlacement.matchesBanner,
    AdPlacement.competitionsBanner,
    AdPlacement.standingsBanner,
  ];

  bool get isNativeSlot => AdPlacementX.nativePlacements.contains(this);

  bool get isTopBanner => AdPlacementX.topBannerPlacements.contains(this);
}
