
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Generative AI
-keep class com.google.ai.client.generativeai.** { *; }
-keep class com.google.crypto.tink.** { *; }

# Mailer (if it uses reflection, though mostly Dart)
# However, R8 mostly affects Android native code. 

# General Safety for Release
-dontwarn io.flutter.**
