# Kickora Play Store Release Checklist

## Versioning

- Current `pubspec.yaml`: `1.0.0+1`
- Suggested next store upload: **versionName `1.0.0`**, **versionCode `2`** (`1.0.0+2` in pubspec)

## Pre-build commands

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```

## Release build

```bash
flutter build appbundle --release --dart-define=KICKORA_API_MODE=backend --dart-define=KICKORA_BACKEND_URL=https://YOUR_BACKEND_URL
```

Optional (only when ready):

```bash
--dart-define=KICKORA_ADS_ENABLED=true
--dart-define=KICKORA_IAP_ENABLED=true
```

## Firebase Console

- [ ] `google-services.json` matches `com.kickora.worldcup`
- [ ] Cloud Messaging topics tested
- [ ] Analytics + Crashlytics enabled for release

## AdMob

- [ ] Create app + native ad units in AdMob
- [ ] Replace test unit IDs via `--dart-define=KICKORA_AD_NATIVE_MATCH_LIST=...` etc.
- [ ] Set `KICKORA_ADS_ENABLED=true` only after review

## Play Console

- [ ] Create subscription `kickora_premium_yearly`
- [ ] Upload AAB to internal testing
- [ ] Privacy Policy URL (host `docs/privacy_policy.md`)
- [ ] Terms URL (host `docs/terms_conditions.md`)

## App behavior verification

- [ ] Mock mode default without dart-defines
- [ ] Notifications OFF on first install
- [ ] No permission dialog until user enables notifications
- [ ] Premium does not unlock without purchase/restore
- [ ] No API keys in APK

## Package name

Confirm: `com.kickora.worldcup`
