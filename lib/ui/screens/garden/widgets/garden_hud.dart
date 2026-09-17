import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/garden_item.dart';
import '../../../../data/models/garden_mechanics.dart';
import '../../../../data/models/garden_state.dart';
import '../../../../data/models/lumi.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../../domain/services/sound_service.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../../widgets/lumi/lumi_avatar.dart';
import '../../../widgets/min_tap_target.dart';
import '../../../widgets/seed_icon.dart';
import '../garden_defs.dart';
import 'garden_common.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Barra superior
// ═════════════════════════════════════════════════════════════════════════════

class GardenTopBar extends StatelessWidget {
  final GardenDef garden;
  final int seeds;
  final int shields;
  final XpMultiplierState? multiplier;
  final bool ambientOn;
  final VoidCallback onBack;
  final VoidCallback onGardens;
  final VoidCallback onToggleAmbient;
  final VoidCallback onShields;
  final VoidCallback onShop;
  final VoidCallback onProgress;

  const GardenTopBar({
    super.key,
    required this.garden,
    required this.seeds,
    required this.shields,
    required this.multiplier,
    required this.ambientOn,
    required this.onBack,
    required this.onGardens,
    required this.onToggleAmbient,
    required this.onShields,
    required this.onShop,
    required this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    final mult = multiplier;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassIconButton(icon: Icons.arrow_back_rounded, label: 'common.back'.tr(), onTap: onBack),
              const SizedBox(width: 2),
              Expanded(
                child: GardenPressable(
                  onTap: onGardens,
                  semanticsLabel: '${garden.nameKey.tr()}. ${'garden.sidebar.gardens'.tr()}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'garden.title'.tr(),
                        style: JournalStyle.hand(
                          const TextStyle(
                            fontSize: 17,
                            height: 1.0,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              garden.nameKey.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.expand_more_rounded,
                            color: Colors.white,
                            size: 20,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              GlassIconButton(icon: Icons.emoji_events_rounded, label: 'garden.sidebar.achievements'.tr(), onTap: onProgress, color: const Color(0xFFFCD34D)),
              GlassIconButton(
                icon: ambientOn ? Icons.music_note_rounded : Icons.music_off_rounded,
                label: ambientOn ? 'garden.ambientOff'.tr() : 'garden.ambientOn'.tr(),
                onTap: onToggleAmbient,
                selected: ambientOn,
              ),
              const SizedBox(width: 4),
              GardenPressable(
                onTap: onShop,
                semanticsLabel: '${'garden.seeds'.tr()}: $seeds. ${'garden.shop'.tr()}',
                child: GlassPanel(
                  padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
                  radius: 20,
                  borderColor: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                  child: SeedCounter(seeds: seeds, iconSize: 28),
                ),
              ),
            ],
          ),
          if (mult != null || shields > 0)
            Padding(
              padding: const EdgeInsets.only(left: 50, top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (mult != null)
                    _StatusChip(
                      color: GardenPalette.violet,
                      leading: const Text('⚡', style: TextStyle(fontSize: 13)),
                      text: 'garden.multiplierChip'.tr(namedArgs: {'mult': mult.multiplier.toStringAsFixed(1), 'mins': '${mult.timeRemaining.inMinutes + 1}'}),
                      glow: true,
                    ),
                  if (shields > 0)
                    GardenPressable(
                      onTap: onShields,
                      semanticsLabel: shields == 1 ? 'garden.shields.countOne'.tr() : 'garden.shields.countOther'.tr(namedArgs: {'count': '$shields'}),
                      child: _StatusChip(
                        color: GardenPalette.gold,
                        leading: const Text('🛡️', style: TextStyle(fontSize: 13)),
                        text: '$shields',
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic);
  }
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final Widget leading;
  final String text;
  final bool glow;

  const _StatusChip({required this.color, required this.leading, required this.text, this.glow = false});

  @override
  Widget build(BuildContext context) {
    final chip = GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      radius: 14,
      borderColor: color.withValues(alpha: 0.7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: Color.lerp(color, Colors.white, 0.45), fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
    if (!glow) return chip;
    return chip
        .animate(onPlay: MotionService.loop(context, reverse: true))
        .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1000.ms, curve: Curves.easeInOut);
  }
}

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final Color? color;

  const GlassIconButton({super.key, required this.icon, required this.label, required this.onTap, this.selected = false, this.color});

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
        child: GlassPanel(
          padding: const EdgeInsets.all(9),
          radius: 14,
          borderColor: (color ?? Colors.white).withValues(alpha: 0.3),
          child: Icon(icon, color: color ?? Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Mochila (inventario)
// ═════════════════════════════════════════════════════════════════════════════

/// Datos que viajan al arrastrar una decoración desde la mochila.
class NewDecoDrag {
  final String itemId;
  const NewDecoDrag(this.itemId);
}

class InventoryTray extends StatelessWidget {
  final GardenState state;
  final String? plantingId;
  final String? boostingId;
  final ValueChanged<GardenItem> onPlant;
  final ValueChanged<GardenItem> onBooster;
  final ValueChanged<GardenItem> onDecoTap;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final VoidCallback onShop;
  final double bottomInset;

  const InventoryTray({
    super.key,
    required this.state,
    required this.plantingId,
    required this.boostingId,
    required this.onPlant,
    required this.onBooster,
    required this.onDecoTap,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onShop,
    required this.bottomInset,
  });

  /// Alto aproximado sin el margen inferior del sistema.
  static double height({required bool isEmpty}) => isEmpty ? 152 : 176;

  @override
  Widget build(BuildContext context) {
    final order = {ItemType.plant: 0, ItemType.decoration: 1, ItemType.booster: 2, ItemType.theme: 3};
    final items =
        <(GardenItem, int)>[
          for (final inv in state.inventory)
            if (inv.quantity > 0)
              if (GardenCatalog.findById(inv.itemId) case final item?) (item, inv.quantity),
        ]..sort((a, b) {
          final byType = order[a.$1.type]!.compareTo(order[b.$1.type]!);
          return byType != 0 ? byType : a.$1.rarity.index.compareTo(b.$1.rarity.index);
        });
    final total = items.fold<int>(0, (s, e) => s + e.$2);

    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 12 + bottomInset),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF16291F).withValues(alpha: 0.94), const Color(0xFF0E1A14)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.14))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('🎒', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Semantics(
                header: true,
                child: Text(
                  'garden.inventory'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
              if (total > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '$total',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
              const Spacer(),
              GardenPressable(
                onTap: onShop,
                semanticsLabel: 'garden.shop'.tr(),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [GardenPalette.green, GardenPalette.greenDark]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_rounded, color: Colors.white, size: 17),
                      const SizedBox(width: 5),
                      Text(
                        'garden.shop'.tr(),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            _EmptyTray(onShop: onShop)
          else
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: items.length,
                separatorBuilder: (_, i) => SizedBox(width: items[i].$1.type != items[i + 1].$1.type ? 16 : 8),
                itemBuilder: (context, i) {
                  final (item, qty) = items[i];
                  final selected = item.id == plantingId || item.id == boostingId;
                  final card = _TrayCard(item: item, quantity: qty, selected: selected);
                  final Widget child = switch (item.type) {
                    ItemType.decoration => Draggable<NewDecoDrag>(
                      data: NewDecoDrag(item.id),
                      affinity: Axis.vertical,
                      dragAnchorStrategy: pointerDragAnchorStrategy,
                      feedback: DecoDragFeedback(item: item),
                      childWhenDragging: Opacity(opacity: 0.35, child: card),
                      onDragStarted: () {
                        HapticFeedback.mediumImpact();
                        onDragStarted();
                      },
                      onDragEnd: (_) => onDragEnded(),
                      child: GardenPressable(
                        onTap: () => onDecoTap(item),
                        semanticsLabel: '${item.nameKey.tr()}, ×$qty. ${'garden.dragHint'.tr()}',
                        child: card,
                      ),
                    ),
                    ItemType.booster => GardenPressable(
                      onTap: () => onBooster(item),
                      selected: selected,
                      semanticsLabel: '${item.nameKey.tr()}, ×$qty',
                      child: card,
                    ),
                    _ => GardenPressable(
                      onTap: () => onPlant(item),
                      selected: selected,
                      semanticsLabel: '${item.nameKey.tr()}, ×$qty. ${'garden.plant'.tr()}',
                      child: card,
                    ),
                  };
                  return child.animate().fadeIn(delay: (40 * i).ms, duration: 260.ms).slideX(begin: 0.25, end: 0, curve: Curves.easeOutCubic);
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Lo que se ve bajo el dedo al arrastrar una decoración: queda un poco
/// arriba del dedo para que no la tape.
class DecoDragFeedback extends StatelessWidget {
  final GardenItem item;
  const DecoDragFeedback({super.key, required this.item});

  /// Desplazamiento vertical del centro respecto del dedo.
  static double lift(String itemId) => GardenAssets.decoSize(itemId) * 0.35;

  @override
  Widget build(BuildContext context) {
    final s = GardenAssets.decoSize(item.id);
    return Transform.translate(
      offset: Offset(-s / 2, -s / 2 - lift(item.id)),
      child: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: GardenItemImage(item: item, size: s, pulse: false),
        ),
      ),
    );
  }
}

class _TrayCard extends StatelessWidget {
  final GardenItem item;
  final int quantity;
  final bool selected;

  const _TrayCard({required this.item, required this.quantity, required this.selected});

  @override
  Widget build(BuildContext context) {
    final rarity = RarityStyle.color(item.rarity);
    final accent = item.type == ItemType.booster ? GardenPalette.gold : GardenPalette.green;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: 76,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            rarity.withValues(alpha: selected ? 0.4 : 0.2),
            Colors.white.withValues(alpha: selected ? 0.16 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? accent : rarity.withValues(alpha: 0.4), width: selected ? 2.5 : 1),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Column(
              children: [
                GardenItemImage(item: item, size: 50, auraScale: 0.7),
                const Spacer(),
                Text(
                  item.nameKey.tr(),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9.5, height: 1.1, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
          if (quantity > 1)
            Positioned(
              top: -6,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: rarity, width: 1.5),
                ),
                child: Text(
                  '×$quantity',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color.lerp(rarity, Colors.black, 0.35)),
                ),
              ),
            ),
          if (item.type == ItemType.decoration)
            Positioned(top: 4, left: 4, child: Icon(Icons.open_with_rounded, size: 13, color: Colors.white.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _EmptyTray extends StatelessWidget {
  final VoidCallback onShop;
  const _EmptyTray({required this.onShop});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Row(
        children: [
          const SeedIcon(size: 44, animated: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'garden.inventoryEmpty'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text('garden.inventoryEmptyDesc'.tr(), style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Lumi en el jardín
// ═════════════════════════════════════════════════════════════════════════════

/// Lumi con un globo que cambia según lo que pasa en el jardín. El globo se
/// guarda solo tras unos segundos; tocar a Lumi lo vuelve a mostrar o da un
/// consejo nuevo.
class GardenLumiBubble extends StatefulWidget {
  final LumiLine line;
  const GardenLumiBubble({super.key, required this.line});

  @override
  State<GardenLumiBubble> createState() => _GardenLumiBubbleState();
}

class _GardenLumiBubbleState extends State<GardenLumiBubble> {
  static const _tips = 6;
  late LumiLine _line = widget.line;
  bool _open = true;
  int _taps = 0;
  Timer? _hide;
  DateTime _lastVoice = DateTime(2000);

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void didUpdateWidget(GardenLumiBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.line.key != widget.line.key || oldWidget.line.args['count'] != widget.line.args['count']) {
      _show(widget.line, voice: true);
    }
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _open = false);
    });
  }

  void _show(LumiLine line, {bool voice = false}) {
    final now = DateTime.now();
    // Sin repetir la voz si las frases cambian muy seguido
    if (voice && now.difference(_lastVoice) > const Duration(seconds: 4)) {
      SoundService.instance.play(Sfx.lumiHello, volume: 0.3);
      _lastVoice = now;
    }
    setState(() {
      _line = line;
      _open = true;
    });
    _scheduleHide();
  }

  void _onTap() {
    SoundService.instance.lumiChirp(_taps);
    if (!_open) {
      _show(widget.line);
    } else {
      _show(LumiLine('garden.lumi.tip.${_taps % _tips}', LumiMood.happy));
    }
    _taps++;
  }

  @override
  Widget build(BuildContext context) {
    final text = _line.key.tr(namedArgs: _line.args);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Semantics(
          button: true,
          label: 'Lumi',
          onTap: _onTap,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: _onTap,
            child: LumiAvatar(mood: _line.mood, size: 62),
          ),
        ),
        Flexible(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(anim), alignment: Alignment.bottomLeft, child: child),
            ),
            child: !_open
                ? const SizedBox.shrink(key: ValueKey('closed'))
                : IgnorePointer(
                    key: ValueKey('${_line.key}_$text'),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 26, left: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                          bottomLeft: Radius.circular(4),
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600, color: Color(0xFF26332B)),
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
