import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/garden_item.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../widgets/aura_container.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../../widgets/seed_icon.dart';
import '../garden_defs.dart';

/// Ilustración de un item (planta, decoración o booster) con su aura de
/// rareza. Si la imagen no carga, muestra el emoji del item.
class GardenItemImage extends StatelessWidget {
  final GardenItem item;
  final double size;
  final PlantStage stage;
  final bool aura;

  /// Tamaño del aura relativo al de la imagen.
  final double auraScale;

  /// Latido del aura: por defecto solo en rarezas altas.
  final bool? pulse;

  const GardenItemImage({
    super.key,
    required this.item,
    required this.size,
    this.stage = PlantStage.adult,
    this.aura = true,
    this.auraScale = 1,
    this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    final image = SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        GardenAssets.preview(item, stage: stage),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Center(
          child: Text(
            item.type == ItemType.plant ? (item.stageEmojis?[stage] ?? item.emoji) : item.emoji,
            style: TextStyle(fontSize: size * 0.6),
          ),
        ),
      ),
    );
    if (!aura) return ExcludeSemantics(child: image);
    return ExcludeSemantics(
      child: AuraContainer(
        item: item,
        sizeMultiplier: size / 60 * auraScale,
        pulse: pulse ?? AuraContainer.pulsesFor(item.rarity),
        child: image,
      ),
    );
  }
}

/// Etiqueta de rareza con su color.
class RarityChip extends StatelessWidget {
  final ItemRarity rarity;
  final bool small;

  const RarityChip({super.key, required this.rarity, this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = RarityStyle.color(rarity);
    final star = switch (rarity) {
      ItemRarity.common => '',
      ItemRarity.rare => '✦ ',
      ItemRarity.epic => '✦✦ ',
      ItemRarity.legendary => '★ ',
      ItemRarity.seasonal => '❄ ',
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, 0.18)!]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$star${RarityStyle.label(rarity).tr()}'.toUpperCase(),
        style: TextStyle(
          fontSize: small ? 8.5 : 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Panel de vidrio oscuro para ponerlo sobre la ilustración del jardín.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final double opacity;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.radius = 20,
    this.borderColor,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0E1A14).withValues(alpha: opacity * 0.9),
            const Color(0xFF0E1A14).withValues(alpha: opacity + 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.16)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

/// Contador de semillas: sube o baja número a número y da un saltito al
/// ganar semillas.
class SeedCounter extends StatefulWidget {
  final int seeds;
  final double iconSize;
  final Color textColor;
  final double fontSize;

  const SeedCounter({
    super.key,
    required this.seeds,
    this.iconSize = 26,
    this.textColor = Colors.white,
    this.fontSize = 15,
  });

  @override
  State<SeedCounter> createState() => _SeedCounterState();
}

class _SeedCounterState extends State<SeedCounter> {
  late int _from = widget.seeds;
  int _pops = 0;

  @override
  void didUpdateWidget(SeedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seeds != widget.seeds) {
      _from = oldWidget.seeds;
      if (widget.seeds > oldWidget.seeds) _pops++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MotionService.reduced(context);
    return Semantics(
      label: '${'garden.seeds'.tr()}: ${widget.seeds}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SeedIcon(size: widget.iconSize)
              .animate(key: ValueKey('seed_pop_$_pops'))
              .scale(
                begin: _pops == 0 || reduced ? const Offset(1, 1) : const Offset(1.35, 1.35),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(width: 4),
          TweenAnimationBuilder<double>(
            key: ValueKey(widget.seeds),
            tween: Tween(begin: _from.toDouble(), end: widget.seeds.toDouble()),
            duration: reduced ? Duration.zero : const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text(
              '${v.round()}',
              style: TextStyle(
                color: widget.textColor,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón que se hunde al tocarlo, con vibración y etiqueta accesible.
class GardenPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticsLabel;
  final bool selected;

  const GardenPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.semanticsLabel,
    this.selected = false,
  });

  @override
  State<GardenPressable> createState() => _GardenPressableState();
}

class _GardenPressableState extends State<GardenPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final content = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: () => setState(() => _down = false),
      onLongPress: widget.onLongPress,
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
    if (widget.semanticsLabel == null) return content;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticsLabel,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: content,
    );
  }
}

/// Hoja inferior con el estilo del jardín: asa, título escrito a mano y
/// colores de claro u oscuro.
class GardenSheet extends StatelessWidget {
  final String? kicker;
  final String title;
  final Widget? leading;
  final Widget child;
  final bool scrollable;
  final ScrollController? controller;

  const GardenSheet({
    super.key,
    this.kicker,
    required this.title,
    required this.child,
    this.leading,
    this.scrollable = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = GardenPalette(isDark);
    final header = Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kicker != null)
                Text(
                  kicker!,
                  style: JournalStyle.hand(TextStyle(fontSize: 19, height: 1.0, color: GardenPalette.green)),
                ),
              Semantics(
                header: true,
                child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: p.ink)),
              ),
            ],
          ),
        ),
      ],
    );
    final handle = Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: p.handle, borderRadius: BorderRadius.circular(2)),
      ),
    );
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: p.sheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: scrollable
          ? ListView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottom),
              children: [handle, header, const SizedBox(height: 16), child],
            )
          : Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [handle, header, const SizedBox(height: 16), child],
              ),
            ),
    );
  }
}

/// Aviso flotante del jardín (sustituye a los SnackBar sueltos).
class GardenToast {
  GardenToast._();

  static void show(BuildContext context, {required String text, Widget? leading, Color color = GardenPalette.green}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(milliseconds: 2400),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, 0.2)!]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              if (leading != null) ...[SizedBox(width: 30, height: 30, child: Center(child: leading)), const SizedBox(width: 10)],
              Expanded(
                child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
              ),
            ],
          ),
        ),
      ));
  }
}

/// Rayos de luz que giran despacio detrás de un item especial.
class LightRays extends StatelessWidget {
  final Color color;
  final double size;

  const LightRays({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _RaysPainter(color: color)),
      ).animate(onPlay: MotionService.loop(context)).rotate(begin: 0, end: 1, duration: 24.seconds),
    );
  }
}

/// Rayos suaves alrededor de la planta (gradiente, sin blur).
class _RaysPainter extends CustomPainter {
  final Color color;
  const _RaysPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
    const rays = 12;
    final paint = Paint()
      ..shader = RadialGradient(colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: c, radius: r));
    for (int i = 0; i < rays; i++) {
      final a = i / rays * math.pi * 2;
      const half = math.pi / rays * 0.45;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - half) * r, c.dy + math.sin(a - half) * r)
        ..lineTo(c.dx + math.cos(a + half) * r, c.dy + math.sin(a + half) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.color != color;
}
