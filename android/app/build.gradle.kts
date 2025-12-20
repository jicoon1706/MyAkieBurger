plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    
}

android {
    namespace = "com.myakieburger.sales"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.myakieburger.sales"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion.toInt()
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

     // ✅ Correct Kotlin DSL syntax for signingConfigs
    signingConfigs {
        create("release") {
            storeFile = file(findProperty("MYAPP_UPLOAD_STORE_FILE") as String)
            storePassword = findProperty("MYAPP_UPLOAD_STORE_PASSWORD") as String
            keyAlias = findProperty("MYAPP_UPLOAD_KEY_ALIAS") as String
            keyPassword = findProperty("MYAPP_UPLOAD_KEY_PASSWORD") as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// 🆕 Add dependencies block here (at the end of the file)
dependencies {
    // Fix Google Play Services issues
    implementation("com.google.android.gms:play-services-base:18.2.0")
}
