/// How the app reaches football data.
enum ApiMode {
  /// Development/testing: Flutter calls API-Football directly with [KICKORA_API_KEY].
  directApi,

  /// Production: Flutter calls the Kickora backend proxy (no API key in the app).
  backendProxy,
}
