import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../data/models/reward_service.dart';
import '../../../data/models/review_deck.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/reward_dialog.dart';
import '../../../domain/services/app_review_service.dart';
import '../../../domain/services/motion_service.dart';

enum _Phase { intro, playing, results }

/// Repaso diario: 5 tarjetas de lecciones ya completadas, sin cronómetro.
/// Las falladas vuelven en próximos repasos. Devuelve `true` al terminar.
class DailyReviewScreen extends StatefulWidget {
  final List<ReviewCard> deck;

  /// Solo para pruebas: no guarda en Firestore ni reproduce sonidos al terminar.
  @visibleForTesting
  final bool preview;

  const DailyReviewScreen({super.key, required this.deck, this.preview = false});

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  static const _xpReward = 10;
  static const _gold = Color(0xFFFBBF24);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFF43F5E);

  late final ConfettiController _confetti;
  _Phase _phase = _Phase.intro;
  int _index = 0;
  int? _answer;
  int _streak = 0;
  int _shakeToken = 0;
  final Set<String> _missed = {};
  final Set<String> _correct = {};
  bool _rewarded = false;
  int _starsShown = 0;

  List<ReviewCard> get _deck => widget.deck;
  ReviewCard get _card => _deck[_index];
  bool get _answered => _answer != null;
  bool get _isRight => _answer == _card.correctIndex;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  // ── Flujo ──────────────────────────────────────────────────────────────────
  void _start() {
    HapticFeedback.mediumImpact();
    SoundService.instance.play(Sfx.reviewStart, volume: 0.6);
    AnalyticsService.instance.reviewStarted(_deck.length);
    setState(() => _phase = _Phase.playing);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) SoundService.instance.play(Sfx.cardDeal, volume: 0.7);
    });
  }

  void _choose(int option) {
    if (_answered) return;
    final right = option == _card.correctIndex;
    setState(() {
      _answer = option;
      if (right) {
        _streak++;
        _correct.add(_card.id);
      } else {
        _streak = 0;
        _missed.add(_card.id);
        _shakeToken++;
      }
    });
    if (right) {
      HapticFeedback.lightImpact();
      if (_streak >= 2) {
        SoundService.instance.combo(_streak - 2, volume: 0.55);
      } else {
        SoundService.instance.play(Sfx.correct, volume: 0.55);
      }
    } else {
      HapticFeedback.heavyImpact();
      SoundService.instance.play(Sfx.wrong, volume: 0.5);
    }
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_index >= _deck.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _answer = null;
    });
    SoundService.instance.play(Sfx.cardDeal, volume: 0.7);
  }

  Future<void> _finish() async {
    setState(() => _phase = _Phase.results);
    final total = _deck.length;
    final score = _correct.length;
    final stars = ReviewDeck.stars(score, total);

    // Estrellas una a una, cada una con su nota
    for (int i = 0; i < stars; i++) {
      await Future.delayed(Duration(milliseconds: i == 0 ? 900 : 380));
      if (!mounted) return;
      setState(() => _starsShown = i + 1);
      SoundService.instance.star(i);
      HapticFeedback.lightImpact();
    }
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    if (score == total) {
      if (!MotionService.instance.reducedNow) _confetti.play();
      SoundService.instance.play(Sfx.reviewPerfect, volume: 0.7);
    } else {
      SoundService.instance.play(Sfx.complete, volume: 0.6);
    }

    if (widget.preview) return;
    AnalyticsService.instance.reviewComplete(score, total);
    final auth = context.read<AuthProvider>();
    final garden = context.read<GardenProvider>();
    // Una tarjeta fallada que luego se acierta en otro repaso sale de la lista
    final corrected = _correct.difference(_missed);
    final rewarded = await auth.completeDailyReview(
      missed: _missed,
      corrected: corrected,
      xpReward: _xpReward,
      garden: garden,
    );
    if (!mounted) return;
    setState(() => _rewarded = rewarded);
    if (rewarded) {
      final reward = await garden.grantReward(RewardSource.review);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) await RewardDialog.show(context, reward);
    }
    if (score == total) AppReviewService.instance.onHappyMoment('perfect_review', auth);
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final accent = _phase == _Phase.playing ? _card.routeColor : const Color(0xFFF59E0B);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0B0B1A),
                  Color.lerp(const Color(0xFF12122A), accent, 0.22)!,
                  const Color(0xFF0B0B1A),
                ],
              ),
            ),
          ),
          ..._floatingOrbs(accent),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child: switch (_phase) {
                _Phase.intro => _buildIntro(),
                _Phase.playing => _buildPlaying(),
                _Phase.results => _buildResults(),
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 40,
              gravity: 0.25,
              colors: const [_gold, _green, Color(0xFF818CF8), Colors.pinkAccent, Colors.white],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _floatingOrbs(Color accent) => [
        for (final (top, left, size, ms) in const [
          (80.0, -60.0, 220.0, 5200),
          (420.0, 260.0, 260.0, 6400),
          (650.0, -40.0, 160.0, 4800),
        ])
          Positioned(
            top: top,
            left: left,
            child: IgnorePointer(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    accent.withValues(alpha: 0.22),
                    accent.withValues(alpha: 0.0),
                  ]),
                ),
              )
                  .animate(onPlay: MotionService.loop(context, reverse: true))
                  .moveY(begin: -12, end: 12, duration: ms.ms, curve: Curves.easeInOut),
            ),
          ),
      ];

  // ── Intro ──────────────────────────────────────────────────────────────────
  Widget _buildIntro() {
    final emojis = _deck.map((c) => c.routeEmoji).toSet().take(4).toList();
    return Padding(
      key: const ValueKey('intro'),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 230,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (int i = 0; i < 3; i++)
                  Transform.rotate(
                    angle: (i - 1) * 0.16,
                    child: Transform.translate(
                      offset: Offset((i - 1) * 46.0, (i - 1).abs() * 14.0),
                      child: _cardBack(i),
                    ),
                  )
                      .animate(delay: (150 * i).ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.4, end: 0, curve: Curves.easeOutBack)
                      .then()
                      .animate(onPlay: MotionService.loop(context, reverse: true))
                      .moveY(begin: 0, end: -6, duration: (1500 + i * 250).ms, curve: Curves.easeInOut),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'review.title'.tr(),
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'review.introSubtitle'.tr(namedArgs: {'n': '${_deck.length}'}),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.5, color: Colors.white.withValues(alpha: 0.7)),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final e in emojis)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 18)),
                ),
            ],
          ).animate().fadeIn(delay: 600.ms),
          const Spacer(),
          Text(
            'review.noTimer'.tr(),
            style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: FilledButton(
              onPressed: _start,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(
                'review.start'.tr(),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          )
              .animate(onPlay: MotionService.loop(context, reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 1100.ms),
        ],
      ),
    );
  }

  Widget _cardBack(int i) {
    const colors = [Color(0xFF6366F1), Color(0xFFF59E0B), Color(0xFFEC4899)];
    final c = colors[i % colors.length];
    return Container(
      width: 140,
      height: 190,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c, Color.lerp(c, Colors.black, 0.35)!],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          const Text('✨', style: TextStyle(fontSize: 40)),
        ],
      ),
    );
  }

  // ── Jugando ────────────────────────────────────────────────────────────────
  Widget _buildPlaying() {
    return Padding(
      key: const ValueKey('playing'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(child: _progress()),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _streak >= 2
                    ? Container(
                        key: ValueKey('streak_$_streak'),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('🔥 ×$_streak',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white)),
                      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack)
                    : const SizedBox(width: 48),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) {
                      final incoming = child.key == ValueKey('card_$_index');
                      final offset = Tween<Offset>(
                        begin: incoming ? const Offset(1.2, 0.05) : const Offset(-1.2, 0.05),
                        end: Offset.zero,
                      ).animate(anim);
                      return SlideTransition(
                        position: offset,
                        child: RotationTransition(
                          turns: Tween<double>(begin: incoming ? 0.04 : -0.04, end: 0).animate(anim),
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                      );
                    },
                    child: KeyedSubtree(key: ValueKey('card_$_index'), child: _cardFace()),
                  ),
                  const SizedBox(height: 18),
                  _answers(),
                  if (_answered && _card.feedback != null) ...[
                    const SizedBox(height: 14),
                    _feedback(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _answered ? 1 : 0,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _answered ? _next : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _card.routeColor,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(
                  _index >= _deck.length - 1 ? 'review.seeResults'.tr() : 'common.next'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress() {
    return Row(
      children: [
        for (int i = 0; i < _deck.length; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: i == _index ? 9 : 7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: i < _index || (i == _index && _answered)
                    ? (_missed.contains(_deck[i].id) ? _red : _green)
                    : i == _index
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
      ],
    );
  }

  Widget _cardFace() {
    final card = _card;
    final border = !_answered ? Colors.white.withValues(alpha: 0.18) : (_isRight ? _green : _red);
    final kindKey = switch (card.kind) {
      ReviewKind.mythFact => 'review.kind.mythFact',
      ReviewKind.category => 'review.kind.category',
      ReviewKind.quiz => 'review.kind.quiz',
    };

    Widget face = Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            card.routeColor.withValues(alpha: 0.34),
            const Color(0xFF16162E),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border, width: _answered ? 2.5 : 1.5),
        boxShadow: [
          BoxShadow(
            color: (_answered ? border : card.routeColor).withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(card.routeEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      card.lessonTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                kindKey.tr().toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
                  color: card.routeColor.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                card.kind == ReviewKind.mythFact ? '"${card.prompt}"' : card.prompt,
                style: const TextStyle(fontSize: 21, height: 1.4, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          if (_answered)
            Positioned(
              right: -6,
              top: -4,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: border, shape: BoxShape.circle),
                child: Icon(_isRight ? Icons.check_rounded : Icons.close_rounded, color: Colors.white, size: 22),
              ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
            ),
        ],
      ),
    );

    if (_answered && !_isRight) {
      face = face.animate(key: ValueKey('shake_$_shakeToken')).shakeX(hz: 5, amount: 6, duration: 420.ms);
    } else if (_answered) {
      face = face
          .animate(key: ValueKey('pop_$_index'))
          .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 160.ms)
          .then()
          .scale(begin: const Offset(1.03, 1.03), end: const Offset(1, 1), duration: 200.ms);
    }
    return face;
  }

  Widget _answers() {
    final card = _card;
    if (card.kind == ReviewKind.mythFact) {
      return Row(
        children: [
          Expanded(child: _answerButton(0, 'routes.mythWord'.tr(), icon: Icons.close_rounded, base: _red)),
          const SizedBox(width: 12),
          Expanded(child: _answerButton(1, 'routes.factWord'.tr(), icon: Icons.check_rounded, base: _green)),
        ],
      );
    }
    return Column(
      children: [
        for (int i = 0; i < card.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _answerButton(i, card.options[i], letter: String.fromCharCode(65 + i)),
          )
              .animate(delay: (60 * i).ms)
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _answerButton(int option, String label, {IconData? icon, String? letter, Color? base}) {
    final isCorrectOption = option == _card.correctIndex;
    final chosen = _answer == option;
    Color bg = Colors.white.withValues(alpha: 0.08);
    Color border = (base ?? Colors.white).withValues(alpha: base == null ? 0.16 : 0.55);
    if (_answered && isCorrectOption) {
      bg = _green.withValues(alpha: 0.25);
      border = _green;
    } else if (_answered && chosen) {
      bg = _red.withValues(alpha: 0.22);
      border = _red;
    } else if (_answered) {
      bg = Colors.white.withValues(alpha: 0.03);
      border = Colors.white.withValues(alpha: 0.06);
    }

    return GestureDetector(
      onTap: _answered ? null : () => _choose(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: base != null ? 18 : 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: _answered && (chosen || isCorrectOption) ? 2 : 1.2),
        ),
        child: Row(
          mainAxisAlignment: base != null ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            if (letter != null) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(
                  child: Text(letter,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white70)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (icon != null) ...[
              Icon(icon, size: 18, color: base),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: base != null && !_answered ? base : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedback() {
    final color = _isRight ? _green : const Color(0xFFF59E0B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_isRight ? Icons.lightbulb_rounded : Icons.replay_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isRight ? _card.feedback! : '${_card.feedback!}\n\n${'review.willReturn'.tr()}',
              style: TextStyle(fontSize: 13.5, height: 1.5, color: Colors.white.withValues(alpha: 0.88)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.15, end: 0);
  }

  // ── Resultados ─────────────────────────────────────────────────────────────
  Widget _buildResults() {
    final total = _deck.length;
    final score = _correct.length;
    final stars = ReviewDeck.stars(score, total);
    final titleKey = switch (stars) {
      3 => 'review.result.perfect',
      2 => 'review.result.great',
      1 => 'review.result.good',
      _ => 'review.result.keepGoing',
    };
    final missedCards = _deck.where((c) => _missed.contains(c.id)).toList();

    return ListView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      children: [
        Center(
          child: SizedBox(
            width: 170,
            height: 170,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: total == 0 ? 0 : score / total),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => CustomPaint(
                painter: _RingPainter(progress: v, color: stars == 3 ? _gold : _green),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${(v * total).round()}/$total',
                          style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text('review.correct'.tr(),
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.fromLTRB(6, i == 1 ? 0 : 14, 6, 0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                    child: child,
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    key: ValueKey('star_${i}_${i < _starsShown}'),
                    size: i == 1 ? 58 : 46,
                    color: i < _starsShown ? _gold : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          titleKey.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        Text(
          _rewarded ? 'review.rewarded'.tr(namedArgs: {'xp': '$_xpReward'}) : 'review.practiceMessage'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white.withValues(alpha: 0.7)),
        ).animate().fadeIn(delay: 650.ms),
        if (missedCards.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text(
            'review.toReview'.tr(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
          ).animate().fadeIn(delay: 800.ms),
          const SizedBox(height: 10),
          for (final (i, c) in missedCards.indexed)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.routeColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Text(c.routeEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.prompt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
                        Text(c.lessonTitle,
                            style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.55))),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: (850 + i * 80).ms).fadeIn().slideX(begin: 0.1, end: 0),
        ],
        const SizedBox(height: 26),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text('common.done'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ).animate().fadeIn(delay: 900.ms),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    // Resplandor con trazos concéntricos (sin MaskFilter.blur)
    for (final (width, alpha) in const [(22.0, 0.08), (16.0, 0.14), (12.0, 1.0)]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width
          ..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}
