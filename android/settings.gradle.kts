import org.gradle.api.initialization.resolve.RepositoriesMode

pluginManagement {
    // Baca flutter.sdk HANYA di dalam blok ini
    val flutterSdkPath =
        run {
            val props = java.util.Properties()
            file("local.properties").inputStream().use { props.load(it) }
            val p = props.getProperty("flutter.sdk")
            require(p != null) { "flutter.sdk not set in local.properties" }
            p
        }

    // plugin Gradle milik Flutter
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // repo artefak engine Flutter
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

dependencyResolutionManagement {
    // Prioritaskan repo dari settings (aman walau ada repo dari project)
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        // penting untuk io.flutter:x86_64_debug & flutter_embedding_debug
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        // maven { url = uri("https://jitpack.io") } // kalau butuh
    }
}

rootProject.name = "IRIS"
include(":app")