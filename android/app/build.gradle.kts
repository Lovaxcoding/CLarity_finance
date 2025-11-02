import java.util.Properties
import java.io.File

// --- Lecture du fichier key.properties ---
val keystoreProperties = Properties()
val keystorePropertiesFile = project.parent!!.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.reader(Charsets.UTF_8).use { reader ->
        keystoreProperties.load(reader)
    }
}

// On donne des noms explicites
val keystorePath = keystoreProperties.getProperty("storeFile")!!
val keystoreAlias = keystoreProperties.getProperty("keyAlias")!!
val keystoreStorePassword = keystoreProperties.getProperty("storePassword")!!
val keystoreKeyPassword = keystoreProperties.getProperty("keyPassword")!!

// --- Plugins ---
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.clarityfinance"
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
        applicationId = "com.example.myapp"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = File(keystorePath)
            storePassword = keystoreStorePassword
            keyAlias = keystoreAlias
            keyPassword = keystoreKeyPassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
        }
    }
}

flutter {
    source = "../.."
}
