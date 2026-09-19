# Reglas para el minificador (R8) en las compilaciones de release.
#
# Sin esto, R8 borra las firmas genéricas y renombra clases que algunas
# librerías necesitan leer en tiempo de ejecución, y la app truena solo en
# release —nunca en debug—, que es lo peor que puede pasar.

# ── flutter_local_notifications ───────────────────────────────────────────
# Guarda y lee los avisos programados con Gson, y Gson necesita la firma
# genérica de `TypeToken<...>`. Sin estas reglas, cualquier llamada que toque
# la caché de notificaciones (programar o cancelar un aviso) lanzaba:
#   "TypeToken must be created with a type argument"
# y mataba la app al abrirla o al volver a ella.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# ── Gson ──────────────────────────────────────────────────────────────────
# `Signature` es la que guarda los tipos genéricos; `InnerClasses` y
# `EnclosingMethod` hacen falta para los TypeToken anónimos.
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes *Annotation*

-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
