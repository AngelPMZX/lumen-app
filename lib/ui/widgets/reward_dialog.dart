import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/models/lumi.dart';
import '../../data/models/reward_service.dart';
import '../../domain/providers/garden_provider.dart';
import '../../domain/services/motion_service.dart';
import '../../domain/services/sound_service.dart';
import '../screens/garden/garden_defs.dart';
import '../screens/garden/widgets/garden_common.dart';
import 'journal/journal_style.dart';
import 'lumi/lumi_avatar.dart';
import 'seed_icon.dart';

// ═════════════════════════════════════════════════════════════════════════════
// RewardDialog — muestra la recompensa ganada (semillas o item)
// ═════════════════════════════════════════════════════════════════════════════

class RewardDialog extends StatefulWidget {
  final RewardResult reward;
  final VoidCallback? onDismiss;

  const RewardDialog({super.key, required this.reward, this.onDismiss});

  /// Muestra el dialog de recompensa
  static Future<void> show(BuildContext context, RewardResult reward) async {
    HapticFeedback.heavyImpact();
    SoundService.instance.play(Sfx.reward, volume: 0.65);
    final item = reward.isItem ? reward.item : null;
    if (item != null) {
      Future.delayed(const Duration(milliseconds: 350), () => SoundService.instance.shine(RarityStyle.shine(item.rarity), volume: 0.45));
    }
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => RewardDialog(
        reward: reward,
        onDismiss: () {
          context.read<GardenProvider>().consumePendingReward();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _particleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(widget.reward.isItem ? 20 : 28, (_) => _Particle(math.Random(), widget.reward));
    if (!MotionService.instance.reducedNow) _particleCtrl.forward();
  }

  @override
  void dispose() {
    _particleCtrl.dispose();
    super.dispose();
  }

  Color get _accent {
    final item = widget.reward.item;
    return widget.reward.isItem && item != null ? RarityStyle.color(item.rarity) : GardenPalette.green;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = GardenPalette(isDark);
    final reward = widget.reward;
    final item = reward.isItem ? reward.item : null;
    final reduced = MotionService.reduced(context);
    final glow = item?.auraColor ?? const Color(0xFFFBBF24);

    final message = item != null
        ? 'garden.reward.itemMessage'.tr(namedArgs: {'name': item.nameKey.tr()})
        : 'garden.reward.seedsMessage'.tr(namedArgs: {'count': '${reward.seeds}'});

    // Tocar en cualquier parte continúa, como dice el botón
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (!reduced)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _particleCtrl,
                    builder: (_, _) => CustomPaint(
                      painter: _ParticlePainter(particles: _particles, progress: _particleCtrl.value),
                    ),
                  ),
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child:
                  Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                        decoration: BoxDecoration(
                          color: p.sheet,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: _accent.withValues(alpha: 0.35), width: 1.5),
                          boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.3), blurRadius: 36, spreadRadius: 2)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 176,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  LightRays(color: glow, size: 230),
                                  (item != null ? GardenItemImage(item: item, size: 112, pulse: true) : const SeedIcon(size: 96, animated: true))
                                      .animate()
                                      .scale(begin: const Offset(0.3, 0.3), end: const Offset(1, 1), duration: 700.ms, curve: Curves.elasticOut)
                                      .fadeIn(duration: 250.ms),
                                  if (!reduced) SparkleBurst(color: glow, size: 220, seed: reward.hashCode),
                                  Positioned(
                                    left: -4,
                                    bottom: 8,
                                    child: const LumiAvatar(
                                      mood: LumiMood.excited,
                                      size: 56,
                                    ).animate().fadeIn(delay: 400.ms, duration: 300.ms).slideX(begin: -0.4, end: 0, curve: Curves.easeOutCubic),
                                  ),
                                ],
                              ),
                            ),
                            if (item != null) ...[RarityChip(rarity: item.rarity).animate().fadeIn(delay: 150.ms, duration: 300.ms), const SizedBox(height: 8)],
                            Semantics(
                              header: true,
                              child: Text(
                                reward.titleKey.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: p.ink),
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                            const SizedBox(height: 6),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14.5, height: 1.45, color: p.inkSoft),
                            ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
                            if (item == null) ...[
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: reward.seeds.toDouble()),
                                    duration: reduced ? Duration.zero : const Duration(milliseconds: 900),
                                    curve: Curves.easeOutCubic,
                                    builder: (_, v, _) => Text(
                                      '+${v.round()}',
                                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF16A34A), height: 1),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('garden.seeds'.tr(), style: JournalStyle.hand(const TextStyle(fontSize: 22, color: GardenPalette.green))),
                                ],
                              ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
                            ],
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: widget.onDismiss,
                              style: FilledButton.styleFrom(
                                backgroundColor: item != null ? _accent : GardenPalette.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              child: Text('garden.reward.tapToContinue'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            ).animate().fadeIn(delay: 550.ms, duration: 350.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(item != null ? Icons.backpack_rounded : Icons.local_florist_rounded, size: 14, color: p.inkSoft),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    item != null ? 'garden.reward.inBackpack'.tr() : 'garden.subtitle'.tr(),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: p.inkSoft),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 750.ms, duration: 350.ms),
                          ],
                        ),
                      )
                      .animate()
                      .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1), duration: 450.ms, curve: Curves.easeOutCubic)
                      .fadeIn(duration: 250.ms),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Partículas que caen
// ═════════════════════════════════════════════════════════════════════════════

class _Particle {
  final double x;
  final double startY;
  final double size;
  final double speed;
  final double wobble;
  final double wobbleSpeed;
  final double rotation;
  final String emoji;

  static const _seedEmojis = ['✨', '🌟', '⭐', '💫', '🌱'];
  static const _itemEmojis = ['✨', '💎', '🌟', '⭐', '🎁'];

  _Particle(math.Random rng, RewardResult reward)
    : x = rng.nextDouble(),
      startY = -0.05 - rng.nextDouble() * 0.2,
      size = 12 + rng.nextDouble() * 14,
      speed = 0.3 + rng.nextDouble() * 0.6,
      wobble = 0.03 + rng.nextDouble() * 0.04,
      wobbleSpeed = 2 + rng.nextDouble() * 3,
      rotation = rng.nextDouble() * math.pi * 2,
      emoji = reward.isItem ? _itemEmojis[rng.nextInt(_itemEmojis.length)] : _seedEmojis[rng.nextInt(_seedEmojis.length)];
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    for (final p in particles) {
      final y = p.startY + progress * p.speed * 1.8;
      if (y > 1.1) continue;
      final x = p.x + math.sin(progress * p.wobbleSpeed * math.pi * 2) * p.wobble;
      final opacity = progress < 0.15 ? progress / 0.15 : (progress > 0.65 ? (1.0 - progress) / 0.35 : 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: p.emoji,
          style: TextStyle(fontSize: p.size * opacity.clamp(0.3, 1.0)),
        ),
        textScaler: TextScaler.noScaling,
        textDirection: ui.TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(p.rotation + progress * 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.progress != progress;
}
