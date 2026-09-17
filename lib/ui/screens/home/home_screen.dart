import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/mood_entry.dart';
import '../../../data/models/quote_service.dart';
import '../../../data/models/daily_challenge.dart';
import '../../../data/models/wellness_route.dart';
import '../../../data/models/reward_service.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../../domain/providers/theme_provider.dart';
import '../../widgets/animated_particles_background.dart';
import '../../widgets/challenge_dialog.dart';
import '../../widgets/reward_dialog.dart';
import '../../widgets/crisis_support_card.dart';
import '../reminders/reminders_screen.dart';
import '../routes/lesson_screen.dart';
import '../diary/new_diary_entry_screen.dart';
import '../breathing/breathing_screen.dart';
import '../garden/garden_screen.dart';
import '../../../domain/services/routes_service.dart';
import '../../../data/models/garden_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gimnasio_emocional/domain/services/notification_service.dart';
import '../../../domain/services/sound_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../data/models/commitment.dart';
import '../../../domain/services/commitment_service.dart';
import '../../widgets/commitment_check_card.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../data/models/weekly_summary.dart';
import '../summary/weekly_summary_screen.dart';
import '../../widgets/weekly_summary_card.dart';
import '../../../data/models/review_deck.dart';
import '../review/daily_review_screen.dart';
import '../../../data/models/lumi.dart';
import '../../../domain/services/mission_service.dart';
import '../missions/missions_screen.dart';
import '../../widgets/missions_home_card.dart';
import '../../../data/models/routes_overview.dart';
import 'widgets/home_header.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_progress.dart';
import 'widgets/mood_checkin_card.dart';
import 'widgets/today_plan.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MoodType? _selectedMood;
  Quote? _quote;
  Map<int, MoodType> _weeklyMoods = {};
  bool _hasDiaryToday = false;
  Set<String> _completedLessons = {};
  bool _hasLessonToday = false;
  List<WellnessRoute> _dynamicRoutes = [];
  bool _challengeCompletedToday = false;
  bool _crisisCardDismissedToday = false;

  /// Reto de una lección por el que hay que preguntar hoy.
  Commitment? _pendingCommitment;

  /// Aviso del resumen semanal (domingo y lunes, hasta abrirlo).
  bool _showWeeklySummaryCard = false;

  /// Lumi aparece cuando ya cargaron los datos del día (así no cambia de
  /// frase a media animación).
  bool _lumiReady = false;
  bool _lumiIntroSeen = true;

  /// Misiones de la semana (null hasta que cargan).
  MissionsState? _missions;
  bool _hasHabits = false;

  /// Repaso diario: tarjetas falladas pendientes y si ya se hizo hoy.
  Set<String> _reviewMissed = {};
  bool _reviewDoneToday = false;

  static const Map<String, String> _quoteTextKeys = {
    'La paz viene de adentro. No la busques afuera.': 'quoteService.localQuotes.0.text',
    'No tienes que controlarlo todo. A veces solo necesitas soltar.': 'quoteService.localQuotes.1.text',
    'Cada día es una nueva oportunidad para ser más amable contigo mismo.': 'quoteService.localQuotes.2.text',
    'La vulnerabilidad no es debilidad. Es la mayor medida de coraje.': 'quoteService.localQuotes.3.text',
    'Tu mente es un jardín. Tus pensamientos son las semillas.': 'quoteService.localQuotes.4.text',
    'No es la carga la que te destruye, es cómo la cargas.': 'quoteService.localQuotes.5.text',
    'Respira. Estás exactamente donde necesitas estar.': 'quoteService.localQuotes.6.text',
    'Hoy mereces tu propia amabilidad tanto como cualquier otra persona.': 'quoteService.localQuotes.7.text',
    'El autocuidado no es egoísmo. No puedes servir de una taza vacía.': 'quoteService.localQuotes.8.text',
    'Las emociones son como olas. Obsérvalas ir y venir.': 'quoteService.localQuotes.9.text',
    'Un paso pequeño hoy es un gran salto para tu bienestar.': 'quoteService.localQuotes.10.text',
    'No tienes que ser perfecto para merecer amor y aceptación.': 'quoteService.localQuotes.11.text',
    'La gratitud transforma lo que tienes en suficiente.': 'quoteService.localQuotes.12.text',
    'Tu valor no disminuye por la incapacidad de alguien de ver tu luz.': 'quoteService.localQuotes.13.text',
    'Está bien no estar bien. Lo que importa es no quedarte ahí.': 'quoteService.localQuotes.14.text',
    'La calma es un superpoder en un mundo lleno de ruido.': 'quoteService.localQuotes.15.text',
    'No compares tu capítulo 1 con el capítulo 20 de alguien más.': 'quoteService.localQuotes.16.text',
    'Sé paciente contigo mismo. El crecimiento toma tiempo.': 'quoteService.localQuotes.17.text',
    'La mejor relación que puedes tener es la que tienes contigo mismo.': 'quoteService.localQuotes.18.text',
    'Hoy elige la compasión. Empieza contigo.': 'quoteService.localQuotes.19.text',
    'El descanso no es rendirse. Es prepararse para seguir.': 'quoteService.localQuotes.20.text',
    'No necesitas una razón para merecer paz interior.': 'quoteService.localQuotes.21.text',
    'Cada respiración es una oportunidad para empezar de nuevo.': 'quoteService.localQuotes.22.text',
    'Tu salud mental es una prioridad, no un lujo.': 'quoteService.localQuotes.23.text',
    'Las pequeñas victorias de hoy son los grandes logros de mañana.': 'quoteService.localQuotes.24.text',
    'Permítete sentir. Las emociones no son tu enemigo.': 'quoteService.localQuotes.25.text',
    'Lo que nutre tu alma nunca es una pérdida de tiempo.': 'quoteService.localQuotes.26.text',
    'No eres tus pensamientos. Eres quien los observa.': 'quoteService.localQuotes.27.text',
    'Hoy es un buen día para cuidar de ti.': 'quoteService.localQuotes.28.text',
    'La verdadera fortaleza se muestra en los momentos de vulnerabilidad.': 'quoteService.localQuotes.29.text',
    'Tu viaje importa. Cada paso cuenta.': 'quoteService.localQuotes.30.text',
  };

 @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
  _checkProfileComplete();
  _loadChallengeState();
  _loadData();
  // Capturar la racha rota antes de cualquier check-in (que la reinicia a 1)
  // y guardarla cuando carguen las mecánicas, para que un escudo la recupere.
  final auth = context.read<AuthProvider>();
  final garden = context.read<GardenProvider>();
  final brokenStreak =
      auth.streakBrokenToday ? auth.userProgress!.currentStreak : 0;
  garden.loadGarden().then((_) {
    if (brokenStreak > 0) garden.saveStreakBeforeBreak(brokenStreak);
  });
  await NotificationService.instance.requestPermissions();
  await _scheduleDailyReminders();
});
}

  void _checkProfileComplete() {
    try {
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isLoggedIn) {
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }
      if (!authProvider.isProfileComplete) {
        if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
        return;
      }
    } catch (e) {
      debugPrint('Profile check error: $e');
    }
  }

  // Carga inmediata del estado del reto — evita el flash de "no completado"
Future<void> _loadChallengeState() async {
  try {
    final uid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final done = prefs.getBool('challenge_done_${uid}_$todayStr') ?? false;
    final crisisDismissed =
        prefs.getBool('crisis_card_dismissed_${uid}_$todayStr') ?? false;
    if (mounted) {
      setState(() {
        _challengeCompletedToday = done;
        _crisisCardDismissedToday = crisisDismissed;
      });
    }
  } catch (e) {
    debugPrint('Error loading challenge state: $e');
  }
}

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      final quote = QuoteService.getQuoteOfTheDay();
      if (!mounted) return;
      setState(() => _quote = quote);
    } catch (e) {
      debugPrint('Error loading quote: $e');
    }

    if (!mounted) return;
    try {
      final auth = context.read<AuthProvider>();
      final moods = await auth.getWeeklyMoods();
      if (!mounted) return;
      setState(() => _weeklyMoods = moods);
    } catch (e) { debugPrint('Error loading weekly moods: $e'); }

    if (!mounted) return;
    try {
      final auth = context.read<AuthProvider>();
      final todayMood = await auth.getTodayMood();
      if (!mounted) return;
      if (todayMood != null) setState(() => _selectedMood = todayMood);
    } catch (e) { debugPrint('Error loading today mood: $e'); }

    if (!mounted) return;
    try {
      final auth = context.read<AuthProvider>();
      final hasDiary = await auth.hasDiaryEntryToday();
      if (!mounted) return;
      setState(() => _hasDiaryToday = hasDiary);
    } catch (e) { debugPrint('Error checking diary: $e'); }

    if (!mounted) return;
    try {
      final locale = context.locale.languageCode;
      final routes = await RoutesService().getRoutes(locale);
      if (!mounted) return;
      setState(() => _dynamicRoutes = routes);
    } catch (e) {
      debugPrint('Error loading dynamic routes: $e');
      if (mounted) setState(() => _dynamicRoutes = WellnessRoute.all);
    }

    if (!mounted) return;
    try {
      final auth = context.read<AuthProvider>();
      final completed = await auth.getCompletedLessons();
      if (!mounted) return;
      final hasLesson = await auth.hasCompletedLessonToday();
      if (!mounted) return;
      setState(() { _completedLessons = completed; _hasLessonToday = hasLesson; });
    } catch (e) { debugPrint('Error loading completed lessons: $e'); }

    if (!mounted) return;
    try {
      final review = await context.read<AuthProvider>().loadReviewState();
      if (mounted) {
        setState(() {
          _reviewMissed = review.missed;
          _reviewDoneToday = review.doneToday;
        });
      }
    } catch (e) { debugPrint('Error loading review state: $e'); }

    if (!mounted) return;
    try {
      final uid = context.read<AuthProvider>().firebaseUser?.uid;
      if (uid != null) {
        final pending = await CommitmentService.instance.pendingToAsk(uid);
        if (mounted) setState(() => _pendingCommitment = pending);
      }
    } catch (e) { debugPrint('Error loading commitment: $e'); }

    if (!mounted) return;
    await _loadWeeklySummaryCard();

    if (!mounted) return;
    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.firebaseUser?.uid;
      if (uid != null) {
        final habits = await auth.getHabits();
        if (!mounted) return;
        final missions = await MissionService.instance.load(
          uid: uid,
          hasHabits: habits.isNotEmpty,
          reviewAvailable: _reviewDeck.isNotEmpty,
        );
        if (mounted) setState(() { _missions = missions; _hasHabits = habits.isNotEmpty; });
      }
    } catch (e) { debugPrint('Error loading missions: $e'); }

    if (!mounted) return;
    try {
      final uid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('lumi_intro_seen_$uid') ?? false;
      if (mounted) setState(() { _lumiIntroSeen = seen; _lumiReady = true; });
    } catch (e) {
      if (mounted) setState(() => _lumiReady = true);
    }

  
  }

  /// Programa (o cancela) los recordatorios diarios en función del estado actual.
/// Streak: solo se programa si el usuario NO hizo check-in hoy.
/// Harvest: solo se programa si hay plantas listas para cosechar.
Future<void> _scheduleDailyReminders() async {
  if (!mounted) return;
  final auth = context.read<AuthProvider>();
  final garden = context.read<GardenProvider>();

  // ── Streak reminder ──────────────────────────────────────────────
  try {
    // Si ya hizo check-in hoy, cancelar cualquier recordatorio pendiente
    final progress = auth.userProgress;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCheckIn = progress?.lastCheckIn;
    final alreadyCheckedInToday = lastCheckIn != null &&
        DateTime(lastCheckIn.year, lastCheckIn.month, lastCheckIn.day) == today;

    if (alreadyCheckedInToday) {
      await NotificationService.instance.cancelStreakReminder();
      debugPrint('✅ Streak reminder cancelled — check-in already done today');
    } else {
      await NotificationService.instance.scheduleStreakReminderAt();
      debugPrint('⏰ Streak reminder scheduled for 20:00');
    }
  } catch (e) {
    debugPrint('Error scheduling streak reminder: $e');
  }

  // ── Harvest reminder ─────────────────────────────────────────────
  try {
    final hasPendingHarvest = garden.garden.any((p) {
      final item = GardenCatalog.findById(p.itemId);
      return item != null && p.hasPendingHarvestFor(item);
    });

    if (hasPendingHarvest) {
      await NotificationService.instance.scheduleHarvestReminder(
        hour: 10, minute: 0,
      );
      debugPrint('🌾 Harvest reminder scheduled for 10:00');
    } else {
      await NotificationService.instance.cancelHarvestReminder();
      debugPrint('🌾 Harvest reminder cancelled — nothing to harvest');
    }
  } catch (e) {
    debugPrint('Error scheduling harvest reminder: $e');
  }
}

  // ── Apoyo en crisis ────────────────────────────────────────────────────────

  /// Días de esta semana con un ánimo de categoría negativa.
  int get _hardDaysThisWeek => _weeklyMoods.values
      .where((mood) => mood.category == 'negative')
      .length;

  /// A partir de 3 días difíciles en la semana ofrecemos las líneas de ayuda.
  /// No es un diagnóstico: solo deja la puerta abierta, y se puede ocultar.
  bool get _shouldOfferCrisisSupport =>
      !_crisisCardDismissedToday && _hardDaysThisWeek >= 3;

  Future<void> _dismissCrisisCard() async {
    HapticFeedback.lightImpact();
    setState(() => _crisisCardDismissedToday = true);
    try {
      final uid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      await prefs.setBool('crisis_card_dismissed_${uid}_$todayStr', true);
    } catch (e) {
      debugPrint('Error dismissing crisis card: $e');
    }
  }

  // ── Lumi ───────────────────────────────────────────────────────────────────

  LumiLine _lumiLine(AuthProvider auth) => LumiDialog.forHome(LumiContext(
        name: auth.userName.isNotEmpty ? auth.userName : 'home.user'.tr(),
        hour: DateTime.now().hour,
        introSeen: _lumiIntroSeen,
        todayMoodCategory: _selectedMood?.category,
        streak: auth.currentStreak,
        streakBroken: auth.streakBrokenToday,
        hasPendingCommitment: _pendingCommitment != null,
        lessonDoneToday: _hasLessonToday,
        nextLessonTitle: _suggested?.nextLesson?.title,
        reviewAvailable: _reviewDeck.isNotEmpty,
        reviewDoneToday: _reviewDoneToday,
      ));

  Future<void> _markLumiIntroSeen() async {
    if (_lumiIntroSeen) return;
    final uid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('lumi_intro_seen_$uid', true);
    } catch (_) {}
    // No se cambia _lumiIntroSeen en esta sesión: la presentación sigue
    // visible hasta la próxima vez que se abra el Home.
  }

  // ── Misiones ───────────────────────────────────────────────────────────────

  Future<void> _openMissions() async {
    HapticFeedback.mediumImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MissionsScreen(hasHabits: _hasHabits, reviewAvailable: _reviewDeck.isNotEmpty),
      ),
    );
    if (mounted) _loadData();
  }

  // ── Repaso diario ──────────────────────────────────────────────────────────

  List<ReviewCard> get _reviewDeck => ReviewDeck.build(
        pool: ReviewDeck.pool(_dynamicRoutes, _completedLessons),
        missedIds: _reviewMissed,
        dayKey: WeeklySummary.dayKey(DateTime.now()),
      );

  Future<void> _openReview() async {
    final deck = _reviewDeck;
    if (deck.isEmpty) {
      HapticFeedback.heavyImpact();
      SoundService.instance.play(Sfx.toggleOff, volume: 0.4);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('review.lockedSubtitle'.tr())));
      return;
    }
    HapticFeedback.mediumImpact();
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DailyReviewScreen(deck: deck)),
    );
    if (done == true && mounted) _loadData();
  }

  // ── Resumen semanal ────────────────────────────────────────────────────────

  /// Clave de la semana: el domingo más reciente (domingo = hoy, lunes = ayer).
  String get _summaryWeekKey {
    final now = DateTime.now();
    final sunday = DateTime(now.year, now.month, now.day - (now.weekday % 7));
    return WeeklySummary.dayKey(sunday);
  }

  Future<void> _loadWeeklySummaryCard() async {
    final uid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
    final title = 'summary.notificationTitle'.tr();
    final body = 'summary.notificationBody'.tr();
    if (!kIsWeb) {
      NotificationService.instance
          .scheduleWeeklySummaryReminder(title: title, body: body)
          .catchError((Object e) => debugPrint('Weekly summary reminder: $e'));
    }
    final weekday = DateTime.now().weekday;
    if (weekday != DateTime.sunday && weekday != DateTime.monday) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('weekly_summary_seen_${uid}_$_summaryWeekKey') ?? false;
      if (mounted) setState(() => _showWeeklySummaryCard = !seen);
    } catch (e) { debugPrint('Weekly summary card: $e'); }
  }

  Future<void> _markWeeklySummarySeen() async {
    final uid = context.read<AuthProvider>().firebaseUser?.uid ?? '';
    setState(() => _showWeeklySummaryCard = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('weekly_summary_seen_${uid}_$_summaryWeekKey', true);
    } catch (_) {}
  }

  Future<void> _openWeeklySummary() async {
    HapticFeedback.mediumImpact();
    await _markWeeklySummarySeen();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WeeklySummaryScreen(source: 'home')),
    );
  }

  // ── Reto de lección ────────────────────────────────────────────────────────

  Future<void> _answerCommitment(CommitmentStatus status) async {
    final commitment = _pendingCommitment;
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    if (commitment == null || uid == null) return;
    await CommitmentService.instance.answer(uid, commitment.id, status);
    AnalyticsService.instance.commitmentAnswered(status.name, commitment.daysAgo(DateTime.now()));
    if (!kIsWeb) {
      NotificationService.instance.cancelCommitmentReminder().catchError((_) {});
    }
    if (status == CommitmentStatus.skipped) return;
    SoundService.instance.play(
      status == CommitmentStatus.done ? Sfx.achievement : Sfx.habit,
      volume: 0.6,
    );
    await Future.delayed(const Duration(milliseconds: 900));
    await _grantGardenReward(RewardSource.commitment);
  }

  Future<void> _retryCommitment() async {
    final commitment = _pendingCommitment;
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    if (commitment == null || uid == null) return;
    await CommitmentService.instance.retryToday(uid, commitment.id);
    AnalyticsService.instance.commitmentRetried();
  }

  // ── Garden reward ──────────────────────────────────────────────────────────

  Future<void> _grantGardenReward(RewardSource source) async {
    if (!mounted) return;
    try {
      final garden = context.read<GardenProvider>();
      final reward = await garden.grantReward(source);
      if (mounted) await RewardDialog.show(context, reward);
    } catch (e) {
      debugPrint('Error granting garden reward: $e');
    }
  }

  // ── Comodín de racha ───────────────────────────────────────────────────────

  Future<void> _useStreakShield() async {
  final garden = context.read<GardenProvider>();
  final auth = context.read<AuthProvider>();
  
  // El escudo solo funciona si la racha está rota
  if (!garden.canUseShield) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Text('🛡️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'home.shieldOnlyWhenBroken'.tr(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          )),
        ]),
        backgroundColor: Colors.grey.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
    }
    return;
  }

  final recoveredStreak = await garden.useStreakShield();
  if (!mounted) return;

  if (recoveredStreak > 0) {
    // Restaurar la racha en Firestore via AuthProvider
    await auth.restoreStreakWithShield(recoveredStreak);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Text('🛡️', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'home.shieldUsed'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        )),
      ]),
      backgroundColor: const Color(0xFFF59E0B),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }
}

  // ── Lessons ────────────────────────────────────────────────────────────────

  /// La lección sugerida: la misma que "Continúa donde te quedaste" en rutas.
  RouteProgress? get _suggested {
    final routes = _dynamicRoutes.isNotEmpty ? _dynamicRoutes : WellnessRoute.all;
    return RoutesOverview.compute(routes, _completedLessons).suggested;
  }

  Future<void> _openNextLesson() async {
    final suggested = _suggested;
    final lesson = suggested?.nextLesson;
    if (suggested == null || lesson == null) {
      SoundService.instance.play(Sfx.routeComplete, volume: 0.6);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('home.allLessonsComplete'.tr()),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      return;
    }
    SoundService.instance.play(Sfx.tapNode, volume: 0.6);
    await _openLesson(suggested.route, lesson);
  }

  /// Abre una lección. `LessonScreen` ya guarda el progreso; aquí solo se
  /// recarga, se da la recompensa del jardín (una vez al día) y se encadena
  /// "Siguiente lección" si la eligió.
  Future<void> _openLesson(WellnessRoute route, Lesson lesson) async {
    final index = route.lessons.indexOf(lesson);
    final next = index >= 0 && index < route.lessons.length - 1 ? route.lessons[index + 1] : null;
    final hadLessonToday = _hasLessonToday;
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lesson: lesson,
          routeColor: route.color,
          routeEmoji: route.emoji,
          routeId: route.id,
          nextLesson: next,
        ),
      ),
    );
    if (!mounted) return;
    final completed = result == true || result == LessonScreen.nextResult;
    if (!completed) return;
    await _loadData();
    if (!hadLessonToday && mounted) await _grantGardenReward(RewardSource.lessonCompleted);
    if (result == LessonScreen.nextResult && next != null && mounted) {
      await _openLesson(route, next);
    }
  }

  // ── Reto diario ────────────────────────────────────────────────────────────

  Future<void> _completeChallenge(DailyChallenge challenge) async {
    // ChallengeAction ya da la recompensa del jardín: aquí solo XP y estado.
    final completed = await ChallengeAction.execute(context, challenge);
    if (!completed || !mounted) return;
    setState(() => _challengeCompletedToday = true);
    final auth = context.read<AuthProvider>();
    final garden = context.read<GardenProvider>();
    try {
      final uid = auth.firebaseUser?.uid ?? '';
      final today = WeeklySummary.dayKey(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('challenge_done_${uid}_$today', true);
      // El id incluye el año: antes `challenge_<día>_<mes>` chocaba con el
      // mismo día del año siguiente y ya no daba XP.
      await auth.completeLesson('challenge_$today', challenge.xpReward, garden: garden);
    } catch (e) {
      debugPrint('Error awarding challenge XP: $e');
    }
  }

  // ── Diario rápido ──────────────────────────────────────────────────────────

  Future<void> _openQuickDiary() async {
    SoundService.instance.play(Sfx.pageTurn, volume: 0.6);
    final auth = context.read<AuthProvider>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NewDiaryEntryScreen()),
    );
    if (result != true || !mounted) return;
    _loadData();
    // Recompensa del jardín por escribir: una vez al día
    final uid = auth.firebaseUser?.uid ?? '';
    final prefs = await SharedPreferences.getInstance();
    final key = 'diary_reward_${uid}_${WeeklySummary.dayKey(DateTime.now())}';
    if (prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);
    await _grantGardenReward(RewardSource.diaryEntry);
  }

  // ── Mood ───────────────────────────────────────────────────────────────────

  Future<void> _onMoodSelected(MoodType mood) async {
    HapticFeedback.mediumImpact();

    if (_selectedMood != null && _selectedMood != mood) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('home.moodChangeTitle'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
          content: RichText(
            text: TextSpan(
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 15),
              children: [
                TextSpan(text: 'home.moodChangeFrom'.tr()),
                TextSpan(text: '${_selectedMood!.emoji} ${_moodLabel(_selectedMood!)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: 'home.moodChangeTo'.tr()),
                TextSpan(text: '${mood.emoji} ${_moodLabel(mood)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('common.cancel'.tr(), style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: mood.color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('home.moodChange'.tr()),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }

    setState(() => _selectedMood = mood);
    final auth = context.read<AuthProvider>();
    await auth.recordCheckIn();

    if (auth.firebaseUser != null) {
      final entry = MoodEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(), mood: mood);
      try {
        final isFirstToday = await auth.saveMoodEntry(entry);
        SoundService.instance.play(Sfx.checkin, volume: 0.6);
        AnalyticsService.instance.moodCheckIn();
        setState(() => _weeklyMoods[DateTime.now().weekday] = mood);
        if (mounted && isFirstToday) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(
              content: Row(children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'home.moodRegistered'.tr(namedArgs: {'mood': _moodLabel(mood), 'xp': '${mood.xpReward}'}),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                )),
                const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 20),
              ]),
              backgroundColor: Color.lerp(mood.color, Colors.black, 0.15),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ));
        }
        if (isFirstToday && mounted) {
          await _grantGardenReward(RewardSource.moodCheckIn);
        }
      } catch (e) { debugPrint('Error saving mood: $e'); }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _moodLabel(MoodType mood) {
    final key = 'mood.${mood.name}';
    final translated = key.tr();
    return translated == key ? mood.label : translated;
  }

  String _levelTitleKey(int level) {
    if (level <= 3) return 'userProgress.levelTitles.emotionalNovice';
    if (level <= 7) return 'userProgress.levelTitles.consciousApprentice';
    if (level <= 12) return 'userProgress.levelTitles.innerExplorer';
    if (level <= 18) return 'userProgress.levelTitles.resilientWarrior';
    return 'userProgress.levelTitles.zenMaster';
  }

  String _levelTitleText(int level, String fallback, dynamic progress) {
    try {
      final key = (progress as dynamic).levelTitleKey as String?;
      if (key != null) { final t = key.tr(); if (t != key) return t; }
    } catch (_) {}
    final derivedKey = _levelTitleKey(level);
    final t = derivedKey.tr();
    return t == derivedKey ? fallback : t;
  }

  String _challengeTitle(DailyChallenge c) {
    if (c.titleKey != null) { final t = c.titleKey!.tr(); if (t != c.titleKey) return t; }
    return c.title;
  }

  String _challengeDescription(DailyChallenge c) {
    if (c.descriptionKey != null) { final t = c.descriptionKey!.tr(); if (t != c.descriptionKey) return t; }
    return c.description;
  }

  String _challengeCategory(DailyChallenge c) {
    if (c.categoryKey != null) { final t = c.categoryKey!.tr(); if (t != c.categoryKey) return t; }
    return c.category;
  }

  String _quoteText(Quote quote) {
    try {
      final key = (quote as dynamic).textKey as String?;
      if (key != null) { final t = key.tr(); if (t != key) return t; }
    } catch (_) {}
    final mappedKey = _quoteTextKeys[quote.text];
    if (mappedKey != null) { final t = mappedKey.tr(); if (t != mappedKey) return t; }
    return quote.text;
  }

  String _quoteAuthor(Quote quote) {
    try {
      final key = (quote as dynamic).authorKey as String?;
      if (key != null) { final t = key.tr(); if (t != key) return t; }
    } catch (_) {}
    if (quote.author == 'Desconocido') {
      final t = 'quoteService.unknownAuthor'.tr();
      if (t != 'quoteService.unknownAuthor') return t;
    }
    return quote.author;
  }

  List<Color> _getArchetypeGradient(String? archetype) {
    switch (archetype) {
      case 'explorador': return [const Color(0xFF6366F1), const Color(0xFF4338CA)];
      case 'guerrero':   return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case 'social':     return [const Color(0xFFEC4899), const Color(0xFFDB2777)];
      case 'sabio':      return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'libre':      return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      default:           return [AppColors.primary, AppColors.primaryDark];
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'home.greetingMorning'.tr();
    if (hour < 19) return 'home.greetingAfternoon'.tr();
    return 'home.greetingEvening'.tr();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final gardenProvider = context.watch<GardenProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = authProvider.userProgress;
    final streak = authProvider.currentStreak;
    final totalXp = progress?.totalXp ?? 0;
    final level = progress?.level ?? 1;
    final levelTitle = _levelTitleText(level, progress?.levelTitle ?? '', progress);
    final xpForNext = progress?.xpForNextLevel ?? 100;
    final xpInLevel = xpForNext == 0 ? 0 : totalXp % xpForNext;
    final challenge = DailyChallenge.getToday();
    final suggested = _suggested;
    final avatarColors = _getArchetypeGradient(authProvider.userModel?.archetype);
    final name = authProvider.userName.isNotEmpty ? authProvider.userName : 'home.user'.tr();

    final hasHarvest = gardenProvider.garden.any((p) {
      final item = GardenCatalog.findById(p.itemId);
      return item != null && p.hasPendingHarvestFor(item);
    });
    final gardenBadge = hasHarvest
        ? GardenBadge.harvest
        : gardenProvider.seeds > 0
            ? GardenBadge.seeds
            : GardenBadge.none;
    final activeMultiplier = gardenProvider.activeMultiplier;
    final hasDeck = _reviewDeck.isNotEmpty;

    // Entrada escalonada de cada bloque
    Widget enter(Widget child, int order) => child
        .animate()
        .fadeIn(delay: (120 + order * 60).ms, duration: 420.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF0F0F23), const Color(0xFF15152B), const Color(0xFF16213E)]
                    : [const Color(0xFFF1EEFF), const Color(0xFFFAF8FF), const Color(0xFFFFFBF3)],
              ),
            ),
          ),
          const AnimatedParticlesBackground(particleCount: 14, maxShootingStars: 0),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 36),
                children: [
                  HomeHeader(
                    name: name,
                    greeting: _getGreeting(),
                    avatarColors: avatarColors,
                    level: level,
                    levelProgress: xpForNext == 0 ? 0 : xpInLevel / xpForNext,
                    streak: streak,
                    gardenBadge: gardenBadge,
                    isDark: isDark,
                    onGarden: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GardenScreen())),
                    onToggleTheme: themeProvider.toggleTheme,
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (activeMultiplier != null) ...[
                          _buildMultiplierBanner(activeMultiplier.multiplier, activeMultiplier.timeRemaining, isDark),
                          const SizedBox(height: 12),
                        ],
                        if (gardenProvider.canUseShield) ...[
                          _buildShieldBanner(gardenProvider.streakShields, isDark),
                          const SizedBox(height: 12),
                        ],

                        // ── Lumi en su cielo + progreso de hoy ─────────────────
                        HomeHero(
                          line: _lumiReady ? _lumiLine(authProvider) : null,
                          isDark: isDark,
                          onIntroSeen: _markLumiIntroSeen,
                          checkInDone: _selectedMood != null,
                          lessonDone: _hasLessonToday,
                          diaryDone: _hasDiaryToday,
                          hour: DateTime.now().hour,
                        ),
                        const SizedBox(height: 16),

                        // ── Avisos del día (solo si aplican) ───────────────────
                        if (_pendingCommitment != null) ...[
                          enter(
                            CommitmentCheckCard(
                              key: ValueKey(_pendingCommitment!.id),
                              commitment: _pendingCommitment!,
                              isDark: isDark,
                              onAnswer: _answerCommitment,
                              onRetry: _retryCommitment,
                              onClose: () => setState(() => _pendingCommitment = null),
                            ),
                            1,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_showWeeklySummaryCard) ...[
                          enter(
                            WeeklySummaryCard(isDark: isDark, onOpen: _openWeeklySummary, onDismiss: _markWeeklySummarySeen),
                            1,
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_shouldOfferCrisisSupport) ...[
                          CrisisSupportCard(isDark: isDark, onDismiss: _dismissCrisisCard),
                          const SizedBox(height: 16),
                        ],

                        // ── Ánimo ──────────────────────────────────────────────
                        enter(
                          MoodCheckInCard(
                            selected: _selectedMood,
                            weeklyMoods: _weeklyMoods,
                            isDark: isDark,
                            onSelect: _onMoodSelected,
                          ),
                          2,
                        ),
                        const SizedBox(height: 26),

                        // ── Plan de hoy ────────────────────────────────────────
                        enter(HomeSectionTitle(kicker: 'home.planKicker'.tr(), title: 'home.todayTraining'.tr(), isDark: isDark), 3),
                        const SizedBox(height: 12),
                        enter(
                          TodayLessonCard(
                            routeEmoji: suggested?.route.emoji,
                            routeTitle: suggested?.route.title,
                            lessonTitle: suggested?.nextLesson?.title,
                            color: suggested?.route.color ?? const Color(0xFF10B981),
                            colorDark: suggested?.route.colorDark ?? const Color(0xFF059669),
                            doneToday: _hasLessonToday,
                            allComplete: suggested == null,
                            onTap: suggested == null ? null : _openNextLesson,
                          ),
                          4,
                        ),
                        const SizedBox(height: 12),
                        enter(
                          Row(
                            children: [
                              Expanded(
                                child: QuickActionTile(
                                  emoji: '🃏',
                                  title: _reviewDoneToday ? 'review.doneTitle'.tr() : 'review.title'.tr(),
                                  subtitle: !hasDeck
                                      ? 'review.lockedSubtitle'.tr()
                                      : _reviewDoneToday
                                          ? 'review.doneSubtitle'.tr()
                                          : 'review.homeSubtitle'.tr(),
                                  color: const Color(0xFFF59E0B),
                                  state: !hasDeck
                                      ? QuickTileState.locked
                                      : _reviewDoneToday
                                          ? QuickTileState.done
                                          : QuickTileState.normal,
                                  isDark: isDark,
                                  onTap: _openReview,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: QuickActionTile(
                                  emoji: '🌬️',
                                  title: 'home.breathingTitle'.tr(),
                                  subtitle: 'home.breathingSubtitle'.tr(),
                                  color: AppColors.moodCalm,
                                  isDark: isDark,
                                  // La recompensa la da BreathingScreen al completar la sesión
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BreathingScreen())),
                                ),
                              ),
                            ],
                          ),
                          5,
                        ),
                        const SizedBox(height: 12),
                        enter(
                          Row(
                            children: [
                              Expanded(
                                child: QuickActionTile(
                                  emoji: '📝',
                                  title: 'home.quickDiary'.tr(),
                                  subtitle: _hasDiaryToday ? 'home.diaryDoneSubtitle'.tr() : 'home.quickDiarySubtitle'.tr(),
                                  color: const Color(0xFF10B981),
                                  state: _hasDiaryToday ? QuickTileState.done : QuickTileState.normal,
                                  isDark: isDark,
                                  onTap: _openQuickDiary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: QuickActionTile(
                                  emoji: '🎯',
                                  title: 'home.habitsShort'.tr(),
                                  subtitle: 'home.habitsRemindersSubtitle'.tr(),
                                  color: const Color(0xFF8B5CF6),
                                  isDark: isDark,
                                  onTap: () async {
                                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const RemindersScreen()));
                                    if (mounted) _loadData();
                                  },
                                ),
                              ),
                            ],
                          ),
                          6,
                        ),
                        const SizedBox(height: 16),
                        enter(
                          DailyChallengeCard(
                            challenge: challenge,
                            title: _challengeTitle(challenge),
                            description: _challengeDescription(challenge),
                            category: _challengeCategory(challenge),
                            done: _challengeCompletedToday,
                            isDark: isDark,
                            onTap: () => _completeChallenge(challenge),
                          ),
                          7,
                        ),

                        // ── Misiones ───────────────────────────────────────────
                        if (_missions != null) ...[
                          const SizedBox(height: 16),
                          enter(MissionsHomeCard(state: _missions!, isDark: isDark, onTap: _openMissions), 8),
                        ],
                        const SizedBox(height: 26),

                        // ── Tu progreso ────────────────────────────────────────
                        enter(HomeSectionTitle(kicker: 'home.progressKicker'.tr(), title: 'home.yourSummary'.tr(), isDark: isDark), 9),
                        const SizedBox(height: 12),
                        enter(
                          HomeProgressCard(
                            streak: streak,
                            bestStreak: progress?.longestStreak ?? 0,
                            level: level,
                            levelTitle: levelTitle,
                            xpInLevel: xpInLevel,
                            xpForNext: xpForNext,
                            totalXp: totalXp,
                            levelColors: avatarColors,
                            isDark: isDark,
                          ),
                          10,
                        ),
                        const SizedBox(height: 26),

                        // ── Frase del día ──────────────────────────────────────
                        if (_quote != null)
                          enter(QuoteNote(text: _quoteText(_quote!), author: _quoteAuthor(_quote!), isDark: isDark), 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BANNER: Multiplicador XP ───────────────────────────────────────────────

  Widget _buildMultiplierBanner(double mult, Duration remaining, bool isDark) {
    final mins = remaining.inMinutes + 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          blurRadius: 12,
        )],
      ),
      child: Row(children: [
        const Text('⚡', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'home.xpMultiplierActive'.tr(namedArgs: {'mult': mult.toStringAsFixed(1)}),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
            ),
            Text(
              'home.xpMultiplierHint'.tr(namedArgs: {'mins': '$mins'}),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${mins}min',
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  // ── BANNER: Comodín de racha ───────────────────────────────────────────────

  Widget _buildShieldBanner(int shields, bool isDark) {
    return GestureDetector(
      onTap: _useStreakShield,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 12,
          )],
        ),
        child: Row(children: [
          const Text('🛡️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'home.shieldAvailable'.tr(namedArgs: {'count': '$shields'}),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text(
                'home.shieldHint'.tr(),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'home.shieldUse'.tr(),
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ]),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

}