# Preflight cleanup — Arabic Kickora

## 1. Final status

**PASS**

The Arabic repository worktree is clean. Legitimate branding, documentation, identity, listing, and tooling work is committed. Generated verification dumps remain on disk but are gitignored. No secrets, keystores, or machine-specific files were committed. Version, package identity, and Billing Client were not changed.

The repository is **clean and safe** for the upcoming two-app feature update.

## 2. Repository identity (this cleanup)

| Item | Value |
|------|--------|
| Absolute root | `C:\Users\user\Desktop\Apps\Cursor Apps\Kickoras apps\Kickora Arabic\kickora` |
| Confirmed app | Arabic Kickora only (not English `com.kickora.live`) |
| Branch | `main` |
| Upstream | `origin/main` |
| Remote | `https://github.com/adlifazaa/kickora.git` |
| Starting HEAD | `2e4784a` — *Record package-correction report commit hash* |
| Android `namespace` / `applicationId` | `com.sugarkeys.kickora` |
| MainActivity | `package com.sugarkeys.kickora` at `android/app/src/main/kotlin/com/sugarkeys/kickora/MainActivity.kt` |
| App version | `1.0.15+16` (unchanged) |
| versionName / versionCode | `1.0.15` / `16` (unchanged) |

`com.kickora.worldcup` and `com.kickora.live` were not used as application identity.

## 3. Original complete dirty-file inventory

Captured at cleanup start against starting HEAD `2e4784a`. Status letters: `M` modified, `D` deleted, `??` untracked.

Billing / package-identity source from the earlier Play-correction task was **already on `main`** (`23aca45` / `2e4784a`). It is not part of this dirty set.

### Modified

| Status | Path |
|--------|------|
| M | `README.md` |
| M | `android/app/src/main/res/values/strings.xml` |
| M | `docs/privacy_policy.md` |
| M | `docs/release_checklist.md` |
| M | `firebase.json` |
| M | `lib/app/app_branding.dart` |
| M | `lib/utils/match_share_formatter.dart` |
| M | `test/match_share_formatter_test.dart` |

### Deleted

| Status | Path |
|--------|------|
| D | `assets/icon/app_icon.png` |
| D | `assets/icon/play_store_icon_512.png` |

### Untracked — branding / docs / tools

| Status | Path |
|--------|------|
| ?? | `assets/branding/README.md` |
| ?? | `assets/branding/final/README.md` |
| ?? | `assets/branding/final/app_icon_1024_NEUTRAL_TEMP.png` |
| ?? | `assets/branding/final/feature_graphic_1024x500.png` |
| ?? | `assets/branding/final/screenshots/01_home.png` |
| ?? | `assets/branding/final/screenshots/02_world_cup_hub.png` |
| ?? | `assets/branding/final/screenshots/03_competitions.png` |
| ?? | `assets/branding/final/screenshots/04_match_details.png` |
| ?? | `assets/branding/final/screenshots/05_standings.png` |
| ?? | `assets/branding/final/screenshots/_test_matches.png` |
| ?? | `assets/branding/final/screenshots/home_ui.xml` |
| ?? | `assets/branding/final/screenshots/home_world_cup_card.png` |
| ?? | `assets/branding/final/screenshots/hub_ui.xml` |
| ?? | `assets/branding/final/screenshots/ui1.xml` |
| ?? | `assets/branding/final/screenshots/world_cup_badge_on_dark.png` |
| ?? | `assets/branding/final/screenshots/world_cup_badge_transparency_check.png` |
| ?? | `assets/branding/final/screenshots/world_cup_hub_header.png` |
| ?? | `assets/branding/placeholder/README.md` |
| ?? | `assets/icon/README.md` |
| ?? | `assets/icon/_deprecated_trophy/README.md` |
| ?? | `assets/icon/_deprecated_trophy/app_icon_trophy.png` |
| ?? | `assets/icon/_deprecated_trophy/play_store_icon_trophy_512.png` |
| ?? | `backend/scripts/phase1-live-validation-output.txt` |
| ?? | `lib/widgets/kickora_brand_mark.dart` |
| ?? | `release_notes/new_play_store_listing_ar.txt` |
| ?? | `tool/generate_feature_graphic.py` |
| ?? | `tool/generate_neutral_launcher_assets.py` |
| ?? | `tool/inspect_launcher_icon.py` |
| ?? | `tool/process_launcher_icon.py` |
| ?? | `tool/process_world_cup_badge.py` |

### Untracked — `.verify_run/` device dumps (60 files)

| Status | Path |
|--------|------|
| ?? | `.verify_run/home.png` |
| ?? | `.verify_run/home2_ui.xml` |
| ?? | `.verify_run/home_ui.xml` |
| ?? | `.verify_run/k_crash.txt` |
| ?? | `.verify_run/k_drawer.png` |
| ?? | `.verify_run/k_drawer.xml` |
| ?? | `.verify_run/k_home.xml` |
| ?? | `.verify_run/k_home_screen.png` |
| ?? | `.verify_run/k_icon_search.png` |
| ?? | `.verify_run/k_launcher2.png` |
| ?? | `.verify_run/k_nav.xml` |
| ?? | `.verify_run/k_search.png` |
| ?? | `.verify_run/k_set2.png` |
| ?? | `.verify_run/k_set2.xml` |
| ?? | `.verify_run/k_set3.png` |
| ?? | `.verify_run/k_set3.xml` |
| ?? | `.verify_run/k_settings.xml` |
| ?? | `.verify_run/k_settings4.png` |
| ?? | `.verify_run/k_settings5.png` |
| ?? | `.verify_run/k_settings5.xml` |
| ?? | `.verify_run/k_settings_final.png` |
| ?? | `.verify_run/k_settings_final.xml` |
| ?? | `.verify_run/k_splash2.png` |
| ?? | `.verify_run/k_sy_2160.png` |
| ?? | `.verify_run/k_sy_2185.png` |
| ?? | `.verify_run/k_sy_2210.png` |
| ?? | `.verify_run/k_sy_2235.png` |
| ?? | `.verify_run/k_sy_2260.png` |
| ?? | `.verify_run/k_tab_1.png` |
| ?? | `.verify_run/k_tab_2.png` |
| ?? | `.verify_run/k_tab_3.png` |
| ?? | `.verify_run/k_tab_4.png` |
| ?? | `.verify_run/k_tab_5.png` |
| ?? | `.verify_run/k_try_108.png` |
| ?? | `.verify_run/k_try_815.png` |
| ?? | `.verify_run/k_wc.xml` |
| ?? | `.verify_run/k_wc2.png` |
| ?? | `.verify_run/k_wc2.xml` |
| ?? | `.verify_run/launcher.png` |
| ?? | `.verify_run/settings.png` |
| ?? | `.verify_run/settings_ui.xml` |
| ?? | `.verify_run/splash.png` |
| ?? | `.verify_run/start.txt` |
| ?? | `.verify_run/test_nod.png` |
| ?? | `.verify_run/ui_cap.xml` |
| ?? | `.verify_run/wc3_home.png` |
| ?? | `.verify_run/wc3_hub.png` |
| ?? | `.verify_run/wc_badge_home.png` |
| ?? | `.verify_run/wc_badge_home2.png` |
| ?? | `.verify_run/wc_badge_hub.png` |
| ?? | `.verify_run/wc_badge_hub2.png` |
| ?? | `.verify_run/wc_crash.txt` |
| ?? | `.verify_run/wc_cup_home.png` |
| ?? | `.verify_run/wc_cup_hub.png` |
| ?? | `.verify_run/wc_final_home.png` |
| ?? | `.verify_run/wc_hub.xml` |
| ?? | `.verify_run/wc_ref_home.png` |
| ?? | `.verify_run/wc_ref_hub.png` |
| ?? | `.verify_run/worldcup.png` |
| ?? | `.verify_run/worldcup_ui.xml` |

### Created during this cleanup (not in the original dirty set)

| Status at end | Path | Notes |
|---------------|------|--------|
| committed | `.gitignore` | Narrow ignore rules added in this task |
| committed | `docs/reports/preflight-cleanup-arabic.md` | This report |
| restored | `android/gradle.properties` | Temporary heap settings for the AAB, then restored to HEAD |

Already gitignored before this task (class C; never staged): `android/key.properties`, `**/*.jks` / `**/*.keystore`, `**/google-services.json`, `lib/firebase_options.dart`, `backend/.env`, `/config/admob.local.json`. `android/local.properties` is machine-specific and was not in the dirty set.

## 4. Classification and disposition

Legend: **A** keep in Git · **B** generated / ignore · **C** sensitive / machine-specific · **D** ambiguous.

| Path | Class | Disposition |
|------|-------|-------------|
| `README.md` | A | Committed in `4654f10`. Package `com.sugarkeys.kickora`. |
| `android/app/src/main/res/values/strings.xml` | A | Committed in `4654f10`. `app_name` aligned to Arabic display name. Facebook placeholders were already tracked; not newly introduced. |
| `docs/privacy_policy.md` | A | Committed in `4654f10`. |
| `docs/release_checklist.md` | A | Committed in `4654f10`. |
| `firebase.json` | A | Committed in `4654f10`. Android `appId` suffix `20fb2a759f6b13439a5cf9` maps to `com.sugarkeys.kickora` (not the English client). |
| `lib/app/app_branding.dart` | A | Committed in `4654f10`. |
| `lib/utils/match_share_formatter.dart` | A | Committed in `4654f10`. Play URL `id=com.sugarkeys.kickora`. |
| `test/match_share_formatter_test.dart` | A | Committed in `4654f10`. |
| `assets/icon/app_icon.png` (deleted) | A | Not restored. Git recorded a 100% rename into `_deprecated_trophy/app_icon_trophy.png` (`44688ec`). |
| `assets/icon/play_store_icon_512.png` (deleted) | A | Same; renamed to `_deprecated_trophy/play_store_icon_trophy_512.png`. |
| `assets/icon/README.md` | A | Committed in `44688ec`. |
| `assets/icon/_deprecated_trophy/*` | A | Archive of obsolete trophy art. Committed in `44688ec`. |
| `assets/branding/README.md` | A | Committed in `44688ec`. Identity `com.sugarkeys.kickora`. |
| `assets/branding/final/README.md` | A | Committed in `44688ec`. |
| `assets/branding/placeholder/README.md` | A | Committed in `44688ec`. Folder documented as unused. |
| `assets/branding/final/feature_graphic_1024x500.png` | A | Committed in `81c1a8d`. Valid 1024×500 PNG. |
| `assets/branding/final/screenshots/01_home.png` … `05_standings.png` | A | Committed in `81c1a8d`. |
| `assets/branding/final/screenshots/home_world_cup_card.png` | A | Committed in `81c1a8d`. |
| `assets/branding/final/screenshots/world_cup_badge_on_dark.png` | A | Committed in `81c1a8d`. |
| `assets/branding/final/screenshots/world_cup_hub_header.png` | A | Committed in `81c1a8d`. |
| `lib/widgets/kickora_brand_mark.dart` | A | Committed in `81c1a8d`. Unused widget, legitimate source (not launcher art). |
| `release_notes/new_play_store_listing_ar.txt` | A | Committed in `81c1a8d`. Package `com.sugarkeys.kickora`. |
| `tool/generate_feature_graphic.py` | A | Committed in `81c1a8d`. |
| `tool/generate_neutral_launcher_assets.py` | A | Committed in `81c1a8d`. |
| `tool/inspect_launcher_icon.py` | A | Committed in `81c1a8d`. |
| `tool/process_launcher_icon.py` | A | Committed in `81c1a8d`. |
| `tool/process_world_cup_badge.py` | A | Committed in `81c1a8d`. |
| `.gitignore` | A | Committed in `fe84122`. Narrow rules only. |
| `docs/reports/preflight-cleanup-arabic.md` | A | This report. |
| `.verify_run/**` (60 files) | B | Ignored via `.verify_run/`. Left on disk. Not committed. |
| `backend/scripts/phase1-live-validation-output.txt` | B | Ignored via `backend/scripts/*-validation-output.txt`. |
| `assets/branding/final/app_icon_1024_NEUTRAL_TEMP.png` | B | Ignored via `*_NEUTRAL_TEMP.png`. |
| `assets/branding/final/screenshots/*.xml` | B | Ignored. |
| `assets/branding/final/screenshots/_test_matches.png` | B | Ignored via `_test_*.png`. |
| `assets/branding/final/screenshots/world_cup_badge_transparency_check.png` | B | Ignored via `*_transparency_check.png`. |
| `android/key.properties`, keystores, `google-services.json`, `local.properties` | C | Already ignored / not in dirty set. Not committed. No secret values printed. |
| `android/gradle.properties` | — | Temporary AAB heap/in-process compiler settings, then restored to HEAD. Not committed. |

No class **D** items required a guess. Trophy-icon deletion is explained in section 5.

## 5. Icon / asset decision and evidence

**Decision:** do **not** restore `assets/icon/app_icon.png` or `assets/icon/play_store_icon_512.png` as production files. They were obsolete trophy art, intentionally replaced by `assets/branding/final/`. Git stored them as a 100% rename into `assets/icon/_deprecated_trophy/`.

### Evidence

* `pubspec.yaml` `flutter.assets` lists only:
  * `assets/branding/final/app_icon_1024.png`
  * `assets/branding/final/play_store_icon_512.png`
  * `assets/images/world_cup_badge.png`
* `flutter_launcher_icons.image_path` / adaptive foreground: `assets/branding/final/app_icon_launcher_transparent.png`
* `AppBranding` production paths point at `assets/branding/final/`
* No remaining source references to `assets/icon/app_icon.png` or `assets/icon/play_store_icon_512.png` except the already-tracked one-off script `tool/remove_icon_watermark.dart` (stale local default output paths; not used by the Flutter build)
* Android launcher resources present and packaged in the AAB:
  * `mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png` (48 / 72 / 96 / 144 / 192)
  * `drawable-*/ic_launcher_foreground.png`
  * `mipmap-anydpi-v26/ic_launcher.xml` + `ic_launcher_round.xml` with background `#1A6B34`
* Signed AAB flutter assets include the three pubspec files above; **no** `assets/icon/` trophy files

### Production files verified present

| File | Notes |
|------|--------|
| `assets/branding/final/app_icon_1024.png` | Already tracked. Packaged in AAB. File bytes are JFIF/JPEG despite `.png` name (pre-existing; not modified here). |
| `assets/branding/final/play_store_icon_512.png` | 512×512 PNG, already tracked, packaged in AAB. |
| `assets/branding/final/app_icon_launcher_transparent.png` | 1024×1024 PNG, already tracked, launcher source. |
| `assets/branding/final/feature_graphic_1024x500.png` | 1024×500 PNG, newly committed. |
| `assets/images/world_cup_badge.png` | 1024×1024 PNG, already tracked, packaged in AAB. |

No new logo was invented. No World Cup UX redesign.

## 6. Package identity verification

| Check | Result |
|-------|--------|
| `android/app/build.gradle.kts` `namespace` | `com.sugarkeys.kickora` |
| `android/app/build.gradle.kts` `applicationId` | `com.sugarkeys.kickora` |
| MainActivity package | `com.sugarkeys.kickora` |
| Share / Play URL | `play.google.com/store/apps/details?id=com.sugarkeys.kickora` |
| AAB binary manifest strings | `com.sugarkeys.kickora` **PRESENT**; `com.kickora.worldcup` **ABSENT**; `com.kickora.live` **ABSENT** |
| AAB zip paths | no `com/kickora/worldcup` or `com/kickora/live` |
| AAB `MainActivity` | `com.sugarkeys.kickora.MainActivity` |
| AAB versionName | `1.0.15` |

## 7. Billing version verification

| Check | Result |
|-------|--------|
| `pubspec.yaml` | `in_app_purchase: ^3.3.0` |
| `pubspec.lock` | `in_app_purchase 3.3.0` → `in_app_purchase_android 0.5.0` |
| AAB `base/root/billing.properties` | `version=8.0.0` / `billing_client=8.0.0` |
| AAB manifest | `com.google.android.play.billingclient.version` **PRESENT**; `8.0.0` **PRESENT**; `7.1.1` **ABSENT**; `com.android.vending.BILLING` **PRESENT** |

No Gradle `resolutionStrategy` force was added. Billing was not downgraded.

## 8. Analyze / test / build results

| Check | Result |
|-------|--------|
| `flutter pub get` | Success |
| `dart format` on touched Dart | 0 files changed |
| `flutter analyze` | **9 infos, 0 warnings, 0 errors** (same pre-existing set; analyzer exit code 1 because infos are reported) |
| `flutter test` | **154 passed**, 0 failed |
| Version bump | **None** — still `1.0.15+16` |

Analyze infos (unchanged, not introduced by this cleanup):

* dangling library doc comments: `lib/app/app_branding.dart`, `lib/core/world_cup/world_cup_stadiums.dart`
* unnecessary underscores in World Cup widgets
* `depend_on_referenced_packages` in already-tracked `tool/remove_icon_watermark.dart`

The signed AAB used a temporary `android/gradle.properties` heap reduction (`-Xmx2048m`, Kotlin in-process, daemon off) because the local JDK could not reserve the default 8G heap. The file was restored to HEAD afterward and was not committed.

## 9. Validation-only signed AAB

**Not a new Play version.** Same `1.0.15` / versionCode `16` as the current released/tested identity. Do not treat this rebuild as a store version bump.

| Field | Value |
|-------|--------|
| Absolute path | `C:\Users\user\Desktop\Apps\Cursor Apps\Kickoras apps\Kickora Arabic\kickora\build\app\outputs\bundle\release\app-release.aab` |
| Package / application ID | **`com.sugarkeys.kickora`** |
| versionName | `1.0.15` |
| versionCode | `16` |
| Size | 57,260,786 bytes (Flutter reported 54.6MB) |
| Local timestamp | 2026-09-19 13:06:31 +03:00 |
| SHA-256 | `B6DCB5ACA074D33029FD10D9C0168975308315AB2242C3D1C306A8E0C2B0C0F2` |
| Signing | `jarsigner -verify` → **jar verified.** Self-signed upload cert (expected). |
| Signer DN | `CN=Adli Abu Faza, OU=Kickora, O=Sugerkeys apps, L=Amman, ST=Jordan, C=JO` |
| Signer cert SHA-256 | `7A:BA:8F:40:F4:36:F1:A3:5F:5D:3A:23:E6:B3:11:CF:8E:E0:28:11:5B:AD:E5:49:30:6B:26:8E:06:1F:4B:B4` |
| Dart defines | `KICKORA_API_MODE=backend`, `KICKORA_BACKEND_URL=https://kickora-aoi0.onrender.com` |
| Committed? | **No** (`/build/` is gitignored) |

## 10. Commit hashes and push result

Cleanup commits on `main` (after starting HEAD `2e4784a`):

| Hash | Message |
|------|---------|
| `4654f10` | Align Arabic docs and share identity to com.sugarkeys.kickora |
| `fe84122` | Ignore local verification dumps and generated branding artifacts |
| `44688ec` | Retire unused trophy icons and document branding replacements |
| `81c1a8d` | Add Play listing graphics, screenshots, and branding tooling |
| `7137635` | Document Arabic preflight cleanup |

Push (no force):

```
To https://github.com/adlifazaa/kickora.git
   2e4784a..7137635  HEAD -> main
```

Remote is the Arabic repository. Branch `main` tracks `origin/main`.

## 11. Remaining risks / manual actions

* `KickoraBrandMark` is committed but unused. Harmless; wire it up only if a later UI task needs it.
* Tracked `tool/remove_icon_watermark.dart` still defaults to old `assets/icon/` output paths. It is not part of the app build. Leave it unless a later tooling cleanup is requested.
* Tracked `assets/branding/final/app_icon_1024.png` is JPEG/JFIF bytes with a `.png` filename. Pre-existing; Play hi-res icon remains the real 512 PNG. Do not silently rewrite branding in a feature task.
* `.verify_run/`, validation output, and temp branding dumps remain on the local disk (gitignored). They can be deleted locally anytime; they will not reappear in `git status`.
* Analyzer still reports 9 pre-existing infos.
* The validation AAB is local-only. Upload to Play only when a real versioned release is intended.
* Facebook App ID / client token strings were already in tracked `strings.xml` before this cleanup; they were not added here.

## 12. Final git status

```
## main...origin/main
```

`git status --short` is empty. Working tree clean.
