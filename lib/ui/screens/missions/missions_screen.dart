import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../data/models/lumi.dart';
import '../../../data/models/reward_service.dart';
import '../../../data/models/weekly_missions.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/mission_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import '../../widgets/reward_dialog.dart';
import '../../widgets/treasure_chest.dart';
import '../../../domain/services/app_review_service.dart';
import '../../../domain/services/motion_service.dart';

/// Apariencia de cada tipo de misión.
class MissionStyle {
  final IconData icon;
  final Color color;
  const MissionStyle(this.icon, this.color);

  static MissionStyle of(MissionType t) => switch (t) {
        MissionType.checkIns => const MissionStyle(Icons.emoji_emotions_rounded, Color(0xFF10B981)),
        MissionType.lessons => const MissionStyle(Icons.menu_book_rounded, Color(0xFF6366F1)),
        MissionType.breathing => const MissionStyle(Icons.air_rounded, Color(0xFF0EA5E9)),
        MissionType.diary => const MissionStyle(Icons.edit_note_rounded, Color(0xFFF59E0B)),
        MissionType.review => const MissionStyle(Icons.style_rounded, Color(0xFFEC4899)),
        MissionType.habits => const MissionStyle(Icons.track_changes_rounded, Color(0xFF14B8A6)),
        MissionType.commitment => const MissionStyle(Icons.handshake_rounded, Color(0xFFF97316)),
      };
}

/// Misiones de la semana: 3 misiones y un cofre que se abre al reclamarlas.
class MissionsScreen extends StatefulWidget {
  final bool hasHabits;
  final bool reviewAvailable;

  /// Solo para pruebas: muestra este estado sin Firestore.
  @visibleForTesting
  final MissionsState? previewState;

  const MissionsScreen({
    super.key,
    required this.hasHabits,
    required this.reviewAvailable,
    this.previewState,
  });

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _rays;
  late final AnimationController _open;
  late final AnimationController _shake;

  MissionsState? _state;
  bool _loading = true;
  bool _busy = false;
  MissionType? _justClaimed;
  bool _announcedReady = false;
  bool _shaking = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _rays = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeatUnlessReduced();
    _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));

    if (widget.previewState != null) {
      _state = widget.previewState;
      _loading = false;
      if (_state!.chestClaimed) _open.value = 1;
      _maybeStartShake();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _rays.dispose();
    _open.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    if (uid == null) return;
    final state = await MissionService.instance.load(
      uid: uid,
      hasHabits: widget.hasHabits,
      reviewAvailable: widget.reviewAvailable,
    );
    if (!mounted) return;
    setState(() {
      _state = state;
      _loading = false;
      if (state.chestClaimed) _open.value = 1;
    });
    _maybeStartShake();
  }

  /// Con las 3 misiones reclamadas, el cofre tiembla cada tanto para invitar
  /// a abrirlo.
  void _maybeStartShake() {
    final state = _state;
    if (state == null || !state.chestReady) return;
    if (!_announcedReady) {
      _announcedReady = true;
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && _state?.chestReady == true) SoundService.instance.play(Sfx.chestShake, volume: 0.6);
      });
    }
    // Con movimiento reducido el cofre listo brilla, pero no tiembla.
    if (_shaking || MotionService.instance.reducedNow) return; // un solo bucle aunque se reclamen varias seguidas
    _shaking = true;
    Future<void> loop() async {
      while (mounted && _state?.chestReady == true) {
        await _shake.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 1600));
      }
      _shaking = false;
    }

    loop();
  }

  Future<void> _claim(Mission mission) async {
    final state = _state;
    if (_busy || state == null || !mission.claimable) return;
    setState(() => _busy = true);
    HapticFeedback.mediumImpact();

    var ok = widget.previewState != null;
    if (!ok) {
      final uid = context.read<AuthProvider>().firebaseUser!.uid;
      final garden = context.read<GardenProvider>();
      ok = await MissionService.instance.claim(uid, state.weekKey, mission.type);
      if (ok) {
        await garden.addSeeds(mission.def.seeds, source: 'mission');
        AnalyticsService.instance.missionClaimed(mission.type.name);
      }
    }
    if (!mounted) return;
    if (ok) SoundService.instance.play(Sfx.missionClaim, volume: 0.7);

    setState(() {
      _busy = false;
      if (ok) {
        _justClaimed = mission.type;
        _state = MissionsState(
          weekKey: state.weekKey,
          chestClaimed: state.chestClaimed,
          missions: [
            for (final m in state.missions)
              m.type == mission.type ? Mission(def: m.def, progress: m.progress, claimed: true) : m,
          ],
        );
      }
    });
    _maybeStartShake();
  }

  Future<void> _openChest() async {
    final state = _state;
    if (_busy || state == null || !state.chestReady) return;
    setState(() => _busy = true);
    HapticFeedback.heavyImpact();

    final garden = context.read<GardenProvider>();
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
    final ok = uid != null && await MissionService.instance.openChest(uid, state.weekKey);
    if (!mounted) return;
    if (!ok) {
      setState(() => _busy = false);
      return;
    }

    SoundService.instance.play(Sfx.chestOpen, volume: 0.75);
    AnalyticsService.instance.missionChestOpened();
    setState(() => _state = MissionsState(weekKey: state.weekKey, missions: state.missions, chestClaimed: true));
    await _open.forward(from: 0);
    if (!MotionService.instance.reducedNow) _confetti.play();
    final reward = await garden.grantReward(RewardSource.missionChest);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _busy = false);
      final auth = context.read<AuthProvider>();
      await RewardDialog.show(context, reward);
      AppReviewService.instance.onHappyMoment('mission_chest', auth);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF14102E), Color(0xFF231B4D), Color(0xFF120F26)],
              ),
            ),
          ),
          ..._twinkles(),
          SafeArea(
            child: _loading || _state == null
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFBBF24)))
                : _buildContent(_state!),
          ),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 45,
              gravity: 0.2,
              colors: const [Color(0xFFFBBF24), Color(0xFF10B981), Color(0xFFEC4899), Color(0xFF818CF8), Colors.white],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _twinkles() {
    final rng = math.Random(7);
    return [
      for (int i = 0; i < 22; i++)
        Positioned(
          left: rng.nextDouble() * 400,
          top: rng.nextDouble() * 820,
          child: IgnorePointer(
            child: Icon(Icons.auto_awesome, size: 6 + rng.nextDouble() * 8, color: Colors.white.withValues(alpha: 0.5))
                .animate(onPlay: MotionService.loop(context, reverse: true))
                .fade(begin: 0.1, end: 0.9, duration: (1200 + rng.nextInt(1800)).ms),
          ),
        ),
    ];
  }

  Widget _buildContent(MissionsState state) {
    final days = WeeklyMissions.daysLeft(DateTime.now());
    final lumiMood = state.chestClaimed
        ? LumiMood.proud
        : state.chestReady || state.claimableCount > 0
            ? LumiMood.excited
            : LumiMood.happy;
    final lumiKey = state.chestClaimed
        ? 'missions.lumi.done'
        : state.chestReady
            ? 'missions.lumi.chest'
            : state.claimableCount > 0
                ? 'missions.lumi.claim'
                : 'missions.lumi.cheer';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context, true),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('missions.title'.tr(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 14, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        days == 1 ? 'missions.lastDay'.tr() : 'missions.daysLeft'.tr(namedArgs: {'n': '$days'}),
                        style: const TextStyle(fontSize: 13, color: Colors.white60),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            LumiAvatar(mood: lumiMood, size: 78, onTap: () {}),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  lumiKey.tr(),
                  key: ValueKey(lumiKey),
                  style: const TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w600, color: Colors.white),
                ).animate().fadeIn(duration: 350.ms),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (final (i, m) in state.missions.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _missionCard(m),
          ).animate(delay: (120 * i).ms).fadeIn(duration: 400.ms).slideX(begin: 0.08, end: 0),
        const SizedBox(height: 16),
        _chestSection(state),
      ],
    );
  }

  Widget _missionCard(Mission m) {
    final style = MissionStyle.of(m.type);
    final title = 'missions.type.${m.type.name}'.tr(namedArgs: {'n': '${m.def.target}'});
    final justClaimed = _justClaimed == m.type;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                style.color.withValues(alpha: m.claimed ? 0.12 : 0.24),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: m.claimable ? const Color(0xFFFBBF24) : style.color.withValues(alpha: 0.35),
              width: m.claimable ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: style.color.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(14)),
                    child: Icon(m.claimed ? Icons.check_rounded : style.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(alpha: m.claimed ? 0.6 : 1),
                            decoration: m.claimed ? TextDecoration.lineThrough : null,
                            decorationColor: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '🌱 +${m.def.seeds}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF86EFAC)),
                        ),
                      ],
                    ),
                  ),
                  if (m.claimed)
                    const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 26)
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.elasticOut),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: m.fraction),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation(m.completed ? const Color(0xFF10B981) : style.color),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${math.min(m.progress, m.def.target)}/${m.def.target}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white70),
                  ),
                ],
              ),
              if (m.claimable) ...[
                const SizedBox(height: 12),
                _claimButton(m),
              ],
            ],
          ),
        ),
        // Semillas que salen volando al reclamar
        if (justClaimed)
          for (int i = 0; i < 7; i++)
            Positioned(
              right: 40 + (i - 3) * 14.0,
              top: 20,
              child: IgnorePointer(
                child: const Text('🌱', style: TextStyle(fontSize: 18))
                    .animate(delay: (i * 40).ms)
                    .moveY(begin: 0, end: -70 - i * 6, duration: 800.ms, curve: Curves.easeOut)
                    .moveX(begin: 0, end: (i - 3) * 10.0, duration: 800.ms)
                    .fadeOut(delay: 400.ms, duration: 400.ms),
              ),
            ),
      ],
    );
  }

  Widget _claimButton(Mission m) {
    return GestureDetector(
      onTap: () => _claim(m),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: const Color(0xFFFBBF24).withValues(alpha: 0.4), blurRadius: 14)],
        ),
        child: Text(
          '${'missions.claim'.tr()}  🌱 +${m.def.seeds}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF3B2410)),
        ),
      )
          .animate(onPlay: MotionService.loop(context, reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 700.ms),
    );
  }

  Widget _chestSection(MissionsState state) {
    final ready = state.chestReady;
    final subtitleKey = state.chestClaimed
        ? 'missions.chestOpened'
        : ready
            ? 'missions.chestReady'
            : 'missions.chestLocked';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: ready ? 0.6 : 0.2)),
      ),
      child: Column(
        children: [
          Text('missions.chestTitle'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            subtitleKey.tr(namedArgs: {'n': '${state.claimedCount}', 'total': '${state.missions.length}'}),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white60),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: ready ? _openChest : null,
            child: AnimatedBuilder(
              animation: Listenable.merge([_rays, _open, _shake]),
              builder: (context, _) {
                final s = _shake.value;
                final dx = s == 0 ? 0.0 : math.sin(s * math.pi * 8) * 6 * (1 - s);
                final tilt = s == 0 ? 0.0 : math.sin(s * math.pi * 8) * 0.04 * (1 - s);
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: Transform.rotate(
                    angle: tilt,
                    child: TreasureChest(
                      size: 210,
                      unlocked: state.claimedCount,
                      locks: state.missions.length,
                      open: Curves.easeOutBack.transform(_open.value.clamp(0.0, 1.0)).clamp(0.0, 1.0),
                      rays: _rays.value,
                      glowing: ready,
                    ),
                  ),
                );
              },
            ),
          ),
          if (ready)
            Text('missions.tapToOpen'.tr(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFFBBF24)))
                .animate(onPlay: MotionService.loop(context, reverse: true))
                .fade(begin: 0.5, end: 1, duration: 800.ms),
        ],
      ),
    );
  }
}
