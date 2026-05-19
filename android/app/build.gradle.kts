import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun extractJsonString(jsonText: String, key: String): String? {
    val pattern = Regex(""""$key"\s*:\s*"([^"]*)"""")
    return pattern.find(jsonText)?.groupValues?.getOrNull(1)?.trim()?.takeIf { it.isNotEmpty() }
}

fun loadAdmobLocalConfig(): Triple<String?, String?, String?> {
    var appId: String? = null
    var main: String? = null
    var feed: String? = null

    val jsonFile = rootProject.file("../config/admob.local.json")
    if (jsonFile.exists()) {
        val text = jsonFile.readText()
        appId = extractJsonString(text, "KICKORA_ADMOB_ANDROID_APP_ID")
        main = extractJsonString(text, "KICKORA_AD_NATIVE_MAIN")
        feed = extractJsonString(text, "KICKORA_AD_NATIVE_FEED")
    }

    val localPropsFile = rootProject.file("local.properties")
    if (localPropsFile.exists()) {
        val props = Properties().apply {
            localPropsFile.inputStream().use { load(it) }
        }
        appId = props.getProperty("admob.app.id")?.trim()?.takeIf { it.isNotEmpty() } ?: appId
        main = props.getProperty("kickora.native.main")?.trim()?.takeIf { it.isNotEmpty() } ?: main
        feed = props.getProperty("kickora.native.feed")?.trim()?.takeIf { it.isNotEmpty() } ?: feed
    }

    return Triple(appId, main, feed)
}

fun generateAdmobDartConfig(main: String?, feed: String?, appId: String?) {
    val out = rootProject.file("../lib/ads/admob_generated_config.dart")
    fun esc(value: String?) = (value ?: "").replace("\\", "\\\\").replace("'", "\\'")
    out.writeText(
        """
// Generated from config/admob.local.json — do not edit manually.
abstract final class AdMobGeneratedConfig {
  static const androidAppId = '${esc(appId)}';
  static const kickoraNativeMain = '${esc(main)}';
  static const kickoraNativeFeed = '${esc(feed)}';
}
""".trimIndent() + "\n",
    )
}

val admobConfig = loadAdmobLocalConfig()
val admobAppId = admobConfig.first ?: "ca-app-pub-3940256099942544~3347511713"
generateAdmobDartConfig(admobConfig.second, admobConfig.third, admobConfig.first)

android {
    namespace = "com.kickora.live"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.kickora.live"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["admobAppId"] = admobAppId
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storePassword = keystoreProperties.getProperty("storePassword")
                storeFile = rootProject.file(
                    keystoreProperties.getProperty("storeFile")
                        ?: error("storeFile is missing in android/key.properties"),
                )
            }
        }
    }

    buildTypes {
        release {
            if (!keystorePropertiesFile.exists()) {
                throw GradleException(
                    """
                    Release signing is not configured.
                    1. Create android/upload-keystore.jks (see android/key.properties.example).
                    2. Copy android/key.properties.example to android/key.properties and fill in passwords.
                    """.trimIndent(),
                )
            }
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
