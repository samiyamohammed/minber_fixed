
// plugins {
//     id("com.android.application")
//     id("kotlin-android")
//     id("dev.flutter.flutter-gradle-plugin")
//     id("com.google.gms.google-services")
// }

// android {
//     namespace = "com.example.minber_super_app_new_fixed"
//     compileSdk = flutter.compileSdkVersion
//     ndkVersion = flutter.ndkVersion

//     compileOptions {
//         sourceCompatibility = JavaVersion.VERSION_1_8
//         targetCompatibility = JavaVersion.VERSION_1_8
//         isCoreLibraryDesugaringEnabled = true
//     }

//     kotlinOptions {
//         jvmTarget = JavaVersion.VERSION_1_8.toString()
//     }

//     defaultConfig {
//         applicationId = "com.example.minber_super_app_new_fixed"
//         minSdk = flutter.minSdkVersion
//         targetSdk = flutter.targetSdkVersion
//         versionCode = flutter.versionCode
//         versionName = flutter.versionName
//     }

//     buildTypes {
//         getByName("release") {
//             signingConfig = signingConfigs.getByName("debug")

//             // ✅ USE THE CORRECT KOTLIN SYNTAX
//             isMinifyEnabled = true
//             isShrinkResources = true
            
//             // ✅ ADD THIS LINE - The function call is the same in Kotlin and Groovy
//             proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
//         }
//     }
// }

// flutter {
//     source = "../.."
// }

// dependencies {
//     coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
// }

// In android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.minber_super_app_new_fixed"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.example.minber_super_app_new_fixed"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // NOTE: For a real release, you should have a dedicated release signing config.
            signingConfig = signingConfigs.getByName("debug")

            // This is the corrected section with Kotlin DSL syntax
            isMinifyEnabled = false
            isShrinkResources = false
            
            // This line correctly tells the build system to use your rules file
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
dependencies {
    implementation("com.google.android.play:core:1.10.3")
    implementation("androidx.work:work-runtime:2.8.1") // This is correct
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}