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
12. **Nada de textos visibles hardcodeados, tampoco en providers**: los mensajes de error que devuelven `AuthProvider` y `GardenProvider` también van con `.tr()` (antes el login mostraba "Contraseña incorrecta" en inglés).
13. **`flutter analyze` está en 0 issues** — mantenerlo así: `withValues(alpha: x)` en vez de `withOpacity(x)`, `activeThumbColor` en `Switch`, `toARGB32()` en vez de `Color.value`, y tras un `await` leer providers antes del `await` o chequear `mounted` (`context.mounted` dentro de closures del `build`).

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
- Los tipos nuevos (desde `mythfact`) viven en `lib/ui/screens/routes/steps/` y avisan a `LessonScreen` con `StepCallbacks` (`onAnswer`, `onReflect`, `onReady`).
- **Contenido de salud mental**: no afirmar datos sin respaldo (p. ej. "21 días para un hábito" o "golpear una almohada libera el enojo" son mitos). Los temas delicados (tristeza persistente, ansiedad) mencionan buscar ayuda profesional.
- **Mapa de lecciones**: `lib/ui/screens/routes/widgets/lesson_path_map.dart`. Camino serpenteante con `sin(i · 0.9)` por índice (no por total de lecciones: la fórmula vieja `sin(i/(n-1)·2π)` dejaba recta una ruta de 2 lecciones). Nodos 3D presionables, anillo giratorio y globo "Empezar" en la lección actual, destellos que fluyen por lo completado, decoración con emojis por ruta (`_themes`, por id), cartel de mitad de camino y trofeo final. Sin `MaskFilter.blur`.
- **Caché de contenido**: `seed/seed_routes.js` escribe `wellness_routes/_meta` (`version`, `routeCount`, `lessonCount`, `stepCount`) cada vez que sube algo. No tiene `order`, así que no sale en la lista de rutas. `RoutesService` lee solo `_meta` (1 lectura); si la versión coincide con la guardada en SharedPreferences (`routes_content_version`) carga todo de la caché local de Firestore (0 lecturas) y verifica los totales; si no, descarga (~473 lecturas) en paralelo. Sin internet usa la caché. En web la persistencia se activa en `main.dart`. **Si editas contenido a mano en la consola, corre `node seed/seed_routes.js --all --meta-only`** o las apps seguirán con la versión vieja.
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
- Hábitos custom por usuario.
- Recordatorios locales programables con timezone correcto.
- Selector 12h con AM/PM forzado y badge visible.

### Diario emocional
- Entradas con mood, texto, tags.
- Historial semanal y mensual.

### Sonido
- `SoundService` (singleton, `lib/domain/services/sound_service.dart`): efectos (`Sfx`), notas (`note(0-7)`), aciertos en racha (`combo(0-5)`), señales de respiración (`BreathCue`) y ambientes en bucle (`Ambient`). Se inicializa en `main.dart` y se mezcla con la música del usuario (`AudioContextConfigFocus.mixWithOthers`).
- **Identidad sonora**: todo en Do mayor pentatónica, suave y a bajo volumen. No agregar sonidos estridentes ni "de casino": es una app de bienestar.
- **Todos los sonidos son propios**, sintetizados con `tools/audio/generate_sounds.py` (numpy + imageio-ffmpeg, MP3). Para cambiar uno, editar el script y regenerar. Los sonidos nuevos se exportan **al final de `main()`**: comparten el generador aleatorio con semilla fija, así que insertarlos antes alteraría los existentes. No meter audios descargados sin revisar la licencia. ~5.5 MB en total.
- Dos interruptores persistidos en SharedPreferences: "Efectos de sonido" en Perfil (`sound_effects_enabled`, afecta a `Sfx`, `note` y `combo`) y el botón 🎵 en la barra de la lección (`lesson_ambient_enabled`). Las señales de respiración tienen su propio switch en esa pantalla.
- **Ambiente por ruta** en lecciones (`SoundService.ambientForRoute`): emociones → música calma, autoconocimiento → noche con grillos, mindfulness → arroyo, resiliencia → viento con campanas, autoestima → amanecer, relaciones → kalimba, amor → caja musical, ansiedad → olas lentas (`tide`: cada ola sube ~4 s y baja ~6 s, invita a respirar 4-6), sueño → canción de cuna (`lullaby`, grave y lenta). `LessonScreen` necesita `routeId` para elegirlo. `setBaseAmbient`/`clearBaseAmbient`; la práctica guiada pone música calma y al terminar llama a `returnToBaseAmbient`.
- **En lecciones**: acierto y error; desde el 2.º acierto seguido cada uno suena más agudo (`combo`); `order` toca la escala nota por nota, así que al ordenar se arma una melodía (pasa `sound: false` a `onAnswer`); tic en slider; on/off en pick; burbuja en historias; swipe en mito/realidad; tono ascendente mientras se mantiene presionado el compromiso; campanitas al completar.
- **En el mapa**: toque de nodo; al volver de una lección suena `unlock` si se desbloqueó otra o `routeComplete` si terminó la ruta.
- **Hitos de la app**: subir de nivel y logros (`CelebrationDialog`), semillas (`RewardDialog`), check-in de ánimo, hábito cumplido, entrada de diario guardada, jardín (plantar, cosechar, booster) y compra en la tienda.

### Respiración guiada
- 3 técnicas (Box, 4-7-8, Flow).
- Sonidos ambientales locales (música calma, lluvia, bosque, océano, arroyo, noche, olas lentas, canción de cuna, campanas de viento, ruido suave). Antes se reproducían desde URLs de mixkit.co, frágiles y con licencia dudosa.
- Señal sonora al inicio de cada fase (inhalar, sostener, exhalar) y cuenco tibetano al terminar; se pueden apagar.
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
- **Polish visual de `lesson_screen.dart`** con personajes.
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
- La pantalla de lección solo tiene modo oscuro.
- Accesibilidad: opción "reducir animaciones" y revisar TalkBack en los pasos nuevos.
- `lesson_screen.dart` (~2 200 líneas): mover quiz, sort, reveal y slider a `steps/`, como los tipos nuevos.

**Antes de publicar**:
- ~~Caché del contenido de rutas con documento de versión~~: hecho.
- ~~Firebase Analytics + Crashlytics~~: hecho. Declararlos en la política de privacidad y en la sección "Seguridad de los datos" de Play Console.

## Historial de git

El proyecto tiene commits granulares por tema. Ver `git log --oneline` para historial completo.