# Flutter ProGuard Rules
# Preservation rules for Flutter and its dependencies

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

# Keep local_auth classes or they might be stripped
-keep class com.dexterous.flutterlocalauth.** { *; }

# Compression & Optimization
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Don't warn about Play Core and Flutter Deferred Components
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Keep generic types for JSON parsing if used
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.* { *; }
