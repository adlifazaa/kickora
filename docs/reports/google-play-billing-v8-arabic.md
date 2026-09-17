# Google Play Billing Library 8 — Arabic Kickora

## 1. Final status

**PASS** (package identity corrected)

The **authoritative Google Play Console package** for this Arabic app is:

**`com.sugarkeys.kickora`**

The previous signed AAB used `com.kickora.worldcup` and was **rejected by Google Play Console** with:

> Your APK or Android App Bundle needs to have the package name com.sugarkeys.kickora

That earlier identity decision was wrong. Uncommitted `com.sugarkeys.kickora` work was the intended Play package, not leftover branding. This correction rebuilds and verifies a signed production AAB as **`com.sugarkeys.kickora`**, while **preserving Billing Library 8.0.0**.

Do **not** use `com.kickora.worldcup` or `com.kickora.live` for this Play app.

The corrected AAB contains Billing **8.0.0** and no Billing Client below 8.0.0.

## 2. Confirmed Arabic app identity

| Item | Value |
|------|--------|
| Absolute path | `C:\Users\user\Desktop\Apps\Cursor Apps\Kickoras apps\Kickora Arabic\kickora` |
| Branch | `main` |
| Authoritative Play package | **`com.sugarkeys.kickora`** |
| Namespace / applicationId | `com.sugarkeys.kickora` |
| MainActivity | `package com.sugarkeys.kickora` at `android/app/src/main/kotlin/com/sugarkeys/kickora/MainActivity.kt` |
| Obsolete package | `com.kickora.worldcup` — removed as application identity (Play rejected it) |
| English package | `com.kickora.live` — **not used**, absent from AAB application identity |
| Remote | `https://github.com/adlifazaa/kickora.git` |

Local `google-services.json` (gitignored, not printed) contains a client for `com.sugarkeys.kickora`. The Google Services plugin selects that client from `applicationId`. The file also lists other clients; they were not copied from the English project and were not modified.

## 3. Root cause (Billing) and identity mistake

### Billing (unchanged, still required)

The Arabic app uses Flutter `in_app_purchase` for Premium (`kickora_premium_yearly`).

**Original Billing path (before the v8 upgrade):**

* `in_app_purchase: ^3.2.0` → resolved `3.2.3`
* `in_app_purchase_android 0.4.0+10`
* `com.android.billingclient:billing:7.1.1` via `:in_app_purchase_android`

**Supported fix (already committed, preserved):**

* `in_app_purchase: ^3.3.0` → `3.3.0`
* `in_app_purchase_android 0.5.0`
* Billing Client **8.0.0**
* No Gradle `resolutionStrategy` / force

### Identity mistake (corrected here)

A previous run treated working-tree `com.sugarkeys.kickora` as unrelated and rebuilt the AAB as `com.kickora.worldcup`. Play Console rejected that AAB because the live Arabic store listing is **`com.sugarkeys.kickora`**.

## 4. Identity correction

| Component | Before (rejected) | After (Play-required) |
|-----------|-------------------|------------------------|
| `namespace` | `com.kickora.worldcup` | `com.sugarkeys.kickora` |
| `applicationId` | `com.kickora.worldcup` | `com.sugarkeys.kickora` |
| MainActivity package | `com.kickora.worldcup` | `com.sugarkeys.kickora` |
| MainActivity path | `.../kotlin/com/kickora/worldcup/MainActivity.kt` | `.../kotlin/com/sugarkeys/kickora/MainActivity.kt` |
| Duplicate launcher | both packages present in tree | only `com.sugarkeys.kickora` remains |

The untracked `android/app/src/main/kotlin/com/sugarkeys/kickora/MainActivity.kt` was the correct file and is now the sole `MainActivity`. The obsolete `com.kickora.worldcup` MainActivity was deleted so `.MainActivity` cannot resolve to two classes.

Billing / version files were **not** reverted: `in_app_purchase 3.3.0`, android `0.5.0`, pubspec `1.0.15+16`.

## 5. Billing verification (after identity correction)

Release runtime classpath:

```
com.android.billingclient:billing:8.0.0
\--- project :in_app_purchase_android
     \--- releaseRuntimeClasspath
```

* `billing-ktx` absent
* No Billing Client `< 8.0.0`
* No Gradle force

### Merged release manifest

`build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`

* `package="com.sugarkeys.kickora"`
* `versionCode="16"` / `versionName="1.0.15"`
* `android:name="com.sugarkeys.kickora.MainActivity"`
* `com.google.android.play.billingclient.version` = `8.0.0`
* `com.android.vending.BILLING` present
* `com.kickora.worldcup` / `com.kickora.live` not used as application identity

## 6. Billing permission

**Kept.** Premium still uses Play Billing.

## 7. Version

Kept **versionName `1.0.15` / versionCode `16`**. The rejected `com.kickora.worldcup` upload did not consume versionCode 16 for `com.sugarkeys.kickora`.

## 8. Files modified for this correction

| File | Reason |
|------|--------|
| `android/app/build.gradle.kts` | `namespace` + `applicationId` → `com.sugarkeys.kickora` |
| `android/app/src/main/kotlin/com/sugarkeys/kickora/MainActivity.kt` | Canonical MainActivity (previously untracked, correct package) |
| `android/app/src/main/kotlin/com/kickora/worldcup/MainActivity.kt` | Removed obsolete package/path |
| `docs/reports/google-play-billing-v8-arabic.md` | Document Play rejection and corrected AAB evidence |

Already on `main` from the Billing task (not reverted): `pubspec.yaml`, `pubspec.lock`.

## 9. Verification results (this correction)

| Check | Result |
|-------|--------|
| `flutter pub get` | Success. Billing packages unchanged (`in_app_purchase 3.3.0`, android `0.5.0`) |
| Formatting | N/A for identity Kotlin (existing 5-line MainActivity kept as-is) |
| `flutter analyze` | 0 errors, 0 warnings, 9 pre-existing infos (same as before) |
| `flutter test` | **154 passed**, 0 failed |
| Android unit tests | None in this app |
| Gradle insight | Billing `8.0.0` via `:in_app_purchase_android` |

## 10. Corrected signed production AAB

| Field | Value |
|-------|--------|
| Absolute path | `C:\Users\user\Desktop\Apps\Cursor Apps\Kickoras apps\Kickora Arabic\kickora\build\app\outputs\bundle\release\app-release.aab` |
| Package / application ID | **`com.sugarkeys.kickora`** |
| versionName | `1.0.15` |
| versionCode | `16` |
| Size | 57,260,789 bytes (54.61 MB; Flutter reported 54.6MB) |
| Local timestamp | 2026-09-17 15:53:20 +03:00 |
| UTC timestamp | 2026-09-17 12:53:20 UTC |
| SHA-256 | `8FFDB141B075F1F1A354377E230F944A62F43251656C56DBE78DBEC77DE36C04` |
| Signing | `jarsigner -verify` → **jar verified.** Self-signed upload cert (expected). |
| Signer DN | `CN=Adli Abu Faza, OU=Kickora, O=Sugerkeys apps, L=Amman, ST=Jordan, C=JO` |
| Signer cert SHA-256 | `7A:BA:8F:40:F4:36:F1:A3:5F:5D:3A:23:E6:B3:11:CF:8E:E0:28:11:5B:AD:E5:49:30:6B:26:8E:06:1F:4B:B4` |

The AAB was **not** committed.

### Rejected previous AAB (do not upload)

| Field | Value |
|-------|--------|
| Package | `com.kickora.worldcup` (rejected by Play) |
| SHA-256 | `B1A70177043087C2A45F57BE561BC7029AC39C0B97AAABE6807696D3AD5278A3` |
| Play message | needs package name `com.sugarkeys.kickora` |

## 11. Final AAB Billing + identity evidence

Inspected the **corrected** signed AAB zip (not only Gradle):

`base/root/billing.properties`:

```
version=8.0.0
client=billing
billing_client=8.0.0
```

`base/manifest/AndroidManifest.xml` binary strings:

* `com.sugarkeys.kickora` **PRESENT** (application identity)
* `com.kickora.worldcup` **ABSENT** as application identity
* `com.kickora.live` **ABSENT**
* `com.google.android.play.billingclient.version` **PRESENT**
* `8.0.0` **PRESENT**
* `7.1.1` **ABSENT**
* `com.android.vending.BILLING` **PRESENT**

No zip paths for `com.kickora.live` or `com/kickora/worldcup`.

## 12. Production build configuration

```bash
flutter build appbundle --release --dart-define=KICKORA_API_MODE=backend --dart-define=KICKORA_BACKEND_URL=https://kickora-aoi0.onrender.com
```

No `KICKORA_API_KEY` dart-define. Temporary local Gradle heap reduction was used again, then `android/gradle.properties` was restored to the original `-Xmx8G` settings (not committed).

## 13. Git

| Item | Value |
|------|--------|
| Original Billing implementation | `b2877907076af5c26044ef8368cd7311428c203d` |
| Identity correction commit | `23aca45d63a16ecbd114fd76926abb4ee91daf95` |
| Updated report commit | `50002a86996062003834f73b6e870639ff4a5981` |
| Push | Arabic `origin/main` `https://github.com/adlifazaa/kickora.git` |

## 14. Manual Google Play steps

**Not performed here** (no Console upload):

1. Upload **this** AAB to the Arabic Play Console app for **`com.sugarkeys.kickora`**.
2. Do **not** upload it to `com.kickora.live` or treat `com.kickora.worldcup` as the store ID.
3. Internal testing first, then device smoke test (launch, Premium purchase/restore).
4. Production when internal testing is clean.
5. Confirm the Billing Library 8 policy warning clears.

## 15. Risks / follow-up

* Device-level purchase/restore smoke test is still required.
* Other Play policy/suspension issues are out of scope for this Billing + package correction.
* minSdk 24, targetSdk 36, ABIs `arm64-v8a` / `armeabi-v7a` / `x86_64`.
