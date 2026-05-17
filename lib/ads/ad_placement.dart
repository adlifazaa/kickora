/// Reserved native ad slots (prepared only — nothing shown until enabled).
enum AdPlacement {
  /// Between rows on live / today / finished match lists.
  matchListNative,

  /// Between competition cards on the competitions grid.
  competitionListNative,

  /// Optional anchored area after scrolling a long feed.
  scrollBottomNative,

  /// @deprecated Banner slot — not used (native-only policy).
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

  bool get isNativeSlot => AdPlacementX.nativePlacements.contains(this);
}
