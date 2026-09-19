# Current football focus + Premium/News update — Arabic Kickora

**Final status: PASS** (source + tests + signed AAB copied). Play Console upload remains manual.

## Confirmed app / package identity

| Item | Value |
| --- | --- |
| Repository path | `C:\Users\user\Desktop\Apps\Cursor Apps\Kickoras apps\Kickora Arabic\kickora` |
| Git branch | `main` |
| Origin (push) | `https://github.com/adlifazaa/kickora.git` |
| Application ID / namespace | `com.sugarkeys.kickora` |
| Version in `pubspec.yaml` | `1.0.16+17` (bumped from `1.0.15+16`) |
| English package (not used here) | `com.kickora.live` |

Identity evidence:

- `android/app/build.gradle.kts`: `namespace = "com.sugarkeys.kickora"`, `applicationId = "com.sugarkeys.kickora"`
- `android/app/google-services.json` includes client `com.sugarkeys.kickora` (existing multi-client Firebase file; not copied from English and not edited)
- Signed AAB `base/manifest/AndroidManifest.xml` contains `com.sugarkeys.kickora`, `versionName` `1.0.16`, `versionCode` `17`
- Same manifest does **not** contain `com.kickora.live` or `com.kickora.worldcup`
- Signed AAB `base/root/billing.properties`: `version=8.0.0` / `billing_client=8.0.0`
- AAB signed by Signflinger (`META-INF/UPLOAD.SF`, `META-INF/UPLOAD.RSA`, `META-INF/MANIFEST.MF`)

No Android identity, Firebase, or signing files were copied from the English app. The English repository and English AAB were not modified.

## Completed requirements

- World Cup is no longer pinned on Home, Competitions, featured-match selection, or primary navigation.
- Home **أهم البطولات** ranks live API competitions: live now → matches today → upcoming within 7 days → popularity. Cap is 5. Name-first matching.
- Featured match order: major live → any live → major upcoming (48h) → any upcoming → major finished → fallback.
- News user copy: `الأخبار غير متاحة مؤقتًا، حاول مرة أخرى لاحقًا.` Technical diagnostics stay out of the UI.
- Premium: Settings no longer hardcodes `غير متوفر`. The row navigates to `AppRoutes.premium`. `PlayBillingBridge.create()` is attached via `controller.completeBillingSetup` after startup. Store UI maps loading / currently unavailable / connection error. Product remains `kickora_premium_yearly`. No fake unlock.
- Classification: **MIXED_CODE_AND_CONSOLE_ACTION** — local sideload cannot prove Play Console product/offer configuration.
- `in_app_purchase` `3.3.0` with pinned `in_app_purchase_android: 0.5.0`.

## Files changed

Modified:

- `lib/app/app_text.dart`
- `lib/app/routes.dart`
- `lib/core/world_cup/world_cup_priority.dart`
- `lib/data/repositories/football_repository.dart`
- `lib/data/services/api_football_parser.dart`
- `lib/main.dart`
- `lib/screens/competition_details_screen.dart`
- `lib/screens/competitions_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/matches_screen.dart`
- `lib/screens/premium_screen.dart`
- `lib/screens/settings_screen.dart`
- `lib/screens/world_cup/world_cup_news_tab.dart`
- `lib/services/app_controller.dart`
- `lib/subscription/play_billing_bridge.dart`
- `lib/subscription/premium_service.dart`
- `lib/subscription/premium_subscription_service.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `test/premium_screen_test.dart`
- `test/world_cup_priority_test.dart`

Added:

- `lib/core/competition/competition_name_normalizer.dart`
- `lib/core/competition/competition_priority_resolver.dart`
- `lib/core/competition/popular_competition_catalog.dart`
- `lib/core/match/featured_match_selector.dart`
- `lib/core/news/news_user_messages.dart`
- `lib/subscription/premium_store_status.dart`
- `lib/widgets/top_competitions_module.dart`
- `test/competition_priority_resolver_test.dart`
- `test/current_football_focus_navigation_test.dart`
- `test/featured_match_selector_test.dart`
- `test/news_user_messages_test.dart`
- `test/premium_store_status_test.dart`
- `docs/reports/current-football-focus-premium-update.md` (this file)

## Validation

Analyze and test were **not re-run** because source files were unchanged since the recorded successful results.

| Check | Result |
| --- | --- |
| `flutter analyze` | 7 **pre-existing info** findings in untouched World Cup/tool files; no new errors in changed files |
| `flutter test` | **181** passed |
| Device QA | SKIPPED — do not overwrite the Play-installed build on the connected phone |
| Signed AAB | **Built, copied, and verified** |

Pre-existing analyzer infos (not fixed; unrelated):

- `dangling_library_doc_comments` in `lib/app/app_branding.dart`, `lib/core/world_cup/world_cup_stadiums.dart`
- `unnecessary_underscores` in World Cup hub/stadium widgets
- `depend_on_referenced_packages` in `tool/remove_icon_watermark.dart`

## Signed AAB

`flutter build appbundle --release` succeeded with Gradle user cache on `D:\DevCaches\gradle` (`C:\Users\user\.gradle` junction). Disposable `build/` was removed after the stable copy.

| Item | Value |
| --- | --- |
| Gradle output | `build\app\outputs\bundle\release\app-release.aab` (54.4 MB) |
| Stable copy | `C:\Users\user\Desktop\Apps\Cursor Apps\Kickoras apps\release_artifacts\kickora-arabic-1.0.16-17.aab` |
| Size | 57,041,784 bytes (54.4 MB) |
| SHA-256 | `0A88E0BFA5E2787C5ABD3915FF5E9CFC4DBBE8EF293257FCCD0F75F8F9406B9B` |
| Package | `com.sugarkeys.kickora` |
| versionName | `1.0.16` |
| versionCode | `17` |
| Play Billing | `8.0.0` |
| Signing | Signflinger release (`META-INF/UPLOAD.RSA`) |

English AAB still present at `C:\Users\user\Desktop\Apps\Cursor Apps\Kickoras apps\release_artifacts\kickora-english-1.0.21-22.aab`.

## Disk space

| Checkpoint | C: free | D: free |
| --- | --- | --- |
| Preflight | 24.25 GB | 7.37 GB |
| During Gradle (lowest observed) | 22.51 GB | 7.34 GB |
| After AAB copy | 22.71 GB | 7.35 GB |
| After deleting disposable Arabic `build/` | 24.16 GB | 7.35 GB |

Floors (C: 8 GB / D: 2 GB) were not crossed. Gradle/Pub caches were not cleaned.

## Git commit / push

Identity, diff, tests (recorded), version `1.0.16+17`, AAB copy, and destination remote were verified before commit. Push target is `origin` = `https://github.com/adlifazaa/kickora.git` only.

## Remaining warnings / manual checks

- Play Console upload is still a manual step.
- Premium on a sideload cannot prove Play Console product/offer configuration.
- World Cup hub screens still exist for deep/legacy use; they are no longer featured on Home/Competitions/navigation.
