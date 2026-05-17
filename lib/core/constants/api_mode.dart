/// How the app reaches football data.
enum ApiMode {
  /// Local mock data only (default for Play Store / MVP).
  mock,

  /// Development: Flutter calls API-Football directly with [KICKORA_API_KEY].
  directApi,

  /// Production: Flutter calls the Kickora backend proxy (no API key in the app).
  backendProxy,
}
