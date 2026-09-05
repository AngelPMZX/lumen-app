import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/achievement.dart';
import '../../../data/models/garden_mechanics.dart';
import '../../../data/models/garden_item.dart';
import '../../../data/models/garden_state.dart';
import '../../../domain/providers/garden_provider.dart';
import 'shop_screen.dart';
import 'package:gimnasio_emocional/domain/services/notification_service.dart';
import '../../widgets/aura_container.dart';
import '../../widgets/seed_icon.dart';

// ═════════════════════════════════════════════════════════════════════════════
// GARDEN CONFIG — slots hardcodeados por jardín
// ═════════════════════════════════════════════════════════════════════════════

/// Definición de un jardín: fondo, slots disponibles, nombre.
/// Las coordenadas son fracciones (0.0–1.0) del tamaño del fondo renderizado.
/// anchorX/anchorY = centro del slot en el fondo.
class GardenDef {
  final String id;
  final String nameKey;
  final String assetPath;
  final List<GardenSlot> slots;
  final bool isUnlocked;

  const GardenDef({
    required this.id,
    required this.nameKey,
    required this.assetPath,
    required this.slots,
    this.isUnlocked = false,
  });
}

class GardenSlot {
  final int slotIndex;    // índice único dentro del jardín
  final double anchorX;   // fracción 0.0–1.0 del ancho del fondo
  final double anchorY;   // fracción 0.0–1.0 del alto del fondo
  final double plantScale; // escala extra para la planta (1.0 = normal)

  const GardenSlot({
    required this.slotIndex,
    required this.anchorX,
    required this.anchorY,
    this.plantScale = 1.0,
  });
}

// ── Catálogo de jardines ──────────────────────────────────────────────────────

class GardensCatalog {
  GardensCatalog._();

  static const GardenDef meadow = GardenDef(
    id: 'meadow',
    nameKey: 'garden.gardens.meadow',
    assetPath: 'assets/images/gardens/garden_meadow.png',
    isUnlocked: true,
    slots: [
      GardenSlot(slotIndex: 0, anchorX: 0.3542, anchorY: 0.2990),
      GardenSlot(slotIndex: 1, anchorX: 0.7942, anchorY: 0.3734),
      GardenSlot(slotIndex: 2, anchorX: 0.1642, anchorY: 0.4637),
      GardenSlot(slotIndex: 3, anchorX: 0.5742, anchorY: 0.5446),
      GardenSlot(slotIndex: 4, anchorX: 0.2525, anchorY: 0.6683),
      GardenSlot(slotIndex: 5, anchorX: 0.7658, anchorY: 0.7883),
    ],
  );

  static const GardenDef mountain = GardenDef(
    id: 'mountain',
    nameKey: 'garden.gardens.mountain',
    assetPath: 'assets/images/gardens/garden_mountain.png',
    isUnlocked: true,
    slots: [
      GardenSlot(slotIndex: 0, anchorX: 0.3292, anchorY: 0.4023),
      GardenSlot(slotIndex: 1, anchorX: 0.7275, anchorY: 0.4190),
      GardenSlot(slotIndex: 2, anchorX: 0.2942, anchorY: 0.5204),
      GardenSlot(slotIndex: 3, anchorX: 0.7042, anchorY: 0.5772),
      GardenSlot(slotIndex: 4, anchorX: 0.7208, anchorY: 0.7055),
      GardenSlot(slotIndex: 5, anchorX: 0.2875, anchorY: 0.7539),
    ],
  );

  // Jardines futuros — bloqueados
  static const GardenDef forest = GardenDef(
    id: 'forest',
    nameKey: 'garden.gardens.forest',
    assetPath: 'assets/images/gardens/garden_forest.png',
    isUnlocked: false,
    slots: [],
  );

  static const GardenDef lake = GardenDef(
    id: 'lake',
    nameKey: 'garden.gardens.lake',
    assetPath: 'assets/images/gardens/garden_lake.png',
    isUnlocked: false,
    slots: [],
  );

  static const GardenDef greenhouse = GardenDef(
    id: 'greenhouse',
    nameKey: 'garden.gardens.greenhouse',
    assetPath: 'assets/images/gardens/garden_greenhouse.png',
    isUnlocked: false,
    slots: [],
  );

  static const List<GardenDef> all = [
    meadow,
    mountain,
    forest,
    lake,
    greenhouse,
  ];

  static GardenDef get defaultGarden => meadow;
}

// ─── Helpers de asset path ────────────────────────────────────────────────────

String _plantAssetPath(String itemId, PlantStage stage) {
  // plant_clover → clover, plant_cactus → cactus, etc.
  final name = itemId.replaceFirst('plant_', '');
  final stageNum = stage.index + 1; // seed=1, sprout=2, young=3, adult=4
  return 'assets/images/plants/${name}_${stageNum}_${stage.name}.png';
}

/// Ruta del PNG de una decoración.
/// deco_zen_stone → assets/images/decorations/zen_stone.png
/// deco_lantern   → assets/images/decorations/lantern.png
String _decoAssetPath(String itemId) {
  final name = itemId.replaceFirst('deco_', '');
  return 'assets/images/decorations/$name.png';
}

/// Tamaño visual de cada decoración en el jardín (px lógicos).
/// Ajusta aquí si una decoración se ve demasiado pequeña o grande.
double _decoSize(String itemId) {
  switch (itemId) {
    case 'deco_zen_stone':  return 70.0;   // piedra — compacta
    case 'deco_lantern':    return 75.0;   // linterna — media
    case 'deco_fountain':   return 110.0;  // fuente — grande
    case 'deco_bridge':     return 130.0;  // puente — muy ancho
    default:                return 80.0;
  }
}

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

  // Jardín activo
  GardenDef _activeGarden = GardensCatalog.defaultGarden;

  // Planting mode (plantas en slots)
  bool _isPlantingMode = false;
  String? _itemToPlant;

  // Planta seleccionada para info panel
  String? _selectedInstanceId;

  // Decoraciones colocadas con drag & drop (fracción del fondo)
  // Cada entrada: {instanceId, itemId, fx, fy}
  final List<_PlacedDeco> _placedDecos = [];

  // Drag en curso
  String? _draggingDecoItemId;  // itemId siendo arrastrado desde inventario
  _PlacedDeco? _movingDeco;     // deco ya colocada siendo movida

  // Anims
  late AnimationController _idleCtrl;   // para balanceo de plantas adultas
  late AnimationController _glowCtrl;   // para el badge de semillas
  late AnimationController _growthTickCtrl;

  @override
  void initState() {
    super.initState();

    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _growthTickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final garden = context.read<GardenProvider>();
      await garden.loadGarden();
      // Verificar si hay cosecha pendiente y notificar
if (!mounted) return;
final hasPending = garden.garden.any((p) {
  final item = GardenCatalog.findById(p.itemId);
  return item != null && p.hasPendingHarvestFor(item);
});
if (hasPending) {
  NotificationService.instance.showHarvestReadyNotification();
}
      if (!mounted) return;
      await _loadDecoPositions(garden);
      // NO auto-cosecha — el usuario la inicia tocando la planta adulta
    });
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    _glowCtrl.dispose();
    _growthTickCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<GardenProvider>(
        builder: (_, garden, __) {
          if (garden.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF10B981)),
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              // ── 1. Fondo del jardín ──────────────────────────────────────
              _buildGardenBackground(garden),

              // ── 2. UI superpuesta ────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(garden),
                    // Panel de planta seleccionada (si hay)
                    if (_selectedInstanceId != null)
                      _buildPlantPanel(garden),
                    const Spacer(),
                    // Banner de modo plantación
                    if (_isPlantingMode)
                      _buildPlantingBanner(),
                    // Inventario
                    _buildInventoryDrawer(garden),
                  ],
                ),
              ),

              // ── 3. Barra lateral de accesos rápidos ──────────────────
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: SafeArea(child: _buildSidebar()),
              ),

              // ── 4. Cubre marca de agua (inf. derecha) ───────────────────
              Positioned(
                right: 0,
                bottom: 0,
                child: _buildWatermarkCover(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FONDO + SLOTS
  // ═══════════════════════════════════════════════════════════════════════════

  // ─── Dimensiones del PNG de fondo (todas las imágenes son 1536x2752) ────────
  static const double _bgNativeW = 1536;
  static const double _bgNativeH = 2752;

  /// Convierte las coordenadas (anchorX, anchorY) del PNG al espacio de pantalla.
  ///
  /// BoxFit.cover escala el PNG para que CUBRA el viewport manteniendo aspecto.
  /// Esto significa que parte del PNG puede quedar recortada.
  /// Este método calcula exactamente qué región del PNG es visible y en qué
  /// coordenadas de pantalla aparece cada punto del PNG.
  ///
  /// [anchorX], [anchorY] — fracción del PNG nativo (0..1)
  /// [viewW], [viewH]     — tamaño real del viewport en píxeles lógicos
  /// Retorna el offset en píxeles lógicos dentro del viewport.
  Offset _bgToScreen(double anchorX, double anchorY,
      double viewW, double viewH) {
    // Escala que aplica BoxFit.cover: la mayor de las dos escalas
    final scaleX = viewW / _bgNativeW;
    final scaleY = viewH / _bgNativeH;
    final scale  = scaleX > scaleY ? scaleX : scaleY;

    // Tamaño del PNG escalado
    final scaledW = _bgNativeW * scale;
    final scaledH = _bgNativeH * scale;

    // Offset de recorte: BoxFit.cover centra la imagen
    final offsetX = (viewW - scaledW) / 2;  // negativo = recortado
    final offsetY = (viewH - scaledH) / 2;

    // Posición en pantalla del punto (anchorX, anchorY) del PNG
    return Offset(
      offsetX + anchorX * scaledW,
      offsetY + anchorY * scaledH,
    );
  }

  Widget _buildGardenBackground(GardenProvider garden) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewW = constraints.maxWidth;
        final viewH = constraints.maxHeight;

        return DragTarget<String>(
          // Acepta drops de itemId de decoraciones
          onWillAcceptWithDetails: (details) {
            final itemId = details.data;
            final item = GardenCatalog.findById(itemId);
            return item != null && item.type == ItemType.decoration;
          },
          onAcceptWithDetails: (details) {
            final itemId = details.data;
            final localPos = details.offset;
            // Convertir posición de pantalla → fracción del fondo
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final localOffset = box.globalToLocal(localPos);
            final fx = (localOffset.dx / viewW).clamp(0.05, 0.95);
            final fy = (localOffset.dy / viewH).clamp(0.05, 0.95);
            _placeDecoration(itemId, fx, fy, viewW, viewH, garden);
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return Stack(
              fit: StackFit.expand,
              children: [
                // ── Fondo ──────────────────────────────────────────────
                Image.asset(
                  _activeGarden.assetPath,
                  fit: BoxFit.cover,
                  width: viewW,
                  height: viewH,
                ),

                // Overlay sutil cuando hay un drag activo
                if (isHovering)
                  Container(color: Colors.white.withOpacity(0.05)),

                // ── Decoraciones colocadas (drag para mover) ────────────
                ..._placedDecos
                    .where((d) => d.gardenId == _activeGarden.id)
                    .map((deco) {
                  final px = deco.fx * viewW;
                  final py = deco.fy * viewH;
                  final decoSize = _decoSize(deco.itemId);
                  return Positioned(
                    left: px - decoSize / 2,
                    top: py - decoSize / 2,
                    child: _buildPlacedDeco(deco, decoSize, viewW, viewH, garden),
                  );
                }),

                // ── Slots de plantas ────────────────────────────────────
                ..._activeGarden.slots.map((slot) {
                  PlantedItem? planted;
                  try {
                    planted = garden.garden.firstWhere(
                      (p) => p.gardenId == _activeGarden.id &&
                             p.slotIndex == slot.slotIndex,
                    );
                  } catch (_) {
                    planted = null;
                  }
                  final pos = _bgToScreen(
                      slot.anchorX, slot.anchorY, viewW, viewH);
                  final size = 140.0 * slot.plantScale;
                  return Positioned(
                    left: pos.dx - size / 2,
                    top:  pos.dy - size / 2,
                    width: size,
                    height: size,
                    child: _buildSlotWidget(slot, planted, garden),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  /// Construye el widget de una decoración ya colocada (draggable para mover)
  Widget _buildPlacedDeco(_PlacedDeco deco, double size,
      double viewW, double viewH, GardenProvider garden) {
    final item = GardenCatalog.findById(deco.itemId);
    if (item == null) return const SizedBox.shrink();
    final assetPath = _decoAssetPath(deco.itemId);

    return LongPressDraggable<_PlacedDeco>(
      data: deco,
      delay: const Duration(milliseconds: 300),
      feedback: Opacity(
        opacity: 0.75,
        child: SizedBox(
          width: size * 1.15,
          height: size * 1.15,
          child: Image.asset(assetPath, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Text(item.emoji, style: const TextStyle(fontSize: 36))),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: SizedBox(
          width: size, height: size,
          child: Image.asset(assetPath, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Text(item.emoji, style: const TextStyle(fontSize: 32))),
        ),
      ),
      onDragStarted: () => setState(() => _movingDeco = deco),
      onDragEnd: (_) => setState(() => _movingDeco = null),
      onDraggableCanceled: (_, __) => setState(() => _movingDeco = null),
      child: DragTarget<_PlacedDeco>(
        onWillAcceptWithDetails: (_) => false, // no apilamos decos
        builder: (_, __, ___) => GestureDetector(
          onLongPress: () => _showDecoOptions(deco, garden),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AuraContainer(
                item: item,
                sizeMultiplier: size / 60,
                child: SizedBox(
                  width: size, height: size,
                  child: Image.asset(assetPath, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Text(item.emoji, style: const TextStyle(fontSize: 32))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotWidget(
      GardenSlot slot, PlantedItem? planted, GardenProvider garden) {
    final size = 140.0 * slot.plantScale;
    final isSelected = planted != null &&
        planted.instanceId == _selectedInstanceId;

    // Slot vacío
    if (planted == null) {
      final canPlant = _isPlantingMode && _itemToPlant != null;

      // Modo normal: completamente invisible (no contamina el fondo)
      if (!canPlant) return SizedBox(width: size, height: size);

      // Modo plantación: círculo brillante estilo PvZ
      return GestureDetector(
        onTap: () => _plantAt(_activeGarden.id, slot.slotIndex),
        child: AnimatedBuilder(
          animation: _idleCtrl,
          builder: (_, __) {
            final pulse = 0.85 + _idleCtrl.value * 0.15;
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow exterior pulsante
                  Container(
                    width: size * pulse,
                    height: size * pulse,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981)
                              .withOpacity(0.25 + _idleCtrl.value * 0.2),
                          blurRadius: 24,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  // Círculo semitransparente principal
                  Container(
                    width: size * 0.78,
                    height: size * 0.78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981)
                          .withOpacity(0.18 + _idleCtrl.value * 0.08),
                      border: Border.all(
                        color: const Color(0xFF10B981)
                            .withOpacity(0.6 + _idleCtrl.value * 0.3),
                        width: 2.5,
                      ),
                    ),
                  ),
                  // Ícono central
                  Icon(
                    Icons.add_rounded,
                    color: Colors.white
                        .withOpacity(0.7 + _idleCtrl.value * 0.3),
                    size: size * 0.28,
                    shadows: const [
                      Shadow(color: Color(0xFF10B981), blurRadius: 8),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0.0, 0.0),
            end: const Offset(1.0, 1.0),
            duration: 350.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 200.ms);
    }

    // Slot con planta
    final item = GardenCatalog.findById(planted.itemId);
    if (item == null) return const SizedBox.shrink();

    final stage = planted.currentStage(item);
    final isAdult = planted.isAdult(item);
    final assetPath = _plantAssetPath(planted.itemId, stage);

    return GestureDetector(
      onTap: () {
        if (_isPlantingMode) return;
        HapticFeedback.lightImpact();
        setState(() {
          _selectedInstanceId =
              isSelected ? null : planted.instanceId;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Halo de selección
          if (isSelected)
            Container(
              width: size + 12,
              height: size + 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF10B981),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),

          // Imagen de la planta — con efectos si es adulta
          if (isAdult)
            _PlantAdultWidget(
              size: size,
              assetPath: assetPath,
              rarity: item.rarity,
              fallback: _plantFallbackEmoji(planted, item),
            )
          else
            AuraContainer(
              item: item,
              sizeMultiplier: size / 60,
              child: SizedBox(
                width: size,
                height: size,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _plantFallbackEmoji(planted, item),
                ),
              ),
            ),

          // Badge de etapa (solo si no adulta)
          if (!isAdult)
            Positioned(
              bottom: -8,
              child: _buildStageBadge(stage),
            ),

          // (sin check — el halo de rareza indica planta adulta)

          // Barra de progreso mini (solo creciendo)
          if (!isAdult)
            Positioned(
              bottom: -18,
              child: SizedBox(
                width: size * 0.75,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: planted.growthProgress(item),
                    minHeight: 4,
                    backgroundColor: Colors.black.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(
                      _stageColor(stage),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _plantFallbackEmoji(PlantedItem planted, GardenItem item) {
    return Center(
      child: Text(
        planted.currentEmoji(item),
        style: const TextStyle(fontSize: 36),
      ),
    );
  }

  Widget _buildStageBadge(PlantStage stage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _stageColor(stage).withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        'garden.stage.${stage.name}'.tr(),
        style: const TextStyle(
          fontSize: 8,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTopBar(GardenProvider garden) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // Back
          _glassButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),

          // Nombre del jardín activo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeGarden.nameKey.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black45, blurRadius: 6),
                    ],
                  ),
                ),
                Text(
                  'garden.subtitle'.tr(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),

          // Multiplicador XP activo
          if (garden.activeMultiplier != null)
            _buildMultiplierBadge(garden.activeMultiplier!),
          if (garden.activeMultiplier != null)
            const SizedBox(width: 8),

          // Escudos de racha
          if (garden.streakShields > 0)
            _buildShieldBadge(garden.streakShields),
          if (garden.streakShields > 0)
            const SizedBox(width: 8),

          // Semillas badge
          _buildSeedsBadge(garden.seeds),
          const SizedBox(width: 8),

          // (Tienda movida a la barra lateral)
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _glassButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: color ?? Colors.white, size: 20),
      ),
    );
  }

  Widget _buildSeedsBadge(int seeds) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF10B981)
                .withOpacity(0.3 + _glowCtrl.value * 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981)
                  .withOpacity(0.1 + _glowCtrl.value * 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SeedIcon(size: 30),
          const SizedBox(width: 4),
          Text(
            '$seeds',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PANEL DE PLANTA SELECCIONADA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlantPanel(GardenProvider garden) {
    PlantedItem? planted;
    try {
      planted = garden.garden
          .firstWhere((p) => p.instanceId == _selectedInstanceId);
    } catch (_) {
      return const SizedBox.shrink();
    }

    final item = GardenCatalog.findById(planted.itemId);
    if (item == null) return const SizedBox.shrink();

    final stage = planted.currentStage(item);
    final isAdult = planted.isAdult(item);
    final timeLeft = planted.timeRemaining(item);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            // Mini imagen de planta
            SizedBox(
              width: 48,
              height: 48,
              child: Image.asset(
                _plantAssetPath(planted.itemId, stage),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  planted!.currentEmoji(item!),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameKey.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (isAdult)
                    Row(
                      children: [
                        const Text('🌸', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          'garden.stage.adult'.tr(),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                        ),
                      ],
                    )
                  else
                    Text(
                      _formatTimeRemaining(timeLeft),
                      style: TextStyle(
                        fontSize: 12,
                        color: _stageColor(stage),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            // Botón cerrar panel
            GestureDetector(
              onTap: () => setState(() => _selectedInstanceId = null),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white54, size: 16),
              ),
            ),
            const SizedBox(width: 6),
            // Botón eliminar
            GestureDetector(
              onTap: () => _confirmRemovePlant(planted!.instanceId, item),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 16),
              ),
            ),
          ]),

          if (!isAdult) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: planted.growthProgress(item),
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(_stageColor(stage)),
              ),
            ),
            const SizedBox(height: 8),
            _buildStageIndicator(planted, item),
          ],

          // Boosters
          if (!isAdult) ...[
            const SizedBox(height: 10),
            _buildBoosterRow(planted, garden),
          ],

          // ── Botón Cosechar — solo aparece si hay cosecha pendiente y planta adulta ──
           if (isAdult) ...[
            const SizedBox(height: 10),
            Builder(
              builder: (_) {
                final pendingThisPlant =
                    planted!.hasPendingHarvestFor(item);
                if (pendingThisPlant) {
                  return GestureDetector(
                    onTap: () => _claimHarvest(planted!.instanceId,
                        context.read<GardenProvider>()),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🌾',
                              style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'garden.harvestClaim'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // Ya cosechada hoy
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('✅',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 6),
                      Text(
                        'garden.harvestClaimed'.tr(),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: -0.05, end: 0);
  }

  Widget _buildStageIndicator(PlantedItem planted, GardenItem item) {
    final current = planted.currentStage(item);
    return Row(
      children: PlantStage.values.asMap().entries.map((e) {
        final stage = e.value;
        final isPast = stage.index < current.index;
        final isCurrent = stage == current;
        final assetPath = _plantAssetPath(planted.itemId, stage);

        return Expanded(
          child: Column(children: [
            AnimatedContainer(
              duration: 300.ms,
              height: 3,
              decoration: BoxDecoration(
                color: isPast || isCurrent
                    ? _stageColor(stage)
                    : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Opacity(
              opacity: isPast || isCurrent ? 1.0 : 0.3,
              child: SizedBox(
                width: isCurrent ? 22 : 16,
                height: isCurrent ? 22 : 16,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Text(
                    item.stageEmojis?[stage] ?? '🌱',
                    style: TextStyle(fontSize: isCurrent ? 14 : 10),
                  ),
                ),
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildBoosterRow(PlantedItem planted, GardenProvider garden) {
    final boosters = GardenCatalog.allBoosters
        .where((b) => garden.state.hasInInventory(b.id))
        .toList();

    if (boosters.isEmpty) {
      return Text(
        '💧 ${'garden.boostersHint'.tr()}',
        style: const TextStyle(fontSize: 11, color: Colors.white38),
      );
    }

    return Row(
      children: boosters.map((booster) {
        final qty = garden.state.quantityOf(booster.id);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => _applyBooster(booster.id, planted.instanceId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
  width: 18, height: 18,
  child: Image.asset(
    'assets/images/boosters/${booster.id.replaceFirst('boost_', '')}.png',
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => Text(
      booster.emoji,
      style: const TextStyle(fontSize: 14),
    ),
  ),
),
                const SizedBox(width: 4),
                Text(
                  '×$qty',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INVENTARIO (drawer inferior)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildInventoryDrawer(GardenProvider garden) {
    // Mostrar plantas Y decoraciones — todo lo que se puede colocar en el jardín
    final placeableItems = garden.inventory
        .where((i) {
          final item = GardenCatalog.findById(i.itemId);
          return item != null &&
              (item.type == ItemType.plant ||
               item.type == ItemType.decoration);
        })
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 3,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          if (placeableItems.isEmpty)
            _buildEmptyInventory()
          else
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: placeableItems.length,
                itemBuilder: (_, i) {
                  final inv = placeableItems[i];
                  final item = GardenCatalog.findById(inv.itemId)!;
                  final isSelected = _itemToPlant == inv.itemId;
                  final isPlant = item.type == ItemType.plant;

                  // Plantas: mostrar etapa adulta para que el usuario reconozca la planta
                  // Decoraciones: PNG de assets/images/decorations/ con fallback a emoji
                  Widget itemVisual;
                  if (isPlant) {
                    itemVisual = Image.asset(
                      _plantAssetPath(inv.itemId, PlantStage.adult),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        _plantAssetPath(inv.itemId, PlantStage.seed),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Text(item.emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  } else {
                    // Decoración: PNG de assets/images/decorations/ con fallback a emoji
                    final decoAsset = _decoAssetPath(inv.itemId);
                    itemVisual = Image.asset(
                      decoAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _rarityColorForItem(item.rarity).withOpacity(0.15),
                        ),
                        child: Center(
                          child: Text(item.emoji,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                    );
                  }

                  // Envolver el visual con aura del item (color+intensidad por rareza)
                  itemVisual = AuraContainer(
                    item: item,
                    sizeMultiplier: 0.8,
                    child: itemVisual,
                  );

                  // Decoraciones son Draggable; plantas usan tap normal
                  final inventoryItem = AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF10B981).withOpacity(0.25)
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : Colors.white.withOpacity(0.12),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 36, height: 36, child: itemVisual),
                        const SizedBox(height: 4),
                        Text(
                          item.nameKey.tr(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                        if (inv.quantity > 1)
                          Text(
                            '×${inv.quantity}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  );

                  if (!isPlant) {
                    // Decoración: Draggable desde el inventario
                    return Draggable<String>(
                      data: inv.itemId,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Opacity(
                          opacity: 0.85,
                          child: SizedBox(
                            width: _decoSize(inv.itemId),
                            height: _decoSize(inv.itemId),
                            child: Image.asset(
                              _decoAssetPath(inv.itemId),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Text(
                                item.emoji,
                                style: TextStyle(
                                    fontSize: _decoSize(inv.itemId) * 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(opacity: 0.3, child: inventoryItem),
                      onDragStarted: () => setState(() {
                        _draggingDecoItemId = inv.itemId;
                        _cancelPlanting();
                      }),
                      onDraggableCanceled: (_, __) =>
                          setState(() => _draggingDecoItemId = null),
                      onDragEnd: (_) =>
                          setState(() => _draggingDecoItemId = null),
                      child: inventoryItem,
                    )
                        .animate(delay: (i * 50).ms)
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: 0.1, end: 0);
                  }

                  // Planta: tap normal para modo plantación
                  return GestureDetector(
                    onTap: () => _selectItemToPlant(inv.itemId),
                    child: inventoryItem,
                  )
                      .animate(delay: (i * 50).ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.1, end: 0);
                },
              ),
            ),
        ],
      ),
    );
  }

  // Helper para color de rareza (usado en el drawer)
  Color _rarityColorForItem(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.common:    return const Color(0xFF10B981);
      case ItemRarity.rare:      return const Color(0xFF3B82F6);
      case ItemRarity.epic:      return const Color(0xFF8B5CF6);
      case ItemRarity.legendary: return const Color(0xFFF59E0B);
      case ItemRarity.seasonal:  return const Color(0xFFEC4899);
    }
  }

  Widget _buildEmptyInventory() {
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          const Text('🪴', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'garden.inventoryEmpty'.tr(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'garden.inventoryEmptyDesc'.tr(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopScreen()),
            ),
            icon: const Icon(Icons.storefront_rounded, size: 16),
            label: Text('garden.shop'.tr()),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLANTING MODE BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPlantingBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(children: [
        const Text('🌱', style: TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'garden.plantHere'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        GestureDetector(
          onTap: _cancelPlanting,
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
        ),
      ]),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.1, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BARRA LATERAL — accesos rápidos + selector de jardín
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSidebar() {
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 80, bottom: 130),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tienda
          _sidebarButton(
            icon: Icons.storefront_rounded,
            color: const Color(0xFF10B981),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopScreen()),
            ),
            tooltip: 'garden.sidebar.shop'.tr(),
          ),
          const SizedBox(height: 10),

          // Cambiar jardín
          _sidebarButton(
            icon: Icons.landscape_rounded,
            color: const Color(0xFF6366F1),
            onTap: _showGardenSelector,
            tooltip: 'garden.sidebar.gardens'.tr(),
          ),
          const SizedBox(height: 10),

          // Logros
          _sidebarButton(
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => _showAchievementsSheet(),
            tooltip: 'garden.sidebar.achievements'.tr(),
          ),
          const SizedBox(height: 10),

          // Selector de jardines activos (indicador visual)
          _buildGardenDots(),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideX(begin: 0.3, end: 0);
  }

  Widget _sidebarButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // Puntos indicadores de jardín activo
  Widget _buildGardenDots() {
    final unlocked = GardensCatalog.all.where((g) => g.isUnlocked).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: unlocked.map((g) {
        final isActive = g.id == _activeGarden.id;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _activeGarden = g;
              _selectedInstanceId = null;
              _cancelPlanting();
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isActive ? 28 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF10B981)
                  : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showAchievementsSheet() {
    // Filtra solo los logros de jardín del sistema general
    final gardenAchievements = Achievement.all
        .where((a) =>
            a.type == AchievementType.gardenPlants ||
            a.type == AchievementType.gardenAdults ||
            a.type == AchievementType.gardenDecorations)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F1F15),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Consumer<GardenProvider>(
            builder: (_, garden, __) {
              final totalPlants = garden.garden
                  .where((p) => p.gardenId == _activeGarden.id)
                  .length;
              final adults = garden.garden
                  .where((p) {
                    if (p.gardenId != _activeGarden.id) return false;
                    final item = GardenCatalog.findById(p.itemId);
                    return item != null && p.isAdult(item);
                  })
                  .length;
              final decos = _placedDecos
                  .where((d) => d.gardenId == _activeGarden.id)
                  .length;

              final unlockedCount = gardenAchievements.where((a) => a.isUnlocked(
                currentStreak: 0, longestStreak: 0, totalXp: 0,
                level: 0, diaryEntries: 0, habitsCompleted: 0,
                moodCheckIns: 0,
                totalPlantsEver: totalPlants,
                adultPlants: adults,
                decorationsPlaced: decos,
              )).length;

              return ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 3,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(children: [
                    const Text('🏆', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Text(
                      'garden.gardens.${_activeGarden.id}'.tr(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    'garden.achievementsSheet.count'.tr(namedArgs: {
                      'unlocked': '$unlockedCount',
                      'total': '${gardenAchievements.length}',
                    }),
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  ...gardenAchievements.map((a) {
                    final unlocked = a.isUnlocked(
                      currentStreak: 0, longestStreak: 0, totalXp: 0,
                      level: 0, diaryEntries: 0, habitsCompleted: 0,
                      moodCheckIns: 0,
                      totalPlantsEver: totalPlants,
                      adultPlants: adults,
                      decorationsPlaced: decos,
                    );
                    final prog = a.progress(
                      currentStreak: 0, longestStreak: 0, totalXp: 0,
                      level: 0, diaryEntries: 0, habitsCompleted: 0,
                      moodCheckIns: 0,
                      totalPlantsEver: totalPlants,
                      adultPlants: adults,
                      decorationsPlaced: decos,
                    );
                    return _achievementTileWithProgress(a, unlocked, prog);
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _achievementTileWithProgress(
      Achievement a, bool unlocked, double prog) {
    final titleKey = a.titleKey;
    final descKey = a.descriptionKey;
    final title = titleKey != null ? titleKey.tr() : a.title;
    final desc = descKey != null ? descKey.tr() : a.description;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: unlocked ? 1.0 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unlocked
                ? a.color.withOpacity(0.12)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unlocked
                  ? a.color.withOpacity(0.35)
                  : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(a.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    color: unlocked ? Colors.white : Colors.white60,
                    fontSize: 13, fontWeight: FontWeight.w700,
                  )),
                  Text(desc, style: const TextStyle(
                    color: Colors.white38, fontSize: 11,
                  )),
                ],
              )),
              if (unlocked)
                Icon(Icons.check_circle_rounded,
                    color: a.color, size: 20)
              else
                Text(
                  '${(prog * a.requirement).round()}/${a.requirement}',
                  style: TextStyle(color: a.color, fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
            ]),
            if (!unlocked && prog > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: prog,
                  minHeight: 4,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(a.color),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }



  void _showGardenSelector() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GardenSelectorModal(
        currentGardenId: _activeGarden.id,
        onSelect: (garden) {
          setState(() => _activeGarden = garden);
          Navigator.pop(ctx);
          // Resetear selección al cambiar jardín
          setState(() {
            _selectedInstanceId = null;
            _cancelPlanting();
          });
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CUBRE MARCA DE AGUA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWatermarkCover() {
    // Cubre marca de agua mostrando estadísticas del jardín
    return Consumer<GardenProvider>(
      builder: (_, garden, __) {
        final plantsInGarden = garden.garden
            .where((p) => p.gardenId == _activeGarden.id)
            .length;
        final decosInGarden = _placedDecos
            .where((d) => d.gardenId == _activeGarden.id)
            .length;
        final adultsInGarden = garden.garden
            .where((p) =>
                p.gardenId == _activeGarden.id &&
                p.isAdult(GardenCatalog.findById(p.itemId)!))
            .length;

        return GestureDetector(
          onTap: () => _showGardenStats(garden),
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statChip('🌱', '$plantsInGarden'),
                const SizedBox(width: 8),
                _statChip('🪨', '$decosInGarden'),
                const SizedBox(width: 8),
                _statChip('🌸', '$adultsInGarden'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statChip(String emoji, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 11)),
      const SizedBox(width: 3),
      Text(value, style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
      )),
    ]);
  }

  void _showGardenStats(GardenProvider garden) {
    HapticFeedback.lightImpact();
    final allPlants = garden.garden
        .where((p) => p.gardenId == _activeGarden.id)
        .toList();
    final adults = allPlants
        .where((p) {
          final item = GardenCatalog.findById(p.itemId);
          return item != null && p.isAdult(item);
        })
        .length;
    final decos = _placedDecos
        .where((d) => d.gardenId == _activeGarden.id)
        .length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF0F1F15),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 3,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(children: [
            const Text('📊', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Text(
              _activeGarden.nameKey.tr(),
              style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800,
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            _buildStatCard2(
              '🌱',
              '${allPlants.length}',
              'garden.stats.plants'.tr(),
              'garden.stats.plantsSub'.tr(),
            ),
            const SizedBox(width: 12),
            _buildStatCard2(
              '🌸',
              '$adults',
              'garden.stats.adults'.tr(),
              'garden.stats.adultsSub'.tr(),
            ),
            const SizedBox(width: 12),
            _buildStatCard2(
              '🪨',
              '$decos',
              'garden.stats.decos'.tr(),
              'garden.stats.decosSub'.tr(),
            ),
          ]),
          const SizedBox(height: 16),
          // Progreso del jardín
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('garden.stats.title'.tr(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(
                allPlants.isEmpty ? '0%' : '${((adults / allPlants.length) * 100).round()}%',
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: allPlants.isEmpty ? 0 : adults / allPlants.length,
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildStatCard2(String emoji, String value, String label, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800,
          )),
          Text(label, style: const TextStyle(
            color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700,
          )),
          Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DECORACIONES — drag & drop con colisión vs plantas
  // ═══════════════════════════════════════════════════════════════════════════

  /// Coloca o mueve una decoración. Verifica que no solape con plantas.
  void _placeDecoration(String itemId, double fx, double fy,
      double viewW, double viewH, GardenProvider garden) {
    // ── Verificar colisión con slots de plantas ──────────────────────────
    const plantRadius = 0.12;   // radio de exclusión en fracción del fondo
    for (final slot in _activeGarden.slots) {
      final dx = (fx - slot.anchorX).abs();
      final dy = (fy - slot.anchorY).abs();
      // Ajustar por aspect ratio del fondo
      final dist = (dx * dx + dy * dy * 2.0);
      if (dist < plantRadius * plantRadius) {
        HapticFeedback.heavyImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Text('🌱', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('garden.positionOccupied'.tr(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ));
        }
        return;
      }
    }

    // ── Verificar colisión con otras decoraciones ──────────────────────
    const decoRadius = 0.08;
    for (final existing in _placedDecos) {
      if (existing.gardenId != _activeGarden.id) continue;
      if (_movingDeco != null && existing.instanceId == _movingDeco!.instanceId) continue;
      final dx = (fx - existing.fx).abs();
      final dy = (fy - existing.fy).abs();
      final dist = dx * dx + dy * dy;
      if (dist < decoRadius * decoRadius) {
        HapticFeedback.heavyImpact();
        return;
      }
    }

    HapticFeedback.mediumImpact();
    setState(() {
      if (_movingDeco != null) {
        // Mover deco existente
        final idx = _placedDecos.indexWhere(
            (d) => d.instanceId == _movingDeco!.instanceId);
        if (idx >= 0) {
          _placedDecos[idx] = _PlacedDeco(
            instanceId: _movingDeco!.instanceId,
            itemId: _movingDeco!.itemId,
            gardenId: _activeGarden.id,
            fx: fx,
            fy: fy,
          );
        }
        _movingDeco = null;
      } else {
        // Nueva deco desde inventario
        _placedDecos.add(_PlacedDeco(
          instanceId: '${DateTime.now().millisecondsSinceEpoch}',
          itemId: itemId,
          gardenId: _activeGarden.id,
          fx: fx,
          fy: fy,
        ));
        // Quitar del inventario y guardar en Firestore
        _consumeDecoFromInventory(itemId, garden);
      }
      _draggingDecoItemId = null;
    });

    // Persistir en Firestore
    _saveDecoPositions(garden);
  }

  Future<void> _consumeDecoFromInventory(
      String itemId, GardenProvider garden) async {
    // Reutilizamos plantItemInSlot con slotIndex=-1 como señal de "deco colocada"
    // O mejor: simplemente gastar la deco del inventario vía provider
    await garden.spendDecoration(itemId);
  }

  Future<void> _saveDecoPositions(GardenProvider garden) async {
    final decoData = _placedDecos.map((d) => d.toMap()).toList();
    await garden.savePlacedDecorations(decoData);
  }

  Future<void> _loadDecoPositions(GardenProvider garden) async {
    final data = await garden.loadPlacedDecorations();
    if (!mounted) return;
    setState(() {
      _placedDecos.clear();
      _placedDecos.addAll(
          data.map((m) => _PlacedDeco.fromMap(m)));
    });
  }

  void _showDecoOptions(_PlacedDeco deco, GardenProvider garden) {
    final item = GardenCatalog.findById(deco.itemId);
    if (item == null) return;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A2E1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 3,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(children: [
            SizedBox(
              width: 48, height: 48,
              child: Image.asset(_decoAssetPath(deco.itemId), fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Text(item.emoji, style: const TextStyle(fontSize: 32))),
            ),
            const SizedBox(width: 12),
            Text(item.nameKey.tr(),
                style: const TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          // Recoger — devuelve al inventario
          ListTile(
            leading: const Icon(Icons.inventory_2_rounded, color: Color(0xFF10B981)),
            title: Text('garden.remove'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text('garden.inventoryEmptyDesc'.tr(),
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () async {
              Navigator.pop(ctx);
              setState(() => _placedDecos.removeWhere(
                  (d) => d.instanceId == deco.instanceId));
              await garden.returnDecoration(deco.itemId);
              await _saveDecoPositions(garden);
            },
          ),
          ListTile(
            leading: const Icon(Icons.open_with_rounded, color: Colors.blue),
            title: Text('garden.decoOptions.move'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text('garden.decoOptions.moveHint'.tr(),
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            onTap: () => Navigator.pop(ctx),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MECÁNICAS — badges de multiplicador, escudos y diálogo de cosecha
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMultiplierBadge(XpMultiplierState mult) {
    final mins = mult.timeRemaining.inMinutes + 1;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF8B5CF6)
                .withOpacity(0.4 + _glowCtrl.value * 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6)
                  .withOpacity(0.15 + _glowCtrl.value * 0.15),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('⚡', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            '×${mult.multiplier.toStringAsFixed(1)} · ${mins}min',
            style: const TextStyle(
              color: Color(0xFF8B5CF6),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildShieldBadge(int shields) {
    return GestureDetector(
      onTap: () => _showShieldInfo(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF59E0B).withOpacity(0.4),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🛡️', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            '$shields',
            style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
            ),
          ),
        ]),
      ),
    );
  }

  void _showShieldInfo() {
    final garden = context.read<GardenProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A0F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 3,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text('🛡️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'garden.shields.title'.tr(),
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            garden.streakShields == 1
                ? 'garden.shields.countOne'.tr()
                : 'garden.shields.countOther'.tr(
                    namedArgs: {'count': '${garden.streakShields}'}),
            style: const TextStyle(color: Color(0xFFF59E0B),
                fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'garden.shields.description'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (garden.streakShields > 0)
            FilledButton.icon(
              onPressed: () async {
  Navigator.pop(ctx);
  final recoveredStreak = await garden.useStreakShield();
  if (recoveredStreak > 0 && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Row(children: [
                      const Text('🛡️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text('home.shieldUsed'.tr(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                    ]),
                    backgroundColor: const Color(0xFFF59E0B),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 3),
                  ));
                }
              },
              icon: const Icon(Icons.shield_rounded),
              label: Text('garden.shields.useNow'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
              ),
            ),
        ]),
      ),
    );
  }

  void _showHarvestDialog(HarvestResult harvest) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1F15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.2),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🌅', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              'garden.harvest.dialogTitle'.tr(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // Semillas
            if (harvest.seedsEarned > 0)
              _harvestRow(
                '✨',
                'garden.harvest.seedsEarned'.tr(
                    namedArgs: {'count': '${harvest.seedsEarned}'}),
                const Color(0xFF10B981),
              ),

            // Multiplicador XP
            if (harvest.gotXpMultiplier) ...[
              const SizedBox(height: 8),
              _harvestRow(
                '⚡',
                'garden.harvest.multiplierLine'.tr(namedArgs: {
                  'mult': harvest.xpMultiplier.toStringAsFixed(1),
                  'mins': '${harvest.multiplierMinutes}',
                }),
                const Color(0xFF8B5CF6),
                subtitle: 'garden.harvest.multiplierHint'.tr(),
              ),
            ],

            // Escudo
            if (harvest.gotStreakShield) ...[
              const SizedBox(height: 8),
              _harvestRow(
                '🛡️',
                'garden.harvest.shieldEarned'.tr(),
                const Color(0xFFF59E0B),
                subtitle: harvest.shieldFromPlant != null
                    ? 'garden.harvest.shieldFromPlant'.tr(namedArgs: {
                        'plant': harvest.shieldFromPlant!.tr(),
                      })
                    : null,
              ),
            ],

            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size(double.infinity, 46),
              ),
              child: Text('challenge.awesome'.tr(),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _harvestRow(String emoji, String text, Color color,
      {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            if (subtitle != null)
              Text(subtitle,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COSECHA MANUAL
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _claimHarvest(
      String instanceId, GardenProvider garden) async {
    HapticFeedback.mediumImpact();
    setState(() => _selectedInstanceId = null);
    final harvest = await garden.harvestPlant(instanceId);
    if (!mounted) return;
    if (harvest != null && harvest.hasAnything) {
      _showHarvestDialog(harvest);
    }
  }

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

  Future<void> _plantAt(String gardenId, int slotIndex) async {
    if (_itemToPlant == null) return;
    HapticFeedback.mediumImpact();

    final garden = context.read<GardenProvider>();
    final (success, error) =
        await garden.plantItemInSlot(_itemToPlant!, gardenId, slotIndex);

    if (success) {
      _cancelPlanting();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Text('🌱', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('garden.plant'.tr(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ));
      }
    } else if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            success ? 'garden.boosterApplied'.tr() : (error ?? 'Error'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ]),
        backgroundColor:
            success ? const Color(0xFF10B981) : Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        backgroundColor: const Color(0xFF1A2E1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Text(item.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Text(item.nameKey.tr(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
        content: Text('garden.remove'.tr(),
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr(),
                style: const TextStyle(color: Colors.white54)),
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

  Color _stageColor(PlantStage stage) {
    switch (stage) {
      case PlantStage.seed:   return const Color(0xFF92400E);
      case PlantStage.sprout: return const Color(0xFF15803D);
      case PlantStage.young:  return const Color(0xFF16A34A);
      case PlantStage.adult:  return const Color(0xFF10B981);
    }
  }

  String _formatTimeRemaining(Duration? duration) {
    if (duration == null || duration == Duration.zero) return '';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return 'garden.timeRemaining'
          .tr(namedArgs: {'hours': '$hours', 'minutes': '$minutes'});
    }
    return 'garden.timeRemainingMinutes'
        .tr(namedArgs: {'minutes': '$minutes'});
  }
}



// ═════════════════════════════════════════════════════════════════════════════
// MODELO: Decoración colocada en el jardín
// ═════════════════════════════════════════════════════════════════════════════

class _PlacedDeco {
  final String instanceId;
  final String itemId;
  final String gardenId;
  final double fx;   // fracción 0..1 del ancho del fondo
  final double fy;   // fracción 0..1 del alto del fondo

  const _PlacedDeco({
    required this.instanceId,
    required this.itemId,
    required this.gardenId,
    required this.fx,
    required this.fy,
  });

  Map<String, dynamic> toMap() => {
    'instanceId': instanceId,
    'itemId': itemId,
    'gardenId': gardenId,
    'fx': fx,
    'fy': fy,
  };

  factory _PlacedDeco.fromMap(Map<String, dynamic> m) => _PlacedDeco(
    instanceId: m['instanceId'] as String,
    itemId: m['itemId'] as String,
    gardenId: m['gardenId'] as String,
    fx: (m['fx'] as num).toDouble(),
    fy: (m['fy'] as num).toDouble(),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// PLANTA ADULTA — vaivén de brisa + halo de rareza + partículas
// ═════════════════════════════════════════════════════════════════════════════

class _PlantAdultWidget extends StatefulWidget {
  final double size;
  final String assetPath;
  final ItemRarity rarity;
  final Widget fallback;

  const _PlantAdultWidget({
    required this.size,
    required this.assetPath,
    required this.rarity,
    required this.fallback,
  });

  @override
  State<_PlantAdultWidget> createState() => _PlantAdultWidgetState();
}

class _PlantAdultWidgetState extends State<_PlantAdultWidget>
    with TickerProviderStateMixin {

  // ── Controllers ────────────────────────────────────────────────────────────
  late AnimationController _breezeCtrl;   // vaivén lateral
  late AnimationController _haloCtrl;     // halo pulsante
  late AnimationController _particleCtrl; // partículas flotantes

  // ── Partículas ─────────────────────────────────────────────────────────────
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    // Vaivén suave — va de -1 a 1 con easeInOut
    _breezeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // Halo pulsante — más lento
    _haloCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Partículas — loop continuo
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Generar sparkles con distribución espacial uniforme
    final rng = math.Random(widget.rarity.index * 42);
    _particles = List.generate(
      _particleCount,
      (i) {
        // Distribuir uniformemente alrededor de la planta con algo de aleatoriedad
        final baseX = 0.15 + (i % 3) * 0.35 + rng.nextDouble() * 0.1;
        final baseY = 0.35 + (i ~/ 3) * 0.25 + rng.nextDouble() * 0.15;
        return _Particle(
          startX: baseX.clamp(0.1, 0.9),
          startY: baseY.clamp(0.3, 0.85),
          phaseOffset: i / _particleCount,  // desfase uniforme = cascada continua
          size: 2.5 + rng.nextDouble() * 3.5,
          drift: (rng.nextDouble() - 0.5) * 0.18,  // deriva lateral muy sutil
        );
      },
    );
  }

  int get _particleCount {
    switch (widget.rarity) {
      case ItemRarity.common:    return 5;
      case ItemRarity.rare:      return 7;
      case ItemRarity.epic:      return 9;
      case ItemRarity.legendary: return 12;
      case ItemRarity.seasonal:  return 8;
    }
  }

  Color get _rarityColor {
    switch (widget.rarity) {
      case ItemRarity.common:    return const Color(0xFF10B981); // verde
      case ItemRarity.rare:      return const Color(0xFF3B82F6); // azul
      case ItemRarity.epic:      return const Color(0xFF8B5CF6); // morado
      case ItemRarity.legendary: return const Color(0xFFF59E0B); // dorado
      case ItemRarity.seasonal:  return const Color(0xFFEC4899); // rosa
    }
  }

  double get _haloOpacity {
    switch (widget.rarity) {
      case ItemRarity.common:    return 0.20;
      case ItemRarity.rare:      return 0.28;
      case ItemRarity.epic:      return 0.35;
      case ItemRarity.legendary: return 0.45;
      case ItemRarity.seasonal:  return 0.30;
    }
  }

  @override
  void dispose() {
    _breezeCtrl.dispose();
    _haloCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final color = _rarityColor;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,   // sparkles pueden salir del borde
        children: [
          // ── Halo de rareza pulsante ───────────────────────────────────
          AnimatedBuilder(
            animation: _haloCtrl,
            builder: (_, __) {
              final pulse = 0.88 + _haloCtrl.value * 0.12;
              final opacity = _haloOpacity * (0.7 + _haloCtrl.value * 0.3);
              return Container(
                width: size * pulse,
                height: size * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(opacity),
                      blurRadius: 18 + _haloCtrl.value * 8,
                      spreadRadius: 2 + _haloCtrl.value * 3,
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Imagen con vaivén de brisa ────────────────────────────────
          AnimatedBuilder(
            animation: _breezeCtrl,
            builder: (_, child) {
              // Curva suave tipo seno: de -0.025 a +0.025 radianes
              final t = CurvedAnimation(
                parent: _breezeCtrl,
                curve: Curves.easeInOut,
              ).value;
              final angle = (t * 2 - 1) * 0.025; // ±0.025 rad ≈ ±1.4°
              return Transform.rotate(
                angle: angle,
                alignment: Alignment.bottomCenter,
                child: child,
              );
            },
            child: SizedBox(
              width: size,
              height: size,
              child: Image.asset(
                widget.assetPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => widget.fallback,
              ),
            ),
          ),

          // ── Partículas flotantes — área extendida para que suban por encima ──
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) {
              // El canvas es más alto que el slot para que los sparkles
              // puedan subir por encima de la planta sin cortarse
              return SizedBox(
                width: size,
                height: size * 1.6,  // extra espacio arriba
                child: CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleCtrl.value,
                    color: color,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Modelo de partícula ──────────────────────────────────────────────────────

class _Particle {
  final double startX;      // posición X inicial (0..1 relativo al widget)
  final double startY;      // posición Y inicial (0..1)
  final double phaseOffset; // desfase del ciclo (0..1)
  final double size;        // tamaño en píxeles
  final double drift;       // deriva horizontal

  const _Particle({
    required this.startX,
    required this.startY,
    required this.phaseOffset,
    required this.size,
    required this.drift,
  });
}

// ─── Painter de partículas — destellos estilo firefly/magia ─────────────────

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  const _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  /// Dibuja una estrella de 4 puntas suave (tipo sparkle)
  void _drawSparkle(Canvas canvas, Offset center, double radius,
      double opacity, Color color) {
    if (opacity <= 0) return;

    // Núcleo central brillante (sin blur — evita shader crash en WebGL)
    final corePaint = Paint()
      ..color = Color.lerp(color, Colors.white, 0.6)!
          .withOpacity((opacity * 0.9).clamp(0, 1))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.35, corePaint);

    // 4 rayos suaves del sparkle
    final rayPaint = Paint()
      ..color = color.withOpacity((opacity * 0.55).clamp(0, 1))
      ..strokeWidth = radius * 0.35
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Rayo vertical y horizontal (más largos)
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 1.4),
      Offset(center.dx, center.dy + radius * 1.4),
      rayPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 1.4, center.dy),
      Offset(center.dx + radius * 1.4, center.dy),
      rayPaint,
    );

    // Rayos diagonales (más cortos)
    final diagPaint = Paint()
      ..color = color.withOpacity((opacity * 0.30).clamp(0, 1))
      ..strokeWidth = radius * 0.22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final d = radius * 0.85;
    canvas.drawLine(
        Offset(center.dx - d, center.dy - d),
        Offset(center.dx + d, center.dy + d),
        diagPaint);
    canvas.drawLine(
        Offset(center.dx + d, center.dy - d),
        Offset(center.dx - d, center.dy + d),
        diagPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress + p.phaseOffset) % 1.0;

      // Curva de opacidad: fade in rápido → plateau → fade out suave
      final double opacity;
      if (t < 0.12) {
        opacity = t / 0.12;
      } else if (t < 0.65) {
        opacity = 1.0;
      } else {
        opacity = (1.0 - t) / 0.35;
      }

      // Movimiento: sube flotando con una leve oscilación sinusoidal lateral
      final floatY = p.startY - t * 0.85;
      final wobbleX = math.sin(t * math.pi * 3 + p.phaseOffset * math.pi * 2)
          * p.drift * 0.4;
      final x = (p.startX + wobbleX) * size.width;
      final y = floatY * size.height;

      // Tamaño pulsa ligeramente
      final r = p.size * (0.7 + math.sin(t * math.pi * 4) * 0.15 + opacity * 0.3);

      _drawSparkle(canvas, Offset(x, y), r, opacity.clamp(0, 1), color);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress || old.color != color;
}

// ═════════════════════════════════════════════════════════════════════════════
// MODAL SELECTOR DE JARDÍN
// ═════════════════════════════════════════════════════════════════════════════

class _GardenSelectorModal extends StatelessWidget {
  final String currentGardenId;
  final void Function(GardenDef) onSelect;

  const _GardenSelectorModal({
    required this.currentGardenId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1F15),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Handle
          Container(
            width: 40,
            height: 3,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Text('🌿', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                'garden.selectGarden'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Grid de jardines
          // Grid de jardines
Expanded(
  child: SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
    child: GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.75,
      children: GardensCatalog.all
          .asMap()
          .entries
          .map((e) => _buildGardenCard(e.value, e.key, context))
          .toList(),
    ),
  ),
),
        ],
      ),
    );
  }

  Widget _buildGardenCard(GardenDef garden, int index, BuildContext context) {
    final isCurrent = garden.id == currentGardenId;
    final isLocked = !garden.isUnlocked;

    return GestureDetector(
      onTap: isLocked ? null : () => onSelect(garden),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent
                ? const Color(0xFF10B981)
                : Colors.white.withOpacity(0.1),
            width: isCurrent ? 2.5 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Preview del fondo
              Image.asset(
                garden.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.green.withOpacity(0.2),
                  child: const Icon(Icons.landscape_rounded,
                      color: Colors.white38, size: 40),
                ),
              ),

              // Overlay oscuro
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(isLocked ? 0.7 : 0.55),
                    ],
                  ),
                ),
              ),

              // Lock overlay
              if (isLocked)
                Container(
                  color: Colors.black.withOpacity(0.45),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded,
                          color: Colors.white54, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'common.comingSoon'.tr(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // Nombre + badge activo
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        garden.nameKey.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 6),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'garden.active'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (index * 60).ms)
        .fadeIn(duration: 350.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          curve: Curves.easeOut,
        );
  }
}