import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import '../../../data/models/diary_entry.dart';
import '../../../data/models/mood_entry.dart';
import '../../../data/models/wellness_route.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../../domain/services/sound_service.dart';
import 'steps/commit_step.dart';
import 'steps/myth_fact_step.dart';
import 'steps/order_step.dart';
import 'steps/pick_step.dart';
import 'steps/practice_step.dart';
import 'steps/step_common.dart';
import 'steps/story_step.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../domain/services/commitment_service.dart';
import '../../../domain/services/notification_service.dart';
import '../../../domain/services/analytics_service.dart';

// ─── Character state ──────────────────────────────────────────────────────────
enum _CharacterState { idle, correct, wrong }

// ═════════════════════════════════════════════════════════════════════════════
// STAR DOT
// ═════════════════════════════════════════════════════════════════════════════
class _StarDot extends StatefulWidget {
  final double size;
  final double maxOpacity;
  final int delayMs;
  final int durationMs;
  final Color glowColor;

  const _StarDot({
    required this.size,
    required this.maxOpacity,
    required this.delayMs,
    required this.durationMs,
    required this.glowColor,
  });

  @override
  State<_StarDot> createState() => _StarDotState();
}

class _StarDotState extends State<_StarDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0.05, end: widget.maxOpacity)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        final v = _anim.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: v,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: widget.size > 1.8
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: v * 0.9),
                        blurRadius: widget.size * 1.5,
                        spreadRadius: widget.size * 0.2,
                      ),
                      BoxShadow(
                        color: widget.glowColor.withValues(alpha: v * 0.7),
                        blurRadius: widget.size * 4.0,
                        spreadRadius: widget.size * 0.5,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: v * 0.6),
                        blurRadius: widget.size * 2.0,
                      ),
                    ],
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHOOTING STAR
// ═════════════════════════════════════════════════════════════════════════════
class _ShootingStar extends StatefulWidget {
  final double startX;
  final double startY;
  final double angle;
  final double length;
  final Color color;
  final int delayMs;
  final int durationMs;

  const _ShootingStar({
    required this.startX,
    required this.startY,
    required this.angle,
    required this.length,
    required this.color,
    required this.delayMs,
    required this.durationMs,
  });

  @override
  State<_ShootingStar> createState() => _ShootingStarState();
}

class _ShootingStarState extends State<_ShootingStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    _progress = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scheduleNext();
  }

  void _scheduleNext() {
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (!mounted) return;
      _ctrl.forward(from: 0).then((_) {
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted) _scheduleNext();
        });
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return AnimatedBuilder(
        animation: _progress,
        builder: (_, _) {
          final t = _progress.value;
          if (t == 0) return const SizedBox.shrink();

          final dist = t * widget.length * 2.5;
          final dx = math.cos(widget.angle) * dist;
          final dy = math.sin(widget.angle) * dist;
          final headX = widget.startX * w + dx;
          final headY = widget.startY * h + dy;

          final tailOpacity = (1.0 - t).clamp(0.0, 1.0);
          final headOpacity =
              t < 0.3 ? (t / 0.3) : ((1.0 - t) / 0.7).clamp(0.0, 1.0);

          return CustomPaint(
            size: Size(w, h),
            painter: _ShootingStarPainter(
              headX: headX,
              headY: headY,
              angle: widget.angle,
              length: widget.length * (0.3 + t * 0.7),
              headOpacity: headOpacity.clamp(0.0, 1.0),
              tailOpacity: tailOpacity.clamp(0.0, 1.0),
              color: widget.color,
            ),
          );
        },
      );
    });
  }
}

class _ShootingStarPainter extends CustomPainter {
  final double headX, headY, angle, length;
  final double headOpacity, tailOpacity;
  final Color color;

  _ShootingStarPainter({
    required this.headX,
    required this.headY,
    required this.angle,
    required this.length,
    required this.headOpacity,
    required this.tailOpacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tailX = headX - math.cos(angle) * length;
    final tailY = headY - math.sin(angle) * length;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: tailOpacity * 0.0),
          color.withValues(alpha: tailOpacity * 0.5),
          Colors.white.withValues(alpha: headOpacity),
        ],
      ).createShader(
        Rect.fromPoints(Offset(tailX, tailY), Offset(headX, headY)),
      )
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(tailX, tailY), Offset(headX, headY), paint);

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: headOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(headX, headY), 1.8, dotPaint);
  }

  @override
  bool shouldRepaint(_ShootingStarPainter old) =>
      old.headX != headX || old.headY != headY;
}

// ═════════════════════════════════════════════════════════════════════════════
// STAR CANVAS
// ═════════════════════════════════════════════════════════════════════════════
class _StarCanvas extends StatelessWidget {
  final Color accentColor;

  const _StarCanvas({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;
      final rng = math.Random(99);

      const starCount = 80;
      final stars = List.generate(starCount, (i) {
        final x = rng.nextDouble() * w;
        final y = rng.nextDouble() * h;
        final size = 1.0 + rng.nextDouble() * 2.5;
        final maxOpacity = 0.4 + rng.nextDouble() * 0.6;
        final delayMs = rng.nextInt(2500);
        final durationMs = 800 + rng.nextInt(1800);
        final useAccent = i % 6 == 0;

        return Positioned(
          left: x,
          top: y,
          child: _StarDot(
            size: size,
            maxOpacity: maxOpacity,
            delayMs: delayMs,
            durationMs: durationMs,
            glowColor: useAccent ? accentColor : Colors.white,
          ),
        );
      });

      final angleBase = math.pi / 5;
      final shootingStars = [
        _ShootingStar(
          startX: 0.1, startY: 0.05, angle: angleBase,
          length: w * 0.22, color: accentColor, delayMs: 2000, durationMs: 900,
        ),
        _ShootingStar(
          startX: 0.6, startY: 0.02, angle: angleBase + 0.1,
          length: w * 0.18, color: Colors.white, delayMs: 5500, durationMs: 750,
        ),
        _ShootingStar(
          startX: 0.3, startY: 0.15, angle: angleBase - 0.15,
          length: w * 0.25, color: const Color(0xFF818CF8), delayMs: 9000, durationMs: 1000,
        ),
        _ShootingStar(
          startX: 0.75, startY: 0.08, angle: angleBase + 0.05,
          length: w * 0.15, color: accentColor, delayMs: 13000, durationMs: 800,
        ),
      ];

      return Stack(
        fit: StackFit.expand,
        children: [
          ...stars,
          ...shootingStars.map((s) => Positioned.fill(child: s)),
        ],
      );
    });
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LESSON SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final Color routeColor;
  final String routeEmoji;

  /// Define el ambiente sonoro de la lección (cada ruta tiene el suyo).
  final String? routeId;

  /// Si existe, la pantalla final ofrece "Siguiente lección" y la pantalla
  /// devuelve [LessonScreen.nextResult] al cerrarse.
  final Lesson? nextLesson;

  /// Resultado de `Navigator.pop` cuando el usuario eligió seguir.
  static const nextResult = 'next';

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.routeColor,
    required this.routeEmoji,
    this.routeId,
    this.nextLesson,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with TickerProviderStateMixin {

  int _currentStep = 0;
  int? _selectedQuizOption;
  bool _quizAnswered = false;

  // ── Estado de los tipos de paso nuevos ─────────────────────────────────────
  /// scenario: opción elegida (no hay correcta, solo consecuencias).
  int? _scenarioChoice;

  /// reveal: si ya giró la tarjeta.
  bool _revealed = false;

  /// slider: valor 0-10 y si ya lo movió (para no dar por válido el 5 inicial).
  double _sliderValue = 5;
  bool _sliderTouched = false;

  /// sort: item → categoría a la que lo arrastró.
  final Map<int, int> _sortAssignments = {};

  /// Pasos con widget propio (mythFact, practice, order, pick, story,
  /// commit): avisan con [StepCallbacks.onReady] cuando ya se puede seguir.
  bool _stepReady = false;

  /// commit: el micro-reto elegido, se muestra al completar la lección.
  String? _commitment;

  /// exercise: guardar también la respuesta en el diario.
  bool _saveExerciseToDiary = false;

  /// Aciertos seguidos dentro de la lección, para la racha.
  int _streakInLesson = 0;
  final _exerciseController = TextEditingController();
  bool _isSaving = false;
  _CharacterState _charState = _CharacterState.idle;
  Color _flashColor = Colors.transparent;
  bool _showFlash = false;
  late ConfettiController _confettiController;
  int _xpEarned = 0;
  bool _showCompletion = false;

  // ── XP multiplicado para mostrar en pantalla de completado ─────────────────
  int _finalXpAwarded = 0;
  double _appliedMultiplier = 1.0;

  LessonStep get _step => widget.lesson.steps[_currentStep];
  bool get _isLastStep => _currentStep == widget.lesson.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    SoundService.instance.setBaseAmbient(
      SoundService.ambientForRoute(widget.routeId),
      volume: 0.18,
    );
    AnalyticsService.instance.lessonStart(widget.routeId, widget.lesson.id);
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _confettiController.dispose();
    SoundService.instance.clearBaseAmbient();
    if (!_showCompletion) {
      AnalyticsService.instance.lessonAbandoned(
        widget.routeId,
        widget.lesson.id,
        _currentStep,
        widget.lesson.steps.length,
      );
    }
    super.dispose();
  }

  bool get _canContinue {
    switch (_step.type) {
      case LessonStepType.reading:
        return true;
      case LessonStepType.quiz:
        return _quizAnswered;
      case LessonStepType.exercise:
        return _exerciseController.text.trim().length >= 10;
      case LessonStepType.scenario:
        return _scenarioChoice != null;
      case LessonStepType.reveal:
        return _revealed;
      case LessonStepType.slider:
        return _sliderTouched;
      case LessonStepType.sort:
        return _sortAssignments.length == (_step.items?.length ?? 0);
      case LessonStepType.mythFact:
      case LessonStepType.practice:
      case LessonStepType.order:
      case LessonStepType.pick:
      case LessonStepType.story:
      case LessonStepType.commit:
        return _stepReady;
    }
  }

  void _nextStep() {
    HapticFeedback.mediumImpact();
    if (_step.type == LessonStepType.exercise && _saveExerciseToDiary) {
      _saveExerciseEntry();
    }
    if (_isLastStep) {
      _completeLesson();
    } else {
      setState(() {
        _currentStep++;
        _selectedQuizOption = null;
        _quizAnswered = false;
        _charState = _CharacterState.idle;
        _exerciseController.clear();
        _scenarioChoice = null;
        _revealed = false;
        _sliderValue = 5;
        _sliderTouched = false;
        _sortAssignments.clear();
        _stepReady = false;
      });
    }
  }

  /// Guarda el micro-reto para preguntarle al usuario mañana si lo cumplió.
  void _saveCommitment(String text) {
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    if (uid == null) return;
    AnalyticsService.instance.commitmentCreated(widget.routeId, widget.lesson.id);
    CommitmentService.instance.save(
      uid: uid,
      text: text,
      lessonId: widget.lesson.id,
      lessonTitle: widget.lesson.title,
      routeId: widget.routeId,
    );
    if (!kIsWeb) {
      NotificationService.instance
          .scheduleCommitmentReminder(
            title: 'commitments.notificationTitle'.tr(),
            body: 'commitments.notificationBody'.tr(namedArgs: {'text': text}),
          )
          .catchError((Object e) => debugPrint('Commitment reminder error: $e'));
    }
  }

  /// Guarda la respuesta del ejercicio como entrada del diario.
  /// Sin XP extra: la lección ya da XP y así no se puede farmear repitiendo.
  void _saveExerciseEntry() {
    final text = _exerciseController.text.trim();
    if (text.length < 10) return;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final entry = DiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mood: MoodType.calm,
      text: text,
      prompt: '${widget.lesson.title} · ${_step.title}',
    );
    AnalyticsService.instance.exerciseSavedToDiary(widget.lesson.id);
    auth.saveDiaryEntry(entry, awardXp: false).then((_) {
      messenger.showSnackBar(SnackBar(
        content: Text('routes.savedToDiary'.tr()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }).catchError((Object e) {
      debugPrint('Error saving exercise to diary: $e');
    });
  }

  // ── Callbacks de los pasos con widget propio ──────────────────────────────
  StepCallbacks get _stepCallbacks => StepCallbacks(
        onAnswer: (correct, xp, {bool sound = true}) {
          if (!mounted) return;
          setState(() {
            _charState =
                correct ? _CharacterState.correct : _CharacterState.wrong;
            _xpEarned += xp;
            _registerAnswer(correct, sound: sound, volume: 0.45);
          });
          _triggerFlash(correct);
        },
        onReflect: (xp) {
          if (!mounted) return;
          setState(() {
            _charState = _CharacterState.correct;
            _xpEarned += xp;
          });
        },
        onReady: () {
          if (mounted) setState(() => _stepReady = true);
        },
      );

  void _selectQuizOption(int index) {
    if (_quizAnswered) return;
    HapticFeedback.lightImpact();
    final isCorrect = index == _step.correctIndex;
    setState(() {
      _selectedQuizOption = index;
      _quizAnswered = true;
      _charState = isCorrect ? _CharacterState.correct : _CharacterState.wrong;
      _xpEarned += isCorrect ? 5 : 0;
      _registerAnswer(isCorrect);
    });
    _triggerFlash(isCorrect);
  }

  void _triggerFlash(bool correct) {
    setState(() {
      _flashColor =
          correct ? const Color(0xFF10B981) : const Color(0xFFEF4444);
      _showFlash = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showFlash = false);
    });
  }

  // ── COMPLETAR LECCIÓN — pasa GardenProvider para aplicar multiplicador ──────
  Future<void> _completeLesson() async {
    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProvider>();
      final garden = context.read<GardenProvider>(); // ← FIX: obtener garden

      // Calcular XP multiplicado ANTES de llamar completeLesson para mostrarlo
      final multiplier = garden.currentXpMultiplier;
      final baseXp = widget.lesson.xpReward;
      final finalXp = multiplier > 1.0
          ? (baseXp * multiplier).round()
          : baseXp;

      // Pasar garden para que completeLesson aplique el multiplicador
      await auth.completeLesson(
        widget.lesson.id,
        baseXp,
        garden: garden, // ← FIX: multiplicador XP aplicado aquí
      );
      AnalyticsService.instance.lessonComplete(widget.routeId, widget.lesson.id, finalXp);

      if (mounted) {
        setState(() {
          _xpEarned += finalXp;       // mostrar XP real (multiplicado)
          _finalXpAwarded = finalXp;
          _appliedMultiplier = multiplier;
          _isSaving = false;
          _showCompletion = true;
          _charState = _CharacterState.correct;
        });
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) {
          SoundService.instance.play(Sfx.complete, volume: 0.7);
          _confettiController.play();
          HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      debugPrint('Error completing lesson: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          _StarCanvas(accentColor: widget.routeColor),
          _buildNebulaBlobs(),
          SafeArea(
            child: _showCompletion
                ? _buildCompletionScreen(isDark)
                : _buildLessonContent(isDark),
          ),
          if (_showFlash)
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showFlash ? 0.13 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Container(color: _flashColor),
              ),
            ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: [
                  widget.routeColor,
                  const Color(0xFFFBBF24),
                  const Color(0xFF10B981),
                  const Color(0xFF818CF8),
                  Colors.white,
                  Colors.pinkAccent,
                ],
                numberOfParticles: 35,
                gravity: 0.25,
                emissionFrequency: 0.05,
                maxBlastForce: 20,
                minBlastForce: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF060612),
            Color.lerp(const Color(0xFF0A0A1E), widget.routeColor, 0.14)!,
            const Color(0xFF0C0C1E),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  Widget _buildNebulaBlobs() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: -100, left: -80,
          child: Container(
            width: 320, height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                widget.routeColor.withValues(alpha: 0.28),
                widget.routeColor.withValues(alpha: 0.0),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -80, right: -100,
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF818CF8).withValues(alpha: 0.2),
                const Color(0xFF818CF8).withValues(alpha: 0.0),
              ]),
            ),
          ),
        ),
        Positioned(
          top: 180, right: -50,
          child: Container(
            width: 180, height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                widget.routeColor.withValues(alpha: 0.12),
                widget.routeColor.withValues(alpha: 0.0),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonContent(bool isDark) {
    return Column(
      children: [
        _buildTopBar(isDark),
        _buildCharacter(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _buildStepContent(isDark),
            ),
          ),
        ),
        _buildBottomButton(isDark),
      ],
    );
  }

  Widget _buildTopBar(bool isDark) {
    // Mostrar multiplicador activo en el top bar si hay uno
    return Consumer<GardenProvider>(
      builder: (_, garden, _) {
        final mult = garden.currentXpMultiplier;
        final hasMultiplier = mult > 1.0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 16, 4),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: const Icon(Icons.close_rounded, size: 18, color: Colors.white60),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _buildProgressNodes()),
                  const SizedBox(width: 10),
                  // Racha de aciertos seguidos dentro de la lección
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _streakInLesson >= 2
                        ? Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildStreakBadge(),
                          )
                        : const SizedBox.shrink(),
                  ),
                  _buildAmbientToggle(),
                  const SizedBox(width: 8),
                  _buildXpBadge(),
                ],
              ),
              // Banner del multiplicador activo dentro de la lección
              if (hasMultiplier) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('⚡', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      'routes.multiplierBanner'.tr(namedArgs: {'mult': mult.toStringAsFixed(1)}),
                      style: const TextStyle(
                        color: Color(0xFF8B5CF6),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ]),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressNodes() {
    final total = widget.lesson.steps.length;
    return Row(
      children: List.generate(total, (i) {
        final isDone = i < _currentStep;
        final isCurrent = i == _currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              height: isCurrent ? 10 : 8,
              decoration: BoxDecoration(
                color: isDone
                    ? widget.routeColor
                    : isCurrent
                        ? widget.routeColor.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                boxShadow: isCurrent
                    ? [BoxShadow(
                        color: widget.routeColor.withValues(alpha: 0.8),
                        blurRadius: 8, spreadRadius: 1,
                      )]
                    : isDone
                        ? [BoxShadow(
                            color: widget.routeColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                          )]
                        : null,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// Activa o silencia el ambiente de la ruta. Se recuerda entre lecciones.
  Widget _buildAmbientToggle() {
    final on = SoundService.instance.lessonAmbientEnabled;
    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        await SoundService.instance.setLessonAmbientEnabled(!on);
        if (mounted) setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: on
              ? widget.routeColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: on
                ? widget.routeColor.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          on ? Icons.music_note_rounded : Icons.music_off_rounded,
          size: 16,
          color: on ? Colors.white : Colors.white38,
        ),
      ),
    );
  }

  Widget _buildXpBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            '+$_xpEarned',
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFFBBF24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter() {
    String assetPath;
    switch (_charState) {
      case _CharacterState.idle:
        assetPath = 'assets/lottie/character_idle.json';
        break;
      case _CharacterState.correct:
        assetPath = 'assets/lottie/character_correct.json';
        break;
      case _CharacterState.wrong:
        assetPath = 'assets/lottie/character_wrong.json';
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween<double>(begin: 0.75, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        ),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: SizedBox(
        key: ValueKey(assetPath),
        height: 110,
        child: Lottie.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _buildCharacterFallback(),
        ),
      ),
    );
  }

  Widget _buildCharacterFallback() {
    String emoji;
    Color glow;
    switch (_charState) {
      case _CharacterState.idle:
        emoji = widget.routeEmoji;
        glow = widget.routeColor;
        break;
      case _CharacterState.correct:
        emoji = '🎉';
        glow = const Color(0xFF10B981);
        break;
      case _CharacterState.wrong:
        emoji = '😅';
        glow = const Color(0xFFEF4444);
        break;
    }

    return Center(
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: glow.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: glow.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 2)],
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 38))),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 1800.ms, curve: Curves.easeInOut);
  }

  Widget _buildStepContent(bool isDark) {
    switch (_step.type) {
      case LessonStepType.reading:
        return _buildReading(isDark);
      case LessonStepType.quiz:
        return _buildQuiz(isDark);
      case LessonStepType.exercise:
        return _buildExercise(isDark);
      case LessonStepType.scenario:
        return _buildScenario(isDark);
      case LessonStepType.reveal:
        return _buildReveal(isDark);
      case LessonStepType.slider:
        return _buildSlider(isDark);
      case LessonStepType.sort:
        return _buildSort(isDark);
      case LessonStepType.mythFact:
        return MythFactStep(
          key: ValueKey('mythfact_$_currentStep'),
          step: _step,
          routeColor: widget.routeColor,
          callbacks: _stepCallbacks,
        );
      case LessonStepType.practice:
        return PracticeStep(
          key: ValueKey('practice_$_currentStep'),
          step: _step,
          routeColor: widget.routeColor,
          callbacks: _stepCallbacks,
        );
      case LessonStepType.order:
        return OrderStep(
          key: ValueKey('order_$_currentStep'),
          step: _step,
          routeColor: widget.routeColor,
          callbacks: _stepCallbacks,
        );
      case LessonStepType.pick:
        return PickStep(
          key: ValueKey('pick_$_currentStep'),
          step: _step,
          routeColor: widget.routeColor,
          callbacks: _stepCallbacks,
        );
      case LessonStepType.story:
        return StoryStep(
          key: ValueKey('story_$_currentStep'),
          step: _step,
          routeColor: widget.routeColor,
          fallbackSpeaker: widget.routeEmoji,
          callbacks: _stepCallbacks,
        );
      case LessonStepType.commit:
        return CommitStep(
          key: ValueKey('commit_$_currentStep'),
          step: _step,
          routeColor: widget.routeColor,
          callbacks: _stepCallbacks,
          onCommitted: (text) {
            _commitment = text;
            SoundService.instance.play(Sfx.commit, volume: 0.7);
            _saveCommitment(text);
          },
        );
    }
  }

  /// Registra un acierto o fallo para la racha interna de la lección y toca
  /// su sonido: desde el segundo acierto seguido, cada uno suena más agudo.
  void _registerAnswer(bool correct, {bool sound = true, double volume = 0.6}) {
    if (correct) {
      _streakInLesson++;
    } else {
      _streakInLesson = 0;
    }
    if (!sound) return;
    if (!correct) {
      SoundService.instance.play(Sfx.wrong, volume: volume * 0.85);
    } else if (_streakInLesson >= 2) {
      SoundService.instance.combo(_streakInLesson - 2, volume: volume);
    } else {
      SoundService.instance.play(Sfx.correct, volume: volume);
    }
  }

  /// Badge de racha dentro de la lección. Aparece a partir de 2 aciertos
  /// seguidos y late cada vez que sube.
  Widget _buildStreakBadge() {
    return Container(
      key: ValueKey('streak_$_streakInLesson'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            'routes.streakInLesson'.tr(namedArgs: {'count': '$_streakInLesson'}),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 350.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 250.ms);
  }

  Widget _buildBottomButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: _canContinue ? _nextStep : null,
          style: FilledButton.styleFrom(
            backgroundColor: widget.routeColor,
            disabledBackgroundColor: widget.routeColor.withValues(alpha: 0.22),
            elevation: _canContinue ? 8 : 0,
            shadowColor: widget.routeColor.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLastStep ? 'common.done'.tr() : 'common.continue'.tr(),
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SCENARIO — situación real, varias reacciones, ninguna "incorrecta"
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScenario(bool isDark) {
    final options = _step.options ?? const [];
    final outcomes = _step.outcomes ?? const [];

    return Column(
      key: ValueKey('scenario_$_currentStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeChip(
          icon: Icons.forum_rounded,
          label: 'routes.scenarioLabel'.tr(),
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 16),
        Text(
          _step.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: Colors.white,
            shadows: [
              Shadow(color: widget.routeColor.withValues(alpha: 0.5), blurRadius: 14),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // La situación, presentada como si alguien te la contara
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
          ),
          child: Text(
            _step.content ?? '',
            style: TextStyle(
              fontSize: 15.5,
              height: 1.7,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'routes.scenarioPrompt'.tr(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: Colors.white38,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(options.length, (i) {
          final chosen = _scenarioChoice == i;
          final decided = _scenarioChoice != null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: decided ? null : () => _chooseScenario(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: chosen
                      ? widget.routeColor.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: decided ? 0.03 : 0.07),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: chosen
                        ? widget.routeColor
                        : Colors.white.withValues(alpha: decided ? 0.06 : 0.14),
                    width: chosen ? 2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: chosen
                                ? widget.routeColor
                                : Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: chosen
                              ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            options[i],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: decided && !chosen ? 0.45 : 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // La consecuencia se despliega solo en la opción elegida
                    if (chosen && i < outcomes.length) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_forward_rounded,
                                size: 15, color: Colors.white54),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                outcomes[i],
                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.55,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.15, end: 0),
                    ],
                  ],
                ),
              ),
            ),
          ).animate(delay: (i * 70).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
        }),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  void _chooseScenario(int index) {
    HapticFeedback.lightImpact();
    SoundService.instance.play(Sfx.pop);
    setState(() {
      _scenarioChoice = index;
      // No hay opción incorrecta: reflexionar ya cuenta.
      _charState = _CharacterState.correct;
      _xpEarned += 5;
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REVEAL — piensa primero, luego gira la tarjeta
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildReveal(bool isDark) {
    return Column(
      key: ValueKey('reveal_$_currentStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeChip(
          icon: Icons.psychology_rounded,
          label: 'routes.revealLabel'.tr(),
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 16),
        Text(
          _step.question ?? _step.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: Colors.white,
            shadows: [
              Shadow(color: widget.routeColor.withValues(alpha: 0.5), blurRadius: 14),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _revealed ? null : _revealAnswer,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _revealed ? 1 : 0),
            duration: const Duration(milliseconds: 620),
            curve: Curves.easeInOutCubic,
            builder: (context, t, _) {
              // Giro 3D: a mitad del recorrido se cambia la cara visible.
              final angle = t * math.pi;
              final mostrandoReverso = t > 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle),
                child: mostrandoReverso
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _revealCard(revelada: true),
                      )
                    : _revealCard(revelada: false),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _revealCard({required bool revelada}) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: revelada
              ? [
                  const Color(0xFF8B5CF6).withValues(alpha: 0.28),
                  widget.routeColor.withValues(alpha: 0.16),
                ]
              : [
                  Colors.white.withValues(alpha: 0.09),
                  Colors.white.withValues(alpha: 0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: revelada
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.16),
          width: revelada ? 2 : 1,
        ),
        boxShadow: revelada
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.28),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: revelada
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lightbulb_rounded, color: Color(0xFFFBBF24), size: 26),
                const SizedBox(height: 12),
                Text(
                  _step.content ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.75,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded,
                        size: 34, color: Colors.white.withValues(alpha: 0.5))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: 0, end: -7, duration: 1100.ms, curve: Curves.easeInOut),
                const SizedBox(height: 14),
                Text(
                  'routes.revealTap'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
    );
  }

  void _revealAnswer() {
    HapticFeedback.mediumImpact();
    SoundService.instance.play(Sfx.flip, volume: 0.8);
    setState(() {
      _revealed = true;
      _charState = _CharacterState.correct;
      _xpEarned += 3;
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SLIDER — termómetro del 0 al 10
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSlider(bool isDark) {
    final v = _sliderValue.round();
    final responses = _step.responses ?? const [];
    // 0-3 bajo, 4-6 medio, 7-10 alto
    final tramo = v <= 3 ? 0 : (v <= 6 ? 1 : 2);
    final colorTramo = [
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ][tramo];

    return Column(
      key: ValueKey('slider_$_currentStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeChip(
          icon: Icons.thermostat_rounded,
          label: 'routes.sliderLabel'.tr(),
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 16),
        Text(
          _step.question ?? _step.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: Colors.white,
            shadows: [
              Shadow(color: widget.routeColor.withValues(alpha: 0.5), blurRadius: 14),
            ],
          ),
        ),
        const SizedBox(height: 26),
        // Número grande que cambia de color con el valor
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              '$v',
              key: ValueKey(v),
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                height: 1,
                color: _sliderTouched ? colorTramo : Colors.white24,
                shadows: _sliderTouched
                    ? [BoxShadow(color: colorTramo.withValues(alpha: 0.5), blurRadius: 26)]
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: colorTramo,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            thumbColor: Colors.white,
            overlayColor: colorTramo.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
          ),
          child: Slider(
            value: _sliderValue,
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: (val) {
              if (!_sliderTouched || val.round() != _sliderValue.round()) {
                HapticFeedback.selectionClick();
                SoundService.instance.play(Sfx.tick, volume: 0.35);
              }
              setState(() {
                _sliderValue = val;
                _sliderTouched = true;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  _step.minLabel ?? '0',
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ),
              Flexible(
                child: Text(
                  _step.maxLabel ?? '10',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        // La respuesta cambia según el tramo en el que caiga
        if (_sliderTouched && tramo < responses.length)
          Container(
            key: ValueKey('resp_$tramo'),
            width: double.infinity,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: colorTramo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorTramo.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.favorite_rounded, color: colorTramo, size: 19),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    responses[tramo],
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.12, end: 0),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SORT — arrastrar cada item a su categoría
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSort(bool isDark) {
    final items = _step.items ?? const [];
    final categories = _step.categories ?? const [];
    final pendientes = [
      for (int i = 0; i < items.length; i++)
        if (!_sortAssignments.containsKey(i)) i
    ];
    final terminado = pendientes.isEmpty && items.isNotEmpty;

    return Column(
      key: ValueKey('sort_$_currentStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeChip(
          icon: Icons.drag_indicator_rounded,
          label: 'routes.sortLabel'.tr(),
          color: const Color(0xFF06B6D4),
        ),
        const SizedBox(height: 16),
        Text(
          _step.title,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            height: 1.25,
            color: Colors.white,
            shadows: [
              Shadow(color: widget.routeColor.withValues(alpha: 0.5), blurRadius: 14),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _step.instruction ?? '',
          style: TextStyle(
            fontSize: 14.5,
            height: 1.6,
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 18),

        // Items por clasificar
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              // Línea discontinua no existe de fábrica; el borde suave basta.
            ),
          ),
          child: pendientes.isEmpty
              ? Center(
                  child: Text(
                    'routes.sortAllPlaced'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pendientes.map((i) {
                    final chip = _sortChip(items[i], const Color(0xFF06B6D4));
                    return Draggable<int>(
                      data: i,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.scale(
                          scale: 1.08,
                          child: _sortChip(items[i], const Color(0xFF06B6D4), elevado: true),
                        ),
                      ),
                      childWhenDragging: Opacity(opacity: 0.25, child: chip),
                      onDragStarted: () => HapticFeedback.selectionClick(),
                      child: chip,
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // Categorías destino
        ...List.generate(categories.length, (c) {
          final asignados = _sortAssignments.entries
              .where((e) => e.value == c)
              .map((e) => e.key)
              .toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DragTarget<int>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (details) => _assignSortItem(details.data, c),
              builder: (context, candidatos, _) {
                final resaltado = candidatos.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: resaltado
                        ? const Color(0xFF06B6D4).withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: resaltado
                          ? const Color(0xFF06B6D4)
                          : Colors.white.withValues(alpha: 0.12),
                      width: resaltado ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categories[c],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (asignados.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: asignados.map((i) {
                            final correcto = (_step.itemCategory != null &&
                                    i < _step.itemCategory!.length)
                                ? _step.itemCategory![i] == c
                                : true;
                            return _sortChip(
                              items[i],
                              correcto ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              icono: correcto
                                  ? Icons.check_rounded
                                  : Icons.close_rounded,
                            ).animate().scale(
                                  begin: const Offset(0.7, 0.7),
                                  end: const Offset(1, 1),
                                  duration: 280.ms,
                                  curve: Curves.easeOutBack,
                                );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        }),

        if (terminado && _step.explanation != null) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school_rounded, color: Color(0xFF10B981), size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _step.explanation!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _sortChip(String texto, Color color,
      {IconData? icono, bool elevado = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: elevado ? 0.35 : 0.18),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        boxShadow: elevado
            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 14, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _assignSortItem(int itemIndex, int categoryIndex) {
    final esperado = (_step.itemCategory != null &&
            itemIndex < _step.itemCategory!.length)
        ? _step.itemCategory![itemIndex]
        : categoryIndex;
    final correcto = esperado == categoryIndex;

    HapticFeedback.mediumImpact();
    setState(() {
      _sortAssignments[itemIndex] = categoryIndex;
      _charState = correcto ? _CharacterState.correct : _CharacterState.wrong;
      if (correcto) _xpEarned += 3;
      _registerAnswer(correcto, volume: 0.45);
    });
    _triggerFlash(correcto);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // READING
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildReading(bool isDark) {
    return Column(
      key: ValueKey('reading_$_currentStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeChip(
          icon: Icons.menu_book_rounded,
          label: 'routes.readingTitle'.tr(),
          color: widget.routeColor,
        ),
        const SizedBox(height: 16),
        Text(
          _step.title,
          style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800, height: 1.2, color: Colors.white,
            shadows: [Shadow(color: widget.routeColor.withValues(alpha: 0.5), blurRadius: 14)],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.routeColor.withValues(alpha: 0.25)),
            boxShadow: [BoxShadow(
              color: widget.routeColor.withValues(alpha: 0.1), blurRadius: 16, spreadRadius: 1,
            )],
          ),
          child: Text(
            _step.content ?? '',
            style: TextStyle(fontSize: 16, height: 1.85, color: Colors.white.withValues(alpha: 0.88)),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // QUIZ
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildQuiz(bool isDark) {
    return Column(
      key: ValueKey('quiz_$_currentStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeChip(
          icon: Icons.quiz_rounded,
          label: 'routes.questionLabel'.tr(),
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 16),
        Text(
          _step.question!,
          style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, height: 1.3, color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(_step.options!.length, (i) => _buildQuizOption(i, isDark)),
        if (_quizAnswered && _step.explanation != null) ...[
          const SizedBox(height: 12),
          _buildExplanation(),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildQuizOption(int i, bool isDark) {
    final isSelected = _selectedQuizOption == i;
    final isCorrect = i == _step.correctIndex;
    final showResult = _quizAnswered;

    Color borderColor = Colors.white.withValues(alpha: 0.12);
    Color bgColor = Colors.white.withValues(alpha: 0.07);

    if (showResult && isCorrect) {
      borderColor = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.18);
    } else if (showResult && isSelected && !isCorrect) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.18);
    } else if (isSelected) {
      borderColor = widget.routeColor;
      bgColor = widget.routeColor.withValues(alpha: 0.14);
    }

    final glowColor = showResult && isCorrect
        ? const Color(0xFF10B981)
        : showResult && isSelected && !isCorrect
            ? const Color(0xFFEF4444)
            : widget.routeColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _selectQuizOption(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: isSelected || (showResult && isCorrect) ? 2.0 : 1.0,
            ),
            boxShadow: (isSelected || (showResult && isCorrect))
                ? [BoxShadow(
                    color: glowColor.withValues(alpha: 0.3),
                    blurRadius: 14, offset: const Offset(0, 3),
                  )]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: showResult && isCorrect
                      ? const Color(0xFF10B981)
                      : showResult && isSelected && !isCorrect
                          ? const Color(0xFFEF4444)
                          : isSelected
                              ? widget.routeColor
                              : Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: showResult
                      ? Icon(
                          isCorrect ? Icons.check_rounded : isSelected ? Icons.close_rounded : null,
                          color: Colors.white, size: 18,
                        )
                      : Text(
                          String.fromCharCode(65 + i),
                          style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13,
                            color: isSelected ? Colors.white : Colors.white60,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _step.options![i],
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: (i * 60).ms)
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.04, end: 0),
    );
  }

  Widget _buildExplanation() {
    final isCorrect = _selectedQuizOption == _step.correctIndex;
    final color = isCorrect ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
            color: color, size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _step.explanation!,
              style: TextStyle(fontSize: 14, height: 1.55, color: Colors.white.withValues(alpha: 0.85)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXERCISE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildExercise(bool isDark) {
    return Column(
      key: ValueKey('exercise_$_currentStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeChip(
          icon: Icons.edit_rounded,
          label: 'routes.exerciseLabel'.tr(),
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 16),
        Text(
          _step.title,
          style: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, height: 1.2, color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
          ),
          child: Text(
            _step.instruction!,
            style: TextStyle(fontSize: 15, height: 1.65, color: Colors.white.withValues(alpha: 0.88)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _exerciseController,
          onChanged: (_) => setState(() {}),
          maxLines: 5,
          maxLength: 500,
          style: const TextStyle(fontSize: 15, color: Colors.white),
          decoration: InputDecoration(
            hintText: _step.placeholder ?? 'routes.exercisePlaceholder'.tr(),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: widget.routeColor, width: 1.8),
            ),
            counterStyle: const TextStyle(color: Colors.white38, fontSize: 11),
            contentPadding: const EdgeInsets.all(18),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline_rounded, size: 13, color: Colors.white38),
            const SizedBox(width: 5),
            Text(
              'routes.exerciseMinChars'.tr(),
              style: const TextStyle(
                fontSize: 12, color: Colors.white38, fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _saveExerciseToDiary = !_saveExerciseToDiary),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.book_rounded, size: 18, color: Colors.white60),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'routes.saveToDiary'.tr(),
                    style: const TextStyle(fontSize: 13.5, color: Colors.white70),
                  ),
                ),
                Switch(
                  value: _saveExerciseToDiary,
                  activeThumbColor: widget.routeColor,
                  onChanged: (v) => setState(() => _saveExerciseToDiary = v),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildTypeChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMPLETION SCREEN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCompletionScreen(bool isDark) {
    final wasMultiplied = _appliedMultiplier > 1.0;
    final baseXp = widget.lesson.xpReward;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 160,
              child: Lottie.asset(
                'assets/lottie/character_correct.json',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _buildCharacterFallback(),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'routes.lessonComplete'.tr(),
              style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 8),
            Text(
              widget.lesson.title,
              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.55)),
              textAlign: TextAlign.center,
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  widget.routeColor.withValues(alpha: 0.22),
                  const Color(0xFFFBBF24).withValues(alpha: 0.12),
                ]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: widget.routeColor.withValues(alpha: 0.35)),
                boxShadow: [BoxShadow(
                  color: widget.routeColor.withValues(alpha: 0.25), blurRadius: 28, spreadRadius: 2,
                )],
              ),
              child: Column(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 6),
                  // Si hubo multiplicador, mostrar XP base tachado + XP real
                  if (wasMultiplied) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '+$baseXp',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.45),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.white54,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '+$_finalXpAwarded XP',
                          style: TextStyle(
                            fontSize: 36, fontWeight: FontWeight.w900, color: widget.routeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'routes.multiplierApplied'.tr(namedArgs: {'mult': _appliedMultiplier.toStringAsFixed(1)}),
                        style: const TextStyle(
                          color: Color(0xFF8B5CF6), fontSize: 11, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ] else
                    Text(
                      '+$_xpEarned XP',
                      style: TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w900, color: widget.routeColor,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'routes.xpEarned'.tr(),
                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 500.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
                ),
            if (_commitment != null) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xFFFBBF24).withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Text('🤝', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'routes.yourCommitment'.tr(),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _commitment!,
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.45,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
            ],
            const SizedBox(height: 36),
            if (widget.nextLesson != null) ...[
              // Seguir sin pasar por el mapa: menos fricción, sesiones más largas
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: () {
                    AnalyticsService.instance.nextLessonTapped(widget.routeId);
                    Navigator.pop(context, LessonScreen.nextResult);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.routeColor,
                    elevation: 8,
                    shadowColor: widget.routeColor.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'routes.nextLesson'.tr(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.15, end: 0),
              const SizedBox(height: 6),
              Text(
                widget.nextLesson!.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.55)),
              ).animate(delay: 650.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'routes.backToMap'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
            ] else
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.routeColor,
                    elevation: 8,
                    shadowColor: widget.routeColor.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    'routes.backToMap'.tr(),
                    style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.3,
                    ),
                  ),
                ),
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.15, end: 0),
          ],
        ),
      ),
    );
  }
}