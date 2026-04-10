import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/garden_item.dart';
import '../../data/models/garden_state.dart';
import '../../data/models/reward_service.dart';

class GardenProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _rng = Random();

  String _generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${_rng.nextInt(99999)}';

  User? get _user => _auth.currentUser;

  // ── State ──────────────────────────────────────────────────────────────────
  GardenState _state = const GardenState();
  GardenState get state => _state;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Recompensa pendiente de mostrar en el RewardDialog
  RewardResult? _pendingReward;
  RewardResult? get pendingReward => _pendingReward;

  // ── Shortcuts ──────────────────────────────────────────────────────────────
  int get seeds => _state.seeds;
  List<PlantedItem> get garden => _state.garden;
  List<InventoryItem> get inventory => _state.inventory;

  // ── Firestore path ─────────────────────────────────────────────────────────
  DocumentReference? get _gardenDoc {
    if (_user == null) return null;
    return _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('garden')
        .doc('state');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> loadGarden() async {
    if (_user == null) return;
    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _gardenDoc!.get();
      if (doc.exists) {
        _state = GardenState.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        // Usuario nuevo — estado inicial con regalo de bienvenida
        _state = GardenState.initial();
        await _saveToFirestore();
      }
    } catch (e) {
      debugPrint('Error loading garden: $e');
      _state = GardenState.initial();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEEDS — dar y gastar
  // ═══════════════════════════════════════════════════════════════════════════

  /// Añade semillas al usuario (llamado desde retos, lecciones, etc.)
  Future<void> addSeeds(int amount, {String? source}) async {
    if (_user == null || amount <= 0) return;
    try {
      _state = _state.copyWith(
        seeds: _state.seeds + amount,
        totalSeedsEarned: _state.totalSeedsEarned + amount,
      );
      await _saveToFirestore();

      // Log de transacción para historial
      await _logSeedTransaction(amount, source ?? 'unknown');
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding seeds: $e');
    }
  }

  /// Gasta semillas (retorna false si no alcanza)
  Future<bool> spendSeeds(int amount) async {
    if (_user == null) return false;
    if (_state.seeds < amount) return false;
    try {
      _state = _state.copyWith(seeds: _state.seeds - amount);
      await _saveToFirestore();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error spending seeds: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHOP — comprar items
  // ═══════════════════════════════════════════════════════════════════════════

  /// Compra un item con semillas y lo añade al inventario
  Future<(bool, String?)> buyItem(GardenItem item) async {
    if (_user == null) return (false, 'No hay sesión activa');
    if (!item.canBuyWithSeeds) return (false, 'Este item no está disponible con semillas');
    if (!item.isCurrentlyAvailable) return (false, 'Este item no está disponible ahora');
    if (_state.seeds < item.seedCost) {
      return (false, 'No tienes suficientes semillas');
    }

    try {
      // Descontar semillas
      final spent = await spendSeeds(item.seedCost);
      if (!spent) return (false, 'No tienes suficientes semillas');

      // Añadir al inventario
      _addToInventory(item.id, 1);
      await _saveToFirestore();
      notifyListeners();
      return (true, null);
    } catch (e) {
      debugPrint('Error buying item: $e');
      return (false, 'Error al comprar. Intenta de nuevo.');
    }
  }

  /// Registra una compra premium (llamado después de validar con RevenueCat)
  Future<void> registerPremiumPurchase(String itemId) async {
    if (_user == null) return;
    try {
      final item = GardenCatalog.findById(itemId);
      if (item == null) return;

      final newPurchasedIds = List<String>.from(_state.purchasedIds);
      if (!newPurchasedIds.contains(itemId)) {
        newPurchasedIds.add(itemId);
      }

      _state = _state.copyWith(purchasedIds: newPurchasedIds);
      _addToInventory(itemId, 1);
      await _saveToFirestore();

      // Log de compra premium para historial / restore
      await _logPremiumPurchase(itemId, item.premiumCost ?? 0);
      notifyListeners();
    } catch (e) {
      debugPrint('Error registering premium purchase: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GARDEN — plantar y usar boosters
  // ═══════════════════════════════════════════════════════════════════════════

  /// Planta un item del inventario en una posición del grid
  Future<(bool, String?)> plantItem(String itemId, int gridX, int gridY) async {
    if (_user == null) return (false, 'No hay sesión activa');

    // Verificar que tiene el item en inventario
    if (!_state.hasInInventory(itemId)) {
      return (false, 'No tienes este item en tu inventario');
    }

    // Verificar posición libre
    if (!_state.isPositionFree(gridX, gridY)) {
      return (false, 'Esta posición ya está ocupada');
    }

    // Verificar límite del grid (6x4 = 24 posiciones)
    if (gridX < 0 || gridX > 5 || gridY < 0 || gridY > 3) {
      return (false, 'Posición inválida');
    }

    try {
      final planted = PlantedItem(
        instanceId: _generateId(),
        itemId: itemId,
        plantedAt: DateTime.now(),
        gridX: gridX,
        gridY: gridY,
      );

      // Quitar del inventario
      _removeFromInventory(itemId, 1);

      // Añadir al jardín
      final newGarden = List<PlantedItem>.from(_state.garden)..add(planted);
      _state = _state.copyWith(garden: newGarden);
      await _saveToFirestore();
      notifyListeners();
      return (true, null);
    } catch (e) {
      debugPrint('Error planting item: $e');
      return (false, 'Error al plantar. Intenta de nuevo.');
    }
  }

  /// Aplica un booster a una planta para acelerar su crecimiento
  Future<(bool, String?)> applyBooster(
      String boosterItemId, String plantInstanceId) async {
    if (_user == null) return (false, 'No hay sesión activa');

    final booster = GardenCatalog.findById(boosterItemId);
    if (booster == null || booster.type != ItemType.booster) {
      return (false, 'Item inválido');
    }
    if (!_state.hasInInventory(boosterItemId)) {
      return (false, 'No tienes este booster');
    }

    final plantIndex = _state.garden
        .indexWhere((p) => p.instanceId == plantInstanceId);
    if (plantIndex == -1) return (false, 'Planta no encontrada');

    final plant = _state.garden[plantIndex];
    final plantItem = GardenCatalog.findById(plant.itemId);
    if (plantItem == null) return (false, 'Item de planta no encontrado');
    if (plant.isAdult(plantItem)) return (false, 'Esta planta ya está adulta');

    try {
      // Calcular boost — elixir zen completa al instante
      final boost = booster.boostDuration ?? Duration.zero;
      final newTotalBoosted = plant.totalBoosted + boost;

      final updatedPlant = plant.copyWith(
        totalBoosted: newTotalBoosted,
        boostedAt: DateTime.now(),
      );

      final newGarden = List<PlantedItem>.from(_state.garden);
      newGarden[plantIndex] = updatedPlant;

      _removeFromInventory(boosterItemId, 1);
      _state = _state.copyWith(garden: newGarden);
      await _saveToFirestore();
      notifyListeners();
      return (true, null);
    } catch (e) {
      debugPrint('Error applying booster: $e');
      return (false, 'Error al aplicar booster.');
    }
  }

  /// Elimina una planta del jardín y la devuelve al inventario
  Future<void> removePlant(String instanceId) async {
    if (_user == null) return;
    try {
      final plant = _state.garden
          .firstWhere((p) => p.instanceId == instanceId);
      final newGarden = _state.garden
          .where((p) => p.instanceId != instanceId)
          .toList();

      // Devolver al inventario
      _addToInventory(plant.itemId, 1);
      _state = _state.copyWith(garden: newGarden);
      await _saveToFirestore();
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing plant: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REWARDS — sistema de recompensas aleatorias
  // ═══════════════════════════════════════════════════════════════════════════

  /// Genera y aplica una recompensa aleatoria según la fuente
  /// Retorna el resultado para mostrarlo en el RewardDialog
  Future<RewardResult> grantReward(RewardSource source) async {
    final reward = RewardService.generate(source);
    await _applyReward(reward);
    _pendingReward = reward;
    notifyListeners();
    return reward;
  }

  /// Genera recompensa de streak milestone
  Future<RewardResult> grantStreakReward(int streakDays) async {
    final reward = RewardService.generateStreakReward(streakDays);
    await _applyReward(reward);
    _pendingReward = reward;
    notifyListeners();
    return reward;
  }

  /// Limpia la recompensa pendiente (después de mostrar el dialog)
  void consumePendingReward() {
    _pendingReward = null;
    notifyListeners();
  }

  Future<void> _applyReward(RewardResult reward) async {
    if (reward.isSeeds) {
      await addSeeds(reward.seeds, source: 'reward');
    } else if (reward.isItem && reward.item != null) {
      _addToInventory(reward.item!.id, 1);
      await _saveToFirestore();
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNOS
  // ═══════════════════════════════════════════════════════════════════════════

  void _addToInventory(String itemId, int quantity) {
    final newInventory = List<InventoryItem>.from(_state.inventory);
    final index = newInventory.indexWhere((i) => i.itemId == itemId);
    if (index >= 0) {
      newInventory[index] = newInventory[index].copyWith(
        quantity: newInventory[index].quantity + quantity,
      );
    } else {
      newInventory.add(InventoryItem(itemId: itemId, quantity: quantity));
    }
    _state = _state.copyWith(inventory: newInventory);
  }

  void _removeFromInventory(String itemId, int quantity) {
    final newInventory = List<InventoryItem>.from(_state.inventory);
    final index = newInventory.indexWhere((i) => i.itemId == itemId);
    if (index < 0) return;

    final current = newInventory[index].quantity;
    if (current <= quantity) {
      newInventory.removeAt(index);
    } else {
      newInventory[index] = newInventory[index].copyWith(
        quantity: current - quantity,
      );
    }
    _state = _state.copyWith(inventory: newInventory);
  }

  Future<void> _saveToFirestore() async {
    if (_gardenDoc == null) return;
    try {
      await _gardenDoc!.set(_state.toMap());
    } catch (e) {
      debugPrint('Error saving garden to Firestore: $e');
    }
  }

  Future<void> _logSeedTransaction(int amount, String source) async {
    if (_user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('garden_transactions')
          .add({
        'type': 'seeds',
        'amount': amount,
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging seed transaction: $e');
    }
  }

  /// Log de compra premium — listo para reconciliar con RevenueCat
  Future<void> _logPremiumPurchase(String itemId, double price) async {
    if (_user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('garden_transactions')
          .add({
        'type': 'premium_purchase',
        'itemId': itemId,
        'price': price,
        'currency': 'USD',
        'timestamp': FieldValue.serverTimestamp(),
        // RevenueCat añadirá aquí: transactionId, productId, etc.
        'revenuecat_id': null,
      });
    } catch (e) {
      debugPrint('Error logging premium purchase: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════
  void resetOnLogout() {
    _state = const GardenState();
    _pendingReward = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}