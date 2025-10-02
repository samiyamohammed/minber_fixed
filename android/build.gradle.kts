// allprojects {
//     repositories {
//         google()
//         mavenCentral()
//     }
// }

// val newBuildDir: Directory =
//     rootProject.layout.buildDirectory
//         .dir("../../build")
//         .get()
// rootProject.layout.buildDirectory.value(newBuildDir)

// subprojects {
//     val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
//     project.layout.buildDirectory.value(newSubprojectBuildDir)
// }
// subprojects {
//     project.evaluationDependsOn(":app")
// }

// tasks.register<Delete>("clean") {
//     delete(rootProject.layout.buildDirectory)
// }
// Project-level build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // You may need to check your main build.gradle file to get the correct versions for these
        classpath("com.android.tools.build:gradle:7.3.0")
        
        // ------------------------------------------------------------------
        // >>> CORRECTED FIREBASE GOOGLE SERVICES CLASS PATH <<<
        classpath("com.google.gms:google-services:4.4.0")
        // ------------------------------------------------------------------
        
        // If your project uses the Kotlin plugin, it might need to be defined here too
        // classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}