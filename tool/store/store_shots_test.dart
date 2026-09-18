@Tags(['store'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimnasio_emocional/data/models/diary_entry.dart';
import 'package:gimnasio_emocional/data/models/garden_item.dart';
import 'package:gimnasio_emocional/data/models/garden_state.dart';
import 'package:gimnasio_emocional/data/models/lumi.dart';
import 'package:gimnasio_emocional/data/models/medals.dart';
import 'package:gimnasio_emocional/data/models/mood_entry.dart';
import 'package:gimnasio_emocional/data/models/weekly_summary.dart';
import 'package:gimnasio_emocional/domain/services/sound_service.dart';
import 'package:gimnasio_emocional/ui/screens/breathing/breathing_data.dart';
import 'package:gimnasio_emocional/ui/screens/breathing/widgets/breath_orb.dart';
import 'package:gimnasio_emocional/ui/screens/breathing/widgets/breathing_sky.dart';
import 'package:gimnasio_emocional/ui/screens/crisis/crisis_support_screen.dart';
import 'package:gimnasio_emocional/ui/screens/diary/diary_screen.dart';
import 'package:gimnasio_emocional/ui/screens/garden/garden_defs.dart';
import 'package:gimnasio_emocional/ui/screens/garden/garden_logic.dart';
import 'package:gimnasio_emocional/ui/screens/garden/widgets/garden_hud.dart';
import 'package:gimnasio_emocional/ui/screens/garden/widgets/garden_plant_slot.dart';
import 'package:gimnasio_emocional/ui/screens/home/widgets/home_header.dart';
import 'package:gimnasio_emocional/ui/screens/home/widgets/home_hero.dart';
import 'package:gimnasio_emocional/ui/screens/home/widgets/mood_checkin_card.dart';
import 'package:gimnasio_emocional/ui/screens/home/widgets/today_plan.dart';
import 'package:gimnasio_emocional/ui/screens/profile/achievements_screen.dart';
import 'package:gimnasio_emocional/ui/screens/summary/weekly_summary_screen.dart';
import 'package:gimnasio_emocional/ui/widgets/journal/journal_style.dart';
import 'package:gimnasio_emocional/ui/widgets/lumi/lumi_avatar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'store_shot.dart';

/// Genera las capturas de la ficha de Google Play con datos de ejemplo.
///
///     flutter test tool/store/store_shots_test.dart
///
/// Salida en `store/screenshots/` a 1080×2160 px. No es una prueba: es la
/// herramienta que las dibuja (así se rehacen en un minuto si cambia el
/// diseño, y nunca traen datos reales de nadie).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Shot');
    for (final path in [r'C:\Windows\Fonts\segoeui.ttf', r'C:\Windows\Fonts\segoeuib.ttf']) {
      final file = File(path);
      if (file.existsSync()) {
        loader.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
      }
    }
    await loader.load();
    // Emoji de Windows: sin esto, todos los emojis salen como cuadritos
    final emoji = FontLoader('ShotEmoji');
    final emojiFile = File(r'C:\Windows\Fonts\seguiemj.ttf');
    if (emojiFile.existsSync()) {
      emoji.addFont(Future.value(ByteData.view(emojiFile.readAsBytesSync().buffer)));
      await emoji.load();
    }
    // Iconos de Material: el entorno de pruebas no los trae cargados
    for (final candidate in [
      r'C:\flutter-sdk\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
      r'C:\flutter-sdk\flutter\bin\cache\dart-sdk\bin\resources\devtools\assets\fonts\MaterialIcons-Regular.otf',
    ]) {
      final file = File(candidate);
      if (file.existsSync()) {
        final icons = FontLoader('MaterialIcons');
        icons.addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
        await icons.load();
        break;
      }
    }
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('es');
    await SoundService.instance.setEffectsEnabled(false);
    // ignore: invalid_use_of_visible_for_testing_member
    JournalStyle.useSystemFonts = true;
  });

  /// [scroll] baja el contenido esos píxeles antes de capturar, para que el
  /// recorte de abajo caiga dentro de una tarjeta y no a media palabra.
  Future<void> shoot(WidgetTester tester, String name, StoreShot shot, {double scroll = 0}) async {
    await tester.binding.setSurfaceSize(StoreShot.canvas);
    final key = GlobalKey();
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('es')],
        path: 'assets/translations',
        startLocale: const Locale('es'),
        fallbackLocale: const Locale('es'),
        child: Builder(
          builder: (context) => MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: ThemeData(fontFamily: 'Shot', fontFamilyFallback: const ['ShotEmoji'], brightness: Brightness.light),
            home: RepaintBoundary(key: key, child: shot),
          ),
        ),
      ),
    );
    // Dejar que carguen traducciones e imágenes
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
    await tester.pump();
    await tester.runAsync(() async {
      final ctx = tester.binding.rootElement!;
      for (final path in <String>{
        for (final g in GardensCatalog.all) g.assetPath,
        GardenAssets.seed,
        for (final p in GardenCatalog.allPlants)
          for (final s in PlantStage.values) GardenAssets.plant(p.id, s),
        for (final d in GardenCatalog.allDecorations) GardenAssets.decoration(d.id),
        for (final b in GardenCatalog.allBoosters) GardenAssets.booster(b.id),
      }) {
        await precacheImage(AssetImage(path), ctx);
      }
    });
    for (var i = 0; i < 14; i++) {
      await tester.pump(const Duration(milliseconds: 220));
    }
    // Las imágenes se decodifican al tamaño en que se ven (`cacheWidth`), así
    // que el precache de arriba no basta: hay que darles tiempo real.
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 600)));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 220));
    }
    if (scroll > 0) {
      // Sin gestos: la pantalla vive dentro de un FittedBox y los punteros de
      // prueba no caen donde se ven.
      tester.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(scroll);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 220));

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File('store/screenshots/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      // ignore: avoid_print
      print('  store/screenshots/$name.png  ${(file.lengthSync() / 1024).toStringAsFixed(0)} KB');
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  // ── 1. Home ───────────────────────────────────────────────────────────────
  testWidgets('01_home', (tester) async {
    final today = DateTime.now().weekday;
    await shoot(
      tester,
      '01_home',
      StoreShot(
        title: 'Tu día, en un vistazo',
        subtitle: 'Ánimo, lección y diario, sin agobios',
        colors: const [Color(0xFF7C6CFF), Color(0xFF4A42DB)],
        screen: Builder(
          builder: (context) => Scaffold(
            backgroundColor: const Color(0xFFF6F3FF),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                children: [
                  HomeHeader(
                    name: 'Ángel',
                    greeting: 'Buenas tardes',
                    avatarColors: const [Color(0xFF6366F1), Color(0xFF4338CA)],
                    level: 7,
                    levelProgress: 0.64,
                    streak: 12,
                    gardenBadge: GardenBadge.harvest,
                    isDark: false,
                    onGarden: () {},
                    onToggleTheme: () {},
                  ),
                  const SizedBox(height: 14),
                  const HomeHero(
                    line: LumiLine('lumi.nextLesson', LumiMood.excited, {'lesson': 'La trampa de evitar'}),
                    isDark: false,
                    checkInDone: true,
                    lessonDone: false,
                    diaryDone: true,
                    hour: 17,
                  ),
                  const SizedBox(height: 16),
                  MoodCheckInCard(
                    selected: MoodType.calm,
                    weeklyMoods: {
                      for (int d = 1; d < today; d++) d: MoodType.values[(d * 3) % MoodType.values.length],
                      today: MoodType.calm,
                    },
                    isDark: false,
                    onSelect: (_) {},
                  ),
                  const SizedBox(height: 16),
                  TodayLessonCard(
                    routeEmoji: '🌊',
                    routeTitle: 'Ansiedad y estrés',
                    lessonTitle: 'La trampa de evitar',
                    color: const Color(0xFF14B8A6),
                    colorDark: const Color(0xFF0F766E),
                    doneToday: false,
                    allComplete: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  });

  // ── 2. Jardín ─────────────────────────────────────────────────────────────
  testWidgets('02_garden', (tester) async {
    final now = DateTime.now();
    final state = GardenState(
      seeds: 64,
      garden: [
        // La planta con cosecha lista va abajo: su burbuja "+N" flota sobre la
        // planta y en los huecos de arriba taparía el título de la barra.
        PlantedItem(instanceId: 'a', itemId: 'plant_cherry', plantedAt: now.subtract(const Duration(days: 6)), gardenId: 'meadow', slotIndex: 0, lastHarvestedAt: now),
        PlantedItem(instanceId: 'b', itemId: 'plant_bamboo', plantedAt: now.subtract(const Duration(days: 4)), gardenId: 'meadow', slotIndex: 1, lastHarvestedAt: now),
        PlantedItem(instanceId: 'd', itemId: 'plant_lotus', plantedAt: now.subtract(const Duration(days: 3)), gardenId: 'meadow', slotIndex: 3),
        PlantedItem(instanceId: 'e', itemId: 'plant_cactus', plantedAt: now.subtract(const Duration(days: 3)), gardenId: 'meadow', slotIndex: 4),
      ],
      inventory: const [
        InventoryItem(itemId: 'plant_clover', quantity: 2),
        InventoryItem(itemId: 'deco_lantern', quantity: 1),
        InventoryItem(itemId: 'boost_water', quantity: 3),
      ],
    );
    const garden = GardensCatalog.meadow;

    await shoot(
      tester,
      '02_garden',
      StoreShot(
        title: 'Tu jardín crece\ncuando te cuidas',
        subtitle: 'Planta, riega y cosecha tus semillas',
        colors: const [Color(0xFF34D399), Color(0xFF047857)],
        screen: Builder(
          builder: (context) => Scaffold(
            backgroundColor: const Color(0xFF0E1A14),
            body: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: InventoryTray.height(isEmpty: false) - 26,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final h = c.maxHeight;
                      return Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          Image.asset(garden.assetPath, fit: BoxFit.cover, width: w, height: h),
                          for (final slot in garden.slots)
                            if (state.garden.where((p) => p.slotIndex == slot.slotIndex).firstOrNull case final planted?)
                              () {
                                final (x, y) = GardenLayout.toScreen(slot.anchorX, slot.anchorY, w, h);
                                final item = GardenCatalog.findById(planted.itemId)!;
                                return Positioned(
                                  left: x - 70,
                                  top: y - 70,
                                  width: 140,
                                  height: 140,
                                  child: PlantSlotView(
                                    planted: planted,
                                    item: item,
                                    size: 140,
                                    mode: SlotMode.normal,
                                    selected: false,
                                    onTap: () {},
                                  ),
                                );
                              }(),
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    bottom: false,
                    child: GardenTopBar(
                      garden: garden,
                      seeds: state.seeds,
                      shields: 1,
                      multiplier: null,
                      ambientOn: true,
                      onBack: () {},
                      onGardens: () {},
                      onToggleAmbient: () {},
                      onShields: () {},
                      onShop: () {},
                      onProgress: () {},
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 60, 0),
                        child: GardenLumiBubble(
                          line: GardenLumi.lineFor(const GardenSnapshot(plants: 4, readyToHarvest: 1, growing: 2, boostersInInventory: 3)),
                        ),
                      ),
                      InventoryTray(
                        state: state,
                        plantingId: null,
                        boostingId: null,
                        onPlant: (_) {},
                        onBooster: (_) {},
                        onDecoTap: (_) {},
                        onDragStarted: () {},
                        onDragEnded: () {},
                        onShop: () {},
                        bottomInset: 0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });

  // ── 3. Respiración ────────────────────────────────────────────────────────
  testWidgets('03_breathing', (tester) async {
    await shoot(
      tester,
      '03_breathing',
      const StoreShot(
        title: 'Respira con Lumi',
        subtitle: '3 técnicas, ambientes y señales suaves',
        colors: [Color(0xFF818CF8), Color(0xFF1E1B4B)],
        screen: _BreathingScene(),
      ),
    );
  });

  // ── 4. Diario ─────────────────────────────────────────────────────────────
  testWidgets('04_diary', (tester) async {
    final now = DateTime.now();
    await shoot(
      tester,
      '04_diary',
      StoreShot(
        title: 'Tu diario, solo tuyo',
        subtitle: 'Escribe como en un cuaderno de verdad',
        colors: const [Color(0xFFFBBF24), Color(0xFFB45309)],
        screen: DiaryScreen(
          previewName: 'Ángel',
          previewEntries: [
            DiaryEntry(
              id: '1',
              mood: MoodType.calm,
              text: 'Hoy salí a caminar sin el teléfono. Veinte minutos nada más, pero volví con la cabeza en orden.',
              gratitude: 'El café de la mañana y que hubo sol.',
              createdAt: now.subtract(const Duration(hours: 3)),
            ),
            DiaryEntry(
              id: '2',
              mood: MoodType.happy,
              text: 'Terminé la lección de autoestima y me quedé pensando en eso de hablarme como le hablo a alguien que quiero.',
              createdAt: now.subtract(const Duration(days: 1, hours: 5)),
            ),
            DiaryEntry(
              id: '3',
              mood: MoodType.grateful,
              text: 'Llamé a mi mamá. Nada importante, pero colgué de buenas.',
              createdAt: now.subtract(const Duration(days: 2, hours: 2)),
            ),
          ],
        ),
      ),
    );
  });

  // ── 5. Medallas ───────────────────────────────────────────────────────────
  testWidgets('05_medals', (tester) async {
    await shoot(
      tester,
      '05_medals',
      const StoreShot(
        title: 'Mira todo lo que llevas',
        subtitle: '22 medallas de bronce, plata y oro',
        colors: [Color(0xFFFCD34D), Color(0xFFB45309)],
        screen: AchievementsScreen(
          stats: AchievementStats(
            currentStreak: 12,
            longestStreak: 14,
            totalXp: 780,
            level: 8,
            diaryEntries: 14,
            habitsCompleted: 9,
            moodCheckIns: 26,
            lessonsCompleted: 21,
            plantsInGarden: 4,
            adultPlants: 2,
            decorationsPlaced: 1,
            seenIds: {
              'streak_3', 'streak_7', 'xp_100', 'xp_500', 'level_2', 'level_5',
              'diary_1', 'diary_10', 'mood_1', 'habits_5', 'garden_first_plant', 'garden_first_adult',
            },
          ),
        ),
      ),
    );
  });

  // ── 6. Resumen semanal ────────────────────────────────────────────────────
  testWidgets('06_summary', (tester) async {
    final days = [for (int i = 6; i >= 0; i--) WeeklySummary.dayKey(DateTime.now().subtract(Duration(days: i)))];
    final moods = [MoodType.calm, MoodType.happy, MoodType.anxious, MoodType.grateful, MoodType.calm, MoodType.happy, MoodType.happy];
    await shoot(
      tester,
      '06_summary',
      StoreShot(
        title: 'Tu semana, en claro',
        subtitle: 'Patrones tuyos, calculados en tu teléfono',
        colors: const [Color(0xFFA78BFA), Color(0xFF5B21B6)],
        screen: WeeklySummaryScreen(
          source: 'store',
          previewSummary: WeeklySummary(
            days: days,
            dayMoods: {for (final (i, d) in days.indexed) d: moods[i]},
            moodCounts: {MoodType.happy: 3, MoodType.calm: 2, MoodType.grateful: 1, MoodType.anxious: 1},
            dominantMood: MoodType.happy,
            recurringHardMood: null,
            trend: MoodTrend.up,
            bestDay: days[5],
            negativeDays: 1,
            lessons: 5,
            breathingSessions: 3,
            diaryEntries: 4,
            habitsDone: 11,
            commitmentsDone: 2,
            insights: const [
              ActivityInsight(activity: SummaryActivity.breathing, moodWith: 2.8, moodWithout: 2.1, daysWith: 5, daysWithout: 6),
              ActivityInsight(activity: SummaryActivity.diary, moodWith: 2.7, moodWithout: 2.2, daysWith: 6, daysWithout: 5),
            ],
          ),
        ),
      ),
      scroll: 88,
    );
  });

  // ── 7. Ayuda en crisis ────────────────────────────────────────────────────
  testWidgets('07_crisis', (tester) async {
    // La pantalla detecta el país por la región del teléfono, y en una prueba
    // eso es en_US: sin esto la captura de la ficha (en español) saldría con
    // las líneas de Estados Unidos.
    tester.platformDispatcher.localesTestValue = const [Locale('es', 'MX')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await shoot(
      tester,
      '07_crisis',
      const StoreShot(
        title: 'Ayuda gratis,\nsiempre a un toque',
        subtitle: 'Líneas de crisis por país, dentro de la app',
        colors: [Color(0xFF6C8FE8), Color(0xFF1E3A8A)],
        screen: CrisisSupportScreen(),
      ),
    );
  });
}

/// La pantalla de respiración en plena inhalación.
class _BreathingScene extends StatefulWidget {
  const _BreathingScene();

  @override
  State<_BreathingScene> createState() => _BreathingSceneState();
}

class _BreathingSceneState extends State<_BreathingScene> with SingleTickerProviderStateMixin {
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(seconds: 4), value: 0.82);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final technique = kTechniques.first;
    final session = BreathingSession.minutes(technique, 3);
    return Scaffold(
      backgroundColor: const Color(0xFF05060F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          BreathingSky(tint: technique.color, breath: _breath),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                BreathOrb(
                  breath: _breath,
                  color: technique.color,
                  position: session.positionAt(1),
                  size: 250,
                  caption: 'Ciclo 2 de 11',
                ),
                const SizedBox(height: 18),
                Transform.scale(scale: 1.05, child: const LumiAvatar(mood: LumiMood.calm, size: 58)),
                const SizedBox(height: 6),
                Text(
                  'Lumi respira contigo',
                  style: JournalStyle.hand(TextStyle(fontSize: 17, color: Colors.white.withValues(alpha: 0.7))),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
