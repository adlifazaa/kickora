# Production branding assets — `com.sugarkeys.kickora`

Approved display name: **Kickora | نتائج كرة القدم مباشرة**

Place **final approved** files here before building or uploading to Google Play.
No temporary or placeholder graphics belong in this repository.

## Required files

| File | Size | Used for |
|------|------|----------|
| `app_icon_1024.png` | 1024×1024 PNG | Master icon → `dart run flutter_launcher_icons` |
| `play_store_icon_512.png` | 512×512 PNG | Play Console → Hi-res icon |
| `feature_graphic_1024x500.png` | 1024×500 PNG/JPG | Play Console → Feature graphic |
| `screenshots/phone_01.png` … | 1080×1920+ | Play Console → Phone screenshots |

Optional: `ic_notification.png` (96×96 white silhouette) if replacing
`android/app/src/main/res/drawable/ic_notification.xml`.

## Launcher regeneration

1. Keep approved master icon at `app_icon_1024.png` in this folder.
2. From repo root run: `dart run flutter_launcher_icons`
   - Regenerates Android `mipmap-*/ic_launcher.png` and iOS `AppIcon.appiconset/`.
3. Keep approved store icon at `play_store_icon_512.png`.
4. Keep approved feature graphic at `feature_graphic_1024x500.png`.
5. Add screenshots under `screenshots/`.
6. Upload Play Console listing assets manually.

## Policy (no exceptions)

- No FIFA World Cup Trophy silhouette
- No FIFA / official tournament emblems
- No gold+green tournament poster identity as primary brand
