import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The upload key lives outside git. android/key.properties is gitignored; if
// it is present the release build is signed for Play, otherwise it falls back
// to the debug key so `flutter run --release` still works on a machine that
// has never been set up to ship.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.sobra.app.sobra_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.sobra.app.sobra_app"
        // google_mobile_ads 9.x requires Android API 24 or newer.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Meta App Events, read by AndroidManifest.xml. Debug and profile runs
        // send nothing, the same default the Firebase telemetry keeps, so a
        // developer's phone never counts as an install from a Meta ad.
        manifestPlaceholders["metaAppEventsEnabled"] = "false"
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (keystorePropertiesFile.exists()) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
            manifestPlaceholders["metaAppEventsEnabled"] = "true"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Install and open events for Meta app-install campaigns. Core only: no
    // Facebook Login or sharing. The SDK initializes itself from the manifest
    // and reads the Play Install Referrer, so no Dart code calls it.
    implementation("com.facebook.android:facebook-core:18.3.0")
}
