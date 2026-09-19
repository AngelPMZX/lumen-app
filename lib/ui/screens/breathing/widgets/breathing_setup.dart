import '../../../widgets/clip_sideways.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../domain/services/motion_service.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../../widgets/min_tap_target.dart';
import '../breathing_data.dart';

/// Título de sección del setup, con una línea a mano arriba.
class BreathSectionTitle extends StatelessWidget {
  final String kicker;
  final String title;
  final Color color;
  final Widget? trailing;

  const BreathSectionTitle({super.key, required this.kicker, required this.title, required this.color, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kicker, style: JournalStyle.hand(TextStyle(fontSize: 17, height: 1.0, color: Color.lerp(color, Colors.white, 0.35)))),
              Semantics(
                header: true,
                child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Tarjeta de técnica con su ritmo dibujado en barras.
class TechniqueCard extends StatelessWidget {
  final BreathingTechnique technique;
  final bool selected;
  final VoidCallback onTap;

  const TechniqueCard({super.key, required this.technique, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = technique;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '${t.nameKey.tr()}. ${t.descriptionKey.tr()}. ${t.benefitKey.tr()}',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: selected
                  ? [t.color.withValues(alpha: 0.28), t.color.withValues(alpha: 0.08)]
                  : [Colors.white.withValues(alpha: 0.07), Colors.white.withValues(alpha: 0.04)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? t.color : Colors.white.withValues(alpha: 0.1), width: selected ? 2 : 1),
            boxShadow: selected ? [BoxShadow(color: t.color.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: t.color.withValues(alpha: selected ? 0.3 : 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text(t.emoji, style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                t.nameKey.tr(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: t.color.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(7)),
                              child: Text(
                                t.descriptionKey.tr(),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color.lerp(t.color, Colors.white, 0.5)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          t.benefitKey.tr(),
                          style: TextStyle(fontSize: 12, height: 1.3, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: Icon(Icons.check_circle_rounded, color: t.color, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PhaseBars(technique: t, active: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// El ritmo de la técnica: una barra por fase, del ancho de su duración.
class PhaseBars extends StatelessWidget {
  final BreathingTechnique technique;
  final bool active;

  const PhaseBars({super.key, required this.technique, required this.active});

  static Color colorFor(BreathMove move, Color base) => switch (move) {
        BreathMove.inhale => Color.lerp(base, Colors.white, 0.45)!,
        BreathMove.hold => Color.lerp(base, Colors.white, 0.1)!,
        BreathMove.exhale => Color.lerp(base, Colors.black, 0.2)!,
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: Row(
        children: [
          for (final (i, p) in technique.phases.indexed)
            Expanded(
              flex: p.seconds,
              child: Padding(
                padding: EdgeInsets.only(right: i == technique.phases.length - 1 ? 0 : 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colorFor(p.move, technique.color).withValues(alpha: active ? 0.95 : 0.4),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${p.labelKey.tr()} ${p.seconds}s',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: active ? 0.75 : 0.4)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Minutos de la sesión.
class DurationPicker extends StatelessWidget {
  final List<int> options;
  final int selected;
  final Color color;
  final ValueChanged<int> onSelect;

  const DurationPicker({super.key, required this.options, required this.selected, required this.color, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, min) in options.indexed)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == options.length - 1 ? 0 : 10),
              child: Semantics(
                button: true,
                selected: min == selected,
                inMutuallyExclusiveGroup: true,
                label: 'breathing.minutes'.plural(min),
                onTap: () => onSelect(min),
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => onSelect(min),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: min == selected ? LinearGradient(colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.15)]) : null,
                      color: min == selected ? null : Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: min == selected ? color : Colors.white.withValues(alpha: 0.1), width: min == selected ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$min',
                          style: TextStyle(
                            fontSize: 20,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            color: min == selected ? Color.lerp(color, Colors.white, 0.5) : Colors.white70,
                          ),
                        ),
                        Text(
                          'breathing.minShort'.tr(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ambientes con escucha previa: el que está sonando late despacio.
class AmbientPicker extends StatelessWidget {
  final String selectedId;
  final String? playingId;
  final Color color;
  final ValueChanged<AmbientChoice> onSelect;

  const AmbientPicker({super.key, required this.selectedId, required this.playingId, required this.color, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ClipSideways(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: kAmbientChoices.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final s = kAmbientChoices[i];
            final isSelected = s.id == selectedId;
            final isPlaying = s.id == playingId;
            final chip = AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.15)]) : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? color : Colors.white.withValues(alpha: 0.1), width: isSelected ? 2 : 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 17)),
                  const SizedBox(width: 7),
                  Text(
                    s.labelKey.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  if (isPlaying) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.graphic_eq_rounded, size: 14, color: Color.lerp(color, Colors.white, 0.5)),
                  ],
                ],
              ),
            );
            return Semantics(
              button: true,
              selected: isSelected,
              inMutuallyExclusiveGroup: true,
              label: s.labelKey.tr(),
              onTap: () => onSelect(s),
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => onSelect(s),
                child: isPlaying
                    ? chip
                        .animate(onPlay: MotionService.loop(context, reverse: true))
                        .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 1200.ms, curve: Curves.easeInOut)
                    : chip,
              ),
            );
          },
        ),
),
    );
  }
}

/// Interruptor de las señales de sonido de cada fase.
class CueToggle extends StatelessWidget {
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const CueToggle({super.key, required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: '${'breathing.cuesLabel'.tr()}. ${'breathing.cuesSubtitle'.tr()}',
      onTap: () => onChanged(!value),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              AnimatedScale(
                scale: value ? 1 : 0.9,
                duration: const Duration(milliseconds: 250),
                child: const Text('🔔', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('breathing.cuesLabel'.tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('breathing.cuesSubtitle'.tr(), style: const TextStyle(fontSize: 12, color: Colors.white54)),
                  ],
                ),
              ),
              IgnorePointer(
                child: Switch(value: value, activeThumbColor: color, onChanged: (_) {}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón redondo translúcido de la barra superior.
class BreathIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const BreathIconButton({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: MinTapTarget(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, size: 18, color: Colors.white70),
        ),
      ),
    );
  }
}
