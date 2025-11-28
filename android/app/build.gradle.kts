plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.trpl5a.aplikasimobile"
    // Pin compileSdk to match installed Android SDK (was flutter.compileSdkVersion)
    compileSdk = 36
    // Pin NDK to stable r29 installed on this machine.
    // Previously set to flutter.ndkVersion; pinning avoids unexpected NDK resolution changes.
    ndkVersion = "29.0.13846066"

    // Ensure Android Gradle Plugin uses a specific CMake version from the SDK.
    externalNativeBuild {
        cmake {
            version = "4.2.0"
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.trpl5a.aplikasimobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Pin minSdk/targetSdk to match the SDKs installed on this machine.
        // minSdk was flutter.minSdkVersion
        minSdk = 24
        // targetSdk was flutter.targetSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
