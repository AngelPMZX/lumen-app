import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/lumi.dart';
import '../../../data/models/reward_service.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/motion_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/discovery_dialog.dart';
import '../../widgets/journal/journal_style.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import '../../widgets/reward_dialog.dart';
import 'breathing_data.dart';
import 'widgets/breath_orb.dart';
import 'widgets/breathing_setup.dart';
import 'widgets/breathing_sky.dart';

enum _Step { science, setup, session, completion }

/// Respiración guiada: eliges técnica, minutos y ambiente, y un orbe te guía
/// fase por fase con señales de sonido. Lumi respira contigo.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> with TickerProviderStateMixin {
  static const _prefScienceSeen = 'breathing_science_seen';
  static const int _xpReward = 15;

  _Step _step = _Step.setup;
  BreathingTechnique _technique = kTechniques.first;
  int _minutes = 3;
  AmbientChoice _sound = kAmbientChoices.first;
  bool _cuesEnabled = true;

  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(seconds: 4));

  Timer? _timer;
  BreathingSession _session = BreathingSession.minutes(kTechniques.first, 3);
  int _elapsed = 0;
  int _phaseIndex = -1;
  bool _paused = false;
  bool _finishing = false;
  bool _rewardedToday = false;
  String? _playingAmbientId;

  Color get _color => _technique.color;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      DiscoveryDialog.maybeShow(context, DiscoveryFeature.breathing);
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        // La primera vez explicamos por qué respirar; luego se entra directo
        if (!(prefs.getBool(_prefScienceSeen) ?? false)) {
          setState(() => _step = _Step.science);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breath.dispose();
    SoundService.instance.stopAmbient(fadeOut: const Duration(milliseconds: 600));
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Ambiente
  // ═══════════════════════════════════════════════════════════════════════════

  /// Escucha previa al elegir: el mismo bucle sigue sonando en la sesión.
  Future<void> _previewAmbient(AmbientChoice choice) async {
    setState(() {
      _sound = choice;
      _playingAmbientId = choice.ambient == null ? null : choice.id;
    });
    SoundService.instance.play(choice.ambient == null ? Sfx.toggleOff : Sfx.toggleOn, volume: 0.35);
    final ambient = choice.ambient;
    if (ambient == null) {
      await SoundService.instance.stopAmbient(fadeOut: const Duration(milliseconds: 400));
    } else {
      await SoundService.instance.startAmbient(ambient, volume: 0.3, fadeIn: const Duration(milliseconds: 600));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sesión
  // ═══════════════════════════════════════════════════════════════════════════

  void _startSession() {
    _session = BreathingSession.minutes(_technique, _minutes);
    setState(() {
      _elapsed = 0;
      _phaseIndex = -1;
      _paused = false;
      _finishing = false;
      _step = _Step.session;
    });
    HapticFeedback.mediumImpact();
    final ambient = _sound.ambient;
    if (ambient != null) {
      SoundService.instance.startAmbient(ambient, volume: 0.5);
    }
    _syncPhase(force: true);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused) return;
      setState(() => _elapsed++);
      if (_session.isOver(_elapsed)) {
        _finishSession();
      } else {
        _syncPhase();
      }
    });
  }

  /// Pone el orbe donde toca. [force] al empezar o al reanudar.
  void _syncPhase({bool force = false}) {
    final pos = _session.positionAt(_elapsed);
    final changed = pos.phaseIndex != _phaseIndex;
    if (!changed && !force) return;
    if (changed) {
      _phaseIndex = pos.phaseIndex;
      if (!force) HapticFeedback.lightImpact();
      if (_cuesEnabled) {
        SoundService.instance.cue(pos.phase.cue, volume: pos.phase.move == BreathMove.hold ? 0.45 : 0.6);
      }
    }
    // Al reanudar, el orbe recorre solo lo que falta de la fase
    _breath.duration = Duration(seconds: pos.secondsLeft.clamp(1, pos.phase.seconds));
    if (pos.phase.expanded) {
      _breath.forward();
    } else {
      _breath.reverse();
    }
  }

  void _togglePause() {
    HapticFeedback.lightImpact();
    setState(() => _paused = !_paused);
    if (_paused) {
      _breath.stop();
      SoundService.instance.pauseAmbient();
    } else {
      SoundService.instance.resumeAmbient();
      _syncPhase(force: true);
    }
  }

  Future<void> _finishSession() async {
    if (_finishing) return;
    _finishing = true;
    _timer?.cancel();
    _breath.stop();
    final garden = context.read<GardenProvider>();
    final auth = context.read<AuthProvider>();
    HapticFeedback.heavyImpact();
    if (_cuesEnabled) SoundService.instance.cue(BreathCue.bowl, volume: 0.8);
    AnalyticsService.instance.breathingComplete(_technique.id, _minutes);
    await SoundService.instance.stopAmbient(fadeOut: const Duration(milliseconds: 1500));
    bool rewarded = false;
    try {
      rewarded = await auth.completeBreathingSession(_xpReward, garden: garden);
    } catch (e) {
      debugPrint('Breathing reward error: $e');
    }
    if (!mounted) return;
    setState(() {
      _rewardedToday = rewarded;
      _playingAmbientId = null;
      _step = _Step.completion;
    });
    if (!rewarded) return;
    final reward = await garden.grantReward(RewardSource.breathing);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) await RewardDialog.show(context, reward);
  }

  void _stopSession() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    _breath.stop();
    _breath.value = 0;
    SoundService.instance.stopAmbient(fadeOut: const Duration(milliseconds: 600));
    setState(() {
      _paused = false;
      _playingAmbientId = null;
      _step = _Step.setup;
    });
  }

  Future<void> _markScienceSeen() async {
    setState(() => _step = _Step.setup);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefScienceSeen, true);
    } catch (_) {}
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: _step != _Step.session,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _stopSession();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF05060F),
          body: Stack(
            fit: StackFit.expand,
            children: [
              BreathingSky(tint: _color, breath: _step == _Step.session ? _breath : null),
              SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                          .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                      child: child,
                    ),
                  ),
                  child: switch (_step) {
                    _Step.science => _buildScience(),
                    _Step.setup => _buildSetup(),
                    _Step.session => _buildSession(),
                    _Step.completion => _buildCompletion(),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Por qué respirar ──────────────────────────────────────────────────────

  Widget _buildScience() {
    return SingleChildScrollView(
      key: const ValueKey('science'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreathIconButton(icon: Icons.close_rounded, label: 'common.close'.tr(), onTap: () => Navigator.pop(context)),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_color.withValues(alpha: 0.35), _color.withValues(alpha: 0.04)]),
                border: Border.all(color: _color.withValues(alpha: 0.4), width: 1.5),
              ),
              child: const Center(child: Text('🫁', style: TextStyle(fontSize: 44))),
            )
                .animate(onPlay: MotionService.loop(context, reverse: true))
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.06, 1.06), duration: 2400.ms, curve: Curves.easeInOut),
          ),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(
              'breathing.scienceTitle'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 18),
          for (final (i, (emoji, titleKey, descKey)) in kScienceFacts.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titleKey.tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 3),
                          Text(descKey.tr(), style: TextStyle(fontSize: 12.5, height: 1.4, color: Colors.white.withValues(alpha: 0.62))),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (250 + i * 110).ms, duration: 400.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
            ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'breathing.scienceSource'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, color: Colors.white38),
            ),
          ),
          const SizedBox(height: 22),
          _PrimaryButton(
            color: _color,
            label: 'breathing.startSession'.tr(),
            icon: Icons.arrow_forward_rounded,
            onTap: _markScienceSeen,
          ).animate().fadeIn(delay: 700.ms, duration: 350.ms),
        ],
      ),
    );
  }

  // ── Preparar la sesión ────────────────────────────────────────────────────

  Widget _buildSetup() {
    return Column(
      key: const ValueKey('setup'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Row(
            children: [
              BreathIconButton(icon: Icons.close_rounded, label: 'common.close'.tr(), onTap: () => Navigator.pop(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'breathing.configTitle'.tr(),
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
              ),
              BreathIconButton(
                icon: Icons.help_outline_rounded,
                label: 'breathing.scienceTitle'.tr(),
                onTap: () => setState(() => _step = _Step.science),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  LumiAvatar(mood: LumiMood.calm, size: 54, onTap: () {}),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                        ),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Text(
                        'breathing.lumiSetup'.tr(),
                        style: const TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 14),
              BreathSectionTitle(kicker: 'breathing.techniqueKicker'.tr(), title: 'breathing.techniqueLabel'.tr(), color: _color),
              const SizedBox(height: 10),
              for (final (i, t) in kTechniques.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TechniqueCard(
                    technique: t,
                    selected: t.id == _technique.id,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      SoundService.instance.play(Sfx.tapNode, volume: 0.35);
                      setState(() => _technique = t);
                    },
                  ).animate().fadeIn(delay: (80 + i * 70).ms, duration: 350.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                ),
              const SizedBox(height: 14),
              BreathSectionTitle(kicker: 'breathing.durationKicker'.tr(), title: 'breathing.durationLabel'.tr(), color: _color),
              const SizedBox(height: 10),
              DurationPicker(
                options: const [1, 3, 5, 10],
                selected: _minutes,
                color: _color,
                onSelect: (m) {
                  HapticFeedback.selectionClick();
                  SoundService.instance.play(Sfx.tick, volume: 0.4);
                  setState(() => _minutes = m);
                },
              ),
              const SizedBox(height: 18),
              BreathSectionTitle(
                kicker: 'breathing.soundKicker'.tr(),
                title: 'breathing.soundLabel'.tr(),
                color: _color,
              ),
              const SizedBox(height: 10),
              AmbientPicker(
                selectedId: _sound.id,
                playingId: _playingAmbientId,
                color: _color,
                onSelect: _previewAmbient,
              ),
              const SizedBox(height: 14),
              CueToggle(
                value: _cuesEnabled,
                color: _color,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  setState(() => _cuesEnabled = v);
                  if (v) SoundService.instance.cue(BreathCue.inhale, volume: 0.5);
                },
              ),
              const SizedBox(height: 26),
              _PrimaryButton(
                color: _color,
                icon: Icons.play_arrow_rounded,
                label: 'breathing.startButton'.tr(namedArgs: {'min': '$_minutes'}),
                onTap: _startSession,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'breathing.cyclesHint'.tr(namedArgs: {'count': '${BreathingSession.minutes(_technique, _minutes).plannedCycles}'}),
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sesión ────────────────────────────────────────────────────────────────

  Widget _buildSession() {
    final pos = _session.positionAt(_elapsed);
    final left = _session.secondsLeftAt(_elapsed);

    return Column(
      key: const ValueKey('session'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Row(
            children: [
              BreathIconButton(icon: Icons.close_rounded, label: 'common.close'.tr(), onTap: _stopSession),
              const Spacer(),
              Column(
                children: [
                  Text(
                    _technique.nameKey.tr(),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color.lerp(_color, Colors.white, 0.45)),
                  ),
                  Semantics(
                    label: 'breathing.timeLeft'.tr(namedArgs: {'time': _formatTime(left)}),
                    excludeSemantics: true,
                    child: Text(
                      _formatTime(left),
                      style: const TextStyle(fontSize: 26, height: 1.1, fontWeight: FontWeight.w900, color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (_sound.ambient != null)
                BreathIconButton(
                  icon: Icons.graphic_eq_rounded,
                  label: _sound.labelKey.tr(),
                  onTap: () {},
                )
              else
                const SizedBox(width: 38),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Avance de la sesión
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                Container(height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(3))),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.linear,
                  width: c.maxWidth * _session.progressAt(_elapsed),
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color.lerp(_color, Colors.white, 0.5)!, _color]),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        BreathOrb(
          breath: _breath,
          color: _color,
          position: pos,
          paused: _paused,
          size: 280,
          caption: 'breathing.cycleOf'.tr(namedArgs: {'cycle': '${pos.cycle}', 'total': '${_session.plannedCycles}'}),
        ),
        const SizedBox(height: 16),
        // Lumi respira contigo
        AnimatedBuilder(
          animation: _breath,
          builder: (_, child) => Transform.scale(scale: 0.92 + _breath.value * 0.16, child: child),
          child: const LumiAvatar(mood: LumiMood.calm, size: 60),
        ),
        const SizedBox(height: 6),
        Text(
          'breathing.lumiBreathes'.tr(),
          style: JournalStyle.hand(TextStyle(fontSize: 17, color: Colors.white.withValues(alpha: 0.65))),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(36, 0, 36, 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundControl(
                icon: Icons.stop_rounded,
                label: 'breathing.stop'.tr(),
                onTap: _stopSession,
              ),
              Semantics(
                button: true,
                label: _paused ? 'breathing.resume'.tr() : 'breathing.pause'.tr(),
                onTap: _togglePause,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: _togglePause,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color.lerp(_color, Colors.white, 0.2)!, _color]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.45), blurRadius: 22, spreadRadius: 2)],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        key: ValueKey(_paused),
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              _RoundControl(
                icon: Icons.check_rounded,
                label: 'breathing.finishNow'.tr(),
                onTap: _finishSession,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Fin de la sesión ──────────────────────────────────────────────────────

  Widget _buildCompletion() {
    final phraseKey = kMotivationalKeys[DateTime.now().second % kMotivationalKeys.length];
    final cycles = _session.cyclesDoneAt(_elapsed);
    final minutesDone = (_elapsed / 60).ceil().clamp(1, _minutes);

    return SingleChildScrollView(
      key: const ValueKey('completion'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [_color.withValues(alpha: 0.4), _color.withValues(alpha: 0.03)]),
                    border: Border.all(color: _color.withValues(alpha: 0.35), width: 2),
                  ),
                  child: const Center(child: Text('🫁', style: TextStyle(fontSize: 54))),
                )
                    .animate(onPlay: MotionService.loop(context, reverse: true))
                    .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.07, 1.07), duration: 2600.ms, curve: Curves.easeInOut),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: const LumiAvatar(mood: LumiMood.proud, size: 54)
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 350.ms)
                      .slideX(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              'breathing.sessionComplete'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
          const SizedBox(height: 14),
          Row(
            children: [
              _ResultTile(emoji: '⏱', value: '$minutesDone', label: 'breathing.minShort'.tr(), color: _color),
              const SizedBox(width: 10),
              _ResultTile(emoji: '🔄', value: '$cycles', label: 'breathing.cyclesLabel'.tr(), color: _color),
              const SizedBox(width: 10),
              _ResultTile(emoji: _technique.emoji, value: '', label: _technique.nameKey.tr(), color: _color),
            ],
          ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_color.withValues(alpha: 0.25), const Color(0xFFFBBF24).withValues(alpha: 0.12)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _color.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Text(_rewardedToday ? '⚡' : '✅', style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 4),
                Text(
                  _rewardedToday ? '+$_xpReward XP' : 'breathing.rewardClaimed'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _rewardedToday ? 32 : 19,
                    fontWeight: FontWeight.w900,
                    color: Color.lerp(_color, Colors.white, 0.4),
                  ),
                ),
                Text(
                  _rewardedToday ? 'breathing.xpLabel'.tr() : 'breathing.rewardClaimedHint'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), curve: Curves.easeOutCubic),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Text(
              phraseKey.tr(),
              textAlign: TextAlign.center,
              style: JournalStyle.hand(TextStyle(fontSize: 21, height: 1.3, color: Colors.white.withValues(alpha: 0.9))),
            ),
          ).animate().fadeIn(delay: 550.ms, duration: 400.ms),
          const SizedBox(height: 24),
          _PrimaryButton(color: _color, label: 'breathing.backHome'.tr(), onTap: () => Navigator.pop(context))
              .animate()
              .fadeIn(delay: 650.ms, duration: 350.ms),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              setState(() {
                _step = _Step.setup;
                _elapsed = 0;
                _phaseIndex = -1;
                _finishing = false;
              });
              _breath.value = 0;
            },
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              'breathing.anotherSession'.tr(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ).animate().fadeIn(delay: 750.ms, duration: 350.ms),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final Color color;
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const _PrimaryButton({required this.color, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          elevation: 8,
          shadowColor: color.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: 22), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoundControl({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: Colors.white70, size: 26),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _ResultTile({required this.emoji, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              if (value.isNotEmpty)
                Text(value, style: const TextStyle(fontSize: 20, height: 1.2, fontWeight: FontWeight.w900, color: Colors.white)),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
