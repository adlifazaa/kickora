# Kickora Arabic branding assets (`com.sugarkeys.kickora`)

Approved display name: **Kickora | نتائج كرة القدم مباشرة**

## Active pipeline

| Path | Purpose |
|------|---------|
| `final/` | **Production assets only** — drop approved art here |
| `../icon/_deprecated_trophy/` | Old trophy icons — **do not use or reference** |

The `placeholder/` folder is **not used**. Do not add temporary branding PNGs to this repo.

## Launcher icon workflow

1. Add `final/app_icon_1024.png` (approved production master).
2. Run `dart run flutter_launcher_icons` (configured in `pubspec.yaml`).
3. Upload remaining `final/` assets to Google Play Console.

See `final/README.md` for the full checklist.

## In-app logo

`KickoraBrandMark` is available as a code widget (not a launcher image file).
Launcher icons are platform resources under `android/` and `ios/`.
