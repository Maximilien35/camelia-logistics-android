import java.util.Properties
import java.io.FileInputStream
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Clé du SDK Google Maps (carte de l'écran A4, T2.9). **Jamais dans le dépôt**
// (règle n°10) : elle arrive de `android/local.properties`, qui est ignoré par
// git, et à défaut de la variable d'environnement `GOOGLE_MAPS_API_KEY_ANDROID`
// — c'est par là que les builds Codemagic la reçoivent, réglée dans
// l'interface Codemagic, sans toucher `codemagic.yaml` (règle n°1).
//
// Sans clé le build passe quand même et la carte s'affiche en gris : un build
// de développement qui ne touche pas à l'écran A4 n'a pas à être bloqué. Ce
// n'est pas une URL de backend, la règle n°2 ne s'applique pas ici.
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}
val googleMapsApiKey: String =
    localProperties.getProperty("GOOGLE_MAPS_API_KEY")
        ?: System.getenv("GOOGLE_MAPS_API_KEY_ANDROID")
        ?: ""
if (googleMapsApiKey.isEmpty()) {
    logger.lifecycle(
        "GOOGLE_MAPS_API_KEY absente (android/local.properties ou " +
            "GOOGLE_MAPS_API_KEY_ANDROID) : la carte de l'ecran A4 restera grise."
    )
}
dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))


    // TODO: Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")


    // Add the dependencies for any other desired Firebase products
    // https://firebase.google.com/docs/android/setup#available-libraries

    "coreLibraryDesugaring"("com.android.tools:desugar_jdk_libs:2.1.4")
}
android {
    namespace = "com.camelia.logistics"
    compileSdk = flutter.compileSdkVersion
    // NDK r27 : le 28.1.13356709 précédemment déclaré n'est pas installable en
    // l'état sur les postes de l'équipe — le dossier du SDK est vide (aucun
    // `source.properties`), ce qui fait échouer la configuration Gradle avec
    // `[CXX1101]`. Le r27 est complet et suffit : ce projet n'embarque aucun code
    // natif propre, la version du NDK ne sert qu'aux dépendances qui en exigent
    // une. Ne change ni l'applicationId, ni la signature, ni codemagic.yaml.
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.camelia.logistics"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 8.0 minimum : décision produit du 13 septembre 2026, maintenue
        // le 15 septembre après l'abandon de Yandex MapKit (qui l'avait motivée).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Injectée dans `AndroidManifest.xml` à la place de `${googleMapsApiKey}`.
        manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey
    }
     signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            // R8 et ProGuard pour la réduction de taille
            isMinifyEnabled = true
            isShrinkResources = true

            // Configuration ProGuard (si vous en avez une)
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            // Votre configuration de signature
            signingConfig = signingConfigs.getByName("release")

        }
    }
}

kotlin {
    jvmToolchain(17)
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
