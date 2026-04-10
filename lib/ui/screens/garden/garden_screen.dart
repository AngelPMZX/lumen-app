import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/garden_item.dart';
import '../../../data/models/garden_state.dart';
import '../../../domain/providers/garden_provider.dart';
import 'shop_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
// GARDEN SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen>
    with TickerProviderStateMixin {

  late AnimationController _bgCtrl;
  late AnimationController _glowCtrl;

  // Grid: 4 columnas × 3 filas = 12 posiciones
  static const int _cols = 4;
  static const int _rows = 3;

  // Estado de selección
  String? _selectedInstanceId;   // planta seleccionada
  bool _isPlantingMode = false;   // modo "elige dónde plantar"
  String? _itemToPlant;           // item del inventario a plantar

  // Timer para actualizar etapas de crecimiento
  late AnimationController _growthTickCtrl;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Ticker cada 60 seg para refrescar etapas de crecimiento
    _growthTickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GardenProvider>().loadGarden();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _glowCtrl.dispose();
    _growthTickCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(isDark),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(isDark),
                Expanded(
                  child: Consumer<GardenProvider>(
                    builder: (_, garden, __) {
                      if (garden.isLoading) return _buildLoading();
                      return _buildContent(garden, isDark);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ─────────────────────────────────────────────────────────────

  Widget _buildBackground(bool isDark) {
    return AnimatedBuilder(
      animation: _bgCtrl,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0A1628),
                    Color.lerp(const Color(0xFF0D2137),
                        const Color(0xFF0A2B1E), _bgCtrl.value)!,
                    const Color(0xFF0A1628),
                  ]
                : [
                    const Color(0xFFE8F5E9),
                    Color.lerp(const Color(0xFFF1F8E9),
                        const Color(0xFFE3F2FD), _bgCtrl.value)!,
                    const Color(0xFFF9FBE7),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Círculos de ambiente
            Positioned(
              top: -80, right: -60,
              child: Container(
                width: 280, height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    (isDark
                        ? const Color(0xFF10B981)
                        : const Color(0xFF4CAF50)).withOpacity(0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: -60, left: -40,
              child: Container(
                width: 220, height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    (isDark
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF81C784)).withOpacity(0.07),
                    Colors.transparent,
                  ]),
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
    return Consumer<GardenProvider>(
      builder: (_, garden, __) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          children: [
            // Back
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

            // Título
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('garden.title'.tr(), style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A2E1A),
                  )),
                  Text('garden.subtitle'.tr(), style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black38,
                  )),
                ],
              ),
            ),

            // Semillas badge
            _buildSeedsBadge(garden.seeds, isDark),
            const SizedBox(width: 10),

            // Shop button
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ShopScreen())),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Color(0xFF10B981), size: 20),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSeedsBadge(int seeds, bool isDark) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF10B981)
                .withOpacity(0.2 + _glowCtrl.value * 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981)
                  .withOpacity(0.05 + _glowCtrl.value * 0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('✨', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text('$seeds', style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 14, fontWeight: FontWeight.w800,
          )),
        ]),
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF10B981)),
    );
  }

  // ── Content ────────────────────────────────────────────────────────────────

  Widget _buildContent(GardenProvider garden, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        children: [
          // Modo plantación banner
          if (_isPlantingMode) _buildPlantingBanner(isDark),

          // Grid del jardín
          _buildGardenGrid(garden, isDark),
          const SizedBox(height: 20),

          // Panel de planta seleccionada
          if (_selectedInstanceId != null)
            _buildPlantPanel(garden, isDark),

          // Inventario
          _buildInventorySection(garden, isDark),
        ],
      ),
    );
  }

  // ── Planting mode banner ───────────────────────────────────────────────────

  Widget _buildPlantingBanner(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
      ),
      child: Row(children: [
        const Text('🌱', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text('garden.plantHere'.tr(), style: const TextStyle(
          color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 14,
        ))),
        GestureDetector(
          onTap: _cancelPlanting,
          child: const Icon(Icons.close_rounded,
              color: Color(0xFF10B981), size: 20),
        ),
      ]),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  // ── Garden grid ────────────────────────────────────────────────────────────

  Widget _buildGardenGrid(GardenProvider garden, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFF81C784).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(isDark ? 0.05 : 0.08),
            blurRadius: 20, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_rows, (row) => Padding(
          padding: EdgeInsets.only(bottom: row < _rows - 1 ? 8 : 0),
          child: Row(
            children: List.generate(_cols, (col) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: col < _cols - 1 ? 8 : 0),
                child: _buildGridCell(garden, col, row, isDark),
              ),
            )),
          ),
        )),
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 500.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _buildGridCell(
      GardenProvider garden, int x, int y, bool isDark) {
    // ¿Tiene algo plantado?
    PlantedItem? planted;
    try {
      planted = garden.garden.firstWhere(
          (p) => p.gridX == x && p.gridY == y);
    } catch (_) {
      planted = null;
    }

    final isSelected = planted != null &&
        planted.instanceId == _selectedInstanceId;

    if (planted != null) {
      return _buildOccupiedCell(planted, isSelected, garden, isDark);
    }

    return _buildEmptyCell(x, y, isDark);
  }

  Widget _buildEmptyCell(int x, int y, bool isDark) {
    final canPlant = _isPlantingMode && _itemToPlant != null;

    return GestureDetector(
      onTap: canPlant ? () => _plantAt(x, y) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 80,
        decoration: BoxDecoration(
          color: canPlant
              ? const Color(0xFF10B981).withOpacity(0.12)
              : isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canPlant
                ? const Color(0xFF10B981).withOpacity(0.5)
                : isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06),
            width: canPlant ? 2 : 1,
          ),
        ),
        child: canPlant
            ? const Center(child: Text('➕', style: TextStyle(fontSize: 24)))
            : Center(child: Icon(Icons.add_rounded,
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.12),
                size: 20)),
      ),
    );
  }

  Widget _buildOccupiedCell(
      PlantedItem planted, bool isSelected,
      GardenProvider garden, bool isDark) {
    final item = GardenCatalog.findById(planted.itemId);
    if (item == null) return const SizedBox.shrink();

    final stage = planted.currentStage(item);
    final progress = planted.growthProgress(item);
    final emoji = planted.currentEmoji(item);
    final isAdult = planted.isAdult(item);

    return GestureDetector(
      onTap: () {
        if (_isPlantingMode) return;
        HapticFeedback.lightImpact();
        setState(() {
          _selectedInstanceId =
              isSelected ? null : planted.instanceId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 80,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF10B981).withOpacity(0.15)
              : isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF10B981)
                : isAdult
                    ? const Color(0xFF10B981).withOpacity(0.4)
                    : isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isAdult ? [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.15),
              blurRadius: 8,
            ),
          ] : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Emoji de la planta
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: TextStyle(
                  fontSize: stage == PlantStage.seed ? 20
                      : stage == PlantStage.sprout ? 24
                      : stage == PlantStage.young ? 28 : 32,
                ))
                    .animate(onPlay: (c) => isAdult
                        ? c.repeat(reverse: true) : null)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1.05, 1.05),
                      duration: 2000.ms,
                      curve: Curves.easeInOut,
                    ),
                if (!isAdult) ...[
                  const SizedBox(height: 4),
                  // Barra de progreso mini
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: Colors.black.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(
                        _stageColor(stage),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Badge de etapa
            if (!isAdult)
              Positioned(
                top: 4, right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: _stageColor(stage).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _stageLabel(stage),
                    style: const TextStyle(
                        fontSize: 7, color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),

            // Checkmark si adulta
            if (isAdult)
              Positioned(
                top: 4, right: 4,
                child: Container(
                  width: 16, height: 16,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _stageColor(PlantStage stage) {
    switch (stage) {
      case PlantStage.seed:   return const Color(0xFF92400E);
      case PlantStage.sprout: return const Color(0xFF15803D);
      case PlantStage.young:  return const Color(0xFF16A34A);
      case PlantStage.adult:  return const Color(0xFF10B981);
    }
  }

  String _stageLabel(PlantStage stage) {
    return 'garden.stage.${stage.name}'.tr();
  }

  // ── Plant info panel ───────────────────────────────────────────────────────

  Widget _buildPlantPanel(GardenProvider garden, bool isDark) {
    PlantedItem? planted;
    try {
      planted = garden.garden.firstWhere(
          (p) => p.instanceId == _selectedInstanceId);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final item = GardenCatalog.findById(planted.itemId);
    if (item == null) return const SizedBox.shrink();

    final stage = planted.currentStage(item);
    final isAdult = planted.isAdult(item);
    final timeLeft = planted.timeRemaining(item);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF10B981).withOpacity(0.08)
            : const Color(0xFF10B981).withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(children: [
            Text(planted.currentEmoji(item),
                style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nameKey.tr(), style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A2E1A),
                )),
                Text(item.descriptionKey.tr(), style: TextStyle(
                  fontSize: 12, height: 1.4,
                  color: isDark ? Colors.white54 : Colors.black45,
                )),
              ],
            )),
            // Quitar planta
            GestureDetector(
              onTap: () => _confirmRemovePlant(planted!.instanceId, item),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 16),
              ),
            ),
          ]),

          const SizedBox(height: 14),

          // Progreso / estado
          if (isAdult)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Text('🌸', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text('garden.fullyGrown'.tr(), style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 13, fontWeight: FontWeight.w700,
                )),
              ]),
            )
          else ...[
            // Etapa actual
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('garden.growthProgress'.tr(), style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black45,
                )),
                Text(
                  _formatTimeRemaining(timeLeft),
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: _stageColor(stage),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: planted.growthProgress(item),
                minHeight: 10,
                backgroundColor: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation(_stageColor(stage)),
              ),
            ),
            const SizedBox(height: 8),
            // Etapas visuales
            _buildStageIndicator(planted, item, isDark),
          ],

          // Boosters disponibles
          if (!isAdult) ...[
            const SizedBox(height: 14),
            _buildBoosterRow(planted, garden, isDark),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildStageIndicator(
      PlantedItem planted, GardenItem item, bool isDark) {
    final current = planted.currentStage(item);
    final stages = PlantStage.values;

    return Row(
      children: stages.asMap().entries.map((e) {
        final stage = e.value;
        final isPast = stage.index < current.index;
        final isCurrent = stage == current;
        final emoji = item.stageEmojis?[stage] ?? '🌱';

        return Expanded(
          child: Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 4,
              decoration: BoxDecoration(
                color: isPast || isCurrent
                    ? _stageColor(stage)
                    : isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Opacity(
  opacity: isPast || isCurrent ? 1.0 : 0.3,
  child: Text(emoji, style: TextStyle(
      fontSize: isCurrent ? 16 : 12)),
),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildBoosterRow(
      PlantedItem planted, GardenProvider garden, bool isDark) {
    final boosters = GardenCatalog.allBoosters
        .where((b) => garden.state.hasInInventory(b.id))
        .toList();

    if (boosters.isEmpty) {
      return Text(
        '💧 ${'garden.boostersHint'.tr()}',
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('garden.applyBooster'.tr(), style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white60 : Colors.black54,
        )),
        const SizedBox(height: 8),
        Row(
          children: boosters.map((booster) {
            final qty = garden.state.quantityOf(booster.id);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => _applyBooster(booster.id, planted.instanceId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(booster.emoji,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text('×$qty', style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12, fontWeight: FontWeight.w700,
                    )),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Inventory section ──────────────────────────────────────────────────────

  Widget _buildInventorySection(GardenProvider garden, bool isDark) {
    final plants = garden.inventory
        .where((i) {
          final item = GardenCatalog.findById(i.itemId);
          return item != null && item.type == ItemType.plant;
        })
        .toList();

    final decorations = garden.inventory
        .where((i) {
          final item = GardenCatalog.findById(i.itemId);
          return item != null && item.type == ItemType.decoration;
        })
        .toList();

    if (garden.inventory.isEmpty) {
      return _buildEmptyInventory(isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('garden.inventory'.tr(), style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF1A2E1A),
        )),
        const SizedBox(height: 12),

        if (plants.isNotEmpty) ...[
          _buildInventoryCategory(
              'garden.categories.plants'.tr(), plants, garden, isDark),
          const SizedBox(height: 12),
        ],

        if (decorations.isNotEmpty)
          _buildInventoryCategory(
              'garden.categories.decorations'.tr(),
              decorations, garden, isDark),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildEmptyInventory(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(children: [
        const Text('🪴', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text('garden.inventoryEmpty'.tr(), style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : Colors.black54,
        )),
        const SizedBox(height: 4),
        Text('garden.inventoryEmptyDesc'.tr(), style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white38 : Colors.black38,
        ), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ShopScreen())),
          icon: const Icon(Icons.storefront_rounded, size: 18),
          label: Text('garden.shop'.tr()),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ]),
    );
  }

  Widget _buildInventoryCategory(
      String label,
      List<InventoryItem> items,
      GardenProvider garden,
      bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white54 : Colors.black45,
        )),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final inv = items[i];
            final item = GardenCatalog.findById(inv.itemId)!;
            final isBeingPlanted = _itemToPlant == inv.itemId;

            return GestureDetector(
              onTap: () => _selectItemToPlant(inv.itemId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isBeingPlanted
                      ? const Color(0xFF10B981).withOpacity(0.15)
                      : isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isBeingPlanted
                        ? const Color(0xFF10B981)
                        : isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
                    width: isBeingPlanted ? 2 : 1,
                  ),
                  boxShadow: isDark ? null : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(item.nameKey.tr(), style: TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ), textAlign: TextAlign.center, maxLines: 2),
                    if (inv.quantity > 1) ...[
                      const SizedBox(height: 2),
                      Text('×${inv.quantity}', style: const TextStyle(
                        fontSize: 9, color: Color(0xFF10B981),
                        fontWeight: FontWeight.w700,
                      )),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════════════════════════════════════

  void _selectItemToPlant(String itemId) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_itemToPlant == itemId && _isPlantingMode) {
        _cancelPlanting();
      } else {
        _itemToPlant = itemId;
        _isPlantingMode = true;
        _selectedInstanceId = null;
      }
    });
  }

  void _cancelPlanting() {
    setState(() {
      _isPlantingMode = false;
      _itemToPlant = null;
    });
  }

  Future<void> _plantAt(int x, int y) async {
    if (_itemToPlant == null) return;
    HapticFeedback.mediumImpact();

    final garden = context.read<GardenProvider>();
    final (success, error) = await garden.plantItem(_itemToPlant!, x, y);

    if (success) {
      _cancelPlanting();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Text('🌱', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('garden.plant'.tr(),
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ));
      }
    } else if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  Future<void> _applyBooster(
      String boosterId, String plantInstanceId) async {
    HapticFeedback.mediumImpact();
    final garden = context.read<GardenProvider>();
    final (success, error) =
        await garden.applyBooster(boosterId, plantInstanceId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          Text(success ? '✨' : '❌',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            success
                ? 'garden.boosterApplied'.tr()
                : (error ?? 'Error'),
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w600),
          ),
        ]),
        backgroundColor: success
            ? const Color(0xFF10B981) : Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _confirmRemovePlant(
      String instanceId, GardenItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Text(item.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Text(item.nameKey.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        content: Text('garden.remove'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<GardenProvider>().removePlant(instanceId);
      setState(() => _selectedInstanceId = null);
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatTimeRemaining(Duration? duration) {
    if (duration == null || duration == Duration.zero) return '';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return 'garden.timeRemaining'.tr(
          namedArgs: {'hours': '$hours', 'minutes': '$minutes'});
    }
    return 'garden.timeRemainingMinutes'.tr(
        namedArgs: {'minutes': '$minutes'});
  }
}

// Extensión para opacity en Text
extension on Widget {
  Widget opacity(double value) => Opacity(opacity: value, child: this);
}