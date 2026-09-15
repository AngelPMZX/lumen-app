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
8. **Imágenes grandes en WebP** (quality ~85), no PNG — los PNG ilustrados pesan ~2 MB cada uno.
9. **Días de racha**: usar `UserProgress.daysSinceCheckIn` (días de calendario en UTC), nunca `difference().inDays` entre fechas locales — falla en días con cambio de horario.
10. **`progress/current` se sobrescribe completo** con `.set(toMap())` en varios lugares: no guardar campos extra ahí. Datos auxiliares van en su propio doc de `progress/` (`celebrated_achievements`, `discoveries`, `breathing`).
11. **PowerShell 5.1 parte los argumentos con comillas dobles** al llamar ejecutables (`git commit -m "..."`, `python -c "..."`): usar `git commit -F archivo.txt` y scripts `.py` en archivo.

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
- 7 rutas × 24 lecciones × 72 pasos bilingües en Firestore.
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
- **Reglas de Firestore**: restringir lectura de `users/{userId}` al dueño antes de publicar (hoy cualquier usuario autenticado puede leer perfiles ajenos).
- **Limpieza de warnings** de `flutter analyze` (~430, sobre todo imports sin usar).
- **Polish visual de `lesson_screen.dart`** con personajes.
- **Panel admin** de rutas de bienestar (sin script Node.js).
- **Guía de batería para Xiaomi/Huawei/Oppo** al detectar el fabricante.
- **Pre-publicación**: firma release keystore, íconos, screenshots, política de privacidad.
- **Spam del email de reset**: requiere plan Blaze + dominio propio + SPF/DKIM.

## Historial de git

El proyecto tiene commits granulares por tema. Ver `git log --oneline` para historial completo.