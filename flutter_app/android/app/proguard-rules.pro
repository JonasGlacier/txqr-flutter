# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Go-bind (gomobile) ProGuard Rules
# Adjust the package name if your Go package is different
-keep class go.** { *; }
-keep class github.com.divan.txqr.mobile.** { *; }
-keep class mobile.** { *; }

# Preserve JNI methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Fix for missing Play Core classes in Flutter
-dontwarn com.google.android.play.core.**

# Standard Android ProGuard rules are usually included by getDefaultProguardFile("proguard-android-optimize.txt")
