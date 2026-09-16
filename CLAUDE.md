# Lumen — Gimnasio Emocional

App Flutter para bienestar emocional. Estilo "Duolingo del bienestar" con rachas, rutas de aprendizaje, jardín zen gamificado, diario emocional y hábitos.

## Contexto del desarrollador

- **Ángel Pérez** — desarrollador solo, IT analyst con background en Blazor/.NET/SQL Server, aprendiendo Flutter en el proceso.
- Trabaja desde VS Code en Windows (PowerShell), proyecto en `C:\Proyectos\gimnasio_emocional`.
- Idioma preferido: español para conversaciones, inglés para code/commits.
- Estilo: pragmático, prefiere entregar features completas antes que perfeccionar.

## Stack

- **Frontend**: Flutter (Dart) + Material 3
- **Estado**: Provider
- **Backend**: Firebase (Auth, Firestore, Storage)
- **i18n**: easy_localization (ES/EN)
- **Notificaciones**: flutter_local_notifications + timezone + flutter_timezone
- **Auth**: Email/password + Google Sign-In (web + Android)
- **Persistencia moneda del jardín**: Firestore
- **Monetización planeada**: RevenueCat (aún no activo)

## Identidad de la app

- **Estudio**: TheDarking Studios. **Nombre visible**: Lumen (Android, iOS y web).
- **applicationId / namespace / bundle id**: `com.thedarkingstudios.lumen`. **Permanente**: una vez publicado en Google Play no se puede cambiar.
- **Paquete Dart**: sigue siendo `gimnasio_emocional` (interno, no visible; cambiarlo obligaría a tocar todos los `import 'package:gimnasio_emocional/...'`).
- **Firebase**: mismo proyecto `lumen-app-5bcda`. `google-services.json` contiene **dos** apps Android: la vieja (`com.example.gimnasio_emocional`, sin uso) y la nueva. No borrar la vieja sin revisar.
  - App ID Android nuevo: `1:190336343882:android:c8619d6ea07db43d41ebb3` (también en `firebase_options.dart`).
  - SHA-1 de debug registrado: `1D:81:1B:F7:87:C4:D9:65:42:F4:9B:57:BA:84:3B:A7:3E:B9:DB:60`.
  - SHA-1 de release registrado: `C6:8D:20:D8:9B:62:89:2B:2D:B6:B3:61:A3:73:34:72:20:98:4C:83`.
  - Al cambiar de máquina o generar el keystore de release, registrar su SHA-1 o Google Sign-In falla en Android.
- **Firma release**: `android/app/build.gradle.kts` lee `android/key.properties` si existe; si no, usa la llave de debug. `key.properties`, `*.jks` y `*.keystore` están en `.gitignore` y **nunca** se suben.
  - Keystore en `C:\Proyectos\keys\lumen-release.jks`, alias `lumen`, válido 10 000 días. **Si se pierde el archivo o su contraseña, Google Play no permite volver a actualizar la app publicada** — mantener respaldo fuera de la máquina.
  - Verificar la firma de un APK: `apksigner verify --print-certs <apk>` (debe decir `CN=Angel Perez`, no `Android Debug`).

## Arquitectura

Clean architecture simplificada:

- `lib/core/` — constantes (rutas, colores), tema, utilidades (validators)
- `lib/data/models/` — Modelos (UserModel, UserProgress, MoodEntry, Reminder, WellnessRoute, GardenItem, GardenState, GardenMechanics, etc.)
- `lib/domain/providers/` — Providers (AuthProvider, GardenProvider, ThemeProvider)
- `lib/domain/services/` — Servicios (NotificationService singleton, RoutesService singleton con cache)
- `lib/ui/screens/` — Pantallas organizadas por feature
- `lib/ui/widgets/` — Widgets reutilizables (SeedIcon, AuraContainer, RewardDialog, etc.)

## Reglas de código IMPORTANTES

1. **NUNCA usar `MaskFilter.blur` en CustomPainter** — crashea WebGL en Flutter web. Reemplazar con círculos concéntricos con alpha decreciente.
2. **NUNCA usar `const` con `.tr()`** — no compila con easy_localization.
3. **Todos los `Image.asset` deben tener `errorBuilder`** con fallback a emoji para robustez.
4. **Los archivos siempre completos copy-paste** — nunca snippets parciales cuando modifico código.
5. **Imports relativos** para archivos del proyecto (`../../widgets/...`), no `package:...`.
6. **Reglas de Firestore NO cascadean a subcolecciones** — cada nivel necesita `match` explícito.
7. **Nueva subcolección bajo `users/{uid}`** → agregarla a `_userSubcollections` en `AuthProvider`, o sus datos quedan huérfanos al eliminar la cuenta.
8. **Todos los assets de imagen son `.webp`** (quality 85) — no volver a meter PNG. La conversión de los 42 PNG originales bajó `assets/` de 91 MB a 8.4 MB (92% menos) y el APK release de 151 MB a un tamaño publicable. Un PNG ilustrado pesaba hasta 8.7 MB; su WebP pesa 0.68 MB.
9. **Días de racha**: usar `UserProgress.daysSinceCheckIn` (días de calendario en UTC), nunca `difference().inDays` entre fechas locales — falla en días con cambio de horario.
10. **`progress/current` se sobrescribe completo** con `.set(toMap())` en varios lugares: no guardar campos extra ahí. Datos auxiliares van en su propio doc de `progress/` (`celebrated_achievements`, `discoveries`, `breathing`).
11. **PowerShell 5.1 parte los argumentos con comillas dobles** al llamar ejecutables (`git commit -m "..."`, `python -c "..."`): usar `git commit -F archivo.txt` y scripts `.py` en archivo.
12. **`flutter analyze` está en 0 issues** — mantenerlo así: `withValues(alpha: x)` en vez de `withOpacity(x)`, `activeThumbColor` en `Switch`, `toARGB32()` en vez de `Color.value`, y tras un `await` leer providers antes del `await` o chequear `mounted` (`context.mounted` dentro de closures del `build`).

## Features implementadas

### Autenticación
- Login/registro con email+password.
- Google Sign-In (Android con SHA-1 registrado, web con `--web-port 8080`).
- Recuperación de contraseña con cooldown de reenvío.
- Verificación de email obligatoria (modo estricto) — Google exento. También se exige al abrir la app con sesión guardada (splash).
- Emails de verificación y reset en el idioma de la app.
- Reset password funcional.
- Cambiar contraseña desde Editar perfil (solo cuentas de email).
- Eliminar cuenta desde Editar perfil: reautentica, borra todas las subcolecciones, `users/{uid}`, `_server_time` y el usuario de Auth.

### Home
- Check-in de ánimo diario con 12 emojis.
- Racha diaria con validación anti-trampa vía server timestamp (colección `_server_time`).
- La racha mostrada es `AuthProvider.currentStreak` (0 si ya se perdió un día); `currentStreak` en Firestore solo se recalcula al hacer check-in.
- Lección del día + diario rápido.
- Reto diario aleatorio.
- Timeline emocional semanal.

### Rutas de bienestar (Wellness Routes)
- 7 rutas, 19 lecciones, 57 pasos bilingües en Firestore (verificado 2026-09-16; el dato viejo de "24 lecciones × 72 pasos" era incorrecto).
- **Tipos de paso**: `reading`, `quiz`, `exercise` (originales) + `scenario`, `reveal`, `slider`, `sort` (nuevos). `RoutesService._parseStep` cae en `reading` ante un tipo desconocido, así que agregar tipos no rompe contenido viejo.
  - `scenario`: situación + opciones + `outcomes` (una consecuencia por opción, ninguna incorrecta).
  - `reveal`: pregunta + respuesta oculta tras una tarjeta que gira.
  - `slider`: pregunta 0-10 + `responses` de 3 tramos (0-3, 4-6, 7-10).
  - `sort`: `categories` + `items` + `itemCategory` (índice correcto por item) + `explanation`.
- Antes las 19 lecciones tenían exactamente la misma estructura (1 reading + 1 quiz + 1 exercise), que es la causa de que se sintieran repetitivas.
- `seed_route_emociones.js` reescribe los pasos de la ruta `emociones` con los tipos nuevos. Acepta `--dry-run`. Borra y reemplaza los `steps` de esas lecciones; no toca `users/{uid}`.
- Path curvo estilo Duolingo con nodos de lecciones desbloqueables.
- Contenido cargado dinámicamente por locale (`title_es`/`title_en`, etc.).

### Jardín (Garden)
- Plantar semillas, crecen en tiempo real, cosechar recompensas.
- 5 plantas base + 2 estacionales (christmas_tree en dic, pumpkin en oct).
- 4 decoraciones, 4 boosters (water/sun/fertilizer/elixir).
- Assets ilustrados estilo watercolor children's book (PNG en `assets/images/plants/`, `decorations/`, `boosters/`, `currency/`).
- Sistema de auras (color+intensidad por rareza).
- Tienda con precios en semillas + premium ($0.99 vía RevenueCat futuro).
- Escudos de racha: el home guarda la racha rota (`saveStreakBeforeBreak`, tras cargar las mecánicas) y el escudo solo se puede usar ese día (`streakBreakDate` en `garden/mechanics`), antes o después del check-in. Si ya hizo check-in, hoy también cuenta.
- Múltiples jardines (meadow, forest, mountain, lake, greenhouse).

### Hábitos y recordatorios
- Hábitos custom por usuario.
- Recordatorios locales programables con timezone correcto.
- Selector 12h con AM/PM forzado y badge visible.

### Diario emocional
- Entradas con mood, texto, tags.
- Historial semanal y mensual.

### Respiración guiada
- 3 técnicas (Box, 4-7-8, Flow).
- Sonidos ambientales.
- Recompensa XP + semillas (`RewardSource.breathing`) solo en la primera sesión del día (`progress/breathing`, hora del servidor).

### Discovery moments
- Popup ilustrado la primera vez que se entra al jardín, respiración, diario, rutas o recordatorios, con +5 semillas (`DiscoveryDialog`).
- Guardado en `progress/discoveries`. Diario y Rutas se disparan al tocar la pestaña en `MainShell` (viven en un `IndexedStack`, su `initState` corre al abrir la app).

### Onboarding
- 4 slides al terminar profile setup: bienvenida, rutas, diario, jardín.
- Colores por slide (verde, naranja, azul, morado).
- Skip con confirmación.
- Repetible desde Perfil → Ajustes → "Ver tour de nuevo".
- Flag `onboardingCompleted` en Firestore.

### Ayuda en crisis
- Pantalla `CrisisSupportScreen` (`lib/ui/screens/crisis/`) con líneas de ayuda gratuitas por país.
- Datos en `lib/data/models/crisis_resource.dart`: México (Línea de la Vida), Colombia (106), Argentina (135), Chile (*4141), España (024), EE. UU. (988) + Find A Helpline como respaldo internacional.
- **Los números son información de seguridad**: cada país lleva su `sourceUrl` oficial. No agregar ni cambiar un número sin verificarlo en la fuente oficial primero.
- Accesos: Perfil → "¿Necesitas ayuda ahora?", icono en la cabecera del Diario, y tarjeta automática en Home cuando hay 3+ días de ánimo negativo en la semana (`_shouldOfferCrisisSupport`, ocultable por día).
- Usa `url_launcher` (`tel:`, `sms:`, `https:`); Android 11+ exige los `<intent>` declarados en `<queries>` del AndroidManifest.

## Bugs importantes resueltos (no volver a introducir)

1. **Timezone bug**: `tz.initializeTimeZones()` no configura `tz.local`. Debe usarse `FlutterTimezone.getLocalTimezone()` + `tz.setLocalLocation()` en `NotificationService.initialize()`.
2. **Reglas Firestore para `_server_time`**: sin ellas, la racha nunca se registra silenciosamente.
3. **Reglas Firestore para subcolección `steps`**: sin ella, rutas caen a fallback en español hardcoded.
4. **Xiaomi/MIUI mata notificaciones programadas**: no es bug del código, es agresividad de MIUI con background tasks. Se pide al usuario configurar "Sin restricciones" en batería.
5. **Google Sign-In en Android**: requiere SHA-1 registrado en Firebase Console.
6. **Google Sign-In en web**: requiere puerto fijo (`--web-port 8080`) y ese origen registrado en Google Cloud Console.
7. **`assets/assets/` en errores 404 de Flutter web**: no es bug, es cómo Flutter web sirve assets.
8. **Racha mostrada que no bajaba**: mostrar `progress.currentStreak` directo deja ver la racha vieja tras perder días. Usar `AuthProvider.currentStreak`.
9. **Escudo de racha inservible**: `saveStreakBeforeBreak` nunca se llamaba y el escudo del jardín no restauraba la racha. Ambos flujos deben terminar en `restoreStreakWithShield`.
10. **Respiración guardada como lección** (`completed_lessons/breathing_session_<día>`): bloqueaba XP el mismo día del mes siguiente y contaba como lección del día.
12. **Frase del día en inglés**: `QuoteService` consultaba ZenQuotes.io, que solo devuelve frases en inglés y sin `textKey`, así que se mostraban sin traducir. Además se cacheaban por día sin guardar el idioma. Ahora el catálogo es local y bilingüe, elegido de forma determinista por día del año: sin red, sin caché, igual en web y móvil.
11. **Recompensa doble de respiración**: la tarjeta del home daba semillas (SharedPreferences) al volver de `BreathingScreen`, aunque no se completara la sesión, además de la de `_finishSession`. La única fuente es `BreathingScreen` vía `completeBreathingSession`.

## Reglas de Firestore vigentes

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      match /{subcollection}/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /{subcollection}/{docId}/{nestedCol}/{nestedDoc} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    match /wellness_routes/{routeId} {
      allow read: if request.auth != null;
      allow write: if false;
      match /lessons/{lessonId} {
        allow read: if request.auth != null;
        allow write: if false;
        match /steps/{stepId} {
          allow read: if request.auth != null;
          allow write: if false;
        }
      }
    }
    match /_server_time/{userId} {
      allow read, write, delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Comandos frecuentes

```powershell
# Correr en web (puerto FIJO para Google Sign-In)
flutter run -d chrome --web-port 8080

# Generar APK debug
flutter build apk --debug
# Sale en: build\app\outputs\flutter-apk\app-debug.apk

# Xiaomi bloquea adb install — transferir APK manualmente (WhatsApp/Drive/USB)

# Limpiar antes de cambios grandes
flutter clean; flutter pub get
```

## Pendientes actuales

- **RevenueCat activo** para monetización.
- **Reverificar líneas de crisis** antes de publicar y cada ~6 meses (última verificación: 2026-09-15).
- **Reglas de Firestore**: restringir lectura de `users/{userId}` al dueño antes de publicar (hoy cualquier usuario autenticado puede leer perfiles ajenos).
- **Polish visual de `lesson_screen.dart`** con personajes.
- **Panel admin** de rutas de bienestar (sin script Node.js).
- **Guía de batería para Xiaomi/Huawei/Oppo** al detectar el fabricante.
- **Pre-publicación**: generar keystore de release + `key.properties` + registrar su SHA-1 en Firebase, íconos, screenshots, política de privacidad.
- **Spam del email de reset**: requiere plan Blaze + dominio propio + SPF/DKIM.

## Historial de git

El proyecto tiene commits granulares por tema. Ver `git log --oneline` para historial completo.