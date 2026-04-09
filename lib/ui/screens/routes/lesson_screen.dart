import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/wellness_route.dart';
import '../../../domain/providers/auth_provider.dart';

// ─── Character state ──────────────────────────────────────────────────────────
enum _CharacterState { idle, correct, wrong }

// ═════════════════════════════════════════════════════════════════════════════
// STAR DOT — individual twinkling star (widget-based, web compatible)
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
    // Stagger start
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    // min opacity = 0.05 so stars almost disappear at trough
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
      builder: (_, __) {
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
                      // Inner bright core
                      BoxShadow(
                        color: Colors.white.withOpacity(v * 0.9),
                        blurRadius: widget.size * 1.5,
                        spreadRadius: widget.size * 0.2,
                      ),
                      // Colored outer glow
                      BoxShadow(
                        color: widget.glowColor.withOpacity(v * 0.7),
                        blurRadius: widget.size * 4.0,
                        spreadRadius: widget.size * 0.5,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.white.withOpacity(v * 0.6),
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
// SHOOTING STAR — animated streak across the screen
// ═════════════════════════════════════════════════════════════════════════════
class _ShootingStar extends StatefulWidget {
  final double startX;   // 0..1 fraction of screen width
  final double startY;   // 0..1 fraction of screen height
  final double angle;    // radians
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

    // fire → wait 8s → fire again
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
        builder: (_, __) {
          final t = _progress.value;
          if (t == 0) return const SizedBox.shrink();

          // Head position travels along the angle
          final dist = t * widget.length * 2.5;
          final dx = math.cos(widget.angle) * dist;
          final dy = math.sin(widget.angle) * dist;
          final headX = widget.startX * w + dx;
          final headY = widget.startY * h + dy;

          // Tail fades out as head moves
          final tailOpacity = (1.0 - t).clamp(0.0, 1.0);
          // Head fades in then out
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
          Colors.white.withOpacity(tailOpacity * 0.0),
          color.withOpacity(tailOpacity * 0.5),
          Colors.white.withOpacity(headOpacity),
        ],
      ).createShader(
        Rect.fromPoints(Offset(tailX, tailY), Offset(headX, headY)),
      )
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(tailX, tailY), Offset(headX, headY), paint);

    // Bright head dot
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(headOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(headX, headY), 1.8, dotPaint);
  }

  @override
  bool shouldRepaint(_ShootingStarPainter old) =>
      old.headX != headX || old.headY != headY;
}

// ═════════════════════════════════════════════════════════════════════════════
// STAR CANVAS — full star field with twinkling stars + shooting stars
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

      // ── Twinkling stars ──────────────────────────────────────────────────
      const starCount = 80;
      final stars = List.generate(starCount, (i) {
        final x = rng.nextDouble() * w;
        final y = rng.nextDouble() * h;
        final size = 1.0 + rng.nextDouble() * 2.5;
        final maxOpacity = 0.4 + rng.nextDouble() * 0.6; // brighter range
        final delayMs = rng.nextInt(2500);
        final durationMs = 800 + rng.nextInt(1800); // faster twinkle
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

      // ── Shooting stars ───────────────────────────────────────────────────
      final angleBase = math.pi / 5; // ~36° downward-right
      final shootingStars = [
        _ShootingStar(
          startX: 0.1,
          startY: 0.05,
          angle: angleBase,
          length: w * 0.22,
          color: accentColor,
          delayMs: 2000,
          durationMs: 900,
        ),
        _ShootingStar(
          startX: 0.6,
          startY: 0.02,
          angle: angleBase + 0.1,
          length: w * 0.18,
          color: Colors.white,
          delayMs: 5500,
          durationMs: 750,
        ),
        _ShootingStar(
          startX: 0.3,
          startY: 0.15,
          angle: angleBase - 0.15,
          length: w * 0.25,
          color: const Color(0xFF818CF8),
          delayMs: 9000,
          durationMs: 1000,
        ),
        _ShootingStar(
          startX: 0.75,
          startY: 0.08,
          angle: angleBase + 0.05,
          length: w * 0.15,
          color: accentColor,
          delayMs: 13000,
          durationMs: 800,
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

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.routeColor,
    required this.routeEmoji,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with TickerProviderStateMixin {

  int _currentStep = 0;
  int? _selectedQuizOption;
  bool _quizAnswered = false;
  final _exerciseController = TextEditingController();
  bool _isSaving = false;
  _CharacterState _charState = _CharacterState.idle;
  Color _flashColor = Colors.transparent;
  bool _showFlash = false;
  late ConfettiController _confettiController;
  int _xpEarned = 0;
  bool _showCompletion = false;

  LessonStep get _step => widget.lesson.steps[_currentStep];
  bool get _isLastStep => _currentStep == widget.lesson.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _exerciseController.dispose();
    _confettiController.dispose();
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
    }
  }

  void _nextStep() {
    HapticFeedback.mediumImpact();
    if (_isLastStep) {
      _completeLesson();
    } else {
      setState(() {
        _currentStep++;
        _selectedQuizOption = null;
        _quizAnswered = false;
        _charState = _CharacterState.idle;
        _exerciseController.clear();
      });
    }
  }

  void _selectQuizOption(int index) {
    if (_quizAnswered) return;
    HapticFeedback.lightImpact();
    final isCorrect = index == _step.correctIndex;
    setState(() {
      _selectedQuizOption = index;
      _quizAnswered = true;
      _charState = isCorrect ? _CharacterState.correct : _CharacterState.wrong;
      _xpEarned += isCorrect ? 5 : 0;
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

  Future<void> _completeLesson() async {
    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.completeLesson(widget.lesson.id, widget.lesson.xpReward);
      if (mounted) {
        setState(() {
          _xpEarned += widget.lesson.xpReward;
          _isSaving = false;
          _showCompletion = true;
          _charState = _CharacterState.correct;
        });
        await Future.delayed(const Duration(milliseconds: 150));
        if (mounted) {
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
          top: -100,
          left: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                widget.routeColor.withOpacity(0.28),
                widget.routeColor.withOpacity(0.0),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -100,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF818CF8).withOpacity(0.2),
                const Color(0xFF818CF8).withOpacity(0.0),
              ]),
            ),
          ),
        ),
        Positioned(
          top: 180,
          right: -50,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                widget.routeColor.withOpacity(0.12),
                widget.routeColor.withOpacity(0.0),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Lesson content ──────────────────────────────────────────────────────
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 18, color: Colors.white60),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: _buildProgressNodes()),
          const SizedBox(width: 10),
          _buildXpBadge(),
        ],
      ),
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
                        ? widget.routeColor.withOpacity(0.7)
                        : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: widget.routeColor.withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : isDone
                        ? [
                            BoxShadow(
                              color: widget.routeColor.withOpacity(0.4),
                              blurRadius: 4,
                            )
                          ]
                        : null,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildXpBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFBBF24).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFBBF24).withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            '+$_xpEarned',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFBBF24),
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
          errorBuilder: (_, __, ___) => _buildCharacterFallback(),
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
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: glow.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: glow.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: glow.withOpacity(0.35),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 38)),
        ),
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
    }
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
            disabledBackgroundColor: widget.routeColor.withOpacity(0.22),
            elevation: _canContinue ? 8 : 0,
            shadowColor: widget.routeColor.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLastStep
                          ? 'common.done'.tr()
                          : 'common.continue'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isLastStep
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
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
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: Colors.white,
            shadows: [
              Shadow(color: widget.routeColor.withOpacity(0.5), blurRadius: 14),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.routeColor.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: widget.routeColor.withOpacity(0.1),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            _step.content ?? '',
            style: TextStyle(
              fontSize: 16,
              height: 1.85,
              color: Colors.white.withOpacity(0.88),
            ),
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
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.3,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(
            _step.options!.length, (i) => _buildQuizOption(i, isDark)),
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

    Color borderColor = Colors.white.withOpacity(0.12);
    Color bgColor = Colors.white.withOpacity(0.07);

    if (showResult && isCorrect) {
      borderColor = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withOpacity(0.18);
    } else if (showResult && isSelected && !isCorrect) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFEF4444).withOpacity(0.18);
    } else if (isSelected) {
      borderColor = widget.routeColor;
      bgColor = widget.routeColor.withOpacity(0.14);
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
                ? [
                    BoxShadow(
                      color: glowColor.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: showResult && isCorrect
                      ? const Color(0xFF10B981)
                      : showResult && isSelected && !isCorrect
                          ? const Color(0xFFEF4444)
                          : isSelected
                              ? widget.routeColor
                              : Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: showResult
                      ? Icon(
                          isCorrect
                              ? Icons.check_rounded
                              : isSelected
                                  ? Icons.close_rounded
                                  : null,
                          color: Colors.white,
                          size: 18,
                        )
                      : Text(
                          String.fromCharCode(65 + i),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color:
                                isSelected ? Colors.white : Colors.white60,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _step.options![i],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
    final color =
        isCorrect ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _step.explanation!,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: Colors.white.withOpacity(0.85),
              ),
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
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.25)),
          ),
          child: Text(
            _step.instruction!,
            style: TextStyle(
              fontSize: 15,
              height: 1.65,
              color: Colors.white.withOpacity(0.88),
            ),
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
            hintText:
                _step.placeholder ?? 'routes.exercisePlaceholder'.tr(),
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: widget.routeColor, width: 1.8),
            ),
            counterStyle:
                const TextStyle(color: Colors.white38, fontSize: 11),
            contentPadding: const EdgeInsets.all(18),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 13, color: Colors.white38),
            const SizedBox(width: 5),
            Text(
              'routes.exerciseMinChars'.tr(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COMPLETION SCREEN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCompletionScreen(bool isDark) {
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
                errorBuilder: (_, __, ___) => _buildCharacterFallback(),
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
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
            const SizedBox(height: 8),
            Text(
              widget.lesson.title,
              style: TextStyle(
                  fontSize: 15, color: Colors.white.withOpacity(0.55)),
              textAlign: TextAlign.center,
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 28),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  widget.routeColor.withOpacity(0.22),
                  const Color(0xFFFBBF24).withOpacity(0.12),
                ]),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: widget.routeColor.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: widget.routeColor.withOpacity(0.25),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 6),
                  Text(
                    '+$_xpEarned XP',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: widget.routeColor,
                    ),
                  ),
                  Text(
                    'routes.xpEarned'.tr(),
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.5)),
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
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: widget.routeColor,
                  elevation: 8,
                  shadowColor: widget.routeColor.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'routes.backToMap'.tr(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
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