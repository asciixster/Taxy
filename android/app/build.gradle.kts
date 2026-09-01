plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingEnvironment = mapOf(
    "storeFile" to System.getenv("TAXY_ANDROID_KEYSTORE_PATH"),
    "storePassword" to System.getenv("TAXY_ANDROID_KEYSTORE_PASSWORD"),
    "keyAlias" to System.getenv("TAXY_ANDROID_KEY_ALIAS"),
    "keyPassword" to System.getenv("TAXY_ANDROID_KEY_PASSWORD"),
)
val releaseSigningConfigured = signingEnvironment.values.all { !it.isNullOrBlank() }
val releaseBuildRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true) || it.contains("bundle", ignoreCase = true)
}

if (releaseBuildRequested && !releaseSigningConfigured) {
    throw GradleException(
        "Production signing is not configured. Set TAXY_ANDROID_KEYSTORE_PATH, " +
            "TAXY_ANDROID_KEYSTORE_PASSWORD, TAXY_ANDROID_KEY_ALIAS and " +
            "TAXY_ANDROID_KEY_PASSWORD.",
    )
}

android {
    namespace = "pt.taxy.app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "pt.taxy.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = 35
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        if (releaseSigningConfigured) {
            create("production") {
                storeFile = file(signingEnvironment.getValue("storeFile")!!)
                storePassword = signingEnvironment.getValue("storePassword")
                keyAlias = signingEnvironment.getValue("keyAlias")
                keyPassword = signingEnvironment.getValue("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseSigningConfigured) {
                signingConfigs.getByName("production")
            } else {
                null
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    testImplementation(kotlin("test"))
    androidTestImplementation("androidx.test:runner:1.6.2")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
}
