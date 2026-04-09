import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/providers/auth_provider.dart';

// ─── Breathing technique model ────────────────────────────────────────────────
class _BreathingTechnique {
  final String id;
  final String nameKey;
  final String descriptionKey;
  final String benefitKey;
  final String emoji;
  final Color color;
  final List<_BreathPhase> phases;

  const _BreathingTechnique({
    required this.id,
    required this.nameKey,
    required this.descriptionKey,
    required this.benefitKey,
    required this.emoji,
    required this.color,
    required this.phases,
  });

  int get totalCycleDuration =>
      phases.fold(0, (sum, p) => sum + p.durationSeconds);
}

class _BreathPhase {
  final String labelKey;
  final int durationSeconds;
  final bool expand;

  const _BreathPhase({
    required this.labelKey,
    required this.durationSeconds,
    required this.expand,
  });
}

// ─── Ambient sound ────────────────────────────────────────────────────────────
class _AmbientSound {
  final String id;
  final String labelKey;
  final String emoji;
  final String url;

  const _AmbientSound({
    required this.id,
    required this.labelKey,
    required this.emoji,
    required this.url,
  });
}

// ─── Static data ──────────────────────────────────────────────────────────────
const _techniques = [
  _BreathingTechnique(
    id: 'box',
    nameKey: 'breathing.box.name',
    descriptionKey: 'breathing.box.description',
    benefitKey: 'breathing.box.benefit',
    emoji: '⬜',
    color: Color(0xFF6366F1),
    phases: [
      _BreathPhase(labelKey: 'breathing.phase.inhale', durationSeconds: 4, expand: true),
      _BreathPhase(labelKey: 'breathing.phase.hold',   durationSeconds: 4, expand: true),
      _BreathPhase(labelKey: 'breathing.phase.exhale', durationSeconds: 4, expand: false),
      _BreathPhase(labelKey: 'breathing.phase.hold',   durationSeconds: 4, expand: false),
    ],
  ),
  _BreathingTechnique(
    id: 'calm_478',
    nameKey: 'breathing.calm478.name',
    descriptionKey: 'breathing.calm478.description',
    benefitKey: 'breathing.calm478.benefit',
    emoji: '🌊',
    color: Color(0xFF0EA5E9),
    phases: [
      _BreathPhase(labelKey: 'breathing.phase.inhale', durationSeconds: 4,  expand: true),
      _BreathPhase(labelKey: 'breathing.phase.hold',   durationSeconds: 7,  expand: true),
      _BreathPhase(labelKey: 'breathing.phase.exhale', durationSeconds: 8,  expand: false),
    ],
  ),
  _BreathingTechnique(
    id: 'flow',
    nameKey: 'breathing.flow.name',
    descriptionKey: 'breathing.flow.description',
    benefitKey: 'breathing.flow.benefit',
    emoji: '🍃',
    color: Color(0xFF10B981),
    phases: [
      _BreathPhase(labelKey: 'breathing.phase.inhale', durationSeconds: 4, expand: true),
      _BreathPhase(labelKey: 'breathing.phase.exhale', durationSeconds: 8, expand: false),
    ],
  ),
];

const _ambientSounds = [
  _AmbientSound(id: 'none',   labelKey: 'breathing.sound.none',   emoji: '🔇', url: ''),
  _AmbientSound(id: 'rain',   labelKey: 'breathing.sound.rain',   emoji: '🌧️', url: 'https://assets.mixkit.co/active_storage/sfx/212/212-preview.mp3'),
  _AmbientSound(id: 'forest', labelKey: 'breathing.sound.forest', emoji: '🌲', url: 'https://assets.mixkit.co/active_storage/sfx/1173/1173-preview.mp3'),
  _AmbientSound(id: 'ocean',  labelKey: 'breathing.sound.ocean',  emoji: '🌊', url: 'https://assets.mixkit.co/active_storage/sfx/1246/1246-preview.mp3'),
  _AmbientSound(id: 'white',  labelKey: 'breathing.sound.white',  emoji: '☁️', url: 'https://assets.mixkit.co/active_storage/sfx/2583/2583-preview.mp3'),
];

// Science facts — keys only, text lives in JSON
const _scienceFactKeys = [
  ('🧠', 'breathing.science.vagus.title', 'breathing.science.vagus.desc'),
  ('❤️', 'breathing.science.hrv.title',   'breathing.science.hrv.desc'),
  ('⚡', 'breathing.science.amygdala.title', 'breathing.science.amygdala.desc'),
  ('🌙', 'breathing.science.sleep.title', 'breathing.science.sleep.desc'),
];

// Motivational phrase keys
const _motivationalKeys = [
  'breathing.motivational.0',
  'breathing.motivational.1',
  'breathing.motivational.2',
  'breathing.motivational.3',
];

enum _BreathingStep { science, setup, session, completion }

// ═════════════════════════════════════════════════════════════════════════════
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});
  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {

  _BreathingStep _step = _BreathingStep.science;

  _BreathingTechnique _selectedTechnique = _techniques[0];
  int _selectedMinutes = 3;
  _AmbientSound _selectedSound = _ambientSounds[0];

  late AnimationController _breathController;
  late AnimationController _pulseController;

  int _currentPhaseIndex = 0;
  int _phaseSecondsLeft = 0;
  int _totalSecondsLeft = 0;
  bool _sessionRunning = false;
  bool _sessionPaused = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  late List<_StarData> _stars;

  static const int _xpReward = 15;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this, duration: const Duration(seconds: 4));
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    final rng = math.Random(42);
    _stars = List.generate(60, (_) => _StarData(
      x: rng.nextDouble(), y: rng.nextDouble(),
      size: 0.8 + rng.nextDouble() * 2.0,
      opacity: 0.2 + rng.nextDouble() * 0.7,
      delayMs: rng.nextInt(3000),
      durationMs: 900 + rng.nextInt(2000),
    ));

    _audioPlayer.setVolume(0.4);
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _t(String key) {
    final t = key.tr();
    return t == key ? key : t;
  }

  String _techniqueName(_BreathingTechnique t) => _t(t.nameKey);
  String _techniqueBenefit(_BreathingTechnique t) => _t(t.benefitKey);
  String _phaseLabel(_BreathPhase p) => _t(p.labelKey);
  String _soundLabel(_AmbientSound s) => _t(s.labelKey);

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Audio ─────────────────────────────────────────────────────────────────
  Future<void> _startAudio() async {
    if (_selectedSound.url.isEmpty) return;
    try { await _audioPlayer.play(UrlSource(_selectedSound.url)); }
    catch (e) { debugPrint('Audio error: $e'); }
  }

  Future<void> _stopAudio() async {
    try { await _audioPlayer.stop(); } catch (_) {}
  }

  // ── Session logic ─────────────────────────────────────────────────────────
  void _startSession() {
    setState(() {
      _sessionRunning = true;
      _sessionPaused = false;
      _totalSecondsLeft = _selectedMinutes * 60;
      _currentPhaseIndex = 0;
      _phaseSecondsLeft = _selectedTechnique.phases[0].durationSeconds;
    });
    _runPhase();
    _startAudio();
    HapticFeedback.mediumImpact();
  }

  void _runPhase() {
    final phase = _selectedTechnique.phases[_currentPhaseIndex];
    _breathController.duration = Duration(seconds: phase.durationSeconds);
    if (phase.expand) {
      _breathController.forward(from: _breathController.value);
    } else {
      _breathController.reverse(from: _breathController.value);
    }
    _tickSecond();
  }

  void _tickSecond() {
    if (!mounted || !_sessionRunning || _sessionPaused) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_sessionRunning || _sessionPaused) return;
      setState(() { _totalSecondsLeft--; _phaseSecondsLeft--; });
      if (_totalSecondsLeft <= 0) { _finishSession(); return; }
      if (_phaseSecondsLeft <= 0) {
        setState(() {
          _currentPhaseIndex =
              (_currentPhaseIndex + 1) % _selectedTechnique.phases.length;
          _phaseSecondsLeft =
              _selectedTechnique.phases[_currentPhaseIndex].durationSeconds;
        });
        HapticFeedback.lightImpact();
        _runPhase();
      } else {
        _tickSecond();
      }
    });
  }

  void _togglePause() {
    HapticFeedback.lightImpact();
    setState(() => _sessionPaused = !_sessionPaused);
    if (_sessionPaused) { _breathController.stop(); _stopAudio(); }
    else { _runPhase(); _startAudio(); }
  }

  Future<void> _finishSession() async {
    await _stopAudio();
    _breathController.stop();
    HapticFeedback.heavyImpact();
    try {
      final auth = context.read<AuthProvider>();
      if (auth.userProgress != null) {
        await auth.completeLesson(
            'breathing_session_${DateTime.now().day}', _xpReward);
      }
    } catch (e) { debugPrint('XP award error: $e'); }
    if (mounted) setState(() { _sessionRunning = false; _step = _BreathingStep.completion; });
  }

  void _stopSession() {
    HapticFeedback.mediumImpact();
    _stopAudio();
    _breathController.stop();
    setState(() { _sessionRunning = false; _step = _BreathingStep.setup; });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          _buildStarfield(),
          _buildNebulaBlobs(),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                      begin: const Offset(0, 0.04), end: Offset.zero)
                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case _BreathingStep.science:   return _buildScienceCard();
      case _BreathingStep.setup:     return _buildSetupScreen();
      case _BreathingStep.session:   return _buildSessionScreen();
      case _BreathingStep.completion: return _buildCompletionScreen();
    }
  }

  // ── Backgrounds ───────────────────────────────────────────────────────────
  Widget _buildBackground() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF060612), Color(0xFF0C0C20), Color(0xFF0D0D22)],
      ),
    ),
  );

  Widget _buildStarfield() => LayoutBuilder(builder: (_, constraints) {
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;
    return Stack(
      fit: StackFit.expand,
      children: _stars.map((s) => Positioned(
        left: s.x * w, top: s.y * h,
        child: _TwinklingStar(star: s),
      )).toList(),
    );
  });

  Widget _buildNebulaBlobs() => Stack(
    fit: StackFit.expand,
    children: [
      Positioned(
        top: -100, left: -80,
        child: Container(
          width: 300, height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _selectedTechnique.color.withOpacity(0.22),
              _selectedTechnique.color.withOpacity(0.0),
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
              const Color(0xFF818CF8).withOpacity(0.15),
              const Color(0xFF818CF8).withOpacity(0.0),
            ]),
          ),
        ),
      ),
    ],
  );

  // ── Close / Back button ───────────────────────────────────────────────────
  Widget _closeButton({VoidCallback? onTap, bool isBack = false}) =>
    GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(
          isBack ? Icons.arrow_back_rounded : Icons.close_rounded,
          size: 18, color: Colors.white60),
      ),
    );

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 — SCIENCE CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScienceCard() {
    return Center(
      key: const ValueKey('science'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(alignment: Alignment.topLeft, child: _closeButton()),
            const SizedBox(height: 24),

            // Lung icon
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
                  const Color(0xFF6366F1).withOpacity(0.3),
                  const Color(0xFF6366F1).withOpacity(0.05),
                ]),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.4), width: 1.5),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 30, spreadRadius: 5,
                )],
              ),
              child: const Center(child: Text('🫁', style: TextStyle(fontSize: 48))),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05),
                    duration: 2000.ms, curve: Curves.easeInOut)
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1),
                    duration: 700.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 28),

            // Title — from JSON
            Text(
              'breathing.scienceTitle'.tr(),
              style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900,
                color: Colors.white, height: 1.2),
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // Science facts
            ..._scienceFactKeys.asMap().entries.map((e) {
              final (emoji, titleKey, descKey) = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildScienceFact(emoji, _t(titleKey), _t(descKey))
                    .animate(delay: (300 + e.key * 120).ms)
                    .fadeIn(duration: 500.ms)
                    .slideX(begin: 0.05, end: 0),
              );
            }),

            const SizedBox(height: 8),

            // Source badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.science_rounded, color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Text('breathing.scienceSource'.tr(),
                    style: const TextStyle(fontSize: 10, color: Colors.white38)),
              ]),
            ).animate(delay: 800.ms).fadeIn(duration: 500.ms),

            const SizedBox(height: 32),

            // CTA
            SizedBox(
              width: double.infinity, height: 58,
              child: FilledButton(
                onPressed: () => setState(() => _step = _BreathingStep.setup),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  elevation: 8,
                  shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('breathing.startSession'.tr(), style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ]),
              ),
            ).animate(delay: 900.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildScienceFact(String emoji, String title, String desc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(
              fontSize: 13, color: Colors.white.withOpacity(0.65), height: 1.4)),
        ])),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2 — SETUP
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSetupScreen() {
    return Column(
      key: const ValueKey('setup'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            _closeButton(
                onTap: () => setState(() => _step = _BreathingStep.science),
                isBack: true),
            const SizedBox(width: 14),
            Text('breathing.configTitle'.tr(), style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Technique label
              Text('breathing.techniqueLabel'.tr(), style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white60)),
              const SizedBox(height: 10),
              ..._techniques.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildTechniqueCard(t),
              )),

              const SizedBox(height: 20),

              // Duration label
              Text('breathing.durationLabel'.tr(), style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white60)),
              const SizedBox(height: 10),
              Row(children: [1, 3, 5].map((min) {
                final isSelected = _selectedMinutes == min;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: min < 5 ? 10 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMinutes = min),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedTechnique.color.withOpacity(0.2)
                              : Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? _selectedTechnique.color
                                : Colors.white.withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(child: Text('$min min', style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: isSelected
                              ? _selectedTechnique.color : Colors.white60,
                        ))),
                      ),
                    ),
                  ),
                );
              }).toList()),

              const SizedBox(height: 20),

              // Sound label
              Text('breathing.soundLabel'.tr(), style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white60)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _ambientSounds.map((s) {
                    final isSelected = _selectedSound.id == s.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSound = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _selectedTechnique.color.withOpacity(0.2)
                                : Colors.white.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? _selectedTechnique.color
                                  : Colors.white.withOpacity(0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(s.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(_soundLabel(s), style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? _selectedTechnique.color : Colors.white60,
                            )),
                          ]),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),

              // Start button
              SizedBox(
                width: double.infinity, height: 58,
                child: FilledButton(
                  onPressed: () {
                    setState(() => _step = _BreathingStep.session);
                    Future.delayed(
                        const Duration(milliseconds: 300), _startSession);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _selectedTechnique.color,
                    elevation: 8,
                    shadowColor: _selectedTechnique.color.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'breathing.startButton'.tr(
                          namedArgs: {'min': '$_selectedMinutes'}),
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTechniqueCard(_BreathingTechnique t) {
    final isSelected = _selectedTechnique.id == t.id;
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedTechnique = t); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? t.color.withOpacity(0.15) : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? t.color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(
            color: t.color.withOpacity(0.2), blurRadius: 12,
            offset: const Offset(0, 4),
          )] : null,
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: t.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(t.emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_techniqueName(t), style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: t.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_t(t.descriptionKey), style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: t.color)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(_techniqueBenefit(t), style: TextStyle(
                fontSize: 12, color: Colors.white.withOpacity(0.55), height: 1.3)),
          ])),
          if (isSelected)
            Icon(Icons.check_circle_rounded, color: t.color, size: 22),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 3 — SESSION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSessionScreen() {
    final phase = _sessionRunning
        ? _selectedTechnique.phases[_currentPhaseIndex]
        : _selectedTechnique.phases[0];

    return Column(
      key: const ValueKey('session'),
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            _closeButton(onTap: _stopSession),
            const Spacer(),
            Text(_formatTime(_totalSecondsLeft), style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            const Spacer(),
            if (_selectedSound.url.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_selectedSound.emoji,
                    style: const TextStyle(fontSize: 16)))
            else
              const SizedBox(width: 36),
          ]),
        ),

        const Spacer(),

        Text(_techniqueName(_selectedTechnique), style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: _selectedTechnique.color, letterSpacing: 1)),
        const SizedBox(height: 8),

        // Breathing circle
        AnimatedBuilder(
          animation: _breathController,
          builder: (_, __) {
            final scale = 0.65 + _breathController.value * 0.35;
            final glowOpacity = 0.2 + _breathController.value * 0.4;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280 * scale + 40, height: 280 * scale + 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _selectedTechnique.color.withOpacity(glowOpacity * 0.3)),
                  ),
                ),
                Container(
                  width: 280 * scale + 20, height: 280 * scale + 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: _selectedTechnique.color.withOpacity(glowOpacity * 0.5),
                        width: 1.5),
                  ),
                ),
                Container(
                  width: 280 * scale, height: 280 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _selectedTechnique.color.withOpacity(0.35),
                      _selectedTechnique.color.withOpacity(0.08),
                    ]),
                    border: Border.all(
                        color: _selectedTechnique.color.withOpacity(0.6), width: 2),
                    boxShadow: [BoxShadow(
                      color: _selectedTechnique.color.withOpacity(glowOpacity),
                      blurRadius: 40, spreadRadius: 5,
                    )],
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(
                      _sessionRunning && !_sessionPaused
                          ? _phaseLabel(phase)
                          : (_sessionPaused
                              ? 'breathing.paused'.tr()
                              : '...'),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sessionRunning ? '$_phaseSecondsLeft' : '',
                      style: TextStyle(
                          fontSize: 48, fontWeight: FontWeight.w900,
                          color: _selectedTechnique.color, height: 1),
                    ),
                  ]),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 40),

        // Phase indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _selectedTechnique.phases.asMap().entries.map((e) {
            final isActive = e.key == _currentPhaseIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 24 : 8, height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? _selectedTechnique.color
                    : _selectedTechnique.color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Phase labels row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _selectedTechnique.phases.asMap().entries.map((e) {
            final isActive = e.key == _currentPhaseIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '${_phaseLabel(e.value)} ${e.value.durationSeconds}s',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? Colors.white : Colors.white38,
                ),
              ),
            );
          }).toList(),
        ),

        const Spacer(),

        // Controls
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
          child: Row(children: [
            // Stop
            GestureDetector(
              onTap: _stopSession,
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.stop_rounded, color: Colors.white60, size: 26),
              ),
            ),
            const Spacer(),
            // Pause/Resume
            GestureDetector(
              onTap: _sessionRunning ? _togglePause : null,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _selectedTechnique.color,
                    _selectedTechnique.color.withOpacity(0.7),
                  ]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(
                    color: _selectedTechnique.color.withOpacity(0.4),
                    blurRadius: 20, spreadRadius: 2,
                  )],
                ),
                child: Icon(
                  _sessionPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: Colors.white, size: 36),
              ),
            ),
            const Spacer(),
            // Finish early
            GestureDetector(
              onTap: _finishSession,
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white60, size: 26),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 4 — COMPLETION
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCompletionScreen() {
    // Pick motivational phrase based on second to avoid always showing same one
    final phraseKey =
        _motivationalKeys[DateTime.now().second % _motivationalKeys.length];

    return Center(
      key: const ValueKey('completion'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [
                  _selectedTechnique.color.withOpacity(0.3),
                  _selectedTechnique.color.withOpacity(0.05),
                ]),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _selectedTechnique.color.withOpacity(0.4), width: 2),
                boxShadow: [BoxShadow(
                  color: _selectedTechnique.color.withOpacity(0.3),
                  blurRadius: 30, spreadRadius: 5,
                )],
              ),
              child: const Center(child: Text('✨', style: TextStyle(fontSize: 52))),
            )
                .animate()
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1),
                    duration: 600.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            Text('breathing.sessionComplete'.tr(), style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))
                .animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 8),
            Text(
              'breathing.sessionSubtitle'.tr(namedArgs: {
                'min': '$_selectedMinutes',
                'technique': _techniqueName(_selectedTechnique),
              }),
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 28),

            // XP card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  _selectedTechnique.color.withOpacity(0.22),
                  const Color(0xFFFBBF24).withOpacity(0.1),
                ]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _selectedTechnique.color.withOpacity(0.35)),
                boxShadow: [BoxShadow(
                  color: _selectedTechnique.color.withOpacity(0.2),
                  blurRadius: 24, spreadRadius: 2,
                )],
              ),
              child: Column(children: [
                const Text('⚡', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 6),
                Text('+$_xpReward XP', style: TextStyle(
                    fontSize: 34, fontWeight: FontWeight.w900,
                    color: _selectedTechnique.color)),
                Text('breathing.xpLabel'.tr(),
                    style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
              ]),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1),
                    curve: Curves.easeOutBack),

            const SizedBox(height: 20),

            // Motivational phrase
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text('"${_t(phraseKey)}"',
                style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic,
                    color: Colors.white.withOpacity(0.8), height: 1.5),
                textAlign: TextAlign.center),
            ).animate(delay: 600.ms).fadeIn(duration: 500.ms),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity, height: 58,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedTechnique.color,
                  elevation: 8,
                  shadowColor: _selectedTechnique.color.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: Text('breathing.backHome'.tr(), style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ).animate(delay: 700.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => setState(() {
                _step = _BreathingStep.setup;
                _sessionRunning = false;
              }),
              child: Text('breathing.anotherSession'.tr(),
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
            ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

// ─── Star widgets ─────────────────────────────────────────────────────────────
class _StarData {
  final double x, y, size, opacity;
  final int delayMs, durationMs;
  const _StarData({
    required this.x, required this.y, required this.size,
    required this.opacity, required this.delayMs, required this.durationMs,
  });
}

class _TwinklingStar extends StatefulWidget {
  final _StarData star;
  const _TwinklingStar({required this.star});
  @override
  State<_TwinklingStar> createState() => _TwinklingStarState();
}

class _TwinklingStarState extends State<_TwinklingStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: widget.star.durationMs));
    Future.delayed(Duration(milliseconds: widget.star.delayMs), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween<double>(begin: 0.05, end: widget.star.opacity)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Opacity(
      opacity: _anim.value.clamp(0.0, 1.0),
      child: Container(
        width: widget.star.size, height: widget.star.size,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          boxShadow: widget.star.size > 1.6 ? [
            BoxShadow(color: Colors.white.withOpacity(_anim.value * 0.8),
                blurRadius: widget.star.size * 2),
            BoxShadow(color: const Color(0xFF818CF8).withOpacity(_anim.value * 0.5),
                blurRadius: widget.star.size * 4),
          ] : null,
        ),
      ),
    ),
  );
}