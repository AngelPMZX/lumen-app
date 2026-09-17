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
- **Backend**: Firebase (Auth, Firestore, Storage, Analytics, Crashlytics)
- **i18n**: easy_localization (ES/EN)
- **Notificaciones**: flutter_local_notifications + timezone + flutter_timezone
- **Auth**: Email/password + Google Sign-In (web + Android)
- **Animación y diseño**: flutter_animate, confetti, google_fonts (Poppins en la app; Caveat y Lora en el diario), `CustomPainter` propios (Lumi, cielos, cofre, mapa)
- **Sonido**: audioplayers con sonidos sintetizados propios (`tools/audio/generate_sounds.py`)
- **Compartir y reseñas**: share_plus, in_app_review
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
- `lib/domain/services/` — Servicios singleton (Notification, Routes con caché, Sound, Motion, Analytics, Commitment, Mission, WeeklySummary, AppReview, DiaryDraft)
- `lib/ui/screens/` — Pantallas organizadas por feature
- `lib/ui/widgets/` — Widgets reutilizables (Lumi, `journal/` estilo cuaderno, `MinTapTarget`, SeedIcon, AuraContainer, RewardDialog, etc.)
- **Lógica pura con pruebas** en `lib/data/models/` (sin Flutter ni Firebase): `WeeklySummary`, `WeeklyMissions`, `ReviewDeck`, `LumiDialog`, `RoutesOverview`, `DiaryInsights`/`HabitHistory`. Las pantallas nuevas traen `preview*` (`@visibleForTesting`) para renderizarlas sin Firebase.

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
12. **Nada de textos visibles hardcodeados, tampoco en providers**: los mensajes de error que devuelven `AuthProvider` y `GardenProvider` también van con `.tr()` (antes el login mostraba "Contraseña incorrecta" en inglés).
13. **`flutter analyze` está en 0 issues** — mantenerlo así: `withValues(alpha: x)` en vez de `withOpacity(x)`, `activeThumbColor` en `Switch`, `toARGB32()` en vez de `Color.value`, y tras un `await` leer providers antes del `await` o chequear `mounted` (`context.mounted` dentro de closures del `build`).
14. **Nada de curvas con rebote (`easeOutBack`, `elasticOut`) en `AnimatedContainer` que cambie sombras**: el rebote interpola el `blurRadius` por debajo de 0 y lanza una aserción. Usar `easeOutCubic`; el rebote va bien en `scale`/`slide`.
15. **Bucles de animación respetan "Reducir animaciones"**: `.animate(onPlay: MotionService.loop(context, reverse: true))` en vez de `(c) => c.repeat(...)`, `controller..repeatUnlessReduced()` en vez de `..repeat()`, y el confeti solo si `!MotionService.instance.reducedNow`.

## Guía de diseño y polish (lo que ya tiene la app)

Cada pantalla nueva o que se pule debe quedar al nivel de lecciones, rutas, diario, misiones y repaso. Checklist:

1. **Personalidad y calidez**: Lumi presente cuando aporta (saludo, reacción al ánimo, estados vacíos, celebraciones) con `LumiAvatar`/`LumiNote`; su mood acompaña (cariñosa ante lo difícil, nunca decepcionada). Textos amables y en lenguaje neutro.
2. **Animaciones con sentido**: entradas escalonadas con flutter_animate (`fadeIn` + `slide`/`scale` suaves), microinteracciones al tocar (hundirse con `AnimatedScale` ~0.97, destellos con `SparkleBurst`, anillos de progreso que se llenan), celebraciones (confeti, `RewardDialog`) solo en logros reales. Nada de rebote en contenedores con sombra (regla 14).
3. **Sonidos propios** para acciones clave (tocar, marcar, guardar, completar, celebrar), suaves y en la misma escala; se agregan al final del generador (ver "Sonido").
4. **Modo claro y oscuro** revisados los dos; colores legibles (en claro, acentos oscurecidos para texto).
5. **Reducir animaciones**: bucles con `MotionService.loop`/`repeatUnlessReduced`, sin confeti ni sacudidas si está activo (regla 15).
6. **Accesibilidad**: `Semantics` con etiqueta y estado, `onTap` si se excluyen hijos, áreas de toque de 48 dp (`MinTapTarget`), nada que dependa solo de un gesto.
7. **Confianza y privacidad**: decir claramente qué es privado, no perder lo que escribe el usuario (borradores), confirmar antes de borrar.
8. **i18n completa** (ES/EN, sin textos fijos) y `flutter analyze` en 0.
9. **Lógica separada y probada** cuando haya cálculos (rachas, totales, recomendaciones).
10. **Revisar el diseño con capturas**: una prueba temporal en `test/tmp_*_test.dart` con `matchesGoldenFile` + `--update-goldens`, fuente `C:\Windows\Fonts\segoeui.ttf` cargada con `FontLoader`, `EasyLocalization` real, `SoundService.setEffectsEnabled(false)` y `JournalStyle.useSystemFonts = true`. Generar cada caso con `--name '<nombre>$'` (varias pruebas seguidas en el mismo proceso salen en blanco). Los emojis e iconos se ven como cuadros: es normal. Borrar las pruebas y PNG temporales al terminar.

## Features implementadas

### Autenticación
- Login/registro con email+password.
- **Contraseñas seguras (2026-09-17)**: `PasswordStrength` (`lib/data/models/password_strength.dart`, lógica pura con pruebas) exige mínimo 8 caracteres, letras y números, nada de contraseñas muy usadas (lista de filtraciones, repeticiones y series tipo `abcdefgh`) ni que contenga el nombre o el correo. `Validators.strongPassword` la aplica en el registro y al cambiar la contraseña; `Validators.password` (solo "no vacía") se queda para entrar, porque hay cuentas viejas de 6 caracteres. En el registro y en editar perfil se ve una barra de fuerza con las reglas que faltan (`PasswordStrengthMeter`).
- **Sin filtrar qué correos existen**: al entrar, `user-not-found`, `wrong-password` e `invalid-credential` responden lo mismo ("Correo o contraseña incorrectos"); el correo de recuperación ya fingía éxito con correos que no existen. Conviene activar además *Email enumeration protection* en Firebase Console.
- **Google Sign-In**: errores traducidos (antes era un texto fijo en español), caso `account-exists-with-different-credential` explicado y cierre de sesión de Google si Firebase falla, para que el siguiente intento vuelva a preguntar la cuenta.
- El correo se valida con un dominio de cualquier largo (antes `{2,4}` rechazaba `.online`, `.digital`…).
- **Diseño de las pantallas de cuenta** (`lib/ui/screens/auth/widgets/auth_widgets.dart`): fondo con luces que flotan **sin `MaskFilter.blur`** (login y registro lo usaban, y también `AnimatedParticlesBackground`), tarjeta, campos con `autofillHints`, banner de error, botón de Google con su logo dibujado y nota de privacidad que abre un resumen de qué se guarda.
- Google Sign-In (Android con SHA-1 registrado, web con `--web-port 8080`).
- Recuperación de contraseña con cooldown de reenvío.
- Verificación de email obligatoria (modo estricto) — Google exento. También se exige al abrir la app con sesión guardada (splash).
- Emails de verificación y reset en el idioma de la app.
- Reset password funcional.
- Cambiar contraseña desde Editar perfil (solo cuentas de email).
- Eliminar cuenta desde Editar perfil: reautentica, borra todas las subcolecciones, `users/{uid}`, `_server_time` y el usuario de Auth.
- **Editar perfil** (`edit_profile_screen.dart` + `widgets/edit_profile_widgets.dart`, rediseño 2026-09-17): tarjeta "Así te verás" que se actualiza mientras escribes, nombre, **nombre de usuario editable** (antes el campo estaba deshabilitado aunque `updateUserProfile` ya sabía reservarlo) con revisión de disponibilidad al escribir (`isUsernameTaken`, 600 ms), correo con sello de verificado, arquetipo de solo lectura (se definió al crear la cuenta), contraseña en tarjeta desplegable y zona de eliminar cuenta. El botón "Guardar cambios" es una barra que solo aparece si hay cambios, y al salir con cambios sin guardar Lumi pregunta antes. `ArchetypeStyle` (en `widgets/profile_widgets.dart`) comparte colores, emoji y nombre del arquetipo con el perfil.

### Home (menú principal)
- Check-in de ánimo diario con 12 emojis.
- Racha diaria con validación anti-trampa vía server timestamp (colección `_server_time`).
- La racha mostrada es `AuthProvider.currentStreak` (0 si ya se perdió un día); `currentStreak` en Firestore solo se recalcula al hacer check-in.
- **Diseño (2026-09-17)**, piezas en `lib/ui/screens/home/widgets/`, en este orden:
  1. `HomeHeader`: avatar con anillo de nivel, saludo a mano, llamita de racha, jardín (punto verde con semillas, naranja latiendo con cosecha) y tema.
  2. Banners de multiplicador y escudo (solo si aplican).
  3. `HomeHero`: el **cielo del momento** (`ReminderSky` por hora) con `LumiCompanionCard(transparent: true)` y el progreso de hoy (ánimo, lección, diario) con anillo 🎉 al completar los 3.
  4. Avisos del día: `CommitmentCheckCard`, `WeeklySummaryCard`, `CrisisSupportCard`.
  5. `MoodCheckInCard`: burbujas grandes; al elegir se resume con el ánimo grande, destellos y una frase según la categoría (cariñosa si es difícil); "Cambiar" vuelve a abrir las opciones; abajo la semana en emojis (reemplaza a `WeeklyMoodChart`, borrado).
  6. "Tu entrenamiento de hoy": `TodayLessonCard` (color de la ruta, emoji flotando; tras hacer una hoy ofrece "Hacer otra") y cuadrícula de `QuickActionTile` (repaso, respiración, diario, hábitos; estados hecho/bloqueado).
  7. `DailyChallengeCard` y `MissionsHomeCard`.
  8. "Tu resumen": `HomeProgressCard` (racha con semana de llamas + nivel con anillo y XP; reemplaza stat cards, tarjeta de nivel y `DailyProgressRing`, borrado).
  9. `QuoteNote`: la frase del día como nota a mano con cinta.
- Entradas escalonadas, deslizar para refrescar, tarjetas que se hunden al tocar, todo con `Semantics` y respetando "Reducir animaciones".
- **La lección sugerida es `RoutesOverview.suggested`**, la misma que "Continúa" del menú de rutas. `_openLesson` acepta "Siguiente lección" y no vuelve a llamar a `completeLesson` (ya lo hace `LessonScreen`); la recompensa del jardín por lección desde el Home es una vez al día.
- **Reto diario**: `ChallengeAction.execute` ya da la recompensa del jardín (antes el Home daba otra). Se guarda como `completed_lessons/challenge_<yyyy-MM-dd>` (antes `challenge_<día>_<mes>`, que chocaba al año siguiente) y `hasCompletedLessonToday` lo ignora.

### Rutas de bienestar (Wellness Routes)
- 9 rutas. Meta: **10 lecciones por ruta, 5-7 pasos cada una**, sin dos lecciones con la misma secuencia de tipos. Antes eran 19 lecciones con la misma forma (reading + quiz + exercise), por eso se sentían repetitivas.
- **Contenido fuente**: `seed/routes/<id>.js` (un archivo por ruta). Las 9 rutas tienen 10 lecciones: 90 lecciones y 513 pasos en total (emociones 61, autoconocimiento 60, mindfulness 55, resiliencia 56, autoestima 54, relaciones 56, amor 54, ansiedad 57, sueño 60).
- **Rutas Ansiedad y estrés** (`ansiedad`, order 7, ids `ans_1..10`, teal 🌊) y **Sueño** (`sueno`, order 8, ids `sue_1..10`, violeta 🌙), agregadas el 2026-09-16. Basadas en TCC y TCC-I: alarma interna, estrés vs. ansiedad, suspiro doble, 5-4-3-2-1, ciclo de evitación y escalera de exposición, tiempo de preocupación, catastrofizar, relajación muscular progresiva, ataques de pánico; reloj circadiano, cafeína, ritual de desconexión, control de estímulos, lista de pendientes, escaneo para dormir, intención paradójica, siestas/alcohol/ejercicio. **Reglas de seguridad del contenido**: pánico → descartar causa médica si es la primera vez o el dolor de pecho es distinto; sueño → nunca sugerir medicamentos ni suplementos, derivar a médico ante apnea (ronquidos con pausas), somnolencia al manejar o insomnio ≥3 noches/semana por ≥3 meses. Las cifras (vida media de la cafeína ~5 h, 7-9 h de sueño, ciclos de ~90 min) van con matices ("en promedio", "varía"). Candidatas a premium en el futuro; la ayuda en crisis siempre gratis.
- **Temas delicados remiten a ayuda**: tristeza persistente, ansiedad, relaciones controladoras, rupturas y falta de sentido mencionan buscar un profesional y las líneas de Perfil → "¿Necesitas ayuda ahora?". Mantenerlo al editar contenido.
- **Subir contenido**: `node seed/seed_routes.js <ruta> --dry-run` (valida y resume), sin `--dry-run` escribe; `--all` para todas; `--prune` borra lecciones que ya no estén en el archivo. Si hay un error de validación (campos ES/EN faltantes, listas de distinto largo, índices fuera de rango) no escribe nada. Las advertencias de variedad no bloquean.
- **Nunca renombrar el `id` de una lección existente**: el progreso (`completed_lessons`) se guarda por id. El `order` lo calcula el script por posición.
- `seed_wellness_routes.js` es legado y exige `--legacy-overwrite`: correrlo pisaría el contenido nuevo.
- **13 tipos de paso**. `RoutesService._parseStep` cae en `reading` ante un tipo desconocido.
  - Originales: `reading`, `quiz`, `exercise` (este último tiene switch "Guardar también en mi diario", sin XP extra: `saveDiaryEntry(awardXp: false)`).
  - `scenario`: situación + opciones + `outcomes` (una consecuencia por opción, ninguna incorrecta).
  - `reveal`: pregunta + respuesta oculta tras una tarjeta que gira.
  - `slider`: pregunta 0-10 + `responses` de 3 tramos (0-3 verde, 4-6 ámbar, 7-10 rojo): formular la pregunta para que "alto" sea lo difícil.
  - `sort`: `categories` + `items` + `itemCategory` (índice correcto por item) + `explanation`. Solo para cosas con respuesta objetiva.
  - `mythfact`: `statements` + `truths` (bool) + `feedbacks`. Deslizar o tocar Mito/Realidad. Mezclar verdaderas y falsas.
  - `practice`: práctica guiada con temporizador. `intro` + `prompts` + `durations` (seg) + `motions` (`in`/`out`/`hold`/`still`, mueve el orbe) + `outro`.
  - `order`: `items` en el orden correcto (la app los desordena) + `explanation`. El orden debe ser inequívoco.
  - `pick`: selección múltiple reflexiva sin respuesta correcta. `options` + `explanation` o `responses` de 3 (según cuántas marque).
  - `story`: burbujas de chat al tocar. `lines`: `> ` = el usuario, `* ` = narración, resto = `speaker` (emoji).
  - `commit`: micro-reto; elegir uno de `options` y mantener presionado. Se muestra en la pantalla de lección completada.
- **Estructura de la lección**: `lesson_screen.dart` (~720 líneas, antes ~2 400) solo coordina barra superior, Lumi, "Continuar", racha, XP y guardado. **Los 13 tipos** viven en `lib/ui/screens/routes/steps/<tipo>_step.dart` y avisan con `StepCallbacks` (`onAnswer`, `onReflect`, `onReady`); `exercise` avisa su borrador con `onDraftChanged` y la pantalla lo guarda al continuar. Fondo en `widgets/lesson_background.dart` (un solo `CustomPainter` y un controlador) y pantalla final en `widgets/lesson_complete_view.dart`. Piezas comunes en `steps/step_common.dart` (`StepChip`, `StepHeading`, `StepBody`, `StepCard`, `StepNote`, `StepInlineButton`, `StepColors`).
- **Modo claro y oscuro**: la lección sigue el tema de la app. Oscuro = cielo nocturno (estrellas que titilan, fugaces, nebulosas); claro = amanecer (sol tibio, burbujas de luz que suben). **Los pasos no usan `Colors.white` directo**: piden el color a `LessonPalette.of(context)` (`ink`, `inkA(a)` texto, `card(a)` rellenos, `line(a)` bordes, `accent(c)` color legible como texto, `glow`, `cardShadow`). Blanco directo solo sobre rellenos de color (círculo elegido, botón). En claro los rellenos de opciones elegidas son opacos (`Color.lerp(Colors.white, color, 0.14)`): con alpha se transparenta la sombra de color. El `feedback` de un `Draggable` se dibuja fuera del árbol: envolverlo en `LessonPaletteScope`.
- **Contenido de salud mental**: no afirmar datos sin respaldo (p. ej. "21 días para un hábito" o "golpear una almohada libera el enojo" son mitos). Los temas delicados (tristeza persistente, ansiedad) mencionan buscar ayuda profesional.
- **Menú de rutas** (`routes_screen.dart`): encabezado con Lumi, 3 contadores (lecciones, rutas completas, XP en rutas), tarjeta "Continúa donde te quedaste" (`widgets/continue_route_card.dart`: abre directo la siguiente lección con el mapa de fondo), filtros Todas / En progreso / Sin empezar / Completadas y tarjetas `widgets/route_card.dart` (medallón con anillo de progreso, estado, lecciones y XP, emojis de la ruta al fondo). Esqueleto con brillo al cargar, deslizar para refrescar, transición suave menú ↔ mapa y **atrás desde el mapa vuelve al menú** (`PopScope`). La lógica es pura y probada: `RoutesOverview` (`lib/data/models/routes_overview.dart`) calcula totales, filtros y la ruta sugerida (la empezada más avanzada; si no hay, la primera sin empezar). `previewRoutes`/`previewCompleted` (`@visibleForTesting`) renderizan sin Firebase.
- **Emojis por ruta**: `RouteTheme.decorations(id)` (`lib/ui/screens/routes/route_theme.dart`), compartidos por el menú y el mapa. Al agregar una ruta, agregar sus emojis ahí.
- **Mapa de lecciones**: `lib/ui/screens/routes/widgets/lesson_path_map.dart`. Camino serpenteante con `sin(i · 0.9)` por índice (no por total de lecciones: la fórmula vieja `sin(i/(n-1)·2π)` dejaba recta una ruta de 2 lecciones). Nodos 3D presionables, anillo giratorio y globo "Empezar" en la lección actual, destellos que fluyen por lo completado, decoración con emojis por ruta (`RouteTheme`), cartel de mitad de camino y trofeo final. Sin `MaskFilter.blur`.
- **Caché de contenido**: `seed/seed_routes.js` escribe `wellness_routes/_meta` (`version`, `routeCount`, `lessonCount`, `stepCount`) cada vez que sube algo. No tiene `order`, así que no sale en la lista de rutas. `RoutesService` lee solo `_meta` (1 lectura); si la versión coincide con la guardada en SharedPreferences (`routes_content_version`) carga todo de la caché local de Firestore (0 lecturas) y verifica los totales; si no, descarga (~473 lecturas) en paralelo. Sin internet usa la caché. En web la persistencia se activa en `main.dart`. **Si editas contenido a mano en la consola, corre `node seed/seed_routes.js --all --meta-only`** o las apps seguirán con la versión vieja.
- Contenido cargado dinámicamente por locale (`title_es`/`title_en`, etc.).

### Jardín (Garden)
- Plantar semillas, crecen en tiempo real, cosechar recompensas.
- 5 plantas base + 2 estacionales (christmas_tree en dic, pumpkin en oct).
- 4 decoraciones, 4 boosters (water/sun/fertilizer/elixir).
- Assets ilustrados estilo watercolor children's book (WebP en `assets/images/plants/`, `decorations/`, `boosters/`, `currency/`).
- **Auras de rareza (no quitar, lo pidió Ángel)**: cada item tiene `auraColor`/`auraOpacity`/`auraBlurRadius` en `GardenItem`. `AuraContainer` las dibuja como degradado radial (sin blur) y con `pulse` late despacio; `AuraContainer.pulsesFor` lo activa en épico, legendario y de temporada. Las plantas adultas tienen además halo del mismo color y destellos que suben.
- **Siempre con nuestras ilustraciones**: `GardenAssets` (`garden_defs.dart`) da la ruta de cada planta por etapa, decoración, booster, semilla y fondo; `GardenItemImage` las muestra con su aura y cae en el emoji si falla. Una prueba verifica que existan todos los archivos.
- Tienda con precios en semillas + premium ($0.99 vía RevenueCat futuro).
- Escudos de racha: el home guarda la racha rota (`saveStreakBeforeBreak`, tras cargar las mecánicas) y el escudo solo se puede usar ese día (`streakBreakDate` en `garden/mechanics`), antes o después del check-in. Si ya hizo check-in, hoy también cuenta.
- Múltiples jardines (meadow y mountain abiertos; forest, lake y greenhouse "próximamente"). El último elegido se guarda en SharedPreferences (`garden_active_id`).

**Pantalla del jardín** (`lib/ui/screens/garden/`, rediseño 2026-09-17; `garden_screen.dart` pasó de ~3 100 a ~880 líneas):
- `garden_defs.dart`: `GardenDef`/`GardensCatalog` (fondo, huecos, ambiente y tono), `GardenAssets`, `RarityStyle` (color de etiqueta por rareza), `GardenPalette` (claro/oscuro) y `PlacedDeco`.
- `garden_logic.dart` (lógica pura con pruebas en `test/ui/garden_logic_test.dart`): `GardenLayout` convierte entre la ilustración (1536×2752, `BoxFit.cover`) y la pantalla; `GardenRules.checkDecoration` (lejos de plantas, sin amontonar, dentro de lo visible); `GardenLumi.lineFor` elige qué dice Lumi.
- **La escena ocupa el espacio sobre la mochila** (`InventoryTray.height`), para que ninguna planta quede tapada. Plantas y decoraciones se ordenan por altura (profundidad).
- `widgets/`: `garden_plant_slot.dart` (hueco vacío que brilla al plantar, planta que se mece, píldora con anillo de crecimiento, burbuja "+N" con cosecha lista, anillo dorado en modo booster), `plant_info_panel.dart` (etapas con sus ilustraciones, boosters ahí mismo, cosecha, guardar en la mochila), `garden_hud.dart` (barra superior con contador de semillas animado, logros, sonido y chips de multiplicador/escudos; mochila; Lumi con globo), `harvest_dialog.dart`, `garden_sheets.dart` (elegir jardín, progreso y logros, opciones de decoración, escudos, confirmar), `shop_widgets.dart`, `garden_common.dart` (`GardenItemImage`, `RarityChip`, `GlassPanel`, `SeedCounter`, `GardenPressable`, `GardenSheet`, `GardenToast`, `LightRays`).
- **Interacción**: tocar una planta con cosecha lista cosecha directo; si no, abre su panel. Planta de la mochila → modo plantar (los huecos libres brillan). Booster de la mochila → modo potenciar (tocar una planta que crece). Decoraciones: se arrastran hacia arriba desde la mochila (`Draggable` con `affinity: Axis.vertical`, así la lista sigue deslizándose); tocar una colocada abre opciones y mantenerla presionada la mueve.
- **Decoraciones en coordenadas de la ilustración** (`v: 2` en `garden/decorations`). Las viejas eran fracciones de la pantalla (`legacy`): se muestran igual y se convierten al moverlas. Antes moverlas no funcionaba (el `DragTarget<String>` rechazaba la decoración colocada) y la posición al soltar tomaba la esquina y no el centro.
- De noche (20-6 h) el jardín se oscurece y hay luciérnagas. Ambiente sonoro por jardín (prado → bosque, montaña → montaña, noche → grillos) con botón propio (`garden_ambient_enabled`); se apaga al salir.
- Ya no se lanza una notificación de cosecha al entrar (el usuario ya está en el jardín); suena `harvestReady`.

**Tienda** (`shop_screen.dart`): encabezado con la ilustración del invernadero, semillas y Lumi de tendera; categorías fijas arriba con nuestras ilustraciones; vitrinas en cuadrícula (`SliverGridDelegateWithMaxCrossAxisExtent`) con el aura del item de fondo, etiqueta de rareza, cuántos tienes y botón de precio ("Faltan N" si no alcanza). Secciones: con semillas, premium y de temporada bloqueadas. Tocar una vitrina abre el detalle (rayos de luz, etapas de la planta, cosecha diaria, probabilidad de XP, escudos) y se puede comprar ahí. **Antes no se podía volver a comprar algo que ya tenías** (el botón se cambiaba por un check), aunque plantas y boosters son consumibles. `ShopScreen(previewState:)` (`@visibleForTesting`) renderiza sin Firebase.

**`RewardDialog`**: la ilustración del item con su aura y rayos, etiqueta de rareza, Lumi, contador de semillas y brillo sonoro según rareza. Sin partículas con movimiento reducido.

**Sonidos del jardín** (octava tanda del generador): `leafTap` (tocar planta), `decoPlace` (colocar decoración), `shine(0-2)` (mirar/comprar un item, más notas cuanto más raro) y `harvestReady`.

### Perfil y medallas
- **Perfil** (`profile_screen.dart` + `widgets/profile_widgets.dart`, rediseño 2026-09-17): `ProfileHero` con los colores del arquetipo (avatar con anillo de nivel, insignia "Nv", arquetipo con emoji, título de nivel a mano, barra de XP que se llena, "miembro desde" y Lumi con una frase), `ProfileStatsGrid` (6 contadores que suben: racha, mejor racha, XP, lecciones, páginas del diario, check-ins), `MedalShowcaseCard` (anillo de avance, hasta 4 medallas con "¡Nueva!" y "Tu próxima medalla") y ajustes en 3 grupos (`SettingsGroup`: tu espacio, preferencias con interruptores que suenan, ayuda y más). "Acerca de", idioma y cerrar sesión son hojas con Lumi.
- **Medallas dibujadas con código** (`lib/ui/widgets/medal_badge.dart`): listón del color del logro, borde dentado de bronce, plata u oro, disco con el emoji y un destello que la cruza; bloqueada en gris con candado y anillo de avance.
- **Lógica pura con pruebas** (`lib/data/models/medals.dart`, `test/data/models/medals_test.dart`): `AchievementStats`, `Medals.evaluate` (metal por dificultad dentro del tipo: bronce, plata, oro; con dos, la segunda es oro), `nextUp`, `showcase`, `tierCounts` y `ProfileLumi.lineFor`.
- **Datos reales**: antes el perfil pasaba hábitos = 0, check-ins = solo la semana y el jardín en 0, así que esas medallas nunca se ganaban, y leía hasta 999 entradas del diario. Ahora usa los contadores `count()` de `AuthProvider` (`diaryEntryCount`, `habitsCompletedCount`, `moodCheckInCount`), las plantas del `GardenProvider` y las decoraciones guardadas.
- **Medallas vistas**: `AuthProvider.celebratedAchievementIds` + `markAchievementsSeen` (mismo doc `progress/celebrated_achievements`). Una medalla vista sigue ganada aunque el dato baje (p. ej. guardar plantas) y "¡Nueva!" sale una sola vez (al abrir la vitrina o tocarla).
- `AchievementsScreen(stats:, onSeen:)`: encabezado dorado con anillo total, rayos y conteo por metal, Lumi, próxima medalla, filtros por categoría y cuadrícula; `showMedalDetail` abre la medalla girando con rayos y destellos, avance y una frase de Lumi.
- Sonido propio `medal(0-2)` (tintineo más brillante según el metal); al abrir la vitrina con medallas nuevas suena `achievement`.
- Títulos de medallas en lenguaje neutro (antes "Escritor Frecuente", "Disciplinado", "Veterano"…).

### Retos de lecciones (seguimiento)
- Al comprometerse en un paso `commit`, `CommitmentService` guarda el reto en `users/{uid}/commitments` (está en `_userSubcollections`). Máximo uno pendiente por día: elegir otro el mismo día lo reemplaza, así la recompensa no se repite.
- Notificación única al día siguiente a las 10:00 (`scheduleCommitmentReminder`, id 4000; no en web).
- Desde el día siguiente, el Home muestra `CommitmentCheckCard`: "Sí, lo hice" / "Más o menos" dan semillas (`RewardSource.commitment`); "No pude" responde con amabilidad y ofrece "Intentarlo hoy" o "Soltarlo". Si pasan más de 3 días sin respuesta se marca `expired` sin preguntar (preguntar tarde se siente a regaño).
- `dayKey` es la fecha local `yyyy-MM-dd`, y `daysAgo` compara en UTC para que un día con cambio de horario no cuente como 0.
- Al completar una lección, "Siguiente lección" (si hay) devuelve `LessonScreen.nextResult` y `RoutesScreen` abre la siguiente.

### Compartir ruta y reseñas
- Al completar una ruta, `RoutesScreen` muestra `RouteCompleteDialog` (confeti y la tarjeta flotando). `RouteShareCard` mide 360×450 lógicos y se exporta con `RepaintBoundary.toImage(pixelRatio: 3)` a PNG de 1080×1350 (formato vertical de historias); se comparte con `share_plus` junto con un texto. Si falla la imagen (algunos navegadores), comparte solo el texto. Se puede volver a abrir tocando el trofeo de una ruta completada en el mapa.
- **La tarjeta nunca incluye datos personales ni de ánimo**, solo la ruta, la fecha y la marca (lo dice en el diálogo).
- `AppReviewService.onHappyMoment` (con `in_app_review`) pide reseña solo tras logros (ruta completada, cofre semanal, repaso perfecto), **nunca si hoy el ánimo registrado es difícil**, con XP ≥150, al menos 2 momentos felices y como máximo cada 120 días; nunca en web. La decisión (`shouldAsk`) es pura y está probada. Google Play decide además si muestra el diálogo, así que puede no aparecer: es normal.
- Analytics: `route_card_shared`, `review_prompt_requested`.

### Misiones semanales
- 3 misiones por semana (lunes a domingo, `WeeklyMissions.weekKey` = lunes). El check-in de ánimo siempre está; las otras dos se eligen del catálogo (lecciones, respiración, diario, retos, repasos si hay lecciones completadas, hábitos si el usuario tiene). Elección determinista por usuario y semana, guardada al primer acceso en `progress/missions` (`weekKey`, `types`, `claimed`, `chestClaimed`).
- **El avance se cuenta solo** con datos reales desde el lunes (`MissionService._activitySince`). Para eso cada repaso se registra en `users/{uid}/review_sessions` (en `_userSubcollections`), igual que `breathing_sessions`.
- Reclamar una misión da semillas (`addSeeds`, fuente `mission`) y el cofre semanal da un booster seguro (`RewardSource.missionChest`, 100% item). **Ambos reclamos usan transacción** para no cobrarse dos veces.
- `MissionsScreen`: fondo nocturno con destellos, Lumi animando según el estado, tarjetas con barra de progreso y botón "Reclamar" que late a todo lo ancho (las semillas salen volando). Debajo, `TreasureChest` (`CustomPainter`: madera, bandas doradas, un candado por misión que se ilumina al reclamarla, rayos de luz). Listo para abrir, tiembla cada pocos segundos; al tocarlo la tapa se abre, hay confeti y aparece `RewardDialog`.
- Home: `MissionsHomeCard` con 3 anillos de progreso y aviso de "por reclamar" o "cofre listo".
- Sonidos propios: `missionClaim`, `chestShake`, `chestOpen`. Analytics: `mission_claimed`, `mission_chest_opened`.
- Lógica pura con pruebas en `test/data/models/weekly_missions_test.dart`; `previewState` (`@visibleForTesting`) para renderizar sin Firestore.

### Lumi (compañera)
- **Lumi** es la personaje de la app: una gota de luz dibujada con código (`lib/ui/widgets/lumi/lumi_avatar.dart`, `CustomPainter`), sin assets. Flota, respira, parpadea (a veces dos veces), mece su llama y rebota al tocarla. Resplandor con círculos concéntricos (sin `MaskFilter.blur`).
- 7 expresiones (`LumiMood`): `happy`, `excited` (destellos que orbitan), `calm` (ojos cerrados con sonrisa), `sleepy` (boca "o" y z que flotan), `proud` (ojos ^^), `caring` (cejas tiernas y un corazón), `curious` (ceja arriba y "?").
- **Personalidad**: cálida, curiosa y juguetona; nunca juzga ni regaña. **Lenguaje neutro en género** para Lumi y para el usuario (usar "qué orgullo acompañarte", no "orgulloso/a").
- En el Home, `LumiCompanionCard` muestra un globo que se escribe letra por letra. `LumiDialog.forHome` (lógica pura con pruebas) elige qué decir por prioridad: presentarse (una vez, `lumi_intro_seen_{uid}`), noche, volver tras perder la racha, pedir el check-in, día difícil, reto pendiente, hitos de racha (3, 5 y múltiplos de 7), siguiente lección, repaso, todo hecho. Al tocarla rota entre 12 frases (`lumi.tap.N`).
- En las lecciones reemplaza a los Lottie: contenta leyendo, emocionada al acertar, **cariñosa al fallar** (nunca decepcionada) y orgullosa al completar.
- Voz propia: `lumiChirp` (3 variantes al tocarla) y `Sfx.lumiHello` al hablar.
- Se quitaron el paquete `lottie` y `assets/lottie/`: eran tres animaciones genéricas de personajes distintos, de licencia no verificada (una era `404_hand`).

### Repaso diario
- `DailyReviewScreen` (`lib/ui/screens/review/`): 5 tarjetas de lecciones ya completadas, **sin cronómetro** (a propósito: no presionar en una app de bienestar). Tres fases: intro con mazo en abanico, tarjetas repartidas con animación y resultados con anillo de puntuación, 0-3 estrellas y confeti si es perfecto.
- `ReviewDeck` (`lib/data/models/review_deck.dart`, lógica pura con pruebas): convierte pasos `mythfact` (una tarjeta por afirmación), `sort` (una por item, elegir categoría) y `quiz` en tarjetas con id `lessonId:paso:item`. Mazo determinista por día; primero hasta 2 tarjetas falladas antes y luego al azar entre lecciones distintas. Hacen falta al menos 3 tarjetas posibles.
- **Repetición espaciada ligera**: `progress/review` guarda `missed` (tope 40); las que se aciertan salen. XP (10) y semillas (`RewardSource.review`) solo en el primer repaso del día (`lastRewardDate` con hora del servidor); `lastLocalDay` marca "listo hoy" en el Home.
- Sonidos propios: `cardDeal`, `reviewStart`, `star(0-2)` (una nota más aguda por estrella), `reviewPerfect`; la racha usa `combo`.
- Tarjeta en el Home debajo de la lección del día: bloqueada sin lecciones completadas, con check si ya se hizo hoy (se puede repetir sin recompensa).
- Analytics: `review_started`, `review_complete` (aciertos y total, sin contenido).
- `preview: true` (`@visibleForTesting`) evita Firestore para renderizar la pantalla en pruebas.

### Resumen semanal
- `WeeklySummaryScreen` (`lib/ui/screens/summary/`): ánimo dominante y tendencia frente a la semana anterior, ánimo día por día con el mejor día, 6 contadores (check-ins, lecciones, respiraciones, diario, hábitos, retos cumplidos), patrones personales y una lección recomendada.
- **Todo se calcula en el teléfono** (`WeeklySummary.compute`, lógica pura con pruebas en `test/data/models/weekly_summary_test.dart`). `WeeklySummaryService` hace una consulta de 28 días por colección. Analytics solo registra que se abrió.
- **Patrones**: ánimo promedio (positivo 3, neutral 2, difícil 1) en días con una actividad frente a días sin ella, en 28 días. Se muestra solo con ≥3 días en cada grupo y una diferencia ≥0.35; como máximo 2 patrones, presentados como tendencias y no como reglas.
- **Recomendación**: la emoción difícil repetida ≥2 días en la semana se mapea a lecciones (`WeeklySummary.recommendedLessons`); se elige la primera desbloqueada y sin completar. Si no hay emoción repetida, se sigue donde el usuario se quedó. Con ≥4 días difíciles en la semana también muestra `CrisisSupportCard`.
- **Accesos**: tarjeta en el Home domingo y lunes hasta abrirla (`weekly_summary_seen_{uid}_{domingo}` en SharedPreferences), menú en Perfil y notificación semanal los domingos a las 19:00 (id 5000).
- Cada sesión de respiración se guarda en `users/{uid}/breathing_sessions` (`at`); `progress/breathing` solo tenía un contador. Los días previos a este cambio no cuentan para los patrones de respiración.
- `previewSummary` (`@visibleForTesting`) permite renderizar la pantalla sin Firebase.

### Analytics y Crashlytics
- `AnalyticsService` (`lib/domain/services/analytics_service.dart`) con eventos tipados: `lesson_start`, `lesson_complete`, `lesson_abandoned` (con el paso donde se fue), `route_complete`, `next_lesson_tapped`, `commitment_created/answered/retried`, `review_started`, `review_complete`, `breathing_complete`, `weekly_summary_opened`, `weekly_recommendation_tapped`, `mood_checkin`, `diary_entry_saved`, `habit_checkin`, `garden_action`, `exercise_saved_to_diary`.
- **Privacidad (regla)**: nunca enviar qué ánimo registró el usuario, textos del diario, ejercicios o retos, ni visitas a la ayuda en crisis (excluida del `navigatorObservers`). Solo acciones e ids de contenido.
- En debug no se envía nada; para probar: `flutter run --dart-define=ANALYTICS_DEBUG=true` y DebugView (`adb shell setprop debug.firebase.analytics.app com.thedarkingstudios.lumen`). En web solo funciona si `firebase_options.dart` trae `measurementId` (hoy no lo trae: correr `flutterfire configure` con Analytics activo).
- Crashlytics en `main.dart` (no en web, desactivado en debug). Plugin Gradle `com.google.firebase.crashlytics` 2.8.1 en `settings.gradle.kts` y `app/build.gradle.kts`.
- Declarar Analytics y Crashlytics en la política de privacidad y en "Seguridad de los datos" de Play Console.

### Hábitos y recordatorios
- Hábitos custom por usuario. `RemindersScreen`: tarjeta "Hábitos de hoy" con anillo de progreso, mensaje y Lumi según el avance (celebración y `Sfx.achievement` al completar todos). Cada hábito muestra racha 🔥 y los últimos 7 días; al marcar responde al instante (se revierte si falla) con destellos.
- **Historial**: `AuthProvider.getHabitHistory()` lee `habit_checkins` una vez y arma `HabitHistory` por hábito (`lib/data/models/journal_insights.dart`, con pruebas): racha (si hoy aún no, cuenta hasta ayer), semana y `parseDocId` de `habitId_YYYY-MM-DD` (los ids pueden tener guiones bajos).
- Recordatorios con su **cielo** (`reminder_sky.dart`: amanecer 5-10, día 10-17, atardecer 17-20, noche; sol, nubes, luna y estrellas animados; en gris si está apagado). El editor muestra la hora sobre el cielo, mensajes sugeridos y **vista previa de la notificación**. Se quitó la nota "las notificaciones se activarán cuando instales la app" (confundía; la clave `reminders.mobileInstallNote` quedó sin uso).
- `AddHabitScreen`: Lumi y sugeridos en cuadrícula de tarjetas.
- Recordatorios locales programables con timezone correcto.
- Selector 12h con AM/PM forzado y badge visible.

### Diario emocional (estilo cuaderno personal)
- **Estilo compartido** en `lib/ui/widgets/journal/journal_style.dart`: `JournalStyle` (papel cálido, tinta, renglones, sombra; `paperFor(mood)` tiñe el papel con el ánimo; `lumiFor(mood)`), `JournalPaper` (hoja con renglones y margen), `RuledText` (renglones alineados con el propio texto, no con la hoja), `WashiTape`, `StickyNote`, `LumiNote` (Lumi con globo manuscrito) y `SparkleBurst`. Tipografías con google_fonts (igual que Poppins): **Caveat** a mano para fechas, notas y Lumi (nunca para textos largos) y **Lora** para lo que escribe el usuario. `JournalStyle.useSystemFonts` (`@visibleForTesting`) evita descargar fuentes en pruebas.
- `DiaryScreen`: saludo según la hora con el nombre, Lumi con la pregunta del día (toca para escribir con esa pregunta), "hoja de hoy", 3 contadores (`DiaryInsights`: días seguidos escribiendo, entradas del mes, ánimo frecuente en 30 días), calendario con el emoji del ánimo en cada día y páginas agrupadas por día (Hoy, Ayer, fecha) con cinta del color del ánimo.
- `NewDiaryEntryScreen`: la página y el fondo toman el color del ánimo, Lumi reacciona al ánimo y trae una pregunta que se puede cambiar (🎲), hoja con renglones alineados al texto, contador de palabras, frase de ánimo desde 25 palabras, gratitud como nota adhesiva, "🔒 solo tú puedes leer tu diario" y animación al guardar (`Sfx.journalSaved`, libro → corazón, Lumi agradece; cariñosa si el ánimo es difícil).
- **Borrador automático** (`DiaryDraftService`, SharedPreferences `diary_draft_{uid}`, **solo en el teléfono**): se guarda al escribir y al cerrar; al volver aparece "Recuperamos tu borrador" con opción de descartar. Si falla guardar, el texto sigue ahí. Se borra al guardar la entrada y al eliminar la cuenta.
- `DiaryDetailScreen`: la página como en el cuaderno (fecha a mano, cintas, texto seleccionable sobre renglones, gratitud en nota adhesiva, unas palabras de Lumi según el ánimo).
- Las preguntas salen de `DiaryPrompts.*PromptKeys` traducidas (antes se usaban los textos fijos en español) y en lenguaje neutro.
- Sonidos propios: `Sfx.pageTurn` (abrir/escribir, cambiar pregunta) y `Sfx.journalSaved`.
- `previewEntries`/`previewName` (`DiaryScreen`) y `preview` (`NewDiaryEntryScreen`) son `@visibleForTesting`.

### Sonido
- `SoundService` (singleton, `lib/domain/services/sound_service.dart`): efectos (`Sfx`), notas (`note(0-7)`), aciertos en racha (`combo(0-5)`), señales de respiración (`BreathCue`) y ambientes en bucle (`Ambient`). Se inicializa en `main.dart` y se mezcla con la música del usuario (`AudioContextConfigFocus.mixWithOthers`).
- **Identidad sonora**: todo en Do mayor pentatónica, suave y a bajo volumen. No agregar sonidos estridentes ni "de casino": es una app de bienestar.
- **Todos los sonidos son propios**, sintetizados con `tools/audio/generate_sounds.py` (numpy + imageio-ffmpeg, MP3). Para cambiar uno, editar el script y regenerar. Los sonidos nuevos se exportan **al final de `main()`**: comparten el generador aleatorio con semilla fija, así que insertarlos antes alteraría los existentes. No meter audios descargados sin revisar la licencia. ~5.5 MB en total.
- Dos interruptores persistidos en SharedPreferences: "Efectos de sonido" en Perfil (`sound_effects_enabled`, afecta a `Sfx`, `note` y `combo`) y el botón 🎵 en la barra de la lección (`lesson_ambient_enabled`). Las señales de respiración tienen su propio switch en esa pantalla.
- **Ambiente por ruta** en lecciones (`SoundService.ambientForRoute`): emociones → música calma, autoconocimiento → noche con grillos, mindfulness → arroyo, resiliencia → viento con campanas, autoestima → amanecer, relaciones → kalimba, amor → caja musical, ansiedad → olas lentas (`tide`: cada ola sube ~4 s y baja ~6 s, invita a respirar 4-6), sueño → canción de cuna (`lullaby`, grave y lenta). `LessonScreen` necesita `routeId` para elegirlo. `setBaseAmbient`/`clearBaseAmbient`; la práctica guiada pone música calma y al terminar llama a `returnToBaseAmbient`.
- **En lecciones**: acierto y error; desde el 2.º acierto seguido cada uno suena más agudo (`combo`); `order` toca la escala nota por nota, así que al ordenar se arma una melodía (pasa `sound: false` a `onAnswer`); tic en slider; on/off en pick; burbuja en historias; swipe en mito/realidad; tono ascendente mientras se mantiene presionado el compromiso; campanitas al completar.
- **En el mapa**: toque de nodo; al volver de una lección suena `unlock` si se desbloqueó otra o `routeComplete` si terminó la ruta.
- **Hitos de la app**: subir de nivel y logros (`CelebrationDialog`), semillas (`RewardDialog`), check-in de ánimo, hábito cumplido, entrada de diario guardada, jardín (plantar, cosechar, booster, tocar planta, colocar decoración, cosecha lista, brillo por rareza), compra en la tienda y medallas (tintineo por metal).

### Respiración guiada
- 3 técnicas (Box, 4-7-8, Flow) y 1, 3, 5 o 10 minutos.
- **Rediseño 2026-09-17** (`lib/ui/screens/breathing/`): `breathing_data.dart` tiene las técnicas, los ambientes y `BreathingSession` (**lógica pura con pruebas** en `test/ui/breathing_session_test.dart`): dice qué fase toca en cada segundo, cuántos ciclos van y cuánto falta. Todo se deriva del tiempo transcurrido, así que pausar y reanudar nunca descuadra el conteo.
- `widgets/breathing_sky.dart`: cielo nocturno en **un solo `CustomPainter`** (antes eran 60 widgets, cada uno con su `AnimationController`) con estrellas que titilan, dos auroras que ondulan y el tinte de la técnica; respira un poco con el orbe.
- `widgets/breath_orb.dart`: el orbe con resplandor de círculos concéntricos, motas de luz que entran y salen, anillo de avance de la fase y el contador dentro. Debajo, **Lumi respira contigo** (escala con el orbe).
- `widgets/breathing_setup.dart`: tarjetas de técnica con su **ritmo dibujado en barras** (inhala/sostén/exhala a escala), minutos, ambientes con **escucha previa** (el bucle sigue sonando al empezar la sesión) e interruptor de señales. Arriba, Lumi con una frase.
- La pantalla de ciencia ("¿Por qué respirar?") se muestra **solo la primera vez** (`breathing_science_seen`) y queda a mano en el botón ⓘ del setup.
- Al terminar: minutos, ciclos y técnica, la tarjeta de XP, una frase a mano y Lumi orgullosa.
- Sonidos ambientales locales (música calma, lluvia, bosque, océano, arroyo, noche, olas lentas, canción de cuna, campanas de viento, ruido suave). Antes se reproducían desde URLs de mixkit.co, frágiles y con licencia dudosa.
- Señal sonora al inicio de cada fase (inhalar, sostener, exhalar) y cuenco tibetano al terminar; se pueden apagar.
- Recompensa XP + semillas (`RewardSource.breathing`) solo en la primera sesión del día (`progress/breathing`, hora del servidor).
- **Bugs corregidos**: el temporizador se encadenaba con `Future.delayed` y al pausar y reanudar rápido corrían dos cadenas a la vez (el tiempo bajaba al doble); al reanudar, el orbe repetía la fase completa en vez de lo que faltaba; terminar a mano mientras se acababa el tiempo podía cerrar la sesión dos veces (ahora hay guarda `_finishing`).

### Discovery moments
- Popup ilustrado la primera vez que se entra al jardín, respiración, diario, rutas o recordatorios, con +5 semillas (`DiscoveryDialog`).
- Guardado en `progress/discoveries`. Diario y Rutas se disparan al tocar la pestaña en `MainShell` (viven en un `IndexedStack`, su `initState` corre al abrir la app).

### Accesibilidad (TalkBack)
- **Nada que solo funcione con un gesto**: `sort` se puede arrastrar o tocar la tarjeta y luego la categoría (probado en `test/ui/sort_step_test.dart`); el reto (`commit`) de mantener presionado se compromete con doble toque de TalkBack (acción `onTap` en `Semantics`); mito/realidad tiene botones además de deslizar.
- Opciones con estado: `selected` + `inMutuallyExclusiveGroup` (quiz, escenario, reto), `checked` (marcar). La práctica guiada anuncia cada indicación (`liveRegion`). `sort` anuncia correcto/incorrecto.
- Tarjetas del menú, filtros, nodos del mapa ("Lección 3: título. Bloqueada") y botones con etiqueta propia.
- **Si usas `Semantics(excludeSemantics: true)` en algo tocable, pasa también `onTap`**: excluir los hijos borra la acción de toque del `GestureDetector` y TalkBack no podría activarlo.
- Botones pequeños con `MinTapTarget` (`lib/ui/widgets/min_tap_target.dart`): área de toque de 48×48 dp sin cambiar el tamaño visible.

### Reducir animaciones
- `MotionService` (`lib/domain/services/motion_service.dart`, pref `reduce_motion`), interruptor en Perfil. Se suma a la opción del sistema: `app.dart` la inyecta en `MediaQuery.disableAnimations`, así que `MotionService.reduced(context)` es la fuente única (y `reducedNow` sin contexto).
- Apaga bucles (flotar, latir, titilar, rayos, halos), la sacudida del cofre y de `order`, el destello de pantalla completa al responder, el giro 3D de `reveal` y el confeti. Deja las transiciones cortas de entrada. Los sonidos y la vibración no cambian.
- Los controladores que se crean en `initState` se deciden al abrir la pantalla; los de flutter_animate, al construir.

### Registro y arquetipo (profile setup)
- 5 pasos: usuario, sobre ti, gustos, música y **descubrir tu arquetipo**.
- **`ArchetypeQuiz`** (`lib/data/models/archetype.dart`, lógica pura con pruebas): cada gusto suma 2 puntos y cada género 1; gana el arquetipo con más puntos y, si hay empate, el primero del enum (mismo resultado con las mismas respuestas). Antes vivía dentro de la pantalla. `Archetype` guarda el id que va a Firestore (**no renombrarlos**: `explorador`, `guerrero`, `social`, `sabio`, `libre`) y sus claves de texto.
- La revelación (`steps/archetype_result_step.dart`) muestra el emblema entre rayos de luz con destellos, el nombre, una barra de **afinidad** (qué tan marcado salió), las fortalezas y un consejo de Lumi; suena `unlock` y `achievement`.
- **Nombres de arquetipo y títulos de nivel en lenguaje neutro** (antes "Explorador Introspectivo", "Guerrero Resiliente", "Sabio Tranquilo", "Novato Emocional", "Maestro Zen").

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

La fuente de verdad es **`firestore.rules`** en la raíz del repo; publicar copiándolo en Firebase Console → Firestore Database → Reglas. Resumen:

- `users/{userId}` y todas sus subcolecciones (2 niveles): solo el dueño lee y escribe. Nadie puede leer perfiles ajenos.
- `usernames/{username}` → `{uid, createdAt}`: lectura con sesión; crear solo para uno mismo y con formato válido; borrar solo el dueño; sin update. Es la única forma de comprobar si un nombre está ocupado. `updateUserProfile` reserva el nombre nuevo, libera el anterior y guarda el perfil en **una transacción**; `loadUserData` reclama el nombre de cuentas anteriores a la reserva (`_ensureUsernameReserved`); borrar la cuenta lo libera.
- `wellness_routes` (+ `lessons`, `steps`, `_meta`): solo lectura con sesión.
- `_server_time/{userId}`: solo el dueño.
- Todo lo demás, denegado.
- **Si agregas una colección de nivel superior, agrégala a `firestore.rules`** (sin match queda denegada). Las subcolecciones nuevas de `users/{uid}` ya quedan cubiertas, pero van en `_userSubcollections`.

## Comandos frecuentes

```powershell
# Correr en web (puerto FIJO para Google Sign-In)
flutter run -d chrome --web-port 8080

# Subir contenido de rutas (valida primero)
node seed/seed_routes.js --all --dry-run
node seed/seed_routes.js --all

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
- **Panel admin** de rutas de bienestar (sin script Node.js).
- **Guía de batería para Xiaomi/Huawei/Oppo** al detectar el fabricante.
- **Pre-publicación**: generar keystore de release + `key.properties` + registrar su SHA-1 en Firebase, íconos, screenshots, política de privacidad.
- **Spam del email de reset**: requiere plan Blaze + dominio propio + SPF/DKIM.

### Ideas aprobadas (roadmap, 2026-09-16)

**Retención** (en orden de prioridad):
1. ~~Seguimiento de retos (`commit`)~~: hecho, ver "Retos" en Features.
2. ~~Botón "Siguiente lección" en la pantalla de lección completada~~: hecho.
3. ~~Resumen semanal con conclusiones personales~~: hecho, ver "Resumen semanal" en Features.
4. ~~Repaso diario~~: hecho, ver "Repaso diario" en Features.
5. ~~Compañero con personalidad~~: hecho, ver "Lumi" en Features.
6. ~~Misiones semanales~~: hecho, ver "Misiones semanales" en Features.
7. ~~Tarjeta para compartir al completar una ruta~~: hecho, ver "Compartir ruta y reseñas".
8. ~~Pedir reseña en Play Store~~: hecho.
10. **Personalización de Lumi como apoyo al proyecto** (idea de Ángel, 2026-09-16): colores, accesorios (gorrito, bufanda, lentes…) y quizá animaciones especiales, a precio bajo vía RevenueCat. Solo cosmético: nunca bloquear contenido de bienestar ni ayuda. El `LumiPainter` ya dibuja todo por código, así que los accesorios se pueden pintar como capas encima.
9. ~~Rutas nuevas **Ansiedad y Estrés** y **Sueño**~~: hechas. Si se vuelven premium, revisar `WeeklySummary.recommendedLessons` (hoy recomienda `ans_*`/`sue_*`).

**Pulido**:
- ~~Modo claro de la lección~~, ~~"Reducir animaciones"~~ y ~~dividir `lesson_screen.dart`~~: hechos (2026-09-16).
- ~~Accesibilidad de pasos y menú~~: hecha (2026-09-17), ver "Accesibilidad".
- ~~Menú de rutas~~ (2026-09-17) y ~~diario, hábitos y recordatorios estilo cuaderno~~ (2026-09-17): hechos.
- ~~**Jardín y tienda: polish completo**~~: hecho (2026-09-17), ver "Jardín".
- ~~**Perfil y medallas: polish completo**~~: hecho (2026-09-17), ver "Perfil y medallas".
- ~~**Respiración guiada y editar perfil**~~: hechos (2026-09-17), ver "Respiración guiada" y "Autenticación".
- ~~**Registro, login y arquetipo: seguridad y polish**~~: hechos (2026-09-17), ver "Autenticación" y "Registro y arquetipo".
- ~~**Menú principal (Home): polish completo**~~: hecho (2026-09-17), ver "Home". Pedido original (2026-09-17): Mismo checklist: jerarquía clara de las tarjetas (hoy hay muchas; `home_screen.dart` tiene ~1 800 líneas), animaciones de entrada y microinteracciones, Lumi como protagonista del saludo, check-in de ánimo más expresivo, sonidos, modo claro/oscuro, reducir animaciones y accesibilidad. Coherente con el estilo de rutas, diario y misiones.

**Antes de publicar**:
- ~~Caché del contenido de rutas con documento de versión~~: hecho.
- ~~Firebase Analytics + Crashlytics~~: hecho. Declararlos en la política de privacidad y en la sección "Seguridad de los datos" de Play Console.

## Historial de git

El proyecto tiene commits granulares por tema. Ver `git log --oneline` para historial completo.