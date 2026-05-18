# Kickora

Flutter football app (`com.kickora.live`). **Mock data is the default** for Play Store and everyday development — no API keys in the repo or release binaries.

## Developer API test mode (console only)

Debug builds print a single-line trace per fetch:

```text
[Kickora Dev] getLiveMatches apiMode=mock dataSource=mock resultCount=2
```

Never commit real API keys. Pass credentials only via `--dart-define` at run/build time.

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

### Direct API-Football (local testing)

```bash
flutter run --dart-define=KICKORA_API_MODE=direct --dart-define=KICKORA_API_KEY=YOUR_KEY
```

If `KICKORA_API_MODE=direct` is set **without** a key, the app logs a friendly warning and **falls back to mock data** (no crash).

Verbose HTTP logs (still no secrets):

```bash
flutter run --dart-define=KICKORA_API_MODE=direct --dart-define=KICKORA_API_KEY=YOUR_KEY --dart-define=KICKORA_API_DEBUG=true
```

Lower refresh pressure while testing:

```bash
flutter run --dart-define=KICKORA_API_MODE=direct --dart-define=KICKORA_API_KEY=YOUR_KEY --dart-define=KICKORA_API_DEV_MODE=true
```

### Backend proxy (production-style)

```bash
flutter run --dart-define=KICKORA_API_MODE=backend --dart-define=KICKORA_BACKEND_URL=https://your-api.example.com
```

Aliases: `backendproxy`, `backend_proxy`. Without a URL, the app warns and uses mock data.

### Play Store release

Ship **without** `KICKORA_API_KEY` or direct mode — default mock or your hosted backend URL only:

```bash
flutter build appbundle --release --dart-define=KICKORA_API_MODE=backend --dart-define=KICKORA_BACKEND_URL=https://your-api.example.com
```

## Getting Started

See [Flutter documentation](https://docs.flutter.dev/) for environment setup.
