import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../data/models/garden_item.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../widgets/aura_container.dart';
import '../../widgets/seed_icon.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SHOP SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabCtrl;
  static const _tabs = [
    ItemType.plant,
    ItemType.decoration,
    ItemType.booster,
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

// ── Helper: imagen del item (PNG real con fallback a emoji + aura) ─────────

Widget _itemVisual(GardenItem item, {double size = 32}) {
  Widget baseVisual;

  if (item.type == ItemType.plant) {
    final name = item.id.replaceFirst('plant_', '');
    baseVisual = Image.asset(
      'assets/images/plants/${name}_4_adult.png',
      width: size, height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/images/plants/${name}_1_seed.png',
        width: size, height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Text(item.emoji, style: TextStyle(fontSize: size * 0.8)),
      ),
    );
  } else if (item.type == ItemType.decoration) {
    final name = item.id.replaceFirst('deco_', '');
    baseVisual = Image.asset(
      'assets/images/decorations/$name.png',
      width: size, height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Text(item.emoji, style: TextStyle(fontSize: size * 0.8)),
    );
  } else if (item.type == ItemType.booster) {
    final name = item.id.replaceFirst('boost_', '');
    baseVisual = Image.asset(
      'assets/images/boosters/$name.png',
      width: size, height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Text(item.emoji, style: TextStyle(fontSize: size * 0.8)),
    );
  } else {
    baseVisual = Text(item.emoji, style: TextStyle(fontSize: size * 0.8));
  }

  // Envolver con aura por color/rareza
  return AuraContainer(
    item: item,
    sizeMultiplier: size / 32,
    child: SizedBox(
      width: size, height: size,
      child: baseVisual,
    ),
  );
}

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A1628)
          : const Color(0xFFF1F8F1),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isDark),
            _buildTabBar(isDark),
            Expanded(
              child: Consumer<GardenProvider>(
                builder: (_, garden, __) => TabBarView(
                  controller: _tabCtrl,
                  children: _tabs.map((type) =>
                      _buildItemGrid(type, garden, isDark)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────

  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: isDark ? Colors.white70 : Colors.black54, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text('garden.shopTitle'.tr(), style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1A2E1A),
          )),
        ),
        Consumer<GardenProvider>(
          builder: (_, garden, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const SeedIcon(size: 24),
const SizedBox(width: 6),
              Text('${garden.seeds}', style: const TextStyle(
                color: Color(0xFF10B981),
                fontSize: 14, fontWeight: FontWeight.w800,
              )),
            ]),
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ── Tab bar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar(bool isDark) {
    final labels = [
      'garden.categories.plants'.tr(),
      'garden.categories.decorations'.tr(),
      'garden.categories.boosters'.tr(),
    ];
    final icons = ['🌱', '🪨', '💧'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
  controller: _tabCtrl,
  indicator: BoxDecoration(
    color: const Color(0xFF10B981),
    borderRadius: BorderRadius.circular(13),
  ),
  indicatorSize: TabBarIndicatorSize.tab,
  dividerColor: Colors.transparent,
  labelColor: Colors.white,
  unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
  labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
  labelPadding: EdgeInsets.zero,   // ← elimina el padding lateral por defecto
  tabs: List.generate(labels.length, (i) => Tab(
    height: 48,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icons[i], style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            labels[i],
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  )),
),
      ),
    );
  }

  // ── Item grid ──────────────────────────────────────────────────────────────

  Widget _buildItemGrid(ItemType type, GardenProvider garden, bool isDark) {
    final items = _getItemsByType(type);

    if (items.isEmpty) return _buildEmptyCategory(isDark);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const SizedBox(height: 8),
        ...items
            .where((i) => i.canBuyWithSeeds && i.isCurrentlyAvailable)
            .map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildItemCard(item, garden, isDark)
                  .animate(delay: (items.indexOf(item) * 60).ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.05, end: 0),
            )),

        if (items.any((i) => i.isPremium)) ...[
          const SizedBox(height: 8),
          _buildPremiumHeader(isDark),
          const SizedBox(height: 12),
          ...items
              .where((i) => i.isPremium)
              .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPremiumCard(item, garden, isDark),
              )),
        ],

        if (items.any((i) => i.isSeasonal && !i.isCurrentlyAvailable)) ...[
          const SizedBox(height: 8),
          _buildSeasonalHeader(isDark),
          const SizedBox(height: 12),
          ...items
              .where((i) => i.isSeasonal && !i.isCurrentlyAvailable)
              .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildLockedSeasonalCard(item, isDark),
              )),
        ],
      ],
    );
  }

  List<GardenItem> _getItemsByType(ItemType type) {
    switch (type) {
      case ItemType.plant:      return GardenCatalog.allPlants;
      case ItemType.decoration: return GardenCatalog.allDecorations;
      case ItemType.booster:    return GardenCatalog.allBoosters;
      case ItemType.theme:      return [];
    }
  }

  // ── Item card (semillas) ───────────────────────────────────────────────────

  Widget _buildItemCard(GardenItem item, GardenProvider garden, bool isDark) {
    final canAfford = garden.state.canAfford(item);
    final alreadyOwned = garden.state.hasInInventory(item.id);
    final rarityColor = _rarityColor(item.rarity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: alreadyOwned
              ? const Color(0xFF10B981).withOpacity(0.3)
              : isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.07),
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        // ── Visual del item + badge de rareza ──────────────────────────
        Stack(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: rarityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: _itemVisual(item, size: 40)),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: rarityColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'garden.rarity.${item.rarity.name}'.tr(),
                style: const TextStyle(
                    fontSize: 7, color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ]),
        const SizedBox(width: 14),

        // ── Info ───────────────────────────────────────────────────────
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.nameKey.tr(), style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A2E1A),
            )),
            const SizedBox(height: 3),
            Text(item.descriptionKey.tr(), style: TextStyle(
              fontSize: 12, height: 1.4,
              color: isDark ? Colors.white54 : Colors.black45,
            ), maxLines: 2, overflow: TextOverflow.ellipsis),
            if (item.growthTime != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.schedule_rounded, size: 12,
                    color: isDark ? Colors.white38 : Colors.black38),
                const SizedBox(width: 3),
                Text(_formatDuration(item.growthTime!), style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                )),
              ]),
            ],
          ],
        )),
        const SizedBox(width: 12),

        // ── Botón comprar ──────────────────────────────────────────────
        alreadyOwned
            ? _buildOwnedBadge()
            : _buildBuyButton(item, canAfford, garden, isDark),
      ]),
    );
  }

  Widget _buildOwnedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 16),
    );
  }

  Widget _buildBuyButton(
    GardenItem item, bool canAfford, GardenProvider garden, bool isDark) {
  return GestureDetector(
    onTap: canAfford ? () => _buyItem(item, garden) : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: canAfford
            ? const Color(0xFF10B981)
            : isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const SeedIcon(size: 22),
        const SizedBox(width: 6),
        Text('${item.seedCost}', style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w800,
          color: canAfford ? Colors.white : Colors.grey,
        )),
      ]),
    ),
  );
}

  // ── Premium card ───────────────────────────────────────────────────────────

  Widget _buildPremiumCard(GardenItem item, GardenProvider garden, bool isDark) {
    final alreadyPurchased = garden.state.hasPurchased(item.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isDark
            ? [const Color(0xFF1A1A3E), const Color(0xFF2D1B69).withOpacity(0.5)]
            : [const Color(0xFFF5F0FF), const Color(0xFFEDE9FE)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
      ),
      child: Row(children: [
        // ── Visual del item ────────────────────────────────────────────
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(child: _itemVisual(item, size: 40)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(item.nameKey.tr(), style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              )),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('PRO', style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w900,
                  color: Color(0xFF8B5CF6),
                )),
              ),
            ]),
            const SizedBox(height: 3),
            Text(item.descriptionKey.tr(), style: TextStyle(
              fontSize: 12, height: 1.4,
              color: isDark ? Colors.white54 : Colors.black45,
            ), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        )),
        const SizedBox(width: 12),
        alreadyPurchased
            ? _buildOwnedBadge()
            : GestureDetector(
                onTap: () => _showPremiumComingSoon(item),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${item.premiumCost?.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
      ]),
    );
  }

  // ── Seasonal locked card ───────────────────────────────────────────────────

  Widget _buildLockedSeasonalCard(GardenItem item, bool isDark) {
    final monthName = _monthName(item.availableMonth ?? 12);

    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(children: [
          // ── Visual con lock overlay ────────────────────────────────
          Stack(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: _itemVisual(item, size: 40)),
            ),
            Positioned.fill(child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
            )),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.nameKey.tr(), style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : Colors.black54,
              )),
              const SizedBox(height: 3),
              Text(
                'garden.seasonalLocked'.tr(namedArgs: {'month': monthName}),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('garden.seasonal'.tr(), style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white38 : Colors.black38,
            )),
          ),
        ]),
      ),
    );
  }

  // ── Section headers ────────────────────────────────────────────────────────

  Widget _buildPremiumHeader(bool isDark) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('💎', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text('garden.categories.premium'.tr(), style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white,
          )),
        ]),
      ),
      const SizedBox(width: 10),
      Expanded(child: Divider(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.08),
      )),
    ]);
  }

  Widget _buildSeasonalHeader(bool isDark) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('📅', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text('garden.seasonal'.tr(), style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white54 : Colors.black45,
          )),
        ]),
      ),
      const SizedBox(width: 10),
      Expanded(child: Divider(
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.08),
      )),
    ]);
  }

  Widget _buildEmptyCategory(bool isDark) {
    return Center(
      child: Text('garden.inventoryEmpty'.tr(), style: TextStyle(
        color: isDark ? Colors.white38 : Colors.black38,
      )),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _buyItem(GardenItem item, GardenProvider garden) async {
    HapticFeedback.mediumImpact();
    final (success, error) = await garden.buyItem(item);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        SizedBox(
          width: 28, height: 28,
          child: _itemVisual(item, size: 22),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(
          success
              ? 'garden.purchaseSuccess'.tr()
              : (error ?? 'garden.notEnoughSeeds'.tr()),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        )),
      ]),
      backgroundColor: success ? const Color(0xFF10B981) : Colors.red.shade400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showPremiumComingSoon(GardenItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          SizedBox(width: 32, height: 32, child: _itemVisual(item, size: 28)),
          const SizedBox(width: 10),
          Text(item.nameKey.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        content: Text('common.comingSoon'.tr()),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _rarityColor(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:    return const Color(0xFF6366F1);
      case ItemRarity.rare:      return const Color(0xFF3B82F6);
      case ItemRarity.epic:      return const Color(0xFF8B5CF6);
      case ItemRarity.legendary: return const Color(0xFFF59E0B);
      case ItemRarity.seasonal:  return const Color(0xFFEC4899);
    }
  }

  String _formatDuration(Duration d) {
    if (d.inHours >= 24) return '${d.inDays}d';
    if (d.inHours >= 1)  return '${d.inHours}h';
    return '${d.inMinutes}min';
  }

  String _monthName(int month) => 'garden.months.$month'.tr();
}