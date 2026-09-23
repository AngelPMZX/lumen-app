import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/garden_item.dart';
import '../../../../data/models/garden_mechanics.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../../widgets/seed_icon.dart';
import '../garden_defs.dart';
import 'garden_common.dart';

/// Cómo se puede conseguir un item en la tienda ahora mismo.
enum ShopAvailability { seeds, premium, seasonalLocked }

ShopAvailability shopAvailabilityOf(GardenItem item) {
  if (item.isSeasonal && !item.isCurrentlyAvailable) return ShopAvailability.seasonalLocked;
  if (item.canBuyWithSeeds) return ShopAvailability.seeds;
  return ShopAvailability.premium;
}

/// Duración legible ("1 día", "5 h").
String shopDuration(Duration d) => d.inHours >= 24 ? 'garden.durationDays'.plural(d.inDays) : 'garden.durationHours'.tr(namedArgs: {'hours': '${d.inHours}'});

/// Efecto de un booster en texto corto.
String boosterEffect(GardenItem b) {
  final d = b.boostDuration;
  if (d == null || d.inDays >= 30) return 'garden.boostInstant'.tr();
  return 'garden.boostHours'.tr(namedArgs: {'hours': '${d.inHours}'});
}

// ═════════════════════════════════════════════════════════════════════════════
// Tarjeta de item
// ═════════════════════════════════════════════════════════════════════════════

class ShopItemCard extends StatelessWidget {
  final GardenItem item;
  final int owned;
  final int seeds;
  final bool isDark;

  /// Cambia al comprar: dispara el saltito y los destellos.
  final int purchaseBurst;
  final VoidCallback onOpen;
  final VoidCallback onBuy;

  const ShopItemCard({
    super.key,
    required this.item,
    required this.owned,
    required this.seeds,
    required this.isDark,
    required this.onOpen,
    required this.onBuy,
    this.purchaseBurst = 0,
  });

  @override
  Widget build(BuildContext context) {
    final p = GardenPalette(isDark);
    final rarity = RarityStyle.color(item.rarity);
    final availability = shopAvailabilityOf(item);
    final locked = availability == ShopAvailability.seasonalLocked;
    final reduced = MotionService.reduced(context);

    final subtitle = switch (item.type) {
      ItemType.plant => item.growthTime == null ? '' : '⏱ ${shopDuration(item.growthTime!)}',
      ItemType.booster => '⚡ ${boosterEffect(item)}',
      _ => item.descriptionKey.tr(),
    };

    return GardenPressable(
      onTap: onOpen,
      semanticsLabel: [
        item.nameKey.tr(),
        RarityStyle.label(item.rarity).tr(),
        if (owned > 0) 'garden.ownedCount'.tr(namedArgs: {'count': '$owned'}),
        if (locked) 'garden.seasonalLocked'.tr(namedArgs: {'month': 'garden.months.${item.availableMonth ?? 12}'.tr()}),
        if (availability == ShopAvailability.seeds) 'garden.buyWithSeeds'.tr(namedArgs: {'cost': '${item.seedCost}'}),
      ].join('. '),
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: availability == ShopAvailability.premium ? GardenPalette.violet.withValues(alpha: 0.45) : rarity.withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.5,
          ),
          boxShadow: isDark ? null : [BoxShadow(color: rarity.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vitrina con la ilustración y su aura
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0, 0.1),
                            radius: 0.85,
                            colors: [
                              item.auraColor.withValues(alpha: isDark ? 0.3 : 0.2),
                              rarity.withValues(alpha: isDark ? 0.08 : 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ColorFiltered(
                          colorFilter: locked ? _grayscale : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                          child: GardenItemImage(item: item, size: 86, pulse: locked ? false : null)
                              .animate(onPlay: AuraPulse.floats(item.rarity) ? MotionService.loop(context, reverse: true) : null)
                              .moveY(begin: 0, end: AuraPulse.floats(item.rarity) ? -4 : 0, duration: 1800.ms, curve: Curves.easeInOut),
                        )
                        .animate(key: ValueKey('buy_${item.id}_$purchaseBurst'))
                        .scale(
                          begin: purchaseBurst == 0 || reduced ? const Offset(1, 1) : const Offset(1.25, 1.25),
                          end: const Offset(1, 1),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        ),
                    if (purchaseBurst > 0 && !reduced)
                      SparkleBurst(key: ValueKey('shop_burst_$purchaseBurst'), color: item.auraColor, size: 150, seed: purchaseBurst),
                    Positioned(top: 10, left: 10, child: RarityChip(rarity: item.rarity, small: true)),
                    if (owned > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child:
                            Container(
                                  padding: const EdgeInsets.fromLTRB(5, 2, 7, 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF12211A) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: GardenPalette.green.withValues(alpha: 0.6)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.backpack_rounded, size: 12, color: GardenPalette.green),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$owned',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: GardenPalette.green),
                                      ),
                                    ],
                                  ),
                                )
                                .animate(key: ValueKey('owned_$owned'))
                                .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 350.ms, curve: Curves.easeOutBack),
                      ),
                    if (locked)
                      Positioned(
                        right: 10,
                        bottom: 8,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF12211A) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: rarity.withValues(alpha: 0.6)),
                          ),
                          child: Icon(Icons.lock_rounded, color: rarity, size: 15),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nameKey.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: p.ink),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      locked ? 'garden.seasonalLocked'.tr(namedArgs: {'month': 'garden.months.${item.availableMonth ?? 12}'.tr()}) : subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: p.inkSoft),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: switch (availability) {
                  ShopAvailability.seeds => SeedPriceButton(cost: item.seedCost, seeds: seeds, isDark: isDark, onTap: onBuy),
                  ShopAvailability.premium => _PremiumPriceButton(price: item.premiumCost ?? 0, onTap: onOpen),
                  ShopAvailability.seasonalLocked => _LockedButton(isDark: isDark),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Qué rarezas flotan en la vitrina.
class AuraPulse {
  AuraPulse._();
  static bool floats(ItemRarity r) => r != ItemRarity.common;
}

/// Desaturado y aclarado: la pieza se adivina, pero espera su temporada.
const _grayscale = ColorFilter.matrix([
  0.25, 0.25, 0.25, 0, 70, //
  0.25, 0.25, 0.25, 0, 70,
  0.25, 0.25, 0.25, 0, 70,
  0, 0, 0, 0.75, 0,
]);

/// Botón de precio en semillas: verde si alcanza; si no, dice cuántas faltan.
class SeedPriceButton extends StatelessWidget {
  final int cost;
  final int seeds;
  final bool isDark;
  final VoidCallback onTap;
  final bool large;

  const SeedPriceButton({super.key, required this.cost, required this.seeds, required this.isDark, required this.onTap, this.large = false});

  @override
  Widget build(BuildContext context) {
    final affordable = seeds >= cost;
    final p = GardenPalette(isDark);
    final label = affordable
        ? (large ? 'garden.buyFor'.tr(namedArgs: {'cost': '$cost'}) : '$cost')
        : 'garden.missingSeeds'.tr(namedArgs: {'count': '${cost - seeds}'});
    return Semantics(
      button: true,
      enabled: affordable,
      label: affordable ? 'garden.buyWithSeeds'.tr(namedArgs: {'cost': '$cost'}) : label,
      onTap: affordable ? onTap : null,
      excludeSemantics: true,
      child: GardenPressable(
        onTap: affordable ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          height: large ? 54 : 40,
          decoration: BoxDecoration(
            gradient: affordable ? const LinearGradient(colors: [Color(0xFF34D399), GardenPalette.greenDark]) : null,
            color: affordable ? null : (isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFF1ECDD)),
            borderRadius: BorderRadius.circular(large ? 18 : 14),
            boxShadow: affordable ? [BoxShadow(color: GardenPalette.green.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: affordable ? 1 : 0.55,
                child: SeedIcon(size: large ? 28 : 22, withGlow: false),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: large ? 16 : (affordable ? 15 : 11.5), fontWeight: FontWeight.w900, color: affordable ? Colors.white : p.inkSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumPriceButton extends StatelessWidget {
  final double price;
  final VoidCallback onTap;
  const _PremiumPriceButton({required this.price, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💎', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _LockedButton extends StatelessWidget {
  final bool isDark;
  const _LockedButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final p = GardenPalette(isDark);
    return Container(
      height: 40,
      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1ECDD), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_rounded, size: 15, color: p.inkSoft),
          const SizedBox(width: 5),
          Text(
            'garden.seasonal'.tr(),
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: p.inkSoft),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Selector de categoría con nuestras ilustraciones
// ═════════════════════════════════════════════════════════════════════════════

class ShopCategoryBar extends StatelessWidget {
  final List<(ItemType, GardenItem, String)> categories;
  final ItemType selected;
  final bool isDark;
  final ValueChanged<ItemType> onSelect;

  const ShopCategoryBar({super.key, required this.categories, required this.selected, required this.isDark, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final p = GardenPalette(isDark);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.cardBorder),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          for (final (type, icon, label) in categories)
            Expanded(
              child: Semantics(
                button: true,
                selected: type == selected,
                inMutuallyExclusiveGroup: true,
                label: label,
                onTap: () => onSelect(type),
                excludeSemantics: true,
                child: GardenPressable(
                  onTap: () => onSelect(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: type == selected ? const LinearGradient(colors: [Color(0xFF34D399), GardenPalette.greenDark]) : null,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: type == selected ? 1.12 : 1,
                          duration: const Duration(milliseconds: 260),
                          child: GardenItemImage(item: icon, size: 30, aura: false),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: type == selected ? Colors.white : p.inkSoft),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Encabezado de sección de la tienda.
class ShopSectionTitle extends StatelessWidget {
  final String kicker;
  final String title;
  final bool isDark;
  final Color color;

  const ShopSectionTitle({super.key, required this.kicker, required this.title, required this.isDark, this.color = GardenPalette.green});

  @override
  Widget build(BuildContext context) {
    final p = GardenPalette(isDark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker, style: JournalStyle.hand(TextStyle(fontSize: 18, height: 1.0, color: color))),
        Semantics(
          header: true,
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: p.ink),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Detalle de un item
// ═════════════════════════════════════════════════════════════════════════════

class ShopItemDetail extends StatefulWidget {
  final GardenItem item;
  final int Function() owned;
  final int Function() seeds;

  /// Compra; devuelve true si salió bien.
  final Future<bool> Function() onBuy;

  const ShopItemDetail({super.key, required this.item, required this.owned, required this.seeds, required this.onBuy});

  @override
  State<ShopItemDetail> createState() => _ShopItemDetailState();
}

class _ShopItemDetailState extends State<ShopItemDetail> {
  int _burst = 0;
  bool _busy = false;

  Future<void> _buy() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await widget.onBuy();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _burst++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = GardenPalette(isDark);
    final availability = shopAvailabilityOf(item);
    final reduced = MotionService.reduced(context);
    final owned = widget.owned();
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: p.sheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: p.handle, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  LightRays(color: item.auraColor, size: 240),
                  GardenItemImage(item: item, size: 140, pulse: true)
                      .animate()
                      .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 650.ms, curve: Curves.elasticOut)
                      .animate(key: ValueKey('detail_buy_$_burst'))
                      .scale(
                        begin: _burst == 0 || reduced ? const Offset(1, 1) : const Offset(1.2, 1.2),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),
                  if (!reduced) SparkleBurst(key: ValueKey('detail_burst_$_burst'), color: item.auraColor, size: 230, seed: _burst + 7),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RarityChip(rarity: item.rarity),
                if (owned > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: GardenPalette.green.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'garden.ownedCount'.tr(namedArgs: {'count': '$owned'}),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: GardenPalette.green),
                    ),
                  ).animate(key: ValueKey('owned_detail_$owned')).fadeIn(duration: 250.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Semantics(
              header: true,
              child: Text(
                item.nameKey.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: p.ink),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.descriptionKey.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.45, color: p.inkSoft),
            ),
            const SizedBox(height: 16),
            if (item.type == ItemType.plant) _PlantDetails(item: item, isDark: isDark),
            if (item.type == ItemType.booster) _InfoRow(isDark: isDark, emoji: '⚡', title: 'garden.boosterEffect'.tr(), value: boosterEffect(item)),
            if (item.type == ItemType.decoration) _InfoRow(isDark: isDark, emoji: '🖐️', title: 'garden.decoHowTo'.tr(), value: ''),
            const SizedBox(height: 18),
            switch (availability) {
              ShopAvailability.seeds => SeedPriceButton(cost: item.seedCost, seeds: widget.seeds(), isDark: isDark, onTap: _buy, large: true),
              ShopAvailability.premium => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [GardenPalette.violet.withValues(alpha: 0.16), GardenPalette.violet.withValues(alpha: 0.06)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: GardenPalette.violet.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'garden.premiumSoon'.tr(),
                        style: TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: p.ink),
                      ),
                    ),
                    Text(
                      '\$${(item.premiumCost ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: GardenPalette.violet),
                    ),
                  ],
                ),
              ),
              ShopAvailability.seasonalLocked => _InfoRow(
                isDark: isDark,
                emoji: '📅',
                title: 'garden.seasonalLocked'.tr(namedArgs: {'month': 'garden.months.${item.availableMonth ?? 12}'.tr()}),
                value: '',
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _PlantDetails extends StatelessWidget {
  final GardenItem item;
  final bool isDark;
  const _PlantDetails({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final p = GardenPalette(isDark);
    final mech = mechanicsFor(item.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.cardBorder),
          ),
          child: Row(
            children: [
              for (final stage in PlantStage.values) ...[
                Expanded(
                  child: Column(
                    children: [
                      GardenItemImage(
                        item: item,
                        size: 46,
                        stage: stage,
                        aura: stage == PlantStage.adult,
                        grounded: true,
                      )
                          .animate()
                          .fadeIn(delay: (120 * stage.index).ms, duration: 300.ms)
                          .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), curve: Curves.easeOutBack),
                      const SizedBox(height: 4),
                      Text(
                        'garden.stage.${stage.name}'.tr(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GardenPalette.stageColor(stage)),
                      ),
                    ],
                  ),
                ),
                if (stage != PlantStage.adult) Icon(Icons.chevron_right_rounded, size: 16, color: p.inkSoft),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (item.growthTime != null) _InfoRow(isDark: isDark, emoji: '⏱', title: 'garden.growsIn'.tr(), value: shopDuration(item.growthTime!)),
        _InfoRow(
          isDark: isDark,
          leading: const SeedIcon(size: 22, withGlow: false),
          title: 'garden.dailyHarvest'.tr(),
          value: 'garden.perSeedsDay'.tr(namedArgs: {'count': '${mech.seedsPerDay}'}),
        ),
        _InfoRow(
          isDark: isDark,
          emoji: '⚡',
          title: 'garden.xpChance'.tr(namedArgs: {'mult': mech.xpMultiplier.toStringAsFixed(1)}),
          value: '${(mech.xpMultiplierChance * 100).round()}%',
        ),
        if (mech.canGiveStreakShield) _InfoRow(isDark: isDark, emoji: '🛡️', title: 'garden.givesShields'.tr(), value: ''),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final bool isDark;
  final String? emoji;
  final Widget? leading;
  final String title;
  final String value;

  const _InfoRow({required this.isDark, required this.title, required this.value, this.emoji, this.leading});

  @override
  Widget build(BuildContext context) {
    final p = GardenPalette(isDark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.cardBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Center(child: leading ?? Text(emoji ?? '', style: const TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: p.ink),
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFF6EE7B7) : GardenPalette.greenDark),
              ),
          ],
        ),
      ),
    );
  }
}
