# Kickora

Flutter football app (`com.kickora.worldcup`). **Mock data is the default** for Play Store and everyday development — no API keys in the repo or release binaries.

## API modes and production cost control

| Mode | Use case | Command |
|------|----------|---------|
| **mock** (default) | UI work, tests, Play Store without your backend | `flutter run` |
| **directApi** | Local developer testing with your own API-Football key | see below |
| **backendProxy** | **Recommended for production** — keys stay on your server | see below |

Production should use **backendProxy + aggressive caching**, not directApi. The app caches live fixtures (~45s), lists (5–10 min), standings (~20 min), and stable catalogs (24h). Events, statistics, and lineups load **only on the match details screen**, never for list rows.

Debug builds log each request (no secrets): endpoint path, api mode, cache hit/miss, deduped flag, and result count.

### Mock mode (default)

No dart-define required — safe for UI work and store releases:

```bash
flutter run
flutter test
flutter build appbundle --release
```

Optional explicit flag:

```bash
flutter run --dart-define=KICKORA_API_MODE=mock
```

### Direct API-Football (developer testing only)

```bash
flutter run --dart-define=KICKORA_API_MODE=direct --dart-define=KICKORA_API_KEY=YOUR_KEY
```

**Do not ship directApi to the Play Store.** The console warns: *directApi is for development only. Use backendProxy in production.*

If `KICKORA_API_MODE=direct` is set **without** a key, the app logs a friendly warning and **falls back to mock data** (no crash).

Verbose HTTP logs (still no secrets):

```bash
flutter run --dart-define=KICKORA_API_MODE=direct --dart-define=KICKORA_API_KEY=YOUR_KEY --dart-define=KICKORA_API_DEBUG=true
```

Lower refresh pressure while testing:

```bash
flutter run --dart-define=KICKORA_API_MODE=direct --dart-define=KICKORA_API_KEY=YOUR_KEY --dart-define=KICKORA_API_DEV_MODE=true
```

### Backend proxy (recommended production mode)

```bash
flutter run --dart-define=KICKORA_API_MODE=backend --dart-define=KICKORA_BACKEND_URL=https://your-api.example.com
```

Aliases: `backendproxy`, `backend_proxy`. Without a URL, the app warns and uses mock data.

Server-side cache TTL recommendations: `docs/backend_proxy_caching.md`.

Deploy the Node proxy (`backend/README.md`): set `API_FOOTBALL_KEY` on the server only, then use your deploy URL as `KICKORA_BACKEND_URL`.

Release builds log a warning if `KICKORA_API_MODE=direct` is used (falls back to mock — no crash).

### Play Store release

Ship **without** `KICKORA_API_KEY` or direct mode — use backend proxy only:

```bash
flutter build appbundle --release --dart-define=KICKORA_API_MODE=backend --dart-define=KICKORA_BACKEND_URL=https://your-api.example.com
```

## Developer API test mode (console only)

Debug builds print a single-line trace per fetch:

```text
[Kickora Dev] getLiveMatches apiMode=mock dataSource=mock resultCount=2
[Kickora API] path=/fixtures/live apiMode=mock cache=MISS deduped=false resultCount=2
```

Never commit real API keys. Pass credentials only via `--dart-define` at run/build time.

## Firebase

- Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
- `lib/firebase_options.dart` is generated via FlutterFire CLI.
- Analytics and Crashlytics activate only after `FirebaseService.initialize()` succeeds.
- FCM background handler is registered on Android/iOS when Firebase is ready.

## Notifications

- **Off by default** on first install — no OS permission dialog until the user enables notifications in Settings.
- Topic pattern: `team_{id}`, `match_{id}`, `competition_{id}`.
- Types: `goal_scored`, `match_started`, `red_card`, `match_finished`, `favorite_team_update`, `favorite_competition_update`, `favorite_match_update`.

## AdMob (native only)

- Package: `google_mobile_ads`
- Test ad units by default (`AdUnitIds`).
- Real ads require:

```bash
flutter run --dart-define=KICKORA_ADS_ENABLED=true
```

Production native units (when `KICKORA_ADS_ENABLED=true`): `KICKORA_AD_NATIVE_MATCH_LIST_PROD`, `KICKORA_AD_NATIVE_COMPETITION_PROD`, etc. Empty values fall back to Google test IDs.

Failed ad loads show the gentle placeholder — never crash.

## Premium (Google Play Billing)

- Product ID: `kickora_premium_yearly`
- Billing uses `in_app_purchase` when the store is available on the device.
- Premium unlocks only after a successful purchase or restore — never faked in production UI.

## Release build

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --dart-define=KICKORA_API_MODE=backend --dart-define=KICKORA_BACKEND_URL=https://your-api.example.com
```

See `docs/release_checklist.md`, `docs/privacy_policy.md`, and `docs/terms_conditions.md`.

## Getting Started

See [Flutter documentation](https://docs.flutter.dev/) for environment setup.
