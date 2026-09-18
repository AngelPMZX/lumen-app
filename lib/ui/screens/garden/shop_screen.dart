import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/image_sizing.dart';
import '../../../data/models/garden_item.dart';
import '../../../data/models/garden_state.dart';
import '../../../data/models/lumi.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/entrance.dart';
import '../../widgets/journal/journal_style.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import 'garden_defs.dart';
import 'widgets/garden_common.dart';
import 'widgets/garden_hud.dart';
import 'widgets/shop_widgets.dart';

/// Tienda del jardín: vitrinas con las ilustraciones y su aura de rareza,
/// detalle de cada item y compra con semillas.
class ShopScreen extends StatefulWidget {
  /// Solo para pruebas: muestra este estado sin Firebase.
  @visibleForTesting
  final GardenState? previewState;

  const ShopScreen({super.key, this.previewState});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  ItemType _category = ItemType.plant;
  final Map<String, int> _bursts = {};
  int _burstSeq = 0;

  static final _categoryIcons = {
    ItemType.plant: GardenCatalog.findById('plant_clover')!,
    ItemType.decoration: GardenCatalog.findById('deco_lantern')!,
    ItemType.booster: GardenCatalog.findById('boost_water')!,
  };

  List<GardenItem> _itemsOf(ItemType type) => switch (type) {
    ItemType.plant => GardenCatalog.allPlants,
    ItemType.decoration => GardenCatalog.allDecorations,
    ItemType.booster => GardenCatalog.allBoosters,
    ItemType.theme => const [],
  };

  void _select(ItemType type) {
    if (type == _category) return;
    SoundService.instance.play(Sfx.tapNode, volume: 0.4);
    setState(() => _category = type);
  }

  Future<bool> _buy(GardenItem item, GardenProvider garden) async {
    HapticFeedback.mediumImpact();
    final (ok, error) = await garden.buyItem(item);
    if (!mounted) return false;
    if (ok) {
      SoundService.instance.play(Sfx.buy, volume: 0.6);
      Future.delayed(const Duration(milliseconds: 180), () => SoundService.instance.shine(RarityStyle.shine(item.rarity), volume: 0.4));
      AnalyticsService.instance.gardenAction('buy', itemId: item.id);
      setState(() => _bursts[item.id] = ++_burstSeq);
      GardenToast.show(
        context,
        text: 'garden.purchaseSuccess'.tr(),
        leading: GardenItemImage(item: item, size: 30, aura: false),
      );
    } else {
      SoundService.instance.play(Sfx.wrong, volume: 0.45);
      GardenToast.show(context, text: error ?? 'garden.notEnoughSeeds'.tr(), color: const Color(0xFFDC6B4A));
    }
    return ok;
  }

  Future<void> _open(GardenItem item) async {
    SoundService.instance.shine(RarityStyle.shine(item.rarity), volume: 0.45);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.9),
        child: Consumer<GardenProvider>(
          builder: (_, garden, _) =>
              ShopItemDetail(item: item, owned: () => garden.state.quantityOf(item.id), seeds: () => garden.seeds, onBuy: () => _buy(item, garden)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = GardenPalette(isDark);
    final GardenState state = widget.previewState ?? context.watch<GardenProvider>().state;
    final items = _itemsOf(_category);
    final forSeeds = items.where((i) => shopAvailabilityOf(i) == ShopAvailability.seeds).toList();
    final premium = items.where((i) => shopAvailabilityOf(i) == ShopAvailability.premium).toList();
    final seasonal = items.where((i) => shopAvailabilityOf(i) == ShopAvailability.seasonalLocked).toList();

    Widget grid(List<GardenItem> list, int sectionIndex) => SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 230, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 238),
        delegate: SliverChildBuilderDelegate((context, i) {
          final item = list[i];
          return ListEntrance(
            key: ValueKey('in_${_category.name}_${item.id}'),
            index: i,
            step: const Duration(milliseconds: 50),
            base: Duration(milliseconds: 40 * sectionIndex),
            duration: const Duration(milliseconds: 320),
            slideY: 0.12,
            child: ShopItemCard(
              key: ValueKey(item.id),
              item: item,
              owned: state.quantityOf(item.id),
              seeds: state.seeds,
              isDark: isDark,
              purchaseBurst: _bursts[item.id] ?? 0,
              onOpen: () => _open(item),
              onBuy: () => _buy(item, context.read<GardenProvider>()),
            ),
          );
        }, childCount: list.length),
      ),
    );

    final background = isDark ? const Color(0xFF0F1A15) : const Color(0xFFF6F1E4);
    final top = MediaQuery.viewPaddingOf(context).top;

    return Scaffold(
      backgroundColor: background,
      body: EntranceScope(
        // Al cambiar de categoría la cuadrícula se rehace: ahí sí escalona.
        restartOn: _category,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _ShopHeader(seeds: state.seeds, isDark: isDark, line: _lumiLine(state.seeds)),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedCategories(
                    background: background,
                    topInset: top,
                    child: ShopCategoryBar(
                      isDark: isDark,
                      selected: _category,
                      onSelect: _select,
                      categories: [
                        (ItemType.plant, _categoryIcons[ItemType.plant]!, 'garden.categories.plants'.tr()),
                        (ItemType.decoration, _categoryIcons[ItemType.decoration]!, 'garden.categories.decorations'.tr()),
                        (ItemType.booster, _categoryIcons[ItemType.booster]!, 'garden.categories.boosters'.tr()),
                      ],
                    ),
                  ),
                ),
                if (forSeeds.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                      child: ShopSectionTitle(kicker: 'garden.shopSeedsKicker'.tr(), title: 'garden.shopSeedsTitle'.tr(), isDark: isDark),
                    ),
                  ),
                  grid(forSeeds, 0),
                ],
                if (premium.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                      child: ShopSectionTitle(
                        kicker: 'garden.shopPremiumKicker'.tr(),
                        title: 'garden.categories.premium'.tr(),
                        isDark: isDark,
                        color: GardenPalette.violet,
                      ),
                    ),
                  ),
                  grid(premium, 1),
                ],
                if (seasonal.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                      child: ShopSectionTitle(
                        kicker: 'garden.shopSeasonalKicker'.tr(),
                        title: 'garden.seasonal'.tr(),
                        isDark: isDark,
                        color: const Color(0xFFEC4899),
                      ),
                    ),
                  ),
                  grid(seasonal, 2),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 24, 24, 28 + MediaQuery.viewPaddingOf(context).bottom),
                    child: Text(
                      'garden.shopFooter'.tr(),
                      textAlign: TextAlign.center,
                      style: JournalStyle.hand(TextStyle(fontSize: 18, color: p.inkSoft)),
                    ),
                  ),
                ),
              ],
            ),
        ],
        ),
      ),
    );
  }

  LumiLine _lumiLine(int seeds) {
    final cheapest = _itemsOf(
      _category,
    ).where((i) => shopAvailabilityOf(i) == ShopAvailability.seeds).fold<int?>(null, (m, i) => m == null || i.seedCost < m ? i.seedCost : m);
    if (cheapest != null && seeds < cheapest) {
      return const LumiLine('garden.shopLumi.save', LumiMood.caring);
    }
    return switch (_category) {
      ItemType.decoration => const LumiLine('garden.shopLumi.decorations', LumiMood.curious),
      ItemType.booster => const LumiLine('garden.shopLumi.boosters', LumiMood.excited),
      _ => const LumiLine('garden.shopLumi.plants', LumiMood.happy),
    };
  }
}

/// Encabezado ilustrado: el invernadero de fondo, las semillas y Lumi.
class _ShopHeader extends StatelessWidget {
  final int seeds;
  final bool isDark;
  final LumiLine line;

  const _ShopHeader({required this.seeds, required this.isDark, required this.line});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: SizedBox(
        height: 230 + top,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              GardensCatalog.greenhouse.assetPath,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.2),
              cacheWidth:
                  decodePixels(context, MediaQuery.sizeOf(context).width),
              errorBuilder: (_, _, _) => Container(color: GardensCatalog.greenhouse.tint),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: isDark ? 0.45 : 0.2),
                    const Color(0xFF0E1A14).withValues(alpha: isDark ? 0.85 : 0.65),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(8, top + 4, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GlassIconButton(icon: Icons.arrow_back_rounded, label: 'common.back'.tr(), onTap: () => Navigator.pop(context)),
                      const Spacer(),
                      GlassPanel(
                        padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
                        radius: 20,
                        borderColor: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                        child: SeedCounter(seeds: seeds, iconSize: 28),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('garden.shopKicker'.tr(), style: JournalStyle.hand(const TextStyle(fontSize: 22, height: 1.0, color: Color(0xFFA7F3D0)))),
                              Semantics(
                                header: true,
                                child: Text(
                                  'garden.shopTitle'.tr(),
                                  style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  key: ValueKey(line.key),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(4),
                                    ),
                                  ),
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      line.key.tr(),
                                      style: const TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600, color: Color(0xFF26332B)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      LumiAvatar(mood: line.mood, size: 78, onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

class _PinnedCategories extends SliverPersistentHeaderDelegate {
  final Widget child;
  final Color background;

  /// Alto de la barra de estado: al quedar fija arriba no se mete debajo.
  final double topInset;

  _PinnedCategories({required this.child, required this.background, required this.topInset});

  @override
  double get minExtent => 78 + topInset;

  @override
  double get maxExtent => 78 + topInset;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: background, padding: EdgeInsets.fromLTRB(16, 4 + topInset, 16, 4), alignment: Alignment.center, child: child);
  }

  @override
  bool shouldRebuild(_PinnedCategories old) => true;
}
