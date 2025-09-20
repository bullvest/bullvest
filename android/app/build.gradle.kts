plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.bullvest.com"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.bullvest.com"
        minSdk = 24
        targetSdk = 35
        versionCode = 17
        versionName = "1.0.1"
    }

    signingConfigs {
        create("release") {
            storeFile = file("bullvest.jks")
            storePassword = "bullvest101@"
            keyAlias = "bullvest"
            keyPassword = "bullvest101@"
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8

        // Correct Kotlin DSL syntax:
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
}

dependencies {
    // Your other dependencies here...

    // Correct Kotlin DSL syntax:
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
