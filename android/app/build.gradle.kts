plugins {
    id("com.android.application")
    id("kotlin-android")
    // لازم يجي بعد Android/Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase Google Services
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.wadiah_app"

    // يقرأ الإعدادات المتوافقة مع نسخة Flutter/AGP الحالية
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // استخدمي Java 17 (مطلوب للإصدارات الحديثة)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Application Id حق تطبيقكم
        applicationId = "com.example.wadiah_app"

        // خليه يعتمد قيم Flutter (عادة minSdk 21 وما فوق)
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // مؤقتًا نستخدم توقيع debug عشان يشتغل run/release
            signingConfig = signingConfigs.getByName("debug")
            // لو احتجتِ تقليل الحجم:
            // isMinifyEnabled = false
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            // إعدادات debug عادي
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM لإدارة تعارض الإصدارات على الطرف الأصلي
    implementation(platform("com.google.firebase:firebase-bom:34.4.0"))
    // لا تضيفي مكتبات فايربيز يدوياً هنا بإصدارات؛
    // Flutter plugins (firebase_core/auth/firestore/storage) تتولى الموضوع.
}
