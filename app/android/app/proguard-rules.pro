# Flutter y plugins ya traen sus reglas. Conservamos las clases de Firebase Messaging
# por si el shrinker las elimina al no estar google-services.json en el build.
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
