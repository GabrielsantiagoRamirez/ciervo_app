# Flutter conserva los entry points JNI; estas reglas retienen metadatos usados
# por plugins que serializan modelos o registran callbacks por reflexión.
-keepattributes Signature,*Annotation*
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
