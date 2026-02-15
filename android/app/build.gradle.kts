import java.util.Properties
import java.io.FileInputStream

// 1. Load the key.properties file
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.minbertv.minber"
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

    // 2. Define the Release Signing Configuration
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        applicationId = "com.minbertv.minber"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            // 3. CHANGE THIS: Point to the release config, NOT debug
            signingConfig = signingConfigs.getByName("release")

            // Enable optimization for Play Store
            isMinifyEnabled = true
            isShrinkResources = true
            
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // 1. For app updates
    implementation("com.google.android.play:app-update:2.1.0")
    // 2. For in-app reviews
    implementation("com.google.android.play:review:2.0.1")
    // 3. For feature delivery (fixes SplitInstall errors)
    implementation("com.google.android.play:feature-delivery:2.1.0")
    
    // 4. ADD THIS: This library contains the 'Task' and 'Listener' classes R8 is missing
    implementation("com.google.android.play:core-common:2.0.3")

    implementation("androidx.work:work-runtime:2.8.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}