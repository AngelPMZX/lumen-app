import 'dart:math';
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
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/theme_provider.dart';
import '../../widgets/animated_particles_background.dart';
import '../../widgets/weekly_mood_chart.dart';
import '../../widgets/daily_progress_ring.dart';
import '../reminders/reminders_screen.dart';
import '../routes/lesson_screen.dart';
import '../diary/new_diary_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _streakGlow;
  MoodType? _selectedMood;
  Quote? _quote;
  Map<int, MoodType> _weeklyMoods = {};
  bool _isLoadingQuote = true;
  bool _hasDiaryToday = false;
  Set<String> _completedLessons = {};
  bool _hasLessonToday = false;

  static const Map<String, String> _quoteTextKeys = {
    'La paz viene de adentro. No la busques afuera.':
        'quoteService.localQuotes.0.text',
    'No tienes que controlarlo todo. A veces solo necesitas soltar.':
        'quoteService.localQuotes.1.text',
    'Cada día es una nueva oportunidad para ser más amable contigo mismo.':
        'quoteService.localQuotes.2.text',
    'La vulnerabilidad no es debilidad. Es la mayor medida de coraje.':
        'quoteService.localQuotes.3.text',
    'Tu mente es un jardín. Tus pensamientos son las semillas.':
        'quoteService.localQuotes.4.text',
    'No es la carga la que te destruye, es cómo la cargas.':
        'quoteService.localQuotes.5.text',
    'Respira. Estás exactamente donde necesitas estar.':
        'quoteService.localQuotes.6.text',
    'Hoy mereces tu propia amabilidad tanto como cualquier otra persona.':
        'quoteService.localQuotes.7.text',
    'El autocuidado no es egoísmo. No puedes servir de una taza vacía.':
        'quoteService.localQuotes.8.text',
    'Las emociones son como olas. Obsérvalas ir y venir.':
        'quoteService.localQuotes.9.text',
    'Un paso pequeño hoy es un gran salto para tu bienestar.':
        'quoteService.localQuotes.10.text',
    'No tienes que ser perfecto para merecer amor y aceptación.':
        'quoteService.localQuotes.11.text',
    'La gratitud transforma lo que tienes en suficiente.':
        'quoteService.localQuotes.12.text',
    'Tu valor no disminuye por la incapacidad de alguien de ver tu luz.':
        'quoteService.localQuotes.13.text',
    'Está bien no estar bien. Lo que importa es no quedarte ahí.':
        'quoteService.localQuotes.14.text',
    'La calma es un superpoder en un mundo lleno de ruido.':
        'quoteService.localQuotes.15.text',
    'No compares tu capítulo 1 con el capítulo 20 de alguien más.':
        'quoteService.localQuotes.16.text',
    'Sé paciente contigo mismo. El crecimiento toma tiempo.':
        'quoteService.localQuotes.17.text',
    'La mejor relación que puedes tener es la que tienes contigo mismo.':
        'quoteService.localQuotes.18.text',
    'Hoy elige la compasión. Empieza contigo.':
        'quoteService.localQuotes.19.text',
    'El descanso no es rendirse. Es prepararse para seguir.':
        'quoteService.localQuotes.20.text',
    'No necesitas una razón para merecer paz interior.':
        'quoteService.localQuotes.21.text',
    'Cada respiración es una oportunidad para empezar de nuevo.':
        'quoteService.localQuotes.22.text',
    'Tu salud mental es una prioridad, no un lujo.':
        'quoteService.localQuotes.23.text',
    'Las pequeñas victorias de hoy son los grandes logros de mañana.':
        'quoteService.localQuotes.24.text',
    'Permítete sentir. Las emociones no son tu enemigo.':
        'quoteService.localQuotes.25.text',
    'Lo que nutre tu alma nunca es una pérdida de tiempo.':
        'quoteService.localQuotes.26.text',
    'No eres tus pensamientos. Eres quien los observa.':
        'quoteService.localQuotes.27.text',
    'Hoy es un buen día para cuidar de ti.':
        'quoteService.localQuotes.28.text',
    'La verdadera fortaleza se muestra en los momentos de vulnerabilidad.':
        'quoteService.localQuotes.29.text',
    'Tu viaje importa. Cada paso cuenta.':
        'quoteService.localQuotes.30.text',
  };

  @override
  void initState() {
    super.initState();
    _streakGlow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileComplete();
      _loadData();
    });
  }

  void _checkProfileComplete() {
    try {
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isLoggedIn) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
        return;
      }
      if (!authProvider.isProfileComplete) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
        }
        return;
      }
    } catch (e) {
      debugPrint('Profile check error: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final quote = await QuoteService.getQuoteOfTheDay();
      if (mounted) {
        setState(() {
          _quote = quote;
          _isLoadingQuote = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingQuote = false);
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final moods = await authProvider.getWeeklyMoods();
      if (mounted) setState(() => _weeklyMoods = moods);
    } catch (e) {
      debugPrint('Error loading weekly moods: $e');
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final todayMood = await authProvider.getTodayMood();
      if (mounted && todayMood != null) {
        setState(() => _selectedMood = todayMood);
      }
    } catch (e) {
      debugPrint('Error loading today mood: $e');
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final hasDiary = await authProvider.hasDiaryEntryToday();
      if (mounted) setState(() => _hasDiaryToday = hasDiary);
    } catch (e) {
      debugPrint('Error checking diary: $e');
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final completed = await authProvider.getCompletedLessons();
      if (mounted) setState(() => _completedLessons = completed);
    } catch (e) {
      debugPrint('Error loading completed lessons: $e');
    }
  }

  Future<void> _openNextLesson() async {
    for (final route in WellnessRoute.all) {
      for (int i = 0; i < route.lessons.length; i++) {
        final lesson = route.lessons[i];
        if (!_completedLessons.contains(lesson.id)) {
          if (i == 0 || _completedLessons.contains(route.lessons[i - 1].id)) {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => LessonScreen(
                  lesson: lesson,
                  routeColor: route.color,
                  routeEmoji: route.emoji,
                ),
              ),
            );
            if (result == true) {
              _loadData();
              setState(() => _hasLessonToday = true);
            }
            return;
          }
        }
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                'home.allLessonsComplete'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  (String, String, Color)? get _nextLessonInfo {
    for (final route in WellnessRoute.all) {
      for (int i = 0; i < route.lessons.length; i++) {
        final lesson = route.lessons[i];
        if (!_completedLessons.contains(lesson.id)) {
          if (i == 0 || _completedLessons.contains(route.lessons[i - 1].id)) {
            return (
              _lessonTitle(route, lesson),
              '${route.emoji} ${_routeTitle(route)}',
              route.color,
            );
          }
        }
      }
    }
    return null;
  }

  Future<void> _onMoodSelected(MoodType mood) async {
    HapticFeedback.mediumImpact();

    if (_selectedMood != null && _selectedMood != mood) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'home.moodChangeTitle'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          content: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 15,
              ),
              children: [
                TextSpan(text: 'home.moodChangeFrom'.tr()),
                TextSpan(
                  text:
                      '${_selectedMood!.emoji} ${_moodLabel(_selectedMood!)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: 'home.moodChangeTo'.tr()),
                TextSpan(
                  text: '${mood.emoji} ${_moodLabel(mood)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'common.cancel'.tr(),
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: mood.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('home.moodChange'.tr()),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _selectedMood = mood);

    final authProvider = context.read<AuthProvider>();
    await authProvider.recordCheckIn();

    if (authProvider.firebaseUser != null) {
      final entry = MoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mood: mood,
      );
      try {
        final isFirstToday = await authProvider.saveMoodEntry(entry);

        setState(() {
          _weeklyMoods[DateTime.now().weekday] = mood;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(mood.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isFirstToday
                          ? 'home.moodRegistered'.tr(namedArgs: {
                              'mood': _moodLabel(mood),
                              'xp': '${mood.xpReward}',
                            })
                          : 'home.moodUpdated'.tr(
                              namedArgs: {'mood': _moodLabel(mood)},
                            ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isFirstToday)
                    const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFFBBF24),
                      size: 20,
                    ),
                ],
              ),
              backgroundColor: mood.color.withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error saving mood: $e');
      }
    }
  }

  @override
  void dispose() {
    _streakGlow.dispose();
    super.dispose();
  }

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
      if (key != null) {
        final translated = key.tr();
        if (translated != key) return translated;
      }
    } catch (_) {}

    final derivedKey = _levelTitleKey(level);
    final translated = derivedKey.tr();
    return translated == derivedKey ? fallback : translated;
  }

  String? _challengeTitleKey(DailyChallenge challenge) {
    try {
      final key = (challenge as dynamic).titleKey as String?;
      if (key != null) return key;
    } catch (_) {}

    switch (challenge.title) {
      case 'Respira profundo':
        return 'dailyChallenges.breathe.title';
      case 'Gratitud express':
        return 'dailyChallenges.gratitudeExpress.title';
      case 'Caminata consciente':
        return 'dailyChallenges.mindfulWalk.title';
      case 'Desconexión digital':
        return 'dailyChallenges.digitalDetox.title';
      case 'Diario rápido':
        return 'dailyChallenges.quickDiary.title';
      case 'Body scan':
        return 'dailyChallenges.bodyScan.title';
      case 'Acto de bondad':
        return 'dailyChallenges.actOfKindness.title';
      case 'Estiramiento':
        return 'dailyChallenges.stretching.title';
      case 'Meditación breve':
        return 'dailyChallenges.shortMeditation.title';
      case 'Música sanadora':
        return 'dailyChallenges.healingMusic.title';
      case 'Afirmación positiva':
        return 'dailyChallenges.positiveAffirmation.title';
      case 'Observa la naturaleza':
        return 'dailyChallenges.observeNature.title';
      case 'Perdón silencioso':
        return 'dailyChallenges.silentForgiveness.title';
      case 'Limita las quejas':
        return 'dailyChallenges.limitComplaints.title';
    }
    return null;
  }

  String? _challengeDescriptionKey(DailyChallenge challenge) {
    try {
      final key = (challenge as dynamic).descriptionKey as String?;
      if (key != null) return key;
    } catch (_) {}

    switch (challenge.title) {
      case 'Respira profundo':
        return 'dailyChallenges.breathe.description';
      case 'Gratitud express':
        return 'dailyChallenges.gratitudeExpress.description';
      case 'Caminata consciente':
        return 'dailyChallenges.mindfulWalk.description';
      case 'Desconexión digital':
        return 'dailyChallenges.digitalDetox.description';
      case 'Diario rápido':
        return 'dailyChallenges.quickDiary.description';
      case 'Body scan':
        return 'dailyChallenges.bodyScan.description';
      case 'Acto de bondad':
        return 'dailyChallenges.actOfKindness.description';
      case 'Estiramiento':
        return 'dailyChallenges.stretching.description';
      case 'Meditación breve':
        return 'dailyChallenges.shortMeditation.description';
      case 'Música sanadora':
        return 'dailyChallenges.healingMusic.description';
      case 'Afirmación positiva':
        return 'dailyChallenges.positiveAffirmation.description';
      case 'Observa la naturaleza':
        return 'dailyChallenges.observeNature.description';
      case 'Perdón silencioso':
        return 'dailyChallenges.silentForgiveness.description';
      case 'Limita las quejas':
        return 'dailyChallenges.limitComplaints.description';
    }
    return null;
  }

  String? _challengeCategoryKey(DailyChallenge challenge) {
    try {
      final key = (challenge as dynamic).categoryKey as String?;
      if (key != null) return key;
    } catch (_) {}

    switch (challenge.category) {
      case 'Calma':
        return 'dailyChallenges.categories.calm';
      case 'Gratitud':
        return 'dailyChallenges.categories.gratitude';
      case 'Mindfulness':
        return 'dailyChallenges.categories.mindfulness';
      case 'Bienestar':
        return 'dailyChallenges.categories.wellbeing';
      case 'Reflexión':
        return 'dailyChallenges.categories.reflection';
      case 'Social':
        return 'dailyChallenges.categories.social';
      case 'Cuerpo':
        return 'dailyChallenges.categories.body';
      case 'Autoestima':
        return 'dailyChallenges.categories.selfEsteem';
    }
    return null;
  }

  String _challengeTitle(DailyChallenge challenge) {
    final key = _challengeTitleKey(challenge);
    if (key == null) return challenge.title;
    final translated = key.tr();
    return translated == key ? challenge.title : translated;
  }

  String _challengeDescription(DailyChallenge challenge) {
    final key = _challengeDescriptionKey(challenge);
    if (key == null) return challenge.description;
    final translated = key.tr();
    return translated == key ? challenge.description : translated;
  }

  String _challengeCategory(DailyChallenge challenge) {
    final key = _challengeCategoryKey(challenge);
    if (key == null) return challenge.category;
    final translated = key.tr();
    return translated == key ? challenge.category : translated;
  }

  String _routeTitle(WellnessRoute route) {
    try {
      final key = (route as dynamic).titleKey as String?;
      if (key != null) {
        final translated = key.tr();
        if (translated != key) return translated;
      }
    } catch (_) {}

    final key = 'wellnessRoutes.${route.id}.title';
    final translated = key.tr();
    return translated == key ? route.title : translated;
  }

  String _lessonTitle(WellnessRoute route, Lesson lesson) {
    try {
      final key = (lesson as dynamic).titleKey as String?;
      if (key != null) {
        final translated = key.tr();
        if (translated != key) return translated;
      }
    } catch (_) {}

    final key = 'wellnessRoutes.${route.id}.lessons.${lesson.id}.title';
    final translated = key.tr();
    return translated == key ? lesson.title : translated;
  }

  String _quoteText(Quote quote) {
    try {
      final key = (quote as dynamic).textKey as String?;
      if (key != null) {
        final translated = key.tr();
        if (translated != key) return translated;
      }
    } catch (_) {}

    final mappedKey = _quoteTextKeys[quote.text];
    if (mappedKey != null) {
      final translated = mappedKey.tr();
      if (translated != mappedKey) return translated;
    }

    return quote.text;
  }

  String _quoteAuthor(Quote quote) {
    try {
      final key = (quote as dynamic).authorKey as String?;
      if (key != null) {
        final translated = key.tr();
        if (translated != key) return translated;
      }
    } catch (_) {}

    if (quote.author == 'Desconocido') {
      final translated = 'quoteService.unknownAuthor'.tr();
      if (translated != 'quoteService.unknownAuthor') return translated;
    }

    return quote.author;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = _getGreeting();
    final progress = authProvider.userProgress;
    final streak = progress?.currentStreak ?? 0;
    final bestStreak = progress?.longestStreak ?? 0;
    final totalXp = progress?.totalXp ?? 0;
    final level = progress?.level ?? 1;
    final levelTitle = _levelTitleText(
      level,
      progress?.levelTitle ?? 'Novato Emocional',
      progress,
    );
    final xpForNext = progress?.xpForNextLevel ?? 100;
    final challenge = DailyChallenge.getToday();
    final nextLesson = _nextLessonInfo;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF0F0F23),
                        const Color(0xFF1A1A2E),
                        const Color(0xFF16213E)
                      ]
                    : [
                        const Color(0xFFF0F4FF),
                        const Color(0xFFFAFBFF),
                        Colors.white
                      ],
              ),
            ),
          ),
          const AnimatedParticlesBackground(
            particleCount: 20,
            maxShootingStars: 0,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _getArchetypeGradient(
                              authProvider.userModel?.archetype,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: _getArchetypeGradient(
                                authProvider.userModel?.archetype,
                              ).first.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            authProvider.userName.isNotEmpty
                                ? authProvider.userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              authProvider.userName.isNotEmpty
                                  ? authProvider.userName
                                  : 'home.user'.tr(),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.streak.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              color: AppColors.streak,
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$totalXp',
                              style: const TextStyle(
                                color: AppColors.streak,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          themeProvider.toggleTheme();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) =>
                                RotationTransition(
                              turns: Tween(begin: 0.75, end: 1.0)
                                  .animate(anim),
                              child: FadeTransition(
                                opacity: anim,
                                child: child,
                              ),
                            ),
                            child: Icon(
                              isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              key: ValueKey(isDark),
                              color: isDark
                                  ? const Color(0xFFFBBF24)
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 20),

                  // FRASE DEL DÍA
                  if (_quote != null || _isLoadingQuote)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  Colors.white.withValues(alpha: 0.06),
                                  Colors.white.withValues(alpha: 0.03)
                                ]
                              : [
                                  const Color(0xFFFEF9C3),
                                  const Color(0xFFFEF3C7)
                                ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: _isLoadingQuote
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.streak.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.format_quote_rounded,
                                        color: AppColors.streak,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'home.quoteOfDay'.tr(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '"${_quoteText(_quote!)}"',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF78350F),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '— ${_quoteAuthor(_quote!)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF92400E),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_quote!.source == 'ZenQuotes.io') ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'home.poweredBy'.tr(
                                      namedArgs: {'source': _quote!.source},
                                    ),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark
                                          ? Colors.white24
                                          : const Color(0xFFB45309)
                                              .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    )
                        .animate()
                        .fadeIn(delay: 150.ms, duration: 600.ms)
                        .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),

                  // PROGRESO CIRCULAR
                  DailyProgressRing(
                    checkInDone: _selectedMood != null,
                    lessonDone: _hasLessonToday,
                    diaryDone: _hasDiaryToday,
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                  const SizedBox(height: 16),

                  // STREAK CARD
                  AnimatedBuilder(
                    animation: _streakGlow,
                    builder: (context, child) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6C63FF),
                              Color(0xFF5A4FCF),
                              Color(0xFF4A3AB5)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                alpha: 0.15 + _streakGlow.value * 0.1,
                              ),
                              blurRadius: 16 + _streakGlow.value * 8,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.streak.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.streak.withValues(
                                          alpha: _streakGlow.value * 0.3,
                                        ),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: AppColors.streak,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      streak == 1
                                          ? 'home.streakDay'.tr()
                                          : 'home.streakDays'.tr(
                                              namedArgs: {
                                                'count': '$streak'
                                              },
                                            ),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      streak > 0
                                          ? 'home.streakKeepGoing'.tr()
                                          : 'home.streakDoCheckin'.tr(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.emoji_events_rounded,
                                        color: Color(0xFFFBBF24),
                                        size: 18,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$bestStreak',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'home.streakBest'.tr(),
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: List.generate(7, (index) {
                                  final days = [
                                    'days.monShort'.tr(),
                                    'days.tueShort'.tr(),
                                    'days.wedShort'.tr(),
                                    'days.thuShort'.tr(),
                                    'days.friShort'.tr(),
                                    'days.satShort'.tr(),
                                    'days.sunShort'.tr(),
                                  ];
                                  final today = DateTime.now().weekday - 1;
                                  final isToday = index == today;
                                  final isPast = index < today;
                                  final wasActive =
                                      isPast && streak > (today - index);
                                  return Column(
                                    children: [
                                      Text(
                                        days[index],
                                        style: TextStyle(
                                          color: isToday
                                              ? Colors.white
                                              : Colors.white54,
                                          fontSize: 11,
                                          fontWeight: isToday
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isToday
                                              ? AppColors.streak
                                              : wasActive
                                                  ? AppColors.streak
                                                      .withValues(alpha: 0.4)
                                                  : Colors.white
                                                      .withValues(alpha: 0.08),
                                        ),
                                        child: Icon(
                                          isToday
                                              ? Icons
                                                  .local_fire_department_rounded
                                              : wasActive
                                                  ? Icons.check_rounded
                                                  : Icons.circle_outlined,
                                          color: isToday || wasActive
                                              ? Colors.white
                                              : Colors.white24,
                                          size: isToday
                                              ? 16
                                              : wasActive
                                                  ? 14
                                                  : 6,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 700.ms)
                      .slideY(begin: 0.15, end: 0),
                  const SizedBox(height: 20),

                  // MOOD CHECK-IN
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'home.moodCheckIn'.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (_selectedMood != null)
                        GestureDetector(
                          onTap: () => setState(() => _selectedMood = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.refresh_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'home.moodChange'.tr(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ).animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: MoodType.values.map((mood) {
                        final isSelected = _selectedMood == mood;
                        return GestureDetector(
                          onTap: () => _onMoodSelected(mood),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 72,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? mood.color.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: isSelected
                                  ? Border.all(
                                      color:
                                          mood.color.withValues(alpha: 0.5),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  mood.emoji,
                                  style: TextStyle(
                                    fontSize: isSelected ? 30 : 26,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _moodLabel(mood),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? mood.color
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 20),

                  // GRÁFICA SEMANAL
                  WeeklyMoodChart(weeklyMoods: _weeklyMoods)
                      .animate()
                      .fadeIn(delay: 550.ms, duration: 600.ms),
                  const SizedBox(height: 20),

                  // RETO DIARIO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          challenge.color.withValues(alpha: isDark ? 0.15 : 0.08),
                          challenge.color.withValues(alpha: isDark ? 0.08 : 0.03),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: challenge.color.withValues(
                          alpha: isDark ? 0.2 : 0.15,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: challenge.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            challenge.icon,
                            color: challenge.color,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: challenge.color
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'home.challengeLabel'.tr(
                                        namedArgs: {
                                          'category': _challengeCategory(challenge),
                                        },
                                      ),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: challenge.color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    challenge.duration,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _challengeTitle(challenge),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _challengeDescription(challenge),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: challenge.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${challenge.xpReward}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: challenge.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
                  const SizedBox(height: 20),

                  // ACCIONES RÁPIDAS
                  Text(
                    'home.todayTraining'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 650.ms),
                  const SizedBox(height: 14),

                  _buildActionCard(
                    icon: Icons.menu_book_rounded,
                    title: nextLesson != null
                        ? nextLesson.$1
                        : 'home.allComplete'.tr(),
                    subtitle: nextLesson != null
                        ? nextLesson.$2
                        : 'home.congratulations'.tr(),
                    color: nextLesson?.$3 ?? const Color(0xFF10B981),
                    isDark: isDark,
                    delay: 700,
                    onTap: _openNextLesson,
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.air_rounded,
                    title: 'home.breathingTitle'.tr(),
                    subtitle: 'home.breathingSubtitle'.tr(),
                    color: AppColors.moodCalm,
                    isDark: isDark,
                    delay: 750,
                  ),
                  _buildActionCard(
                    icon: Icons.edit_note_rounded,
                    title: 'home.quickDiary'.tr(),
                    subtitle: 'home.quickDiarySubtitle'.tr(),
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    delay: 800,
                    onTap: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NewDiaryEntryScreen(),
                        ),
                      );
                      if (result == true) _loadData();
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    icon: Icons.track_changes_rounded,
                    title: 'home.habitsReminders'.tr(),
                    subtitle: 'home.habitsRemindersSubtitle'.tr(),
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                    delay: 850,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RemindersScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // STATS RÁPIDOS
                  Text(
                    'home.yourSummary'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(delay: 900.ms),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildStatCard('🔥', '$streak', 'home.streak'.tr(), isDark),
                      const SizedBox(width: 12),
                      _buildStatCard('⚡', '$totalXp', 'home.totalXp'.tr(), isDark),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        '🏆',
                        '${'home.levelShort'.tr()} $level',
                        levelTitle,
                        isDark,
                      ),
                    ],
                  ).animate().fadeIn(delay: 950.ms),
                  const SizedBox(height: 20),

                  // NIVEL Y XP
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                Colors.white.withValues(alpha: 0.06),
                                Colors.white.withValues(alpha: 0.03)
                              ]
                            : [
                                const Color(0xFFF5F3FF),
                                const Color(0xFFEDE9FE)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFDDD6FE),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _getArchetypeGradient(
                                authProvider.userModel?.archetype,
                              ),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: _getArchetypeGradient(
                                  authProvider.userModel?.archetype,
                                ).first.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'home.levelShort'.tr(),
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$level',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                levelTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (totalXp % xpForNext) / xpForNext,
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : const Color(0xFFDDD6FE),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getArchetypeGradient(
                                      authProvider.userModel?.archetype,
                                    ).first,
                                  ),
                                  minHeight: 10,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${totalXp % xpForNext} / $xpForNext XP',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1000.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String emoji,
    String value,
    String label,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required int delay,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: -0.05, end: 0);
  }

  List<Color> _getArchetypeGradient(String? archetype) {
    switch (archetype) {
      case 'explorador':
        return [const Color(0xFF6366F1), const Color(0xFF4338CA)];
      case 'guerrero':
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case 'social':
        return [const Color(0xFFEC4899), const Color(0xFFDB2777)];
      case 'sabio':
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'libre':
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      default:
        return [AppColors.primary, AppColors.primaryDark];
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'home.greetingMorning'.tr();
    if (hour < 18) return 'home.greetingAfternoon'.tr();
    return 'home.greetingEvening'.tr();
  }
}
