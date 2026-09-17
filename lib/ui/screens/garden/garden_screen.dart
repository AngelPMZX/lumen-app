import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/garden_item.dart';
import '../../../data/models/garden_state.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/motion_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/discovery_dialog.dart';
import '../../widgets/journal/journal_style.dart';
import 'garden_defs.dart';
import 'garden_logic.dart';
import 'shop_screen.dart';
import 'widgets/garden_common.dart';
import 'widgets/garden_hud.dart';
import 'widgets/garden_plant_slot.dart';
import 'widgets/garden_sheets.dart';
import 'widgets/harvest_dialog.dart';
import 'widgets/plant_info_panel.dart';

/// Jardín zen: la ilustración del jardín con sus plantas y decoraciones,
/// Lumi, la mochila y la tienda.
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  static const _prefActiveGarden = 'garden_active_id';
  static const double _plantSize = 140;

  GardenDef _garden = GardensCatalog.defaultGarden;
  String? _plantingId;
  String? _boostingId;
  String? _selectedId;
  bool _draggingDeco = false;
  bool _decosLoaded = false;
  bool _ambientOn = SoundService.instance.gardenAmbientEnabled;
  final List<PlacedDeco> _decos = [];

  /// Destellos al plantar, aplicar un booster o colocar una decoración.
  final Map<String, int> _bursts = {};
  int _burstSeq = 0;

  /// Refresca el crecimiento mientras la pantalla está abierta.
  Timer? _tick;

  bool get _isNight {
    final h = DateTime.now().hour;
    return h >= 20 || h < 6;
  }

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final garden = context.read<GardenProvider>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = GardensCatalog.byId(prefs.getString(_prefActiveGarden));
      if (mounted && saved.id != _garden.id) setState(() => _garden = saved);
    } catch (_) {}
    _startAmbient();
    await garden.loadGarden();
    if (!mounted) return;
    DiscoveryDialog.maybeShow(context, DiscoveryFeature.garden);
    await _loadDecos(garden);
    if (!mounted) return;
    if (_readyCount(garden.garden) > 0) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) SoundService.instance.play(Sfx.harvestReady, volume: 0.45);
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    SoundService.instance.stopAmbient();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sonido ambiente
  // ═══════════════════════════════════════════════════════════════════════════

  void _startAmbient() {
    if (!_ambientOn) return;
    SoundService.instance.startAmbient(_isNight ? Ambient.night : _garden.ambient, volume: 0.22);
  }

  Future<void> _toggleAmbient() async {
    final on = !_ambientOn;
    setState(() => _ambientOn = on);
    SoundService.instance.play(on ? Sfx.toggleOn : Sfx.toggleOff, volume: 0.4);
    await SoundService.instance.setGardenAmbientEnabled(on);
    if (on) {
      _startAmbient();
    } else {
      await SoundService.instance.stopAmbient(fadeOut: const Duration(milliseconds: 500));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final garden = context.watch<GardenProvider>();
    final media = MediaQuery.of(context);
    // La escena ocupa el espacio sobre la mochila (que se monta un poco
    // encima) para que ninguna planta quede tapada.
    final sceneBottom = InventoryTray.height(isEmpty: garden.inventory.every((i) => i.quantity <= 0)) + media.viewPadding.bottom - 26;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E1A14),
        body: garden.isLoading && garden.garden.isEmpty
            ? _Loading(garden: _garden)
            : Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(left: 0, top: 0, right: 0, bottom: sceneBottom, child: _buildScene(garden)),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GardenTopBar(
                            garden: _garden,
                            seeds: garden.seeds,
                            shields: garden.streakShields,
                            multiplier: garden.activeMultiplier,
                            ambientOn: _ambientOn,
                            onBack: () => Navigator.pop(context),
                            onGardens: () => _openGardens(garden),
                            onToggleAmbient: _toggleAmbient,
                            onShields: () => _openShields(garden),
                            onShop: _openShop,
                            onProgress: () => _openProgress(garden),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: _buildSelectedPanel(garden),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 60, 0),
                          child: IgnorePointer(
                            ignoring: _draggingDeco,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _draggingDeco ? 0.4 : 1,
                              child: GardenLumiBubble(line: GardenLumi.lineFor(_snapshot(garden))),
                            ),
                          ),
                        ),
                        if (_plantingId != null || _boostingId != null) _buildModeBanner(),
                        InventoryTray(
                          state: garden.state,
                          plantingId: _plantingId,
                          boostingId: _boostingId,
                          onPlant: (item) => _togglePlanting(item, garden),
                          onBooster: (item) => _toggleBoosting(item, garden),
                          onDecoTap: (_) => GardenToast.show(
                            context,
                            text: 'garden.dragHint'.tr(),
                            leading: const Icon(Icons.open_with_rounded, color: Colors.white),
                          ),
                          onDragStarted: () => setState(() {
                            _draggingDeco = true;
                            _plantingId = null;
                            _boostingId = null;
                            _selectedId = null;
                          }),
                          onDragEnded: () => setState(() => _draggingDeco = false),
                          onShop: _openShop,
                          bottomInset: media.viewPadding.bottom,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  GardenSnapshot _snapshot(GardenProvider garden) {
    final here = garden.garden.where((p) => p.gardenId == _garden.id).toList();
    int count(ItemType type) => garden.inventory.fold(0, (s, inv) {
          final item = GardenCatalog.findById(inv.itemId);
          return item?.type == type ? s + inv.quantity : s;
        });
    return GardenSnapshot(
      planting: _plantingId != null,
      boosting: _boostingId != null,
      draggingDeco: _draggingDeco,
      plants: here.length,
      readyToHarvest: _readyCount(here),
      growing: here.where((p) {
        final item = GardenCatalog.findById(p.itemId);
        return item != null && !p.isAdult(item);
      }).length,
      seedsInInventory: count(ItemType.plant),
      boostersInInventory: count(ItemType.booster),
      decosInInventory: count(ItemType.decoration),
    );
  }

  int _readyCount(List<PlantedItem> plants) => plants.where((p) {
        final item = GardenCatalog.findById(p.itemId);
        return item != null && p.hasPendingHarvestFor(item);
      }).length;

  // ═══════════════════════════════════════════════════════════════════════════
  // Escena: fondo, decoraciones y plantas ordenadas por profundidad
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScene(GardenProvider garden) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return DragTarget<Object>(
          onWillAcceptWithDetails: (d) => d.data is NewDecoDrag || d.data is PlacedDeco,
          onAcceptWithDetails: (d) => _dropDeco(d.data, d.offset, context, w, h, garden),
          builder: (context, candidates, _) {
            final hovering = candidates.isNotEmpty;
            final layers = <(double, Widget)>[];

            for (final deco in _decos.where((d) => d.gardenId == _garden.id)) {
              final item = GardenCatalog.findById(deco.itemId);
              if (item == null) continue;
              final (bx, by) = deco.backgroundPoint(w, h);
              final (x, y) = GardenLayout.toScreen(bx, by, w, h);
              final s = GardenAssets.decoSize(deco.itemId);
              layers.add((
                y + s / 2,
                Positioned(
                  key: ValueKey('deco_${deco.instanceId}'),
                  left: x - s / 2,
                  top: y - s / 2,
                  width: s,
                  height: s,
                  child: _PlacedDecoView(
                    deco: deco,
                    item: item,
                    size: s,
                    burst: _bursts[deco.instanceId] ?? 0,
                    onDragStarted: () => setState(() {
                      _draggingDeco = true;
                      _selectedId = null;
                    }),
                    onDragEnded: () => setState(() => _draggingDeco = false),
                    onTap: () => _openDecoOptions(deco, item, garden),
                  ),
                ),
              ));
            }

            for (final slot in _garden.slots) {
              final planted = garden.garden.where((p) => p.gardenId == _garden.id && p.slotIndex == slot.slotIndex).firstOrNull;
              final (x, y) = GardenLayout.toScreen(slot.anchorX, slot.anchorY, w, h);
              final size = _plantSize * slot.plantScale;
              final item = planted == null ? null : GardenCatalog.findById(planted.itemId);
              Widget? child;
              if (planted != null && item != null) {
                child = PlantSlotView(
                  planted: planted,
                  item: item,
                  size: size,
                  mode: _plantingId != null
                      ? SlotMode.planting
                      : _boostingId != null
                          ? SlotMode.boosting
                          : SlotMode.normal,
                  selected: planted.instanceId == _selectedId,
                  burst: _bursts[planted.instanceId] ?? 0,
                  onTap: () => _onPlantTap(planted, item, garden),
                );
              } else if (planted == null && _plantingId != null) {
                child = EmptySlotTarget(
                  size: size,
                  itemToPlant: GardenCatalog.findById(_plantingId!),
                  onTap: () => _plantAt(slot.slotIndex, garden),
                );
              } else if (planted == null && _draggingDeco) {
                child = IgnorePointer(child: _NoDecoZone(size: size));
              }
              if (child == null) continue;
              layers.add((
                y + size / 2,
                Positioned(
                  key: ValueKey('slot_${_garden.id}_${slot.slotIndex}'),
                  left: x - size / 2,
                  top: y - size / 2,
                  width: size,
                  height: size,
                  child: child,
                ),
              ));
            }

            layers.sort((a, b) => a.$1.compareTo(b.$1));

            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Image.asset(
                    _garden.assetPath,
                    key: ValueKey(_garden.id),
                    fit: BoxFit.cover,
                    width: w,
                    height: h,
                    errorBuilder: (_, _, _) => Container(color: _garden.tint),
                  ),
                ),
                // Velo para que la barra y la mochila se lean
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0, 0.18, 0.7, 1],
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0),
                          Colors.black.withValues(alpha: 0),
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isNight) const IgnorePointer(child: _NightVeil()),
                if (hovering || _draggingDeco)
                  IgnorePointer(child: Container(color: Colors.white.withValues(alpha: hovering ? 0.08 : 0.04))),
                ...layers.map((l) => l.$2),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedPanel(GardenProvider garden) {
    final planted = garden.garden.where((p) => p.instanceId == _selectedId).firstOrNull;
    final item = planted == null ? null : GardenCatalog.findById(planted.itemId);
    if (planted == null || item == null) return const SizedBox(width: double.infinity);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: PlantInfoPanel(
        key: ValueKey(planted.instanceId),
        planted: planted,
        item: item,
        state: garden.state,
        onClose: () => setState(() => _selectedId = null),
        onHarvest: () => _harvest(planted, item, garden),
        onBooster: (id) => _applyBooster(id, planted, garden),
        onRemove: () => _returnPlant(planted, item, garden),
        onShop: _openShop,
      ),
    );
  }

  Widget _buildModeBanner() {
    final boosting = _boostingId != null;
    final item = GardenCatalog.findById(_boostingId ?? _plantingId ?? '');
    if (item == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
        radius: 18,
        borderColor: (boosting ? GardenPalette.gold : GardenPalette.green).withValues(alpha: 0.8),
        child: Row(
          children: [
            GardenItemImage(item: item, size: 34, stage: boosting ? PlantStage.adult : PlantStage.seed, auraScale: 0.6),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  boosting ? 'garden.tapPlantToBoost'.tr() : 'garden.tapSoilToPlant'.tr(),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            GlassIconButton(icon: Icons.close_rounded, label: 'common.cancel'.tr(), onTap: _cancelModes),
          ],
        ),
      ).animate(key: ValueKey(item.id)).fadeIn(duration: 200.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Acciones con plantas
  // ═══════════════════════════════════════════════════════════════════════════

  void _cancelModes() => setState(() {
        _plantingId = null;
        _boostingId = null;
      });

  void _burst(String id) => _bursts[id] = ++_burstSeq;

  void _togglePlanting(GardenItem item, GardenProvider garden) {
    if (_plantingId == item.id) return _cancelModes();
    final used = garden.garden.where((p) => p.gardenId == _garden.id).length;
    if (used >= _garden.slots.length) {
      SoundService.instance.play(Sfx.toggleOff, volume: 0.4);
      GardenToast.show(context, text: 'garden.gridFull'.tr(), color: GardenPalette.gold, leading: const Text('🌿', style: TextStyle(fontSize: 20)));
      return;
    }
    SoundService.instance.play(Sfx.leafTap, volume: 0.5);
    setState(() {
      _plantingId = item.id;
      _boostingId = null;
      _selectedId = null;
    });
  }

  void _toggleBoosting(GardenItem item, GardenProvider garden) {
    if (_boostingId == item.id) return _cancelModes();
    final growing = garden.garden.any((p) {
      final plant = GardenCatalog.findById(p.itemId);
      return p.gardenId == _garden.id && plant != null && !p.isAdult(plant);
    });
    if (!growing) {
      SoundService.instance.play(Sfx.toggleOff, volume: 0.4);
      GardenToast.show(context, text: 'garden.noGrowingPlants'.tr(), color: GardenPalette.gold, leading: GardenItemImage(item: item, size: 28, aura: false));
      return;
    }
    SoundService.instance.shine(RarityStyle.shine(item.rarity), volume: 0.4);
    setState(() {
      _boostingId = item.id;
      _plantingId = null;
      _selectedId = null;
    });
  }

  void _onPlantTap(PlantedItem planted, GardenItem item, GardenProvider garden) {
    if (_boostingId != null) {
      if (planted.isAdult(item)) {
        GardenToast.show(context, text: 'garden.errors.alreadyAdult'.tr(), color: GardenPalette.gold);
        return;
      }
      _applyBooster(_boostingId!, planted, garden);
      return;
    }
    if (planted.hasPendingHarvestFor(item)) {
      _harvest(planted, item, garden);
      return;
    }
    SoundService.instance.play(Sfx.leafTap, volume: 0.5);
    setState(() => _selectedId = _selectedId == planted.instanceId ? null : planted.instanceId);
  }

  Future<void> _plantAt(int slotIndex, GardenProvider garden) async {
    final itemId = _plantingId;
    if (itemId == null) return;
    HapticFeedback.mediumImpact();
    final (ok, error) = await garden.plantItemInSlot(itemId, _garden.id, slotIndex);
    if (!mounted) return;
    if (ok) {
      SoundService.instance.play(Sfx.plant, volume: 0.65);
      AnalyticsService.instance.gardenAction('plant', itemId: itemId);
      final planted = garden.garden.where((p) => p.gardenId == _garden.id && p.slotIndex == slotIndex).firstOrNull;
      setState(() {
        if (planted != null) _burst(planted.instanceId);
        _plantingId = null;
      });
    } else if (error != null) {
      SoundService.instance.play(Sfx.wrong, volume: 0.45);
      GardenToast.show(context, text: error, color: const Color(0xFFDC6B4A));
    }
  }

  Future<void> _applyBooster(String boosterId, PlantedItem planted, GardenProvider garden) async {
    HapticFeedback.mediumImpact();
    final booster = GardenCatalog.findById(boosterId);
    final (ok, error) = await garden.applyBooster(boosterId, planted.instanceId);
    if (!mounted) return;
    SoundService.instance.play(ok ? Sfx.booster : Sfx.wrong, volume: 0.6);
    if (ok) {
      AnalyticsService.instance.gardenAction('booster', itemId: boosterId);
      setState(() {
        _burst(planted.instanceId);
        _boostingId = null;
      });
      GardenToast.show(
        context,
        text: 'garden.boosterApplied'.tr(),
        leading: booster == null ? null : GardenItemImage(item: booster, size: 28, aura: false),
      );
    } else {
      setState(() => _boostingId = null);
      GardenToast.show(context, text: error ?? 'common.error'.tr(), color: const Color(0xFFDC6B4A));
    }
  }

  Future<void> _harvest(PlantedItem planted, GardenItem item, GardenProvider garden) async {
    HapticFeedback.heavyImpact();
    setState(() {
      _selectedId = null;
      _burst(planted.instanceId);
    });
    final harvest = await garden.harvestPlant(planted.instanceId);
    if (!mounted || harvest == null || !harvest.hasAnything) return;
    SoundService.instance.play(Sfx.harvest, volume: 0.65);
    AnalyticsService.instance.gardenAction('harvest', itemId: item.id);
    await HarvestDialog.show(context, plant: item, harvest: harvest);
  }

  Future<void> _returnPlant(PlantedItem planted, GardenItem item, GardenProvider garden) async {
    final ok = await confirmReturnPlant(context, item);
    if (!ok || !mounted) return;
    await garden.removePlant(planted.instanceId);
    if (!mounted) return;
    SoundService.instance.play(Sfx.pop, volume: 0.5);
    setState(() => _selectedId = null);
    GardenToast.show(context, text: 'garden.plantReturned'.tr(), leading: GardenItemImage(item: item, size: 28, stage: PlantStage.seed, aura: false));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Decoraciones
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadDecos(GardenProvider garden) async {
    final data = await garden.loadPlacedDecorations();
    if (!mounted) return;
    setState(() {
      _decos
        ..clear()
        ..addAll(data.map(PlacedDeco.fromMap));
      _decosLoaded = true;
    });
  }

  Future<void> _saveDecos(GardenProvider garden) async {
    if (!_decosLoaded) return;
    await garden.savePlacedDecorations(_decos.map((d) => d.toMap()).toList());
  }

  Future<void> _dropDeco(Object data, Offset pointer, BuildContext sceneContext, double w, double h, GardenProvider garden) async {
    final box = sceneContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final itemId = switch (data) {
      NewDecoDrag(:final itemId) => itemId,
      PlacedDeco(:final itemId) => itemId,
      _ => null,
    };
    if (itemId == null) return;
    final item = GardenCatalog.findById(itemId);
    if (item == null) return;

    final local = box.globalToLocal(pointer - Offset(0, DecoDragFeedback.lift(itemId)));
    final (bx, by) = GardenLayout.toBackground(local.dx, local.dy, w, h);
    final moving = data is PlacedDeco ? data : null;

    final result = GardenRules.checkDecoration(
      fx: bx,
      fy: by,
      slots: [for (final s in _garden.slots) (s.anchorX, s.anchorY)],
      decos: [
        for (final d in _decos)
          if (d.gardenId == _garden.id && d.instanceId != moving?.instanceId) d.backgroundPoint(w, h),
      ],
      visible: GardenLayout.visibleArea(w, h),
    );

    if (result != DecoPlacement.ok) {
      HapticFeedback.heavyImpact();
      SoundService.instance.play(Sfx.wrong, volume: 0.4);
      GardenToast.show(
        context,
        text: switch (result) {
          DecoPlacement.nearPlant => 'garden.decoNearPlant'.tr(),
          DecoPlacement.nearDeco => 'garden.decoNearDeco'.tr(),
          _ => 'garden.decoOutside'.tr(),
        },
        color: GardenPalette.gold,
        leading: GardenItemImage(item: item, size: 28, aura: false),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    SoundService.instance.play(Sfx.decoPlace, volume: 0.6);
    if (moving != null) {
      setState(() {
        final i = _decos.indexWhere((d) => d.instanceId == moving.instanceId);
        if (i >= 0) _decos[i] = moving.movedTo(bx, by);
        _burst(moving.instanceId);
      });
    } else {
      final deco = PlacedDeco(
        instanceId: '${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}',
        itemId: itemId,
        gardenId: _garden.id,
        fx: bx,
        fy: by,
      );
      setState(() {
        _decos.add(deco);
        _burst(deco.instanceId);
      });
      AnalyticsService.instance.gardenAction('decorate', itemId: itemId);
      await garden.spendDecoration(itemId);
    }
    await _saveDecos(garden);
  }

  Future<void> _openDecoOptions(PlacedDeco deco, GardenItem item, GardenProvider garden) async {
    SoundService.instance.shine(RarityStyle.shine(item.rarity), volume: 0.35);
    final store = await showDecoOptionsSheet(context, item);
    if (!store || !mounted) return;
    setState(() => _decos.removeWhere((d) => d.instanceId == deco.instanceId));
    SoundService.instance.play(Sfx.pop, volume: 0.5);
    await garden.returnDecoration(deco.itemId);
    await _saveDecos(garden);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Hojas y navegación
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _openShop() async {
    SoundService.instance.play(Sfx.tapNode, volume: 0.4);
    _cancelModes();
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
  }

  Future<void> _openGardens(GardenProvider garden) async {
    SoundService.instance.play(Sfx.tapNode, volume: 0.4);
    final counts = <String, int>{};
    for (final p in garden.garden) {
      counts[p.gardenId] = (counts[p.gardenId] ?? 0) + 1;
    }
    final picked = await showGardenSelectorSheet(context, currentId: _garden.id, plantsPerGarden: counts);
    if (picked == null || picked.id == _garden.id || !mounted) return;
    SoundService.instance.play(Sfx.swipe, volume: 0.5);
    setState(() {
      _garden = picked;
      _selectedId = null;
      _plantingId = null;
      _boostingId = null;
    });
    _startAmbient();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefActiveGarden, picked.id);
    } catch (_) {}
  }

  Future<void> _openProgress(GardenProvider garden) {
    SoundService.instance.play(Sfx.tapNode, volume: 0.4);
    final here = garden.garden.where((p) => p.gardenId == _garden.id).toList();
    return showGardenProgressSheet(
      context,
      gardenName: _garden.nameKey.tr(),
      plants: here.length,
      adults: here.where((p) {
        final item = GardenCatalog.findById(p.itemId);
        return item != null && p.isAdult(item);
      }).length,
      decorations: _decos.where((d) => d.gardenId == _garden.id).length,
      slots: _garden.slots.length,
    );
  }

  Future<void> _openShields(GardenProvider garden) async {
    final auth = context.read<AuthProvider>();
    final use = await showShieldSheet(context, shields: garden.streakShields, canUse: garden.canUseShield);
    if (!use || !mounted) return;
    final recovered = await garden.useStreakShield();
    if (recovered > 0) await auth.restoreStreakWithShield(recovered);
    if (recovered > 0 && mounted) {
      SoundService.instance.play(Sfx.unlock, volume: 0.6);
      GardenToast.show(context, text: 'home.shieldUsed'.tr(), color: GardenPalette.gold, leading: const Text('🛡️', style: TextStyle(fontSize: 20)));
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Piezas de la escena
// ═════════════════════════════════════════════════════════════════════════════

/// Decoración colocada: tocar abre opciones, mantener presionado la mueve.
class _PlacedDecoView extends StatelessWidget {
  final PlacedDeco deco;
  final GardenItem item;
  final double size;
  final int burst;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final VoidCallback onTap;

  const _PlacedDecoView({
    required this.deco,
    required this.item,
    required this.size,
    required this.burst,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = GardenItemImage(item: item, size: size);
    return LongPressDraggable<PlacedDeco>(
      data: deco,
      delay: const Duration(milliseconds: 280),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: DecoDragFeedback(item: item),
      childWhenDragging: Opacity(opacity: 0.25, child: image),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
        SoundService.instance.play(Sfx.leafTap, volume: 0.4);
        onDragStarted();
      },
      onDragEnd: (_) => onDragEnded(),
      child: GardenPressable(
        onTap: onTap,
        semanticsLabel: '${item.nameKey.tr()}. ${'garden.decoOptions.moveHint'.tr()}',
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            image.animate(key: ValueKey('deco_in_$burst')).scale(
                  begin: burst == 0 ? const Offset(1, 1) : const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
            if (burst > 0 && !MotionService.reduced(context))
              SparkleBurst(key: ValueKey('deco_burst_$burst'), color: item.auraColor, size: size * 1.4, seed: burst),
          ],
        ),
      ),
    );
  }
}

/// Mientras se arrastra una decoración, los huecos de plantas se marcan como
/// zona reservada.
class _NoDecoZone extends StatelessWidget {
  final double size;
  const _NoDecoZone({required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size * 0.7,
        height: size * 0.44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.elliptical(size * 0.7, size * 0.44)),
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
        ),
        child: const Icon(Icons.eco_rounded, color: Colors.white70, size: 20),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

/// De noche el jardín se oscurece un poco y salen luciérnagas.
class _NightVeil extends StatelessWidget {
  const _NightVeil();

  @override
  Widget build(BuildContext context) {
    final reduced = MotionService.reduced(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF0B1030).withValues(alpha: 0.32)),
        for (int i = 0; i < 12; i++)
          Align(
            alignment: Alignment(
              math.sin(i * 2.4) * 0.9,
              -0.3 + math.cos(i * 1.7) * 0.6,
            ),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFDE68A),
                boxShadow: [BoxShadow(color: const Color(0xFFFDE68A).withValues(alpha: 0.7), blurRadius: 8, spreadRadius: 2)],
              ),
            )
                .animate(onPlay: reduced ? null : (c) => c.repeat(reverse: true), delay: (i * 230).ms)
                .fadeIn(duration: (1400 + i * 90).ms)
                .moveY(begin: 6, end: -10, duration: (2600 + i * 150).ms, curve: Curves.easeInOut)
                .moveX(begin: -4, end: 4, duration: (2600 + i * 150).ms, curve: Curves.easeInOut),
          ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  final GardenDef garden;
  const _Loading({required this.garden});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(garden.assetPath, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: garden.tint)),
        Container(color: Colors.black.withValues(alpha: 0.35)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌱', style: TextStyle(fontSize: 48))
                  .animate(onPlay: MotionService.loop(context, reverse: true))
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 800.ms, curve: Curves.easeInOut),
              const SizedBox(height: 10),
              Text(
                'garden.loading'.tr(),
                style: JournalStyle.hand(const TextStyle(fontSize: 22, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 8)])),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
