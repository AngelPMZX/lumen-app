import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/garden_item.dart';
import '../../../../data/models/garden_mechanics.dart';
import '../../../../data/models/garden_state.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../../widgets/seed_icon.dart';
import '../../routes/widgets/route_progress_ring.dart';
import '../garden_defs.dart';
import '../garden_logic.dart';
import 'garden_common.dart';

enum SlotMode { normal, planting, boosting }

/// Texto corto del tiempo que falta ("3h 20m", "12m").
String gardenTimeShort(Duration d) {
  final (h, m) = GardenRules.hoursMinutes(d);
  if (h >= 48) return 'garden.timeShortDays'.tr(namedArgs: {'days': '${h ~/ 24}', 'hours': '${h % 24}'});
  return h > 0
      ? 'garden.timeShort'.tr(namedArgs: {'hours': '$h', 'minutes': '$m'})
      : 'garden.timeShortMinutes'.tr(namedArgs: {'minutes': '$m'});
}

/// Hueco vacío mientras se elige dónde plantar: un círculo de luz que late,
/// con la semilla que se va a plantar como fantasma.
class EmptySlotTarget extends StatelessWidget {
  final double size;
  final GardenItem? itemToPlant;
  final VoidCallback onTap;

  const EmptySlotTarget({super.key, required this.size, required this.itemToPlant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const green = GardenPalette.green;
    return GardenPressable(
      onTap: onTap,
      semanticsLabel: 'garden.plantHere'.tr(),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // anillos de luz concéntricos (sin blur)
            for (final (f, a) in const [(0.95, 0.10), (0.8, 0.16), (0.64, 0.24)])
              Container(
                width: size * f,
                height: size * f * 0.62,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.elliptical(size * f, size * f * 0.62)),
                  color: green.withValues(alpha: a),
                ),
              ),
            Container(
              width: size * 0.64,
              height: size * 0.64 * 0.62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(size * 0.64, size * 0.4)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 2.5),
              ),
            )
                .animate(onPlay: MotionService.loop(context, reverse: true))
                .scale(begin: const Offset(0.92, 0.92), end: const Offset(1.08, 1.08), duration: 900.ms, curve: Curves.easeInOut),
            if (itemToPlant != null)
              Opacity(
                opacity: 0.55,
                child: GardenItemImage(item: itemToPlant!, size: size * 0.42, stage: PlantStage.seed, aura: false),
              ),
            Positioned(
              bottom: size * 0.2,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: green,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: green.withValues(alpha: 0.5), blurRadius: 8)],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 17),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(begin: const Offset(0.4, 0.4), end: const Offset(1, 1), duration: 380.ms, curve: Curves.easeOutBack).fadeIn(duration: 200.ms);
  }
}

/// Una planta en su hueco.
class PlantSlotView extends StatelessWidget {
  final PlantedItem planted;
  final GardenItem item;
  final double size;
  final SlotMode mode;
  final bool selected;

  /// Cambia cuando se acaba de plantar o de aplicar un booster (dispara el
  /// estallido de destellos).
  final int burst;
  final VoidCallback onTap;

  const PlantSlotView({
    super.key,
    required this.planted,
    required this.item,
    required this.size,
    required this.mode,
    required this.selected,
    required this.onTap,
    this.burst = 0,
  });

  @override
  Widget build(BuildContext context) {
    final stage = planted.currentStage(item);
    final adult = planted.isAdult(item);
    final ready = planted.hasPendingHarvestFor(item);
    final reduced = MotionService.reduced(context);
    final boostTarget = mode == SlotMode.boosting && !adult;
    final dimmed = (mode == SlotMode.boosting && adult) || mode == SlotMode.planting;
    final seedsPerDay = mechanicsFor(item.id).seedsPerDay;

    final status = adult
        ? (ready ? 'garden.readyToHarvest'.tr() : 'garden.harvestClaimed'.tr())
        : '${'garden.stage.${stage.name}'.tr()}, ${gardenTimeShort(planted.timeRemaining(item) ?? Duration.zero)}';

    Widget plant = adult
        ? AdultPlant(item: item, size: size, assetPath: GardenAssets.plant(item.id, stage))
        : _Swaying(
            size: size,
            child: GardenItemImage(item: item, size: size, stage: stage),
          );

    return GardenPressable(
      onTap: mode == SlotMode.planting ? null : onTap,
      selected: selected,
      semanticsLabel: '${item.nameKey.tr()}. $status',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: dimmed ? 0.55 : 1,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Sombra suave en la tierra
              Positioned(
                bottom: size * 0.1,
                child: Container(
                  width: size * 0.62,
                  height: size * 0.16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.elliptical(size * 0.62, size * 0.16)),
                    gradient: RadialGradient(
                      colors: [Colors.black.withValues(alpha: 0.22), Colors.black.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
              // Anillo de selección en la base
              if (selected || boostTarget)
                Positioned(
                  bottom: size * 0.04,
                  child: Container(
                    width: size * 0.82,
                    height: size * 0.26,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.elliptical(size * 0.82, size * 0.26)),
                      border: Border.all(
                        color: boostTarget ? GardenPalette.gold : Colors.white,
                        width: 2.5,
                      ),
                      color: (boostTarget ? GardenPalette.gold : GardenPalette.green).withValues(alpha: 0.22),
                    ),
                  )
                      .animate(onPlay: MotionService.loop(context, reverse: true))
                      .scale(begin: const Offset(0.94, 0.94), end: const Offset(1.06, 1.06), duration: 800.ms, curve: Curves.easeInOut),
                ),
              AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: plant,
              ),
              if (burst > 0 && !reduced)
                SparkleBurst(key: ValueKey('plant_burst_$burst'), color: item.auraColor, size: size * 1.3, seed: burst),
              // Estado debajo: progreso o cosecha
              if (!adult)
                Positioned(
                  bottom: -14,
                  child: _GrowthPill(
                    progress: planted.growthProgress(item),
                    stage: stage,
                    label: gardenTimeShort(planted.timeRemaining(item) ?? Duration.zero),
                  ),
                ),
              if (ready)
                Positioned(
                  top: -size * 0.02,
                  child: _HarvestBubble(seeds: seedsPerDay),
                ),
            ],
          ),
        ),
      ),
    ).animate(key: ValueKey('slot_in_${planted.instanceId}')).scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1, 1),
          duration: 520.ms,
          curve: Curves.elasticOut,
        );
  }
}

class _GrowthPill extends StatelessWidget {
  final double progress;
  final PlantStage stage;
  final String label;

  const _GrowthPill({required this.progress, required this.stage, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = stage == PlantStage.seed ? const Color(0xFFFBBF24) : const Color(0xFF6EE7B7);
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(3, 3, 9, 3),
      radius: 14,
      opacity: 0.55,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RouteProgressRing(
            progress: progress,
            color: color,
            track: Colors.white.withValues(alpha: 0.18),
            size: 20,
            stroke: 3,
            child: const SizedBox.shrink(),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Burbuja que flota sobre una planta con cosecha lista.
class _HarvestBubble extends StatelessWidget {
  final int seeds;
  const _HarvestBubble({required this.seeds});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFBBF24), width: 2),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFBBF24).withValues(alpha: 0.55), blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SeedIcon(size: 22, withGlow: false),
          const SizedBox(width: 2),
          Text(
            '+$seeds',
            style: JournalStyle.hand(const TextStyle(fontSize: 19, height: 1.0, color: Color(0xFF15803D), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    )
        .animate(onPlay: MotionService.loop(context, reverse: true))
        .moveY(begin: 0, end: -6, duration: 1100.ms, curve: Curves.easeInOut)
        .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 1100.ms);
  }
}

/// Vaivén de brisa para las plantas que aún crecen (más corto que el adulto).
class _Swaying extends StatelessWidget {
  final double size;
  final Widget child;
  const _Swaying({required this.size, required this.child});

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: MotionService.loop(context, reverse: true))
        .rotate(begin: -0.006, end: 0.006, duration: 2600.ms, curve: Curves.easeInOut, alignment: Alignment.bottomCenter);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Planta adulta: aura de su color que late, brisa y destellos que suben
// ═════════════════════════════════════════════════════════════════════════════

class AdultPlant extends StatefulWidget {
  final GardenItem item;
  final double size;
  final String assetPath;

  const AdultPlant({super.key, required this.item, required this.size, required this.assetPath});

  @override
  State<AdultPlant> createState() => _AdultPlantState();
}

class _AdultPlantState extends State<AdultPlant> with TickerProviderStateMixin {
  late final AnimationController _breeze =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))..repeatUnlessReduced(reverse: true, rest: 0.5);
  late final AnimationController _halo =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeatUnlessReduced(reverse: true, rest: 0.5);
  late final AnimationController _particles =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeatUnlessReduced(rest: 0.35);
  late final List<_Particle> _list = _buildParticles();

  int get _count => switch (widget.item.rarity) {
        ItemRarity.common => 5,
        ItemRarity.rare => 7,
        ItemRarity.epic => 9,
        ItemRarity.legendary => 12,
        ItemRarity.seasonal => 9,
      };

  List<_Particle> _buildParticles() {
    final rng = math.Random(widget.item.id.hashCode);
    return List.generate(_count, (i) {
      final baseX = 0.15 + (i % 3) * 0.35 + rng.nextDouble() * 0.1;
      final baseY = 0.35 + (i ~/ 3) * 0.25 + rng.nextDouble() * 0.15;
      return _Particle(
        startX: baseX.clamp(0.1, 0.9),
        startY: baseY.clamp(0.3, 0.85),
        phase: i / _count,
        size: 2.5 + rng.nextDouble() * 3.5,
        drift: (rng.nextDouble() - 0.5) * 0.18,
      );
    });
  }

  @override
  void dispose() {
    _breeze.dispose();
    _halo.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final item = widget.item;
    final color = item.auraColor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Aura de rareza: color e intensidad propios del item, latiendo
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _halo,
              builder: (_, _) {
                final t = Curves.easeInOut.transform(_halo.value);
                final opacity = ((item.auraOpacity + 0.2) * (0.75 + t * 0.4)).clamp(0.0, 1.0);
                final d = size * (0.95 + t * 0.15) + item.auraBlurRadius * 2;
                return Container(
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: opacity),
                        color.withValues(alpha: opacity * 0.7),
                        color.withValues(alpha: opacity * 0.25),
                        color.withValues(alpha: 0),
                      ],
                      stops: const [0, 0.38, 0.7, 1],
                    ),
                  ),
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: _breeze,
            builder: (_, child) {
              final t = Curves.easeInOut.transform(_breeze.value);
              return Transform.rotate(angle: (t * 2 - 1) * 0.025, alignment: Alignment.bottomCenter, child: child);
            },
            child: SizedBox(
              width: size,
              height: size,
              child: Image.asset(
                widget.assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Center(
                  child: Text(item.stageEmojis?[PlantStage.adult] ?? item.emoji, style: TextStyle(fontSize: size * 0.4)),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _particles,
              builder: (_, _) => SizedBox(
                width: size,
                height: size * 1.6,
                child: CustomPaint(
                  painter: _ParticlePainter(particles: _list, progress: _particles.value, color: color),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  final double startX;
  final double startY;
  final double phase;
  final double size;
  final double drift;

  const _Particle({required this.startX, required this.startY, required this.phase, required this.size, required this.drift});
}

/// Destellos de 4 puntas que suben (sin blur: seguro en WebGL).
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  const _ParticlePainter({required this.particles, required this.progress, required this.color});

  void _sparkle(Canvas canvas, Offset c, double r, double opacity) {
    if (opacity <= 0) return;
    canvas.drawCircle(
      c,
      r * 0.35,
      Paint()..color = Color.lerp(color, Colors.white, 0.6)!.withValues(alpha: (opacity * 0.9).clamp(0, 1)),
    );
    final ray = Paint()
      ..color = color.withValues(alpha: (opacity * 0.55).clamp(0, 1))
      ..strokeWidth = r * 0.35
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(c.dx, c.dy - r * 1.4), Offset(c.dx, c.dy + r * 1.4), ray);
    canvas.drawLine(Offset(c.dx - r * 1.4, c.dy), Offset(c.dx + r * 1.4, c.dy), ray);
    final diag = Paint()
      ..color = color.withValues(alpha: (opacity * 0.3).clamp(0, 1))
      ..strokeWidth = r * 0.22
      ..strokeCap = StrokeCap.round;
    final d = r * 0.85;
    canvas.drawLine(Offset(c.dx - d, c.dy - d), Offset(c.dx + d, c.dy + d), diag);
    canvas.drawLine(Offset(c.dx + d, c.dy - d), Offset(c.dx - d, c.dy + d), diag);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress + p.phase) % 1.0;
      final opacity = t < 0.12 ? t / 0.12 : (t < 0.65 ? 1.0 : (1.0 - t) / 0.35);
      final y = (p.startY - t * 0.85) * size.height;
      final x = (p.startX + math.sin(t * math.pi * 3 + p.phase * math.pi * 2) * p.drift * 0.4) * size.width;
      final r = p.size * (0.7 + math.sin(t * math.pi * 4) * 0.15 + opacity * 0.3);
      _sparkle(canvas, Offset(x, y), r, opacity.clamp(0, 1));
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress || old.color != color;
}
