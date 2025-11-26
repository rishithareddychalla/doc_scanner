# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Printing package
-keep class net.nfet.flutter.printing.** { *; }
-dontwarn net.nfet.flutter.printing.**

# Image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Camera
-keep class io.flutter.plugins.camera.** { *; }

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Android support
-keep class androidx.** { *; }
-dontwarn androidx.**