import '../../core/utils/firestore_access.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../data/models/garden_item.dart';
import '../../data/models/garden_state.dart';
import '../../data/models/reward_service.dart';
import '../../data/models/garden_mechanics.dart';
import 'package:easy_localization/easy_localization.dart';

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

  RewardResult? _pendingReward;
  RewardResult? get pendingReward => _pendingReward;

  // ── Mecánicas ──────────────────────────────────────────────────────────────
  int _streakShields = 0;
  int get streakShields => _streakShields;

  // Racha que el escudo puede recuperar (estilo TikTok)
  int _lastStreakBeforeBreak = 0;
  // Día (y-m-d local) en que se detectó la racha rota; el escudo solo vale ese día
  String? _streakBreakDate;
  int get lastStreakBeforeBreak => _lastStreakBeforeBreak;

  XpMultiplierState? _activeMultiplier;
  XpMultiplierState? get activeMultiplier {
    if (_activeMultiplier != null && !_activeMultiplier!.isActive) {
      _activeMultiplier = null;
    }
    return _activeMultiplier;
  }

  HarvestResult? _lastHarvest;
  HarvestResult? get lastHarvest => _lastHarvest;
  void clearLastHarvest() {
    _lastHarvest = null;
    notifyListeners();
  }

  // ── Shortcuts ──────────────────────────────────────────────────────────────
  int get seeds => _state.seeds;
  List<PlantedItem> get garden => _state.garden;
  List<InventoryItem> get inventory => _state.inventory;

  // ── Firestore paths ────────────────────────────────────────────────────────
  DocumentReference? get _gardenDoc {
    if (_user == null) return null;
    return _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('garden')
        .doc('state');
  }

  DocumentReference? get _mechanicsDoc {
    if (_user == null) return null;
    return _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('garden')
        .doc('mechanics');
  }

  DocumentReference? get _decoDoc {
    if (_user == null) return null;
    return _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('garden')
        .doc('decorations');
  }

  static const _kMultiplierPrefix = 'garden_xp_multiplier';

  /// Por usuario: si no, el multiplicador de una cuenta se le aplicaba a la
  /// siguiente que entrara en el mismo teléfono.
  String get _kMultiplierKey {
    final uid = _user?.uid;
    return uid == null ? _kMultiplierPrefix : '${_kMultiplierPrefix}_$uid';
  }

  /// Usuario cuyo jardín está cargado en memoria. Si no coincide con la sesión
  /// actual, no se guarda nada: así el jardín de una cuenta nunca se escribe
  /// encima de otra al cambiar de usuario.
  String? _loadedUid;

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> loadGarden() async {
    if (_user == null) return;
    try {
      _isLoading = true;
      notifyListeners();

      _loadedUid = _user!.uid;
      final doc = await _gardenDoc!.getFast();
      if (doc.exists) {
        _state = GardenState.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        _state = GardenState.initial();
        await _saveToFirestore();
      }

      await _loadMechanics();
    } catch (e) {
      debugPrint('Error loading garden: $e');
      _state = GardenState.initial();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMechanics() async {
    _streakShields = 0;
    _lastStreakBeforeBreak = 0;
    _streakBreakDate = null;
    _activeMultiplier = null;
    try {
      if (_mechanicsDoc != null) {
        final doc = await _mechanicsDoc!.getFast();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _streakShields = (data['streakShields'] as int? ?? 0).clamp(0, 3);
          _lastStreakBeforeBreak = data['lastStreakBeforeBreak'] as int? ?? 0;
          _streakBreakDate = data['streakBreakDate'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Error loading mechanics: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_kMultiplierKey);
      if (json != null) {
        final mult = XpMultiplierState.fromMap(
            Map<String, dynamic>.from(jsonDecode(json)));
        if (mult.isActive) {
          _activeMultiplier = mult;
        } else {
          await prefs.remove(_kMultiplierKey);
        }
      }
    } catch (e) {
      debugPrint('Error loading multiplier: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COSECHA INDIVIDUAL POR PLANTA
  // ═══════════════════════════════════════════════════════════════════════════

  Future<HarvestResult?> harvestPlant(String instanceId) async {
    if (_user == null) return null;

    try {
      final plantIndex =
          _state.garden.indexWhere((p) => p.instanceId == instanceId);
      if (plantIndex == -1) return null;

      final planted = _state.garden[plantIndex];
      final item = GardenCatalog.findById(planted.itemId);
      if (item == null) return null;

      if (!planted.hasPendingHarvestFor(item)) return null;

      final mechanics = mechanicsFor(planted.itemId);
      final seedsEarned = mechanics.seedsPerDay;

      // ── Boost XP: máximo 8%, solo si no hay boost activo ──────────────
      bool gotMultiplier = false;
      double multiplierValue = 1.0;
      int multiplierMins = 0;

      if (_activeMultiplier == null) {
        final boostChance = (mechanics.xpMultiplierChance * 0.35).clamp(0.0, 0.08);
        if (_rng.nextDouble() < boostChance) {
          gotMultiplier = true;
          multiplierValue = mechanics.xpMultiplier;
          multiplierMins = mechanics.xpMultiplierMinutes;
        }
      }

      // ── Escudo: máximo 5%, solo si tienes <2, cooldown semanal ────────
      bool gotShield = false;
      String? shieldPlant;

      if (mechanics.canGiveStreakShield && _streakShields < 2) {
        final prefs = await SharedPreferences.getInstance();
        final today = DateTime.now();
        final weekNumber =
            today.difference(DateTime(today.year, 1, 1)).inDays ~/ 7;
        final weekKey = 'shield_${planted.instanceId}_week_$weekNumber';
        final alreadyThisWeek = prefs.getBool(weekKey) ?? false;

        if (!alreadyThisWeek) {
          final shieldChance = (mechanics.shieldChance * 0.30).clamp(0.0, 0.05);
          if (_rng.nextDouble() < shieldChance) {
            gotShield = true;
            shieldPlant = item.nameKey;
            await prefs.setBool(weekKey, true);
          }
        }
      }

      // ── Aplicar recompensas ────────────────────────────────────────────
      if (seedsEarned > 0) {
        await addSeeds(seedsEarned, source: 'plant_harvest');
      }

      if (gotMultiplier) {
        _activeMultiplier = XpMultiplierState(
          multiplier: multiplierValue,
          expiresAt: DateTime.now().add(Duration(minutes: multiplierMins)),
        );
        final prefs2 = await SharedPreferences.getInstance();
        await prefs2.setString(
            _kMultiplierKey, jsonEncode(_activeMultiplier!.toMap()));
      }

      if (gotShield) {
        _streakShields = (_streakShields + 1).clamp(0, 3);
        await _saveMechanics();
      }

      // ── Marcar cosechada hoy ───────────────────────────────────────────
      final updatedPlant = planted.copyWith(
        lastHarvestedAt: DateTime.now(),
      );
      final newGarden = List<PlantedItem>.from(_state.garden);
      newGarden[plantIndex] = updatedPlant;
      _state = _state.copyWith(garden: newGarden);
      await _saveToFirestore();

      final result = HarvestResult(
        seedsEarned: seedsEarned,
        gotXpMultiplier: gotMultiplier,
        xpMultiplier: multiplierValue,
        multiplierMinutes: multiplierMins,
        gotStreakShield: gotShield,
        shieldFromPlant: shieldPlant,
      );

      _lastHarvest = result;
      notifyListeners();
      return result;
    } catch (e) {
      debugPrint('Error harvesting plant $instanceId: $e');
      return null;
    }
  }

  Future<HarvestResult?> checkDailyHarvest() async {
    if (_user == null) return null;
    HarvestResult? combined;
    for (final planted in List<PlantedItem>.from(_state.garden)) {
      final item = GardenCatalog.findById(planted.itemId);
      if (item == null) continue;
      if (!planted.hasPendingHarvestFor(item)) continue;
      final result = await harvestPlant(planted.instanceId);
      if (result != null) {
        combined = HarvestResult(
          seedsEarned: (combined?.seedsEarned ?? 0) + result.seedsEarned,
          gotXpMultiplier:
              (combined?.gotXpMultiplier ?? false) || result.gotXpMultiplier,
          xpMultiplier: result.xpMultiplier,
          multiplierMinutes: result.multiplierMinutes,
          gotStreakShield:
              (combined?.gotStreakShield ?? false) || result.gotStreakShield,
          shieldFromPlant:
              combined?.shieldFromPlant ?? result.shieldFromPlant,
        );
      }
    }
    return combined;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ESCUDO DE RACHA — estilo TikTok
  // ═══════════════════════════════════════════════════════════════════════════

  static String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Guarda la racha que se acaba de romper para que un escudo pueda
  /// recuperarla hoy. HomeScreen la llama al detectar la racha rota.
  Future<void> saveStreakBeforeBreak(int brokenStreak) async {
    if (brokenStreak <= 0) return;
    final today = _dateKey(DateTime.now());
    if (_lastStreakBeforeBreak == brokenStreak && _streakBreakDate == today) {
      return;
    }
    _lastStreakBeforeBreak = brokenStreak;
    _streakBreakDate = today;
    await _saveMechanics();
    notifyListeners();
  }

  /// ¿Puede usarse el escudo ahora? Solo el día en que se detectó la racha
  /// rota (antes o después del check-in de hoy), con escudos disponibles.
  bool get canUseShield =>
      _streakShields > 0 &&
      _lastStreakBeforeBreak > 0 &&
      _streakBreakDate == _dateKey(DateTime.now());

  /// Usa un escudo → devuelve el valor de racha a recuperar.
  /// Retorna 0 si no se pudo usar.
  Future<int> useStreakShield() async {
    if (!canUseShield) return 0;

    try {
      final recoveredStreak = _lastStreakBeforeBreak;
      _streakShields = (_streakShields - 1).clamp(0, 3);
      _lastStreakBeforeBreak = 0;
      _streakBreakDate = null;
      await _saveMechanics();
      notifyListeners();
      return recoveredStreak;
    } catch (e) {
      debugPrint('Error using streak shield: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MULTIPLICADOR XP
  // ═══════════════════════════════════════════════════════════════════════════

  double get currentXpMultiplier {
    final m = activeMultiplier;
    return m != null ? m.multiplier : 1.0;
  }

  Future<void> clearMultiplier() async {
    _activeMultiplier = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kMultiplierKey);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEEDS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> addSeeds(int amount, {String? source}) async {
    if (_user == null || amount <= 0) return;
    try {
      _state = _state.copyWith(
        seeds: _state.seeds + amount,
        totalSeedsEarned: _state.totalSeedsEarned + amount,
      );
      await _saveToFirestore();
      await _logSeedTransaction(amount, source ?? 'unknown');
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding seeds: $e');
    }
  }

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
  // SHOP
  // ═══════════════════════════════════════════════════════════════════════════

  Future<(bool, String?)> buyItem(GardenItem item) async {
    if (_user == null) return (false, 'errors.noSession'.tr());
    if (!item.canBuyWithSeeds) {
      return (false, 'garden.errors.notForSeeds'.tr());
    }
    if (!item.isCurrentlyAvailable) {
      return (false, 'garden.errors.notAvailableNow'.tr());
    }
    if (_state.seeds < item.seedCost) {
      return (false, 'garden.notEnoughSeeds'.tr());
    }

    try {
      final spent = await spendSeeds(item.seedCost);
      if (!spent) return (false, 'garden.notEnoughSeeds'.tr());
      _addToInventory(item.id, 1);
      await _saveToFirestore();
      notifyListeners();
      return (true, null);
    } catch (e) {
      debugPrint('Error buying item: $e');
      return (false, 'garden.errors.buyFailed'.tr());
    }
  }

  Future<void> registerPremiumPurchase(String itemId) async {
    if (_user == null) return;
    try {
      final item = GardenCatalog.findById(itemId);
      if (item == null) return;
      final newPurchasedIds = List<String>.from(_state.purchasedIds);
      if (!newPurchasedIds.contains(itemId)) newPurchasedIds.add(itemId);
      _state = _state.copyWith(purchasedIds: newPurchasedIds);
      _addToInventory(itemId, 1);
      await _saveToFirestore();
      await _logPremiumPurchase(itemId, item.premiumCost ?? 0);
      notifyListeners();
    } catch (e) {
      debugPrint('Error registering premium purchase: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GARDEN — plantar
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isSlotFree(String gardenId, int slotIndex) =>
      !_state.garden
          .any((p) => p.gardenId == gardenId && p.slotIndex == slotIndex);

  Future<(bool, String?)> plantItemInSlot(
      String itemId, String gardenId, int slotIndex) async {
    if (_user == null) return (false, 'errors.noSession'.tr());
    if (!_state.hasInInventory(itemId)) {
      return (false, 'garden.errors.notInInventory'.tr());
    }
    if (!_isSlotFree(gardenId, slotIndex)) {
      return (false, 'garden.positionOccupied'.tr());
    }

    try {
      final planted = PlantedItem(
        instanceId: _generateId(),
        itemId: itemId,
        plantedAt: DateTime.now(),
        gardenId: gardenId,
        slotIndex: slotIndex,
      );
      _removeFromInventory(itemId, 1);
      final newGarden = List<PlantedItem>.from(_state.garden)..add(planted);
      _state = _state.copyWith(garden: newGarden);
      await _saveToFirestore();
      notifyListeners();
      return (true, null);
    } catch (e) {
      debugPrint('Error planting item: $e');
      return (false, 'garden.errors.plantFailed'.tr());
    }
  }

  Future<(bool, String?)> applyBooster(
      String boosterItemId, String plantInstanceId) async {
    if (_user == null) return (false, 'errors.noSession'.tr());
    final booster = GardenCatalog.findById(boosterItemId);
    if (booster == null || booster.type != ItemType.booster) {
      return (false, 'garden.errors.invalidItem'.tr());
    }
    if (!_state.hasInInventory(boosterItemId)) {
      return (false, 'garden.errors.noBooster'.tr());
    }

    final plantIndex =
        _state.garden.indexWhere((p) => p.instanceId == plantInstanceId);
    if (plantIndex == -1) return (false, 'garden.errors.plantNotFound'.tr());

    final plant = _state.garden[plantIndex];
    final plantItem = GardenCatalog.findById(plant.itemId);
    if (plantItem == null) return (false, 'garden.errors.plantNotFound'.tr());
    if (plant.isAdult(plantItem)) return (false, 'garden.errors.alreadyAdult'.tr());

    try {
      final boost = booster.boostDuration ?? Duration.zero;
      final updatedPlant = plant.copyWith(
        totalBoosted: plant.totalBoosted + boost,
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
      return (false, 'garden.errors.boosterFailed'.tr());
    }
  }

  Future<void> removePlant(String instanceId) async {
    if (_user == null) return;
    try {
      final plant =
          _state.garden.firstWhere((p) => p.instanceId == instanceId);
      final newGarden =
          _state.garden.where((p) => p.instanceId != instanceId).toList();
      _addToInventory(plant.itemId, 1);
      _state = _state.copyWith(garden: newGarden);
      await _saveToFirestore();
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing plant: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REWARDS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<RewardResult> grantReward(RewardSource source) async {
    final reward = RewardService.generate(source);
    await _applyReward(reward);
    _pendingReward = reward;
    notifyListeners();
    return reward;
  }

  Future<RewardResult> grantStreakReward(int streakDays) async {
    final reward = RewardService.generateStreakReward(streakDays);
    await _applyReward(reward);
    _pendingReward = reward;
    notifyListeners();
    return reward;
  }

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
  // DECORACIONES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> spendDecoration(String itemId) async {
    _removeFromInventory(itemId, 1);
    await _saveToFirestore();
    notifyListeners();
  }

  Future<void> returnDecoration(String itemId) async {
    _addToInventory(itemId, 1);
    await _saveToFirestore();
    notifyListeners();
  }

  Future<void> savePlacedDecorations(List<Map<String, dynamic>> decos) async {
    if (_decoDoc == null) return;
    try {
      await queueWrite(_decoDoc!.set({'items': decos}), 'decoraciones');
    } catch (e) {
      debugPrint('Error saving decorations: $e');
    }
  }

  Future<List<Map<String, dynamic>>> loadPlacedDecorations() async {
    if (_decoDoc == null) return [];
    try {
      final doc = await _decoDoc!.getFast();
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>?;
      final items = data?['items'] as List<dynamic>? ?? [];
      return items.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading decorations: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNOS
  // ═══════════════════════════════════════════════════════════════════════════

  void _addToInventory(String itemId, int quantity) {
    final newInventory = List<InventoryItem>.from(_state.inventory);
    final index = newInventory.indexWhere((i) => i.itemId == itemId);
    if (index >= 0) {
      newInventory[index] = newInventory[index]
          .copyWith(quantity: newInventory[index].quantity + quantity);
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
      newInventory[index] =
          newInventory[index].copyWith(quantity: current - quantity);
    }
    _state = _state.copyWith(inventory: newInventory);
  }

  /// true si lo que hay en memoria es del usuario con sesión abierta.
  bool get _isOwnState => _user != null && _loadedUid == _user!.uid;

  Future<void> _saveToFirestore() async {
    if (_gardenDoc == null) return;
    if (!_isOwnState) {
      debugPrint('Garden save skipped: state belongs to $_loadedUid');
      return;
    }
    try {
      await queueWrite(_gardenDoc!.set(_state.toMap()), 'jardín');
    } catch (e) {
      debugPrint('Error saving garden to Firestore: $e');
    }
  }

  Future<void> _saveMechanics() async {
    if (_mechanicsDoc == null) return;
    if (!_isOwnState) {
      debugPrint('Garden mechanics save skipped: state belongs to $_loadedUid');
      return;
    }
    try {
      await queueWrite(
        _mechanicsDoc!.set({
          'streakShields': _streakShields,
          'lastStreakBeforeBreak': _lastStreakBeforeBreak,
          'streakBreakDate': _streakBreakDate,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        'mecánicas del jardín',
      );
    } catch (e) {
      debugPrint('Error saving mechanics: $e');
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
        'revenuecat_id': null,
      });
    } catch (e) {
      debugPrint('Error logging premium purchase: $e');
    }
  }

  void resetOnLogout() {
    _state = const GardenState();
    _loadedUid = null;
    _pendingReward = null;
    _isLoading = false;
    _errorMessage = null;
    _streakShields = 0;
    _lastStreakBeforeBreak = 0;
    _streakBreakDate = null;
    _activeMultiplier = null;
    _lastHarvest = null;
    notifyListeners();
  }
}