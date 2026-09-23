import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../data/models/diary_entry.dart';
import '../../../data/models/lumi.dart';
import '../../../data/models/mood_entry.dart';
import '../../../data/models/wellness_route.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/commitment_service.dart';
import '../../../domain/services/motion_service.dart';
import '../../../domain/services/notification_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import 'lesson_palette.dart';
import 'steps/commit_step.dart';
import 'steps/exercise_step.dart';
import 'steps/myth_fact_step.dart';
import 'steps/order_step.dart';
import 'steps/pick_step.dart';
import 'steps/practice_step.dart';
import 'steps/quiz_step.dart';
import 'steps/reading_step.dart';
import 'steps/reveal_step.dart';
import 'steps/scenario_step.dart';
import 'steps/slider_step.dart';
import 'steps/sort_step.dart';
import 'steps/step_common.dart';
import 'steps/story_step.dart';
import 'widgets/lesson_background.dart';
import 'widgets/lesson_complete_view.dart';
import '../../widgets/min_tap_target.dart';

enum _CharacterState { idle, correct, wrong }

/// Una lección: recorre sus pasos y al final guarda el progreso.
///
/// Esta pantalla solo coordina (barra superior, Lumi, botón "Continuar",
/// racha de aciertos, XP y guardado). Cada tipo de paso vive en `steps/` y
/// avisa con [StepCallbacks]; el fondo y la pantalla final están en
/// `widgets/`. Los colores salen de [LessonPalette], que sigue el tema de la
/// app: cielo nocturno en oscuro y amanecer en claro.
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

  /// Pasos que **esconden** el botón "Continuar" hasta poder seguir, en vez de
  /// enseñarlo apagado.
  ///
  /// En una conversación el botón apagado se lee como algo roto ("¿por qué no
  /// avanza?") y compite con el "toca para seguir" de las burbujas: lo dijeron
  /// los testers. En los pasos que se responden (quiz, escenario…) el botón sí
  /// se queda a la vista: ahí indica qué hacer después de elegir.
  static bool hidesContinue(LessonStepType type) => type == LessonStepType.story;

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

class _LessonScreenState extends State<LessonScreen> {
  int _currentStep = 0;

  /// El paso avisó que ya se puede continuar ([StepCallbacks.onReady]).
  bool _stepReady = false;

  /// exercise: borrador y si guardarlo también en el diario.
  String _exerciseDraft = '';
  bool _saveExerciseToDiary = false;

  /// commit: el micro-reto elegido, se muestra al completar la lección.
  String? _commitment;

  /// Aciertos seguidos dentro de la lección, para la racha.
  int _streakInLesson = 0;

  _CharacterState _charState = _CharacterState.idle;
  Color _flashColor = Colors.transparent;
  bool _showFlash = false;
  late final ConfettiController _confettiController;

  bool _isSaving = false;
  bool _showCompletion = false;
  int _xpEarned = 0;
  int _finalXpAwarded = 0;
  double _appliedMultiplier = 1.0;

  LessonStep get _step => widget.lesson.steps[_currentStep];
  bool get _isLastStep => _currentStep == widget.lesson.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _stepReady = _readyOnArrival(_step);
    SoundService.instance.setBaseAmbient(
      SoundService.ambientForRoute(widget.routeId),
      volume: 0.18,
    );
    AnalyticsService.instance.lessonStart(widget.routeId, widget.lesson.id);
  }

  @override
  void dispose() {
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

  /// Leer no pide interacción: se puede continuar de inmediato.
  static bool _readyOnArrival(LessonStep step) => step.type == LessonStepType.reading;

  bool get _canContinue => _step.type == LessonStepType.exercise
      ? _exerciseDraft.trim().length >= ExerciseStep.minChars
      : _stepReady;

  bool get _hidesContinueUntilReady => LessonScreen.hidesContinue(_step.type);

  void _nextStep() {
    HapticFeedback.mediumImpact();
    if (_step.type == LessonStepType.exercise && _saveExerciseToDiary) {
      _saveExerciseEntry();
    }
    if (_isLastStep) {
      _completeLesson();
      return;
    }
    setState(() {
      _currentStep++;
      _charState = _CharacterState.idle;
      _stepReady = _readyOnArrival(_step);
      _exerciseDraft = '';
      _saveExerciseToDiary = false;
    });
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
    final text = _exerciseDraft.trim();
    if (text.length < ExerciseStep.minChars) return;
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

  // ── Callbacks de los pasos ────────────────────────────────────────────────
  StepCallbacks get _stepCallbacks => StepCallbacks(
        onAnswer: (correct, xp, {bool sound = true}) {
          if (!mounted) return;
          setState(() {
            _charState = correct ? _CharacterState.correct : _CharacterState.wrong;
            _xpEarned += xp;
            _registerAnswer(correct, sound: sound, volume: 0.5);
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

  /// Registra un acierto o fallo para la racha interna de la lección y toca
  /// su sonido: desde el segundo acierto seguido, cada uno suena más agudo.
  void _registerAnswer(bool correct, {bool sound = true, double volume = 0.6}) {
    _streakInLesson = correct ? _streakInLesson + 1 : 0;
    if (!sound) return;
    if (!correct) {
      SoundService.instance.play(Sfx.wrong, volume: volume * 0.85);
    } else if (_streakInLesson >= 2) {
      SoundService.instance.combo(_streakInLesson - 2, volume: volume);
    } else {
      SoundService.instance.play(Sfx.correct, volume: volume);
    }
  }

  void _triggerFlash(bool correct) {
    // El destello de pantalla completa es justo lo que "reducir animaciones"
    // debe evitar: el color del paso ya indica el resultado.
    if (MotionService.reduced(context)) return;
    setState(() {
      _flashColor = correct ? StepColors.correct : StepColors.wrong;
      _showFlash = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showFlash = false);
    });
  }

  // ── Completar lección (aplica el multiplicador del jardín) ────────────────
  Future<void> _completeLesson() async {
    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProvider>();
      final garden = context.read<GardenProvider>();
      final reduced = MotionService.reduced(context);

      final multiplier = garden.currentXpMultiplier;
      final baseXp = widget.lesson.xpReward;
      final finalXp = multiplier > 1.0 ? (baseXp * multiplier).round() : baseXp;

      await auth.completeLesson(widget.lesson.id, baseXp, garden: garden);
      AnalyticsService.instance.lessonComplete(widget.routeId, widget.lesson.id, finalXp);

      if (!mounted) return;
      setState(() {
        _xpEarned += finalXp;
        _finalXpAwarded = finalXp;
        _appliedMultiplier = multiplier;
        _isSaving = false;
        _showCompletion = true;
        _charState = _CharacterState.correct;
      });
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      SoundService.instance.play(Sfx.complete, volume: 0.7);
      if (!reduced) _confettiController.play();
      HapticFeedback.heavyImpact();
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
    final palette = LessonPalette(isDark: isDark, route: widget.routeColor);

    return LessonPaletteScope(
      palette: palette,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              LessonBackground(routeColor: widget.routeColor, isDark: isDark),
              SafeArea(
                child: _showCompletion
                    ? LessonCompleteView(
                        lesson: widget.lesson,
                        routeColor: widget.routeColor,
                        nextLesson: widget.nextLesson,
                        xpEarned: _xpEarned,
                        finalXpAwarded: _finalXpAwarded,
                        multiplier: _appliedMultiplier,
                        commitment: _commitment,
                        onNext: () {
                          AnalyticsService.instance.nextLessonTapped(widget.routeId);
                          Navigator.pop(context, LessonScreen.nextResult);
                        },
                        onBackToMap: () => Navigator.pop(context, true),
                      )
                    : _buildLessonContent(palette),
              ),
              if (_showFlash)
                IgnorePointer(
                  child: Container(color: _flashColor.withValues(alpha: 0.13)),
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
        ),
      ),
    );
  }

  Widget _buildLessonContent(LessonPalette p) {
    return Column(
      children: [
        _buildTopBar(p),
        _buildCharacter(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: AnimatedSwitcher(
              duration: MotionService.reduced(context)
                  ? const Duration(milliseconds: 150)
                  : const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: MotionService.reduced(context)
                      ? Offset.zero
                      : const Offset(0.06, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: KeyedSubtree(
                key: ValueKey('step_$_currentStep'),
                child: _buildStep(),
              ),
            ),
          ),
        ),
        _buildBottomBar(p),
      ],
    );
  }

  Widget _buildStep() {
    final step = _step;
    final color = widget.routeColor;
    final callbacks = _stepCallbacks;

    return switch (step.type) {
      LessonStepType.reading => ReadingStep(step: step, routeColor: color),
      LessonStepType.quiz => QuizStep(step: step, routeColor: color, callbacks: callbacks),
      LessonStepType.exercise => ExerciseStep(
          step: step,
          routeColor: color,
          onDraftChanged: (text, saveToDiary) => setState(() {
            _exerciseDraft = text;
            _saveExerciseToDiary = saveToDiary;
          }),
        ),
      LessonStepType.scenario =>
        ScenarioStep(step: step, routeColor: color, callbacks: callbacks),
      LessonStepType.reveal => RevealStep(step: step, routeColor: color, callbacks: callbacks),
      LessonStepType.slider => SliderStep(step: step, routeColor: color, callbacks: callbacks),
      LessonStepType.sort => SortStep(step: step, routeColor: color, callbacks: callbacks),
      LessonStepType.mythFact =>
        MythFactStep(step: step, routeColor: color, callbacks: callbacks),
      LessonStepType.practice =>
        PracticeStep(step: step, routeColor: color, callbacks: callbacks),
      LessonStepType.order => OrderStep(step: step, routeColor: color, callbacks: callbacks),
      LessonStepType.pick => PickStep(step: step, routeColor: color, callbacks: callbacks),
      LessonStepType.story => StoryStep(
          step: step,
          routeColor: color,
          fallbackSpeaker: widget.routeEmoji,
          callbacks: callbacks,
        ),
      LessonStepType.commit => CommitStep(
          step: step,
          routeColor: color,
          callbacks: callbacks,
          onCommitted: (text) {
            _commitment = text;
            SoundService.instance.play(Sfx.commit, volume: 0.7);
            _saveCommitment(text);
          },
        ),
    };
  }

  // ── Barra superior ────────────────────────────────────────────────────────
  Widget _buildTopBar(LessonPalette p) {
    return Consumer<GardenProvider>(
      builder: (_, garden, _) {
        final mult = garden.currentXpMultiplier;
        const violet = Color(0xFF8B5CF6);

        return Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 16, 4),
          child: Column(
            children: [
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: MaterialLocalizations.of(context).closeButtonTooltip,
                    child: MinTapTarget(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: p.card(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: p.line(0.15)),
                        ),
                        child: Icon(Icons.close_rounded, size: 18, color: p.inkA(0.6)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: _buildProgressNodes(p)),
                  const SizedBox(width: 6),
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
                  _buildAmbientToggle(p),
                  const SizedBox(width: 2),
                  _buildXpBadge(p),
                ],
              ),
              if (mult > 1.0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: violet.withValues(alpha: p.isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: violet.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        'routes.multiplierBanner'.tr(
                          namedArgs: {'mult': mult.toStringAsFixed(1)},
                        ),
                        style: TextStyle(
                          color: p.accent(violet),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressNodes(LessonPalette p) {
    final total = widget.lesson.steps.length;
    return Semantics(
      label: '${_currentStep + 1} / $total',
      child: Row(
        children: List.generate(total, (i) {
          final isDone = i < _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < total - 1 ? 4 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                // Sin rebote: la sombra aparece y desaparece, y el rebote
                // volvería negativo su blur.
                curve: Curves.easeOutCubic,
                height: isCurrent ? 10 : 8,
                decoration: BoxDecoration(
                  color: isDone
                      ? widget.routeColor
                      : isCurrent
                          ? widget.routeColor.withValues(alpha: 0.7)
                          : p.line(0.15),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: widget.routeColor.withValues(alpha: p.isDark ? 0.8 : 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Activa o silencia el ambiente de la ruta. Se recuerda entre lecciones.
  Widget _buildAmbientToggle(LessonPalette p) {
    final on = SoundService.instance.lessonAmbientEnabled;
    return Semantics(
      button: true,
      toggled: on,
      label: 'routes.ambientToggle'.tr(),
      child: MinTapTarget(
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
            color: on ? widget.routeColor.withValues(alpha: 0.2) : p.card(0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: on ? widget.routeColor.withValues(alpha: 0.5) : p.line(0.15),
            ),
          ),
          child: Icon(
            on ? Icons.music_note_rounded : Icons.music_off_rounded,
            size: 16,
            color: on ? p.accent(widget.routeColor) : p.inkA(0.38),
          ),
        ),
      ),
    );
  }

  Widget _buildXpBadge(LessonPalette p) {
    const gold = Color(0xFFFBBF24);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: gold.withValues(alpha: p.isDark ? 0.15 : 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            '+$_xpEarned',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: p.accent(gold),
            ),
          ),
        ],
      ),
    );
  }

  /// Badge de racha dentro de la lección. Aparece a partir de 2 aciertos
  /// seguidos y late cada vez que sube.
  Widget _buildStreakBadge() {
    return Container(
      key: ValueKey('streak_$_streakInLesson'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.45), blurRadius: 12),
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

  /// Lumi acompaña la lección: contenta mientras lees, emocionada al acertar
  /// y cariñosa al equivocarte (nunca decepcionada).
  Widget _buildCharacter() {
    final mood = switch (_charState) {
      _CharacterState.idle => LumiMood.happy,
      _CharacterState.correct => LumiMood.excited,
      _CharacterState.wrong => LumiMood.caring,
    };
    return SizedBox(
      height: 110,
      child: Center(child: LumiAvatar(mood: mood, size: 104)),
    );
  }

  /// El botón "Continuar", que en algunos pasos ([_hidesContinueUntilReady])
  /// aparece recién cuando se puede seguir. Al aparecer, la barra crece y el
  /// botón sube: sin rebote, que interpolaría en negativo el blur de su sombra.
  Widget _buildBottomBar(LessonPalette p) {
    final hidden = _hidesContinueUntilReady && !_canContinue;
    final reduced = MotionService.reduced(context);
    final Widget child;
    if (hidden) {
      child = const SizedBox(width: double.infinity);
    } else if (reduced) {
      child = _buildBottomButton(p);
    } else {
      child = _buildBottomButton(p)
          .animate()
          .fadeIn(duration: 260.ms)
          .slideY(begin: 0.45, end: 0, duration: 340.ms, curve: Curves.easeOutCubic);
    }
    return AnimatedSize(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  Widget _buildBottomButton(LessonPalette p) {
    final enabled = _canContinue && !_isSaving;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: enabled ? _nextStep : null,
          style: FilledButton.styleFrom(
            backgroundColor: widget.routeColor,
            disabledBackgroundColor: widget.routeColor.withValues(alpha: 0.22),
            disabledForegroundColor: p.isDark
                ? Colors.white.withValues(alpha: 0.7)
                : p.accent(widget.routeColor).withValues(alpha: 0.65),
            elevation: enabled ? 8 : 0,
            shadowColor: widget.routeColor.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLastStep ? 'common.done'.tr() : 'common.continue'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
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
}
