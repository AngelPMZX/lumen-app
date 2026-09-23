import '../../core/utils/firestore_access.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/models/user_model.dart';
import '../../data/models/user_progress.dart';
import '../../data/models/mood_entry.dart';
import '../../data/models/diary_entry.dart';
import '../../data/models/reminder.dart';
import '../../data/models/habit.dart';
import '../../data/models/habit_xp_quota.dart';
import '../../domain/services/achievement_service.dart';
import '../providers/garden_provider.dart';
import '../services/notification_service.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../data/models/journal_insights.dart';
import '../services/diary_draft_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get firebaseUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isGoogleUser =>
      firebaseUser?.providerData.any((p) => p.providerId == 'google.com') ??
      false;
  /// Tiene contraseña, aunque también haya vinculado Google con el mismo email.
  bool get hasPassword =>
      firebaseUser?.providerData.any((p) => p.providerId == 'password') ??
      false;
  /// Solo entra con Google: no hay contraseña que cambiar ni con qué confirmar.
  bool get isGoogleOnly => isGoogleUser && !hasPassword;

  // ── Vincular Google con una cuenta de correo ───────────────────────────────
  /// Firebase **no** fusiona solo una cuenta de correo verificada con Google
  /// (permitiría entrar en cuentas ajenas): devuelve la credencial de Google
  /// "pendiente" y la app debe pedir la contraseña una vez y vincularla.
  AuthCredential? _pendingGoogleCredential;
  String? _pendingLinkEmail;

  /// Correo de la cuenta que hay que vincular, o null si no hay nada pendiente.
  String? get pendingLinkEmail => _pendingLinkEmail;

  void cancelPendingLink() {
    _pendingGoogleCredential = null;
    _pendingLinkEmail = null;
    notifyListeners();
  }

  /// Entra con la contraseña de la cuenta de siempre y le pega Google encima:
  /// mismo usuario, mismos datos, y a partir de ahora sirven los dos caminos.
  Future<(bool, String?)> linkPendingGoogleWithPassword(String password) async {
    final credential = _pendingGoogleCredential;
    final email = _pendingLinkEmail;
    if (credential == null || email == null) {
      return (false, 'errors.sessionExpired'.tr());
    }
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      await result.user!.linkWithCredential(credential);
      await result.user!.reload();

      _pendingGoogleCredential = null;
      _pendingLinkEmail = null;

      // Mismo trato que al entrar con correo: si la cuenta aún no estaba
      // verificada, primero eso (no debería pasar, porque Firebase solo pide
      // vincular cuando ya lo está, pero no se asume).
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        _needsEmailVerification = true;
        _pendingVerificationEmail = email;
        _isLoading = false;
        notifyListeners();
        return (true, null);
      }

      await loadUserData();
      _isLoading = false;
      notifyListeners();
      return (true, null);
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return switch (e.code) {
        // La cuenta ya tenía Google vinculado: no es un fallo, ya puede entrar.
        'provider-already-linked' || 'credential-already-in-use' => (true, null),
        'wrong-password' || 'invalid-credential' => (false, 'errors.wrongPassword'.tr()),
        'too-many-requests' => (false, 'errors.tooManyRequests'.tr()),
        _ => (false, _getErrorMessage(e.code)),
      };
    } catch (e) {
      debugPrint('linkPendingGoogleWithPassword error: $e');
      _isLoading = false;
      notifyListeners();
      return (false, 'errors.googleFailed'.tr());
    }
  }

  /// Desde Editar perfil: le agrega Google a la cuenta con sesión abierta.
  /// Le pone contraseña a una cuenta que entró con Google.
  ///
  /// Firebase lo hace vinculando el proveedor `password` al mismo usuario, así
  /// que **no se pierde nada**: mismo uid, misma racha, mismo jardín y mismo
  /// diario. A partir de ahí puede entrar con Google o con correo y
  /// contraseña, y cambiarla desde aquí como cualquier otra cuenta.
  ///
  /// Si Firebase pide una sesión reciente, se vuelve a entrar con Google (que
  /// es como esta persona inicia sesión) y se reintenta.
  Future<(bool, String?)> setPasswordOnCurrentAccount(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      return (false, 'errors.noSession'.tr());
    }
    final credential =
        EmailAuthProvider.credential(email: email, password: password);
    try {
      await user.linkWithCredential(credential);
      await user.reload();
      notifyListeners();
      return (true, null);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        final reauthenticated = await _reauthenticateWithGoogle();
        if (!reauthenticated) return (false, 'errors.sessionExpired'.tr());
        try {
          await _auth.currentUser!.linkWithCredential(credential);
          await _auth.currentUser!.reload();
          notifyListeners();
          return (true, null);
        } on FirebaseAuthException catch (e2) {
          debugPrint('setPasswordOnCurrentAccount retry error: ${e2.code}');
          return (false, _getErrorMessage(e2.code));
        }
      }
      debugPrint('setPasswordOnCurrentAccount error: ${e.code}');
      return switch (e.code) {
        // Ya tenía contraseña: la cambia, no la crea.
        'provider-already-linked' => (false, 'editProfile.alreadyHasPassword'.tr()),
        'weak-password' => (false, 'errors.weakPassword'.tr()),
        'requires-recent-login' => (false, 'errors.sessionExpired'.tr()),
        _ => (false, _getErrorMessage(e.code)),
      };
    } catch (e) {
      debugPrint('setPasswordOnCurrentAccount error: $e');
      return (false, 'editProfile.setPasswordError'.tr());
    }
  }

  /// Vuelve a entrar con Google para refrescar la sesión, sin cambiar de
  /// cuenta: si elige otra, no sirve.
  Future<bool> _reauthenticateWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      try { await _googleSignIn.signOut(); } catch (_) {}
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;
      if (googleUser.email.toLowerCase() != (user.email ?? '').toLowerCase()) {
        try { await _googleSignIn.signOut(); } catch (_) {}
        return false;
      }
      final googleAuth = await googleUser.authentication;
      await user.reauthenticateWithCredential(GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken));
      return true;
    } catch (e) {
      debugPrint('_reauthenticateWithGoogle error: $e');
      return false;
    }
  }

  Future<(bool, String?)> linkGoogleToCurrentAccount() async {
    final user = _auth.currentUser;
    if (user == null) return (false, 'errors.noSession'.tr());
    try {
      try { await _googleSignIn.signOut(); } catch (_) {}
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return (false, null);
      // Solo la misma persona: vincular otro correo dejaría la cuenta con dos
      // identidades distintas y sin forma de saber cuál es la buena.
      if (googleUser.email.toLowerCase() != (user.email ?? '').toLowerCase()) {
        try { await _googleSignIn.signOut(); } catch (_) {}
        return (false, 'editProfile.linkGoogleOtherEmail'.tr());
      }
      final googleAuth = await googleUser.authentication;
      await user.linkWithCredential(GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken));
      await user.reload();
      notifyListeners();
      return (true, null);
    } on FirebaseAuthException catch (e) {
      debugPrint('linkGoogleToCurrentAccount error: ${e.code}');
      return switch (e.code) {
        'provider-already-linked' => (true, null),
        'credential-already-in-use' => (false, 'editProfile.linkGoogleTaken'.tr()),
        'requires-recent-login' => (false, 'errors.sessionExpired'.tr()),
        _ => (false, _getErrorMessage(e.code)),
      };
    } catch (e) {
      debugPrint('linkGoogleToCurrentAccount error: $e');
      return (false, 'errors.googleFailed'.tr());
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ── Verificación de email ──────────────────────────────────────────────────
bool _needsEmailVerification = false;
bool get needsEmailVerification => _needsEmailVerification;

String? _pendingVerificationEmail;
String? get pendingVerificationEmail => _pendingVerificationEmail;

void clearVerificationState() {
  _needsEmailVerification = false;
  _pendingVerificationEmail = null;
  notifyListeners();
}

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  UserProgress? _userProgress;
  UserProgress? get userProgress => _userProgress;

  // ── Celebration queue ──────────────────────────────────────────────────────
  List<CelebrationEvent> _pendingCelebrations = [];
  List<CelebrationEvent> get pendingCelebrations => _pendingCelebrations;

  List<CelebrationEvent> consumeCelebrations() {
    final events = List<CelebrationEvent>.from(_pendingCelebrations);
    _pendingCelebrations = [];
    return events;
  }

  // ── Counters ───────────────────────────────────────────────────────────────
  int _diaryEntryCount = 0;
  int _habitsCompletedCount = 0;
  int _moodCheckInCount = 0;

  /// Contadores totales (se cargan con `count()` al iniciar sesión).
  int get diaryEntryCount => _diaryEntryCount;
  int get habitsCompletedCount => _habitsCompletedCount;
  int get moodCheckInCount => _moodCheckInCount;

  // ── Set de achievements ya celebrados (fuente de verdad = Firestore) ───────
  Set<String> _celebratedAchievementIds = {};

  /// Medallas ya celebradas o vistas en el perfil.
  Set<String> get celebratedAchievementIds => Set.unmodifiable(_celebratedAchievementIds);

  /// Marca medallas como vistas (las del jardín no pasan por la celebración):
  /// así quedan ganadas aunque el dato baje y el "¡Nueva!" sale una sola vez.
  Future<void> markAchievementsSeen(Iterable<String> ids) async {
    final before = _celebratedAchievementIds.length;
    _celebratedAchievementIds.addAll(ids);
    if (_celebratedAchievementIds.length == before) return;
    await _saveCelebratedAchievements();
  }

  // ── Diary refresh signal ───────────────────────────────────────────────────
  int _diaryVersion = 0;
  int get diaryVersion => _diaryVersion;

  // ─────────────────────────────────────────────────────────────────────────
  bool get isProfileComplete => _userModel?.profileComplete ?? false;

  String get userName {
    if (_userModel?.username != null && _userModel!.username!.isNotEmpty) {
      return _userModel!.username!;
    }
    if (_userModel != null) return _userModel!.name;
    if (firebaseUser?.displayName != null) return firebaseUser!.displayName!;
    return '';
  }

  String get userEmail {
    if (_userModel != null) return _userModel!.email;
    if (firebaseUser?.email != null) return firebaseUser!.email!;
    return '';
  }

  // ── Racha ──────────────────────────────────────────────────────────────────
  /// Racha a mostrar: 0 si ya se rompió, aunque aún no haya nuevo check-in
  /// (currentStreak en Firestore solo se recalcula al hacer check-in).
  int get currentStreak => _userProgress?.streakAt(DateTime.now()) ?? 0;

  /// true si había una racha y se perdió (último check-in antes de ayer).
  bool get streakBrokenToday {
    final progress = _userProgress;
    if (progress == null || progress.currentStreak == 0) return false;
    return !progress.isStreakAlive(DateTime.now());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD USER DATA
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> loadUserData() async {
    if (firebaseUser == null) return;
    try {
      // Todo lo independiente arranca a la vez: antes iban encadenados y el
      // splash esperaba la suma de seis viajes a Firestore.
      final userF =
          _firestore.collection('users').doc(firebaseUser!.uid).getFast();
      final progressF = _loadUserProgress();
      final celebratedF = _loadCelebratedAchievements();
      final discoveriesF = _loadDiscoveries();

      final doc = await userF;
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
      } else {
        // Cuenta nueva (o recién borrada): no dejar el perfil de quien estuvo
        // antes en esta sesión, o se vería como si fuera suyo.
        _userModel = null;
        _diaryEntryCount = 0;
        _habitsCompletedCount = 0;
        _moodCheckInCount = 0;
      }
      await Future.wait([progressF, celebratedF, discoveriesF]);
      await _ensureUsernameReserved();

      // Los contadores del perfil son agregaciones (`count()`): **solo existen
      // en el servidor**, no hay versión en caché. Sin internet nunca llegan,
      // así que no pueden retrasar la apertura de la app: se piden aparte y la
      // pantalla se actualiza cuando lleguen.
      unawaited(_loadProfileCounters());

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadProfileCounters() async {
    if (firebaseUser == null) return;
    final base = _firestore.collection('users').doc(firebaseUser!.uid);
    try {
      final counts = await Future.wait([
        base.collection('diary').count().get(),
        base
            .collection('habit_checkins')
            .where('completed', isEqualTo: true)
            .count()
            .get(),
        base.collection('moods').count().get(),
      ]).timeout(const Duration(seconds: 8));
      _diaryEntryCount = counts[0].count ?? _diaryEntryCount;
      _habitsCompletedCount = counts[1].count ?? _habitsCompletedCount;
      _moodCheckInCount = counts[2].count ?? _moodCheckInCount;
      notifyListeners();
    } catch (e) {
      // Sin internet se quedan los que ya había: mejor un número de la última
      // vez que un 0 que borra medallas ganadas de la vista.
      debugPrint('Error loading counters: $e');
    }
  }

  // ── Discovery moments (fuente de verdad = Firestore) ───────────────────────
  /// null hasta que se cargan: así nunca se muestra un popup por error.
  Set<String>? _discoveredFeatures;

  Future<void> _loadDiscoveries() async {
    if (firebaseUser == null) return;
    try {
      final doc = await _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('progress').doc('discoveries').getFast();
      _discoveredFeatures =
          Set<String>.from(doc.data()?['ids'] ?? const <String>[]);
    } catch (e) {
      debugPrint('Error loading discoveries: $e');
    }
  }

  /// Marca [featureId] como descubierta. Retorna true solo la primera vez.
  Future<bool> markDiscovered(String featureId) async {
    final discovered = _discoveredFeatures;
    if (firebaseUser == null || discovered == null) return false;
    if (!discovered.add(featureId)) return false;
    try {
      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('progress').doc('discoveries')
            .set({'ids': FieldValue.arrayUnion([featureId])},
                SetOptions(merge: true)),
        'descubrimiento',
      );
    } catch (e) {
      debugPrint('Error saving discovery: $e');
    }
    return true;
  }

  Future<void> _loadCelebratedAchievements() async {
    if (firebaseUser == null) return;
    try {
      final doc = await _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('progress').doc('celebrated_achievements').getFast();
      if (doc.exists) {
        final ids = List<String>.from(doc.data()!['ids'] ?? []);
        _celebratedAchievementIds = ids.toSet();
      } else {
        _celebratedAchievementIds = {};
      }
    } catch (e) {
      debugPrint('Error loading celebrated achievements: $e');
      _celebratedAchievementIds = {};
    }
  }

  Future<void> _saveCelebratedAchievements() async {
    if (firebaseUser == null) return;
    try {
      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('progress').doc('celebrated_achievements')
            .set({'ids': _celebratedAchievementIds.toList()}),
        'logros celebrados',
      );
    } catch (e) {
      debugPrint('Error saving celebrated achievements: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHECK CELEBRATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Parámetros de jardín opcionales para detectar logros de jardín.
  Future<void> _checkCelebrations(
    UserProgress? before,
    UserProgress after, {
    int plantsInGarden = 0,
    int adultPlantsInGarden = 0,
    int decorationsPlaced = 0,
  }) async {
    final events = AchievementService.checkForCelebrations(
      progressBefore: before,
      progressAfter: after,
      diaryEntries: _diaryEntryCount,
      habitsCompleted: _habitsCompletedCount,
      moodCheckIns: _moodCheckInCount,
      celebratedAchievementIds: _celebratedAchievementIds,
      plantsInGarden: plantsInGarden,
      adultPlantsInGarden: adultPlantsInGarden,
      decorationsPlaced: decorationsPlaced,
    );

    if (events.isEmpty) return;

    bool newAchievements = false;
    for (final event in events) {
      if (event.type == CelebrationEventType.achievement &&
          event.achievementId != null) {
        _celebratedAchievementIds.add(event.achievementId!);
        newAchievements = true;
      }
    }
    if (newAchievements) await _saveCelebratedAchievements();
    _pendingCelebrations.addAll(events);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE MOOD ENTRY
  // ═══════════════════════════════════════════════════════════════════════════
  Future<bool> saveMoodEntry(MoodEntry entry) async {
    if (firebaseUser == null) return false;
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingMoods = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('moods')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1).getFast();

      final isFirstMoodToday = existingMoods.docs.isEmpty;

      if (isFirstMoodToday) {
        await _write(
          _firestore
              .collection('users').doc(firebaseUser!.uid).collection('moods')
              .doc(entry.id).set(entry.toMap()),
          'ánimo del día',
        );

        if (_userProgress != null) {
          final oldProgress = _userProgress!;
          final newXp = _userProgress!.totalXp + entry.mood.xpReward;
          final newLevel = (newXp ~/ 100) + 1;
          final updatedProgress = UserProgress(
            currentStreak: _userProgress!.currentStreak,
            longestStreak: _userProgress!.longestStreak,
            lastCheckIn: _userProgress!.lastCheckIn,
            totalXp: newXp,
            level: newLevel,
          );
          await _write(
            _firestore
                .collection('users').doc(firebaseUser!.uid)
                .collection('progress').doc('current')
                .set(updatedProgress.toMap()),
            'progreso',
          );
          _userProgress = updatedProgress;
          _moodCheckInCount++;
          await _checkCelebrations(oldProgress, updatedProgress);
        }
      } else {
        final existingDocId = existingMoods.docs.first.id;
        await _write(
          _firestore
              .collection('users').doc(firebaseUser!.uid).collection('moods')
              .doc(existingDocId)
              .update({
                'mood': entry.mood.key,
                'intensity': entry.intensity,
                'note': entry.note,
              }),
          'ánimo del día',
        );
      }

      notifyListeners();
      return isFirstMoodToday;
    } catch (e) {
      debugPrint('Error saving mood entry: $e');
      rethrow;
    }
  }

  Future<Map<int, MoodType>> getWeeklyMoods() async {
    if (firebaseUser == null) return {};
    try {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('moods')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfWeek))
          .orderBy('timestamp').getFast();

      final Map<int, MoodType> weeklyMoods = {};
      for (final doc in snapshot.docs) {
        final entry = MoodEntry.fromMap(doc.data());
        weeklyMoods[entry.timestamp.weekday] = entry.mood;
      }
      return weeklyMoods;
    } catch (e) {
      debugPrint('Error loading weekly moods: $e');
      return {};
    }
  }

  Future<MoodType?> getTodayMood() async {
    if (firebaseUser == null) return null;
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('moods')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: true)
          .limit(1).getFast();

      if (snapshot.docs.isNotEmpty) {
        return MoodEntry.fromMap(snapshot.docs.first.data()).mood;
      }
    } catch (e) {
      debugPrint('Error getting today mood: $e');
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD USER PROGRESS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _loadUserProgress() async {
    if (firebaseUser == null) return;
    try {
      final doc = await _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('progress').doc('current').getFast();
      if (doc.exists) {
        _userProgress = UserProgress.fromMap(doc.data()!);
      } else {
        _userProgress = UserProgress();
        await _write(
          _firestore
              .collection('users').doc(firebaseUser!.uid)
              .collection('progress').doc('current')
              .set(_userProgress!.toMap()),
          'progreso inicial',
        );
      }
    } catch (e) {
      debugPrint('Error loading user progress: $e');
      _userProgress = UserProgress();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECORD CHECK-IN (streak)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<bool> recordCheckIn() async {
    if (firebaseUser == null || _userProgress == null) return false;
    try {
      final serverTime = await _getServerTimestamp();
      if (_userProgress!.hasCheckedInToday(serverTime)) return false;

      final oldProgress = _userProgress!;
      final updatedProgress = _userProgress!.calculateStreak(serverTime);

      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('progress').doc('current')
            .set(updatedProgress.toMap()),
        'racha',
      );

      _userProgress = updatedProgress;
      // Cancelar recordatorio de racha porque ya hizo check-in hoy
try {
  await NotificationService.instance.cancelStreakReminder();
} catch (e) {
  debugPrint('Error canceling streak reminder: $e');
}
      await _checkCelebrations(oldProgress, updatedProgress);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error recording check-in: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
// PASSWORD RESET
// ═══════════════════════════════════════════════════════════════════════════

/// Envía un correo de restablecimiento de contraseña.
/// Por seguridad, siempre retorna éxito aunque el email no exista (evita
/// que atacantes averigüen qué emails están registrados).
Future<bool> sendPasswordResetEmail(String email, {String? languageCode}) async {
  try {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Configurar idioma del email según el locale de la app
    if (languageCode != null) {
      await _auth.setLanguageCode(languageCode);
    }

    await _auth.sendPasswordResetEmail(email: email.trim());

    _isLoading = false;
    notifyListeners();
    return true;
  } on FirebaseAuthException catch (e) {
    // Errores que SÍ mostramos (invalid-email es útil para el usuario)
    if (e.code == 'invalid-email') {
      _errorMessage = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
    // Para 'user-not-found' y otros, retornamos éxito silencioso
    // (previene enumeración de cuentas — mejor práctica de seguridad)
    if (e.code == 'user-not-found') {
      _isLoading = false;
      notifyListeners();
      return true;  // Fingimos éxito
    }
    // Cualquier otro error real (rate limit, etc.)
    _errorMessage = _getErrorMessage(e.code);
    _isLoading = false;
    notifyListeners();
    return false;
  } catch (e) {
    _errorMessage = 'errors.generic'.tr();
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  /// Restaura la racha perdida (estilo TikTok con escudo).
/// Llamar después de useStreakShield() en GardenProvider.
/// Si hoy ya hizo check-in (la racha se reinició a 1), hoy también cuenta.
/// Si no, se marca ayer como cubierto para que el check-in de hoy sume.
Future<void> restoreStreakWithShield(int streakToRestore) async {
  if (firebaseUser == null || _userProgress == null) return;
  try {
    final now = DateTime.now();
    final checkedInToday = _userProgress!.hasCheckedInToday(now);
    final restored = checkedInToday ? streakToRestore + 1 : streakToRestore;
    final updatedProgress = UserProgress(
      currentStreak: restored,
      longestStreak: _userProgress!.longestStreak > restored
          ? _userProgress!.longestStreak
          : restored,
      lastCheckIn: checkedInToday
          ? _userProgress!.lastCheckIn
          : DateTime(now.year, now.month, now.day - 1, 12),
      totalXp: _userProgress!.totalXp,
      level: _userProgress!.level,
    );
    await _write(
      _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('progress')
          .doc('current')
          .set(updatedProgress.toMap()),
      'racha restaurada',
    );
    _userProgress = updatedProgress;
    notifyListeners();
  } catch (e) {
    debugPrint('Error restoring streak with shield: $e');
  }
}

  /// Hora del servidor, para las recompensas de una vez al día y la racha.
  ///
  /// Sin internet no se puede pedir. Antes eso **tiraba la operación entera**:
  /// el check-in, la sesión de respiración o el repaso que el usuario acababa
  /// de hacer se perdían y tenía que repetirlos. Ahora se usa la hora del
  /// teléfono como respaldo; las guardas de "ya se cobró hoy"
  /// (`lastRewardDate`, el doc en `completed_lessons`) siguen aplicando, así
  /// que lo peor que puede pasar es que alguien sin internet y con el reloj
  /// cambiado adelante un día.
  Future<DateTime> _getServerTimestamp() async {
    final ref = _firestore.collection('_server_time').doc(firebaseUser!.uid);
    try {
      await ref
          .set({'timestamp': FieldValue.serverTimestamp()})
          .timeout(const Duration(seconds: 4));
      final snap = await ref.get().timeout(const Duration(seconds: 4));
      final ts = snap.data()?['timestamp'];
      unawaited(ref.delete().catchError((_) {}));
      if (ts is Timestamp) return ts.toDate();
    } catch (e) {
      debugPrint('📴 Sin hora del servidor, se usa la del teléfono: $e');
    }
    return DateTime.now();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUTH — register, login, google, logout
  // ═══════════════════════════════════════════════════════════════════════════
 Future<bool> registerWithEmail({
  required String email,
  required String password,
  required String name,
  String? languageCode,
}) async {
  try {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await credential.user?.updateDisplayName(name);

    final userModel =
        UserModel(uid: credential.user!.uid, name: name, email: email);
    await _firestore
        .collection('users').doc(credential.user!.uid)
        .set(userModel.toFirestoreMap());
    _userModel = userModel;

    _userProgress = UserProgress();
    await _firestore
        .collection('users').doc(credential.user!.uid)
        .collection('progress').doc('current')
        .set(_userProgress!.toMap());

    // ── Enviar email de verificación ─────────────────────────────
    try {
      // Configurar idioma del email según el locale actual de la app
      if (languageCode != null) {
        await _auth.setLanguageCode(languageCode);
      }
      await credential.user!.sendEmailVerification();
    } catch (e) {
      debugPrint('Error sending email verification: $e');
    }

    // Marcar que necesita verificación (el UI navegará a /verify-email)
    _pendingVerificationEmail = email.trim();
    _needsEmailVerification = true;

    _isLoading = false;
    notifyListeners();
    return true;
  } on FirebaseAuthException catch (e) {
    _errorMessage = _getErrorMessage(e.code);
    _isLoading = false;
    notifyListeners();
    return false;
  } catch (e) {
    _errorMessage = 'errors.generic'.tr();
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  Future<bool> loginWithEmail(
    {required String email, required String password}) async {
  try {
    _isLoading = true;
    _errorMessage = null;
    _needsEmailVerification = false;
    _pendingVerificationEmail = null;
    notifyListeners();

    await _auth.signInWithEmailAndPassword(email: email, password: password);

    // ── Bloquear login si el email NO está verificado ────────────
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      _pendingVerificationEmail = email.trim();
      _needsEmailVerification = true;
      _isLoading = false;
      notifyListeners();
      // Retornamos false pero el flag needsEmailVerification=true
      // le dice al login_screen que redirija a /verify-email
      return false;
    }

    await loadUserData();
    _isLoading = false;
    notifyListeners();
    return true;
  } on FirebaseAuthException catch (e) {
    // Correo o contraseña mal se responden igual: decir "no existe esa
    // cuenta" le confirmaría a un atacante qué correos están registrados.
    _errorMessage = switch (e.code) {
      'user-not-found' || 'wrong-password' || 'invalid-credential' => 'errors.wrongCredentials'.tr(),
      _ => _getErrorMessage(e.code),
    };
    _isLoading = false;
    notifyListeners();
    return false;
  } catch (e) {
    _errorMessage = 'errors.generic'.tr();
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

/// Recarga el usuario desde Firebase y verifica si ya confirmó su email.
/// Retorna true si está verificado, false si aún no.
/// Si retorna true, también carga user data y limpia el flag.
Future<bool> checkEmailVerified() async {
  try {
    if (_auth.currentUser == null) return false;
    await _auth.currentUser!.reload();
    final verified = _auth.currentUser!.emailVerified;
    if (verified) {
      _needsEmailVerification = false;
      _pendingVerificationEmail = null;
      if (_userModel == null) {
        await loadUserData();
      }
      notifyListeners();
    }
    return verified;
  } catch (e) {
    debugPrint('checkEmailVerified error: $e');
    return false;
  }
}

/// Para sesiones guardadas al abrir la app: recarga el usuario y, si su email
/// sigue sin verificar (Google exento), prepara el estado para /verify-email.
/// Retorna true si debe ir a verificar.
Future<bool> needsVerificationOnStartup() async {
  if (_auth.currentUser == null || isGoogleUser) return false;
  try {
    // `reload()` va al servidor. Sin internet falla rápido, pero con señal
    // mala puede colgarse: el splash no puede quedarse esperando por esto.
    await _auth.currentUser!.reload().timeout(const Duration(seconds: 3));
  } catch (e) {
    // Sin conexión: se usa el último estado conocido
    debugPrint('needsVerificationOnStartup reload error: $e');
  }
  final user = _auth.currentUser;
  if (user == null || user.emailVerified) return false;
  _pendingVerificationEmail = user.email;
  _needsEmailVerification = true;
  notifyListeners();
  return true;
}

/// Reenvía el email de verificación al usuario actual.
/// Requiere que haya sesión activa (el user acaba de registrarse o
/// intentó hacer login pero no está verificado).
Future<bool> resendEmailVerification({String? languageCode}) async {
  try {
    if (_auth.currentUser == null) {
      _errorMessage = 'errors.sessionExpired'.tr();
      notifyListeners();
      return false;
    }
    if (languageCode != null) {
      await _auth.setLanguageCode(languageCode);
    }
    await _auth.currentUser!.sendEmailVerification();
    return true;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'too-many-requests') {
      _errorMessage = 'errors.tooManyRequests'.tr();
    } else {
      _errorMessage = _getErrorMessage(e.code);
    }
    notifyListeners();
    return false;
  } catch (e) {
    debugPrint('resendEmailVerification error: $e');
    return false;
  }
}


  Future<bool> loginWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Cerrar la sesión de Google antes de pedirla: si no, `signIn()` entra
      // en silencio con la última cuenta usada en el teléfono, sin preguntar,
      // y se puede acabar dentro de otra cuenta sin querer.
      try { await _googleSignIn.signOut(); } catch (_) {}
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final userCredential = await _auth.signInWithCredential(credential);

      final doc = await _firestore
          .collection('users').doc(userCredential.user!.uid).getFast();
      if (!doc.exists) {
        final userModel = UserModel(
            uid: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'Usuario',
            email: userCredential.user!.email ?? '');
        await _firestore
            .collection('users').doc(userCredential.user!.uid)
            .set(userModel.toFirestoreMap());
        _userModel = userModel;
        _userProgress = UserProgress();
        await _firestore
            .collection('users').doc(userCredential.user!.uid)
            .collection('progress').doc('current')
            .set(_userProgress!.toMap());
      } else {
        _userModel = UserModel.fromMap(doc.data()!);
        await _loadUserProgress();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      // Si la sesión de Firebase falla, cerramos también la de Google para no
      // dejar la cuenta elegida "a medias" en el siguiente intento.
      try { await _googleSignIn.signOut(); } catch (_) {}
      // Ya existe esa cuenta con contraseña: guardamos la credencial de Google
      // para vincularla en cuanto confirme quién es (pantalla de login).
      if (e.code == 'account-exists-with-different-credential' &&
          e.credential != null &&
          (e.email ?? '').isNotEmpty) {
        _pendingGoogleCredential = e.credential;
        _pendingLinkEmail = e.email;
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _errorMessage = switch (e.code) {
        'account-exists-with-different-credential' => 'errors.accountExistsWithEmail'.tr(),
        'invalid-credential' => 'errors.googleFailed'.tr(),
        'user-disabled' => 'errors.userDisabled'.tr(),
        _ => _getErrorMessage(e.code),
      };
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      try { await _googleSignIn.signOut(); } catch (_) {}
      debugPrint('loginWithGoogle error: $e');
      _errorMessage = 'errors.googleFailed'.tr();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try { await _googleSignIn.signOut(); } catch (e) { debugPrint('Google sign out: $e'); }
    try { await _auth.signOut(); } catch (e) { debugPrint('Firebase sign out: $e'); }
    _clearSessionState();
  }

  void _clearSessionState() {
    _userModel = null;
    _userProgress = null;
    _celebratedAchievementIds = {};
    _diaryVersion = 0;
    _discoveredFeatures = null;
    _diaryEntryCount = 0;
    _habitsCompletedCount = 0;
    _moodCheckInCount = 0;
    _needsEmailVerification = false;
    _pendingVerificationEmail = null;
    _isLoading = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE ACCOUNT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Subcolecciones bajo users/{uid}. Si agregas una nueva, agrégala aquí
  /// o sus datos quedarán huérfanos al eliminar la cuenta.
  static const _userSubcollections = [
    'progress',
    'moods',
    'diary',
    'habits',
    'habit_checkins',
    'reminders',
    'completed_lessons',
    'garden',
    'garden_transactions',
    'commitments',
    'breathing_sessions',
    'review_sessions',
  ];

  /// Elimina la cuenta y todos sus datos. Usuarios de email deben pasar
  /// [password]; usuarios de Google confirman eligiendo su cuenta.
  /// Retorna (false, null) si el usuario canceló el selector de Google.
  Future<(bool, String?)> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) return (false, 'errors.sessionExpired'.tr());

    try {
      // 1. Reautenticar primero: user.delete() exige login reciente, y así
      //    no se borra nada si la contraseña es incorrecta.
      if (isGoogleOnly) {
        // Igual que al entrar: preguntar siempre con qué cuenta, que aquí se
        // está borrando todo.
        try { await _googleSignIn.signOut(); } catch (_) {}
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return (false, null);
        final googleAuth = await googleUser.authentication;
        await user.reauthenticateWithCredential(GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken, idToken: googleAuth.idToken));
      } else {
        await user.reauthenticateWithCredential(EmailAuthProvider.credential(
            email: user.email!, password: password ?? ''));
      }

      // 2. Borrar datos de Firestore antes que el usuario de Auth
      //    (las reglas exigen sesión activa para escribir).
      final userDoc = _firestore.collection('users').doc(user.uid);
      for (final name in _userSubcollections) {
        await _deleteCollection(userDoc.collection(name));
      }
      // El borrador del diario vive solo en el teléfono
      await DiaryDraftService.instance.clear(user.uid);
      final username = _userModel?.username?.toLowerCase();
      if (username != null && username.isNotEmpty) {
        try {
          final reserved = await _usernameDoc(username).getFast();
          if (reserved.data()?['uid'] == user.uid) await reserved.reference.delete();
        } catch (e) {
          debugPrint('Release username on delete: $e');
        }
      }
      await userDoc.delete();
      await _firestore.collection('_server_time').doc(user.uid).delete();

      // 3. Notificaciones locales programadas
      try {
        await NotificationService.instance.cancelAllReminders();
      } catch (e) {
        debugPrint('Cancel notifications on delete: $e');
      }

      // 4. Usuario de Auth
      await user.delete();
      try { await _googleSignIn.signOut(); } catch (e) { debugPrint('Google sign out: $e'); }
      _clearSessionState();
      return (true, null);
    } on FirebaseAuthException catch (e) {
      debugPrint('deleteAccount error: ${e.code}');
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return (false, 'errors.wrongPassword'.tr());
        case 'user-mismatch':
          return (false, 'editProfile.deleteAccountWrongGoogle'.tr());
        case 'too-many-requests':
          return (false, 'errors.tooManyRequests'.tr());
        case 'requires-recent-login':
          return (false, 'errors.sessionExpired'.tr());
        default:
          return (false, 'editProfile.deleteAccountError'.tr());
      }
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      return (false, 'editProfile.deleteAccountError'.tr());
    }
  }

  Future<void> _deleteCollection(
      CollectionReference<Map<String, dynamic>> ref) async {
    const batchSize = 400; // límite de Firestore: 500 operaciones por batch
    while (true) {
      final snapshot = await ref.limit(batchSize).getFast();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < batchSize) return;
    }
  }

  Future<void> markOnboardingCompleted() async {
  try {
    if (firebaseUser == null) return;
    await _firestore
        .collection('users').doc(firebaseUser!.uid)
        .update({'onboardingCompleted': true});
    if (_userModel != null) {
      _userModel = _userModel!.copyWith(onboardingCompleted: true);
      notifyListeners();
    }
  } catch (e) {
    debugPrint('markOnboardingCompleted error: $e');
  }
}


  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATE USER PROFILE
  // ═══════════════════════════════════════════════════════════════════════════
  /// Reserva de nombres: `usernames/{username}` → `{uid}`. Es la única forma de
  /// saber si un nombre está ocupado sin poder leer perfiles ajenos (las
  /// reglas solo dejan a cada usuario leer su propio `users/{uid}`).
  DocumentReference<Map<String, dynamic>> _usernameDoc(String username) =>
      _firestore.collection('usernames').doc(username.toLowerCase());

  Future<bool> isUsernameTaken(String username) async {
    try {
      final doc = await _usernameDoc(username).getFast();
      return doc.exists && doc.data()?['uid'] != firebaseUser?.uid;
    } catch (e) {
      debugPrint('Error checking username: $e');
      // Solo es una ayuda para el formulario: la reserva real ocurre en la
      // transacción de updateUserProfile, que sí rechaza duplicados.
      return false;
    }
  }

  /// Cuentas creadas antes de la reserva de nombres: reclama el suyo al cargar.
  Future<void> _ensureUsernameReserved() async {
    final uid = firebaseUser?.uid;
    final name = _userModel?.username?.toLowerCase();
    if (uid == null || name == null || name.isEmpty) return;
    try {
      final ref = _usernameDoc(name);
      final snap = await ref.getFast();
      if (!snap.exists) {
        await _write(
          ref.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()}),
          'reserva de nombre de usuario',
        );
      }
    } catch (e) {
      debugPrint('Error reserving existing username: $e');
    }
  }

  Future<(bool, String?)> updateUserProfile({
    String? name,
    String? username,
    int? age,
    String? gender,
    List<String>? hobbies,
    List<String>? musicGenres,
    String? archetype,
    bool markComplete = false,
  }) async {
    if (firebaseUser == null) return (false, 'errors.noSession'.tr());
    try {
      _isLoading = true;
      notifyListeners();

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (username != null) updates['username'] = username.toLowerCase();
      if (age != null) updates['age'] = age;
      if (gender != null) updates['gender'] = gender;
      if (hobbies != null) updates['hobbies'] = hobbies;
      if (musicGenres != null) updates['musicGenres'] = musicGenres;
      if (archetype != null) updates['archetype'] = archetype;

      if (markComplete) {
        final currentGender = gender ?? _userModel?.gender;
        final currentAge = age ?? _userModel?.age;
        final currentUsername = username ?? _userModel?.username;
        final currentHobbies = hobbies ?? _userModel?.hobbies ?? [];
        final currentMusic = musicGenres ?? _userModel?.musicGenres ?? [];

        if (currentGender == null || currentGender.isEmpty) { _isLoading = false; notifyListeners(); return (false, 'profileSetup.genderRequired'.tr()); }
        if (currentAge == null) { _isLoading = false; notifyListeners(); return (false, 'profileSetup.ageRequired'.tr()); }
        if (currentUsername == null || currentUsername.isEmpty) { _isLoading = false; notifyListeners(); return (false, 'profileSetup.usernameRequired'.tr()); }
        if (currentHobbies.length < 3) { _isLoading = false; notifyListeners(); return (false, 'profileSetup.hobbiesMin'.tr(namedArgs: {'count': '3'})); }
        if (currentMusic.length < 2) { _isLoading = false; notifyListeners(); return (false, 'profileSetup.musicMin'.tr(namedArgs: {'count': '2'})); }

        updates['profileComplete'] = true;
      }

      final uid = firebaseUser!.uid;
      final userRef = _firestore.collection('users').doc(uid);
      final newName = username?.toLowerCase();
      final oldName = _userModel?.username?.toLowerCase();

      if (newName != null && newName != oldName) {
        // Reservar el nombre nuevo, liberar el anterior y guardar el perfil en
        // una sola transacción: si otra persona lo tomó un instante antes, no
        // se guarda nada.
        final taken = await _firestore.runTransaction<bool>((tx) async {
          final newRef = _usernameDoc(newName);
          final newSnap = await tx.get(newRef);
          DocumentSnapshot<Map<String, dynamic>>? oldSnap;
          if (oldName != null && oldName.isNotEmpty) {
            oldSnap = await tx.get(_usernameDoc(oldName));
          }
          if (newSnap.exists && newSnap.data()?['uid'] != uid) return true;

          if (!newSnap.exists) {
            tx.set(newRef, {'uid': uid, 'createdAt': FieldValue.serverTimestamp()});
          }
          if (oldSnap != null && oldSnap.exists && oldSnap.data()?['uid'] == uid) {
            tx.delete(oldSnap.reference);
          }
          tx.update(userRef, updates);
          return false;
        });
        if (taken) {
          _isLoading = false;
          notifyListeners();
          return (false, 'profileSetup.usernameTaken'.tr());
        }
      } else {
        await userRef.update(updates);
      }
      await loadUserData();
      _isLoading = false;
      notifyListeners();
      return (true, null);
    } on FirebaseException {
      _isLoading = false;
      notifyListeners();
      return (false, 'errors.saveCheckConnection'.tr());
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return (false, 'errors.generic'.tr());
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIARY
  // ═══════════════════════════════════════════════════════════════════════════
  /// [awardXp] en false para entradas que ya dieron XP por otro lado
  /// (p. ej. un ejercicio de lección guardado en el diario).
  /// Ver [queueWrite]: guarda sin esperar la confirmación del servidor.
  Future<void> _write(Future<void> op, String what) => queueWrite(op, what);

  Future<void> saveDiaryEntry(DiaryEntry entry, {bool awardXp = true}) async {
    if (firebaseUser == null) return;
    try {
      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid).collection('diary')
            .doc(entry.id).set(entry.toMap()),
        'entrada de diario',
      );

      if (!awardXp) _diaryEntryCount++;

      if (awardXp && _userProgress != null) {
        final oldProgress = _userProgress!;
        int xpGain = 20;
        if (entry.gratitude != null && entry.gratitude!.isNotEmpty) xpGain += 5;

        final newXp = _userProgress!.totalXp + xpGain;
        final newLevel = (newXp ~/ 100) + 1;
        final updatedProgress = UserProgress(
          currentStreak: _userProgress!.currentStreak,
          longestStreak: _userProgress!.longestStreak,
          lastCheckIn: _userProgress!.lastCheckIn,
          totalXp: newXp,
          level: newLevel,
        );
        await _write(
          _firestore
              .collection('users').doc(firebaseUser!.uid)
              .collection('progress').doc('current')
              .set(updatedProgress.toMap()),
          'progreso',
        );
        _userProgress = updatedProgress;
        _diaryEntryCount++;
        await _checkCelebrations(oldProgress, updatedProgress);
      }

      _diaryVersion++;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving diary entry: $e');
      rethrow;
    }
  }

  Future<List<DiaryEntry>> getDiaryEntries({int limit = 50}) async {
    if (firebaseUser == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('diary')
          .orderBy('createdAt', descending: true)
          .limit(limit).getFast();
      return snapshot.docs.map((doc) => DiaryEntry.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Error loading diary entries: $e');
      return [];
    }
  }

  Future<Map<DateTime, MoodType>> getDiaryCalendarMoods(
      DateTime start, DateTime end) async {
    if (firebaseUser == null) return {};
    try {
      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('diary')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('createdAt').getFast();

      final Map<DateTime, MoodType> moods = {};
      for (final doc in snapshot.docs) {
        final entry = DiaryEntry.fromMap(doc.data());
        final normalized = DateTime(
            entry.createdAt.year, entry.createdAt.month, entry.createdAt.day);
        moods[normalized] = entry.mood;
      }
      return moods;
    } catch (e) {
      debugPrint('Error loading diary calendar moods: $e');
      return {};
    }
  }

  Future<void> deleteDiaryEntry(String entryId) async {
    if (firebaseUser == null) return;
    try {
      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid).collection('diary')
            .doc(entryId).delete(),
        'borrar entrada',
      );
      _diaryVersion++;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting diary entry: $e');
      rethrow;
    }
  }

  Future<bool> hasDiaryEntryToday() async {
    if (firebaseUser == null) return false;
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('diary')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1).getFast();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REMINDERS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> saveReminder(Reminder reminder) async {
    if (firebaseUser == null) return;
    try {
      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid).collection('reminders')
            .doc(reminder.id).set(reminder.toMap()),
        'recordatorio',
      );
      notifyListeners();
    } catch (e) { rethrow; }
  }

  Future<List<Reminder>> getReminders() async {
    if (firebaseUser == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('reminders')
          .orderBy('timeInMinutes').getFast();
      return snapshot.docs.map((doc) => Reminder.fromMap(doc.data())).toList();
    } catch (e) {
      try {
        final snapshot = await _firestore
            .collection('users').doc(firebaseUser!.uid).collection('reminders').getFast();
        final list = snapshot.docs.map((doc) => Reminder.fromMap(doc.data())).toList();
        list.sort((a, b) => a.timeInMinutes.compareTo(b.timeInMinutes));
        return list;
      } catch (e2) { return []; }
    }
  }

  Future<void> toggleReminder(String reminderId, bool isEnabled) async {
    if (firebaseUser == null) return;
    try {
      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid).collection('reminders')
            .doc(reminderId).update({'isEnabled': isEnabled}),
        'recordatorio',
      );
      notifyListeners();
    } catch (e) { rethrow; }
  }

  Future<void> deleteReminder(String reminderId) async {
    if (firebaseUser == null) return;
    try {
      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid).collection('reminders')
            .doc(reminderId).delete(),
        'borrar recordatorio',
      );
      notifyListeners();
    } catch (e) { rethrow; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HABITS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> saveHabit(Habit habit) async {
    if (firebaseUser == null) return;
    try {
      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid).collection('habits')
            .doc(habit.id).set(habit.toMap()),
        'hábito',
      );
      notifyListeners();
    } catch (e) { rethrow; }
  }

  Future<List<Habit>> getHabits() async {
    if (firebaseUser == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('habits')
          .orderBy('createdAt').getFast();
      return snapshot.docs.map((doc) => Habit.fromMap(doc.data())).toList();
    } catch (e) { return []; }
  }

  /// Borra el hábito **y sus check-ins**.
  ///
  /// Es lo que la app ya promete al confirmar ("se perderá el historial de
  /// este hábito"), y evita que borrar y volver a crear hábitos infle el
  /// contador de medallas y el avance de las misiones de la semana.
  Future<void> deleteHabit(String habitId) async {
    if (firebaseUser == null) return;
    try {
      final user = _firestore.collection('users').doc(firebaseUser!.uid);
      final checkIns = await user
          .collection('habit_checkins')
          .where('habitId', isEqualTo: habitId)
          .getFast();
      if (checkIns.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in checkIns.docs) {
          batch.delete(doc.reference);
        }
        await _write(batch.commit(), 'historial del hábito');
        _habitsCompletedCount =
            (_habitsCompletedCount - checkIns.docs.length).clamp(0, 1 << 30);
      }
      await _write(
        user.collection('habits').doc(habitId).delete(),
        'borrar hábito',
      );
      notifyListeners();
    } catch (e) { rethrow; }
  }

  Future<bool> checkInHabit(String habitId) async {
    if (firebaseUser == null) return false;
    try {
      final today = DateTime.now();
      final checkIn = HabitCheckIn(habitId: habitId, date: today);
      final existingDoc = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('habit_checkins')
          .doc(checkIn.docId).getFast();
      final isFirstTime = !existingDoc.exists;

      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid).collection('habit_checkins')
            .doc(checkIn.docId).set(checkIn.toMap()),
        'hábito',
      );

      if (isFirstTime) {
        _habitsCompletedCount++;
        await _awardHabitXp();
      }

      notifyListeners();
      return isFirstTime;
    } catch (e) { rethrow; }
  }

  /// Da el XP del hábito mientras quede cupo del día ([HabitXpQuota]).
  ///
  /// El tope es por día y no por hábito: sin él se podía farmear XP sin
  /// límite creando, marcando y borrando hábitos, porque cada hábito nuevo
  /// estrena id y volvía a contar como "primera vez".
  Future<void> _awardHabitXp() async {
    if (firebaseUser == null || _userProgress == null) return;
    final ref = _firestore
        .collection('users').doc(firebaseUser!.uid)
        .collection('progress').doc('habits');
    final quota = HabitXpQuota.fromMap(
      (await ref.getFast()).data(),
      today: HabitXpQuota.dayKey(DateTime.now()),
    );
    if (!quota.hasRoom) return;
    await _write(ref.set(quota.next.toMap()), 'cupo de XP de hábitos');
    // Sin el multiplicador del jardín: ese es para las lecciones.
    await _awardXp(HabitXpQuota.xpPerHabit);
  }

  Future<void> uncheckHabit(String habitId) async {
    if (firebaseUser == null) return;
    try {
      final today = DateTime.now();
      final checkIn = HabitCheckIn(habitId: habitId, date: today);
      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid).collection('habit_checkins')
            .doc(checkIn.docId).update({'completed': false}),
        'hábito',
      );
      notifyListeners();
    } catch (e) { rethrow; }
  }

  /// Historial de todos los hábitos (racha y última semana), en una sola
  /// lectura de `habit_checkins`.
  Future<Map<String, HabitHistory>> getHabitHistory() async {
    if (firebaseUser == null) return {};
    try {
      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('habit_checkins').getFast();
      final days = <String, List<DateTime>>{};
      for (final doc in snapshot.docs) {
        if (doc.data()['completed'] != true) continue;
        final parsed = HabitHistory.parseDocId(doc.id);
        if (parsed == null) continue;
        days.putIfAbsent(parsed.$1, () => []).add(parsed.$2);
      }
      return {for (final e in days.entries) e.key: HabitHistory(e.value)};
    } catch (e) {
      debugPrint('Error loading habit history: $e');
      return {};
    }
  }

  Future<Set<String>> getTodayHabitCheckIns() async {
    if (firebaseUser == null) return {};
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('habit_checkins').getFast();
      return snapshot.docs
          .where((doc) => doc.id.endsWith(dateStr))
          .where((doc) => doc.data()['completed'] == true)
          .map((doc) => doc.data()['habitId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) { return {}; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LESSONS — aplica multiplicador XP si GardenProvider tiene uno activo
  // ═══════════════════════════════════════════════════════════════════════════
  Future<Set<String>> getCompletedLessons() async {
    if (firebaseUser == null) return {};
    try {
      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('completed_lessons').getFast();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) { return {}; }
  }

  /// [garden] — pasar el GardenProvider para aplicar multiplicador XP si activo.
  /// Ejemplo: `auth.completeLesson(id, xp, garden: context.read<GardenProvider>())`
  Future<void> completeLesson(String lessonId, int xpReward,
      {GardenProvider? garden}) async {
    if (firebaseUser == null) return;
    try {
      final existing = await _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('completed_lessons').doc(lessonId).getFast();
      if (existing.exists) return;

      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('completed_lessons').doc(lessonId).set({
          // Hora del teléfono, no `serverTimestamp()`: sin internet ese campo
          // se queda en null en la caché local y `hasCompletedLessonToday()`
          // —que filtra por fecha— no encontraba la lección. Se guardaba, pero
          // el home seguía diciendo que no la habías hecho.
          'completedAt': Timestamp.now(),
          'xpEarned': xpReward,
        }),
        'lección completada',
      );

      await _awardXp(xpReward, garden: garden);
      notifyListeners();
    } catch (e) { rethrow; }
  }

  /// Suma XP (con el multiplicador del jardín si hay uno activo), recalcula
  /// el nivel, guarda el progreso y encola celebraciones.
  Future<void> _awardXp(int xpReward, {GardenProvider? garden}) async {
    if (firebaseUser == null || _userProgress == null) return;
    final oldProgress = _userProgress!;

    final multiplier = garden?.currentXpMultiplier ?? 1.0;
    final finalXp =
        multiplier > 1.0 ? (xpReward * multiplier).round() : xpReward;

    final newXp = oldProgress.totalXp + finalXp;
    final updatedProgress = UserProgress(
      currentStreak: oldProgress.currentStreak,
      longestStreak: oldProgress.longestStreak,
      lastCheckIn: oldProgress.lastCheckIn,
      totalXp: newXp,
      level: (newXp ~/ 100) + 1,
    );
    await _write(
      _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('progress').doc('current')
          .set(updatedProgress.toMap()),
      'progreso',
    );
    _userProgress = updatedProgress;
    await _checkCelebrations(oldProgress, updatedProgress);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BREATHING — solo la primera sesión del día da recompensa
  // ═══════════════════════════════════════════════════════════════════════════

  /// Registra una sesión de respiración. La primera del día (hora del
  /// servidor) da [xpReward] y retorna true para que la UI dé las semillas.
  /// Se guarda en progress/breathing y no en completed_lessons, para que no
  /// cuente como la lección del día.
  // ═══════════════════════════════════════════════════════════════════════════
  // REPASO DIARIO — progress/review
  // ═══════════════════════════════════════════════════════════════════════════
  /// Estado del repaso: ids de tarjetas falladas pendientes y si ya se hizo hoy
  /// (día local, solo para la interfaz; la recompensa usa la hora del servidor).
  Future<({Set<String> missed, bool doneToday})> loadReviewState() async {
    if (firebaseUser == null) return (missed: <String>{}, doneToday: false);
    try {
      final data = (await _firestore
              .collection('users').doc(firebaseUser!.uid)
              .collection('progress').doc('review')
              .getFast())
          .data();
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      return (
        missed: Set<String>.from(data?['missed'] ?? const <String>[]),
        doneToday: data?['lastLocalDay'] == today,
      );
    } catch (e) {
      debugPrint('Error loading review state: $e');
      return (missed: <String>{}, doneToday: false);
    }
  }

  /// Guarda el resultado: las falladas vuelven en próximos repasos y las que
  /// se acertaron salen de la lista. Da XP solo en el primer repaso del día.
  Future<bool> completeDailyReview({
    required Set<String> missed,
    required Set<String> corrected,
    required int xpReward,
    GardenProvider? garden,
  }) async {
    if (firebaseUser == null || _userProgress == null) return false;
    try {
      final serverNow = await _getServerTimestamp();
      final serverDay = '${serverNow.year}-${serverNow.month}-${serverNow.day}';
      final now = DateTime.now();
      final localDay =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final ref = _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('progress').doc('review');
      final data = (await ref.getFast()).data();
      final alreadyRewarded = data?['lastRewardDate'] == serverDay;

      final pending = Set<String>.from(data?['missed'] ?? const <String>[])
        ..removeAll(corrected)
        ..addAll(missed);
      // Tope para que el documento no crezca sin fin: se quedan las recientes
      final pendingList = pending.toList();
      final trimmed = pendingList.length > 40
          ? pendingList.sublist(pendingList.length - 40)
          : pendingList;

      // Historial por sesión (misiones semanales cuentan repasos)
      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('review_sessions')
            .add({'at': Timestamp.now()}),
        'repaso',
      );

      await _write(
        ref.set({
          'missed': trimmed,
          'lastLocalDay': localDay,
          'totalReviews': FieldValue.increment(1),
          if (!alreadyRewarded) 'lastRewardDate': serverDay,
        }, SetOptions(merge: true)),
        'estado del repaso',
      );
      if (alreadyRewarded) return false;

      await _awardXp(xpReward, garden: garden);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error completing review: $e');
      return false;
    }
  }

  Future<bool> completeBreathingSession(int xpReward,
      {GardenProvider? garden}) async {
    if (firebaseUser == null || _userProgress == null) return false;
    try {
      final now = await _getServerTimestamp();
      final today = '${now.year}-${now.month}-${now.day}';
      final ref = _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('progress').doc('breathing');
      final alreadyRewarded =
          (await ref.getFast()).data()?['lastRewardDate'] == today;

      await _write(
        ref.set({
          'totalSessions': FieldValue.increment(1),
          'lastSessionAt': FieldValue.serverTimestamp(),
          if (!alreadyRewarded) 'lastRewardDate': today,
        }, SetOptions(merge: true)),
        'estado de respiración',
      );
      // Historial por sesión: el resumen semanal cruza qué días respiró con
      // su ánimo. `progress/breathing` solo guarda un contador.
      await _write(
        _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('breathing_sessions')
            .add({'at': Timestamp.now()}),
        'sesión de respiración',
      );
      if (alreadyRewarded) return false;

      await _awardXp(xpReward, garden: garden);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error completing breathing session: $e');
      return false;
    }
  }

  Future<bool> hasCompletedLessonToday() async {
    if (firebaseUser == null) return false;
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('completed_lessons')
          .where('completedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('completedAt', isLessThan: Timestamp.fromDate(endOfDay))
          .getFast();
      // Los retos diarios del Home también se guardan en completed_lessons
      // (`challenge_<fecha>`): no son una lección.
      return snapshot.docs.any((d) => !d.id.startsWith('challenge_'));
    } catch (e) { return false; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'errors.emailInUse'.tr();
      case 'invalid-email': return 'errors.invalidEmail'.tr();
      case 'weak-password': return 'errors.weakPassword'.tr();
      case 'user-not-found': return 'errors.userNotFound'.tr();
      case 'wrong-password': return 'errors.wrongPassword'.tr();
      case 'invalid-credential': return 'errors.invalidCredential'.tr();
      case 'too-many-requests': return 'errors.tooManyRequests'.tr();
      case 'network-request-failed': return 'errors.network'.tr();
      case 'user-disabled': return 'errors.userDisabled'.tr();
      case 'operation-not-allowed': return 'errors.generic'.tr();
      default: return 'errors.generic'.tr();
    }
  }
}