# ==============================================================================
# WhatsGo (WA Web To Go Reborn) - ProGuard & R8 Optimization Rules
# ==============================================================================

# Flutter Core & Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve Native JNI & C/C++ Binding Methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve WebKit JavaScript Interface Bridge
-keepattributes *Annotation*
-keepattributes JavascriptInterface
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Flutter InAppWebView Android
-keep class com.pichillilorenzo.flutter_inappwebview_android.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.**

# Flutter Foreground Task Service & Broadcast Receivers
-keep class com.pravera.flutter_foreground_task.** { *; }
-dontwarn com.pravera.flutter_foreground_task.**

# Local Authentication & AndroidX Biometric Framework
-keep class io.flutter.plugins.localauth.** { *; }
-dontwarn io.flutter.plugins.localauth.**
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# Permission Handler Android
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# SharedPreferences & Storage
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# AndroidX MultiDex
-keep class androidx.multidex.** { *; }
-dontwarn androidx.multidex.**

# General warnings suppression for third-party libraries
-dontwarn javax.annotation.**
-dontwarn org.checkerframework.**
-dontwarn kotlin.reflect.**

