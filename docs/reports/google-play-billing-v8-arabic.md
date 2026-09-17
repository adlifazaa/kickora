# Google Play Billing Library 8 — Arabic Kickora

## 1. Final status

**PASS**

The signed production AAB for `com.kickora.worldcup` contains Google Play Billing Library **8.0.0**, with no Billing Client artifact below 8.0.0. Analyze/tests/build/signing/AAB inspection all completed successfully enough to ship this compliance fix.

`flutter analyze` reported 9 pre-existing **info** lints (0 errors, 0 warnings), none in billing code. Full `flutter test` passed **154/154**.

## 2. Confirmed Arabic app identity

| Item | Value |
|------|--------|
| Absolute path | `C:\Users\user\Desktop\Apps\Cursor Apps\Kickoras apps\Kickora Arabic\kickora` |
| Branch | `main` |
| HEAD at task start | `6d720f8d94300e774279d08a226f9c5dee1cad54` |
| Application ID / namespace | `com.kickora.worldcup` (committed Gradle + release AAB) |
| English package | `com.kickora.live` — **not present** in the AAB application identity or AAB paths |
| Remote | `https://github.com/adlifazaa/kickora.git` |

Identity gate: this repository **is** the Arabic app. Committed Gradle used `com.kickora.worldcup`. The working tree had unrelated dirty edits that temporarily set `applicationId`/`namespace` to `com.sugarkeys.kickora`; those Gradle identity edits were restored to the committed Arabic ID before the production AAB was built. They were **not** committed as part of this Billing task. The English project was not modified.

Untracked leftover from prior branding work remains: `android/app/src/main/kotlin/com/sugarkeys/` (not used by the release namespace).

## 3. Root cause

The Arabic app uses Flutter `in_app_purchase` for Premium (`kickora_premium_yearly`). It does **not** use RevenueCat or a custom Billing wrapper.

**Before (proven independently on this repo, not copied from English):**

* `pubspec.yaml`: `in_app_purchase: ^3.2.0`
* `pubspec.lock` / `flutter pub deps`: `in_app_purchase 3.2.3` → `in_app_purchase_android 0.4.0+10`
* Plugin Gradle: `com.android.billingclient:billing:7.1.1`
* `:app:dependencyInsight --configuration releaseRuntimeClasspath --dependency com.android.billingclient`:

```
com.android.billingclient:billing:7.1.1
\--- project :in_app_purchase_android
     \--- releaseRuntimeClasspath
```

No product flavors. Production runtime classpath is `releaseRuntimeClasspath`.

Purchase functionality is actively used via high-level APIs only (`isAvailable`, `queryProductDetails`, `buyNonConsumable`, `restorePurchases`, `completePurchase`). The app does **not** call `queryPurchaseHistory` / `queryPurchaseHistoryAsync` or other low-level Billing Client wrappers, so the 0.5.0 breaking removal of purchase-history APIs does not affect this codebase.

`com.android.vending.BILLING` is present because Premium/IAP remains enabled.

## 4. Fix

| Package | Before | After |
|---------|--------|--------|
| Constraint `in_app_purchase` | `^3.2.0` | `^3.3.0` |
| Resolved `in_app_purchase` | `3.2.3` | `3.3.0` |
| Resolved `in_app_purchase_android` | `0.4.0+10` | `0.5.0` |
| `com.android.billingclient:billing` | `7.1.1` | `8.0.0` |

This is the **smallest supported parent-plugin upgrade** that ships Billing 8.0.0:

* `in_app_purchase 3.3.0` depends on `in_app_purchase_android: ^0.5.0`
* `in_app_purchase_android 0.5.0` changelog: Billing Library 7.1.1 → **8.0.0**
* SDK requirement (`Dart ^3.10`, `Flutter >=3.38`) matches this machine (`Dart 3.11.5`, `Flutter 3.41.9`)
* `flutter pub get` changed **only** those two packages (lockfile +4/−4)
* No Gradle `resolutionStrategy`, force, AAR swap, or transitive override
* Unrelated dependencies were not upgraded
* Product IDs, entitlements, restore behavior, AdMob, Firebase, and API-FOOTBALL/backend config were not changed

## 5. Billing verification

### Release runtime classpath

```
com.android.billingclient:billing:8.0.0
\--- project :in_app_purchase_android
     \--- releaseRuntimeClasspath
```

Release tree (filtered):

```
+--- project :in_app_purchase_android
|    +--- com.android.billingclient:billing:8.0.0
```

### All Billing artifacts

* `com.android.billingclient:billing:8.0.0` — present
* `billing-ktx` — absent
* Any Billing Client `< 8.0.0` — absent
* No Gradle force / resolution strategy

### Merged release manifest

File: `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`

* Package: `com.kickora.worldcup`
* `versionName` `1.0.15` / `versionCode` `16`
* `com.google.android.play.billingclient.version` = `8.0.0`
* `com.android.vending.BILLING` present
* English package `com.kickora.live` not used as application identity

### Final signed AAB

Same Billing 8.0.0 evidence inside the AAB itself (see §11). **PASS is based on the AAB, not only Gradle.**

## 6. Billing permission status and why

**Kept.** `com.android.vending.BILLING` remains because Kickora Premium still uses Play Billing (`in_app_purchase`, product `kickora_premium_yearly`). Removing it would only hide the Play policy signal; it would not be a valid compliance fix.

## 7. Version bump

| | versionName | versionCode | pubspec |
|--|-------------|-------------|---------|
| Committed before this task | `1.0.13` | `14` | `1.0.13+14` |
| Uncommitted dirty pubspec observed at start | `1.0.14` | `15` | `1.0.14+15` |
| This Billing release | `1.0.15` | `16` | `1.0.15+16` |

Highest **reliable local** versionCode: **15** (uncommitted working tree) / **14** (last committed). This release uses **16**, strictly greater than both.

**Limitation (flagged):** the highest versionCode already uploaded to Google Play Console could not be proven from this machine. If Play Console already has a code ≥ 16, bump again before production rollout.

Do **not** reuse English `1.0.20+21`; that version is not this app.

## 8. Files modified and reason

| File | Reason |
|------|--------|
| `pubspec.yaml` | Raise `in_app_purchase` to `^3.3.0`; bump version to `1.0.15+16` |
| `pubspec.lock` | Resolve `in_app_purchase 3.3.0` and `in_app_purchase_android 0.5.0` only |
| `docs/reports/google-play-billing-v8-arabic.md` | This report |

Local-only, **not committed**:

* `android/local.properties` `sdk.dir` corrected to `D:\Android\Sdk` (gitignored)
* Temporary `android/gradle.properties` heap reduction for the AAB build, then restored to the original `-Xmx8G` file
* Working-tree Gradle `applicationId`/`namespace` restored to `com.kickora.worldcup` so the AAB matched Arabic store identity (same as HEAD; no Gradle commit)

## 9. Verification results

| Check | Result |
|-------|--------|
| `flutter pub get` | Success. Changed 2 dependencies only (`in_app_purchase`, `in_app_purchase_android`) |
| Formatting | **N/A** — no Dart source changed for this task |
| `flutter analyze` | 9 **info** lints, 0 errors, 0 warnings. All pre-existing (`app_branding.dart` dangling doc, World Cup unused `_` binds, `tool/remove_icon_watermark.dart` `image` import). None introduced by Billing. Exit code 1 because infos are reported. |
| `flutter test` | **154 passed**, 0 failed (`All tests passed!`) |
| Android unit tests | None in this app (`android/**/src/test` empty) |
| Gradle insight after fix | Billing `8.0.0` via `:in_app_purchase_android` |
| Package remains | `com.kickora.worldcup` |

First `flutter test` attempt failed because `%PROGRAMFILES(X86)%` was unset on this Windows image (Flutter Visual Studio probe). Tests were rerun after setting the standard `C:\Program Files (x86)` path; that is an environment workaround, not an app change.

## 10. Signed production AAB

| Field | Value |
|-------|--------|
| Absolute path | `C:\Users\user\Desktop\Apps\Cursor Apps\Kickoras apps\Kickora Arabic\kickora\build\app\outputs\bundle\release\app-release.aab` |
| Package | `com.kickora.worldcup` |
| versionName | `1.0.15` |
| versionCode | `16` |
| Size | 57,260,752 bytes (54.61 MB; Flutter reported 54.6MB) |
| Local timestamp | 2026-09-17 15:24:27 +03:00 |
| UTC timestamp | 2026-09-17 12:24:27 UTC |
| SHA-256 | `B1A70177043087C2A45F57BE561BC7029AC39C0B97AAABE6807696D3AD5278A3` |
| Signing | `jarsigner -verify` → **jar verified.** Upload key is self-signed (expected for Play upload certs). AAB JarInputStream warnings are format-typical and not a verification failure. |
| Signer DN | `CN=Adli Abu Faza, OU=Kickora, O=Sugerkeys apps, L=Amman, ST=Jordan, C=JO` |
| Signer cert SHA-256 | `7A:BA:8F:40:F4:36:F1:A3:5F:5D:3A:23:E6:B3:11:CF:8E:E0:28:11:5B:AD:E5:49:30:6B:26:8E:06:1F:4B:B4` |
| Signer cert SHA-1 | `6A:E8:1C:BA:03:6D:C8:9A:99:0D:74:F5:B1:80:87:F1:2A:7A:59:47` |
| Cert validity | 2026-05-17 → 2053-10-02 |

The AAB was **not** committed.

## 11. Final AAB Billing evidence

Inspected the signed AAB zip entries (not only Gradle):

* `base/root/billing.properties`:

```
version=8.0.0
client=billing
billing_client=8.0.0
```

* `base/manifest/AndroidManifest.xml` binary strings:
  * `com.kickora.worldcup` **PRESENT**
  * `com.kickora.live` **ABSENT**
  * `com.sugarkeys.kickora` **ABSENT**
  * `com.google.android.play.billingclient.version` **PRESENT**
  * `8.0.0` **PRESENT**
  * `7.1.1` **ABSENT** (also no zip entry whose bytes contained `7.1.1` together with billing)
  * `com.android.vending.BILLING` **PRESENT**
* English package paths in the AAB: **none**

## 12. Production build configuration

Command:

```bash
flutter build appbundle --release --dart-define=KICKORA_API_MODE=backend --dart-define=KICKORA_BACKEND_URL=https://kickora-aoi0.onrender.com
```

This matches `ApiConstants.productionBackendUrl` and release policy (`ApiReleasePolicy` always uses backend proxy in release). No `KICKORA_API_KEY` dart-define was passed.

Gradle `-Pdart-defines` for this build decoded to `KICKORA_API_MODE=backend` and `KICKORA_BACKEND_URL=https://kickora-aoi0.onrender.com` plus Flutter version metadata only.

`libapp.so` string scan: `KICKORA_API_KEY=` **not** present; no private API-Football key was deliberately embedded by the build configuration.

Temporary local Gradle heap reduction was required because the default `-Xmx8G` Kotlin daemon failed (`Could not reserve enough space for object heap` / paging file). `android/gradle.properties` was restored to the original 8G settings after the AAB succeeded.

## 13. Git

| Item | Value |
|------|--------|
| Implementation commit | `b2877907076af5c26044ef8368cd7311428c203d` |
| Report commit | *(this file’s commit on `main`; see `git log -1 -- docs/reports/google-play-billing-v8-arabic.md`)* |
| Push | To be recorded after `git push` to `origin` (`https://github.com/adlifazaa/kickora.git`), branch `main`. Remote was `origin/main` behind local by 3 commits at task start (not diverged). |

Remaining **unrelated** dirty/untracked files (preserved, not committed):

* Modified: `README.md`, `android/app/src/main/res/values/strings.xml`, `docs/privacy_policy.md`, `docs/release_checklist.md`, `firebase.json`, `lib/app/app_branding.dart`, `lib/utils/match_share_formatter.dart`, `test/match_share_formatter_test.dart`
* Deleted: `assets/icon/app_icon.png`, `assets/icon/play_store_icon_512.png`
* Untracked: `.verify_run/`, `android/app/src/main/kotlin/com/sugarkeys/`, branding/icon tooling, `lib/widgets/kickora_brand_mark.dart`, `release_notes/new_play_store_listing_ar.txt`, `backend/scripts/phase1-live-validation-output.txt`

Not committed: AAB, keystore, `key.properties`, `google-services.json`, `local.properties`, heap dumps.

## 14. Manual Google Play steps

These were **not** performed by this task (no Play Console upload):

1. Upload `app-release.aab` to the **Arabic** Play Console app for **`com.kickora.worldcup`** (not the English `com.kickora.live` app).
2. Release to **internal testing** first.
3. Device smoke test: launch, Premium purchase, restore, live scores via backend.
4. Promote to production when internal testing is clean.
5. Confirm the Play Billing Library policy warning clears for this package.

If Play Console already has versionCode ≥ 16, bump `pubspec.yaml` and rebuild before upload.

## 15. Risks / follow-up

* **Device-level purchase/restore smoke test is still required** on a real Play-licensed Android device with the internal-testing track. This run did not exercise the Play Billing UI on a device.
* `in_app_purchase_android` 0.5.0 removes `queryPurchaseHistory`. This app does not call it; still smoke-test restore.
* Local Play Console versionCode is unproven; do not assume 16 is free on the store.
* Unrelated dirty branding/identity work (including an untracked `com.sugarkeys.kickora` MainActivity and docs that mention that package) must **not** be mixed into this Billing upload. The AAB itself is `com.kickora.worldcup`.
* Local `google-services.json` (gitignored) contains multiple `package_name` clients including `com.kickora.live` and `com.sugarkeys.kickora` in addition to `com.kickora.worldcup`. That file was not modified. The AAB application ID is still `com.kickora.worldcup`.
* Any unrelated app suspension or other Play policy issue is **out of scope** and must be reported separately. This update only addresses Billing Library 8 compliance.
* Device compatibility of this AAB: `minSdk` 24, `targetSdk` 36, ABIs `arm64-v8a` / `armeabi-v7a` / `x86_64`. No compatibility refactor was done. 32-bit x86 is not included (standard Flutter release). No evidence this unexpectedly removes support versus current Flutter Android defaults.

## Tooling snapshot (task start)

* Flutter 3.41.9 (stable) / Dart 3.11.5
* Android SDK: `D:\Android\Sdk` (SDK 36.1.0)
* Java: Android Studio JBR 21 for Gradle; Temurin 17 also present
* Git: `main` tracking `origin/main`, ahead 3 at start
