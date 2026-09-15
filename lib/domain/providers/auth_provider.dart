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
import '../../domain/services/achievement_service.dart';
import '../providers/garden_provider.dart';
import '../services/notification_service.dart';
import 'package:easy_localization/easy_localization.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get firebaseUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isGoogleUser =>
      firebaseUser?.providerData.any((p) => p.providerId == 'google.com') ??
      false;

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

  // ── Set de achievements ya celebrados (fuente de verdad = Firestore) ───────
  Set<String> _celebratedAchievementIds = {};

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

  // ── Getter: ¿se rompió la racha hoy? (para mostrar botón de escudo) ────────
  /// true si el último check-in fue hace más de 1 día y hoy no se ha hecho.
  bool get streakBrokenToday {
    if (_userProgress == null) return false;
    final lastCheckIn = _userProgress!.lastCheckIn;
    if (lastCheckIn == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
        lastCheckIn.year, lastCheckIn.month, lastCheckIn.day);
    // Si ya hizo check-in hoy, la racha NO está rota
    if (lastDate == today) return false;
    // Si el último check-in fue antes de ayer, la racha está rota
    final yesterday = today.subtract(const Duration(days: 1));
    return lastDate.isBefore(yesterday);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOAD USER DATA
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> loadUserData() async {
    if (firebaseUser == null) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
      }
      await _loadUserProgress();

      try {
        final diarySnap = await _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('diary').count().get();
        _diaryEntryCount = diarySnap.count ?? 0;

        final habitsSnap = await _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('habit_checkins')
            .where('completed', isEqualTo: true).count().get();
        _habitsCompletedCount = habitsSnap.count ?? 0;

        final moodsSnap = await _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('moods').count().get();
        _moodCheckInCount = moodsSnap.count ?? 0;
      } catch (e) {
        debugPrint('Error loading counters: $e');
      }

      await _loadCelebratedAchievements();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadCelebratedAchievements() async {
    if (firebaseUser == null) return;
    try {
      final doc = await _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('progress').doc('celebrated_achievements').get();
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
      await _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('progress').doc('celebrated_achievements')
          .set({'ids': _celebratedAchievementIds.toList()});
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
          .limit(1).get();

      final isFirstMoodToday = existingMoods.docs.isEmpty;

      if (isFirstMoodToday) {
        await _firestore
            .collection('users').doc(firebaseUser!.uid).collection('moods')
            .doc(entry.id).set(entry.toMap());

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
          await _firestore
              .collection('users').doc(firebaseUser!.uid)
              .collection('progress').doc('current')
              .set(updatedProgress.toMap());
          _userProgress = updatedProgress;
          _moodCheckInCount++;
          await _checkCelebrations(oldProgress, updatedProgress);
        }
      } else {
        final existingDocId = existingMoods.docs.first.id;
        await _firestore
            .collection('users').doc(firebaseUser!.uid).collection('moods')
            .doc(existingDocId)
            .update({
          'mood': entry.mood.key,
          'intensity': entry.intensity,
          'note': entry.note,
        });
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
          .orderBy('timestamp').get();

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
          .limit(1).get();

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
          .collection('progress').doc('current').get();
      if (doc.exists) {
        _userProgress = UserProgress.fromMap(doc.data()!);
      } else {
        _userProgress = UserProgress();
        await _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('progress').doc('current')
            .set(_userProgress!.toMap());
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

      await _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('progress').doc('current')
          .set(updatedProgress.toMap());

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
    _errorMessage = 'auth.errors.generic'.tr();
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  /// Restaura la racha al valor indicado (estilo TikTok con escudo).
/// Llamar después de useStreakShield() en GardenProvider.
Future<void> restoreStreakWithShield(int streakToRestore) async {
  if (firebaseUser == null || _userProgress == null) return;
  try {
    final now = DateTime.now();
    final updatedProgress = UserProgress(
      currentStreak: streakToRestore,
      longestStreak: _userProgress!.longestStreak > streakToRestore
          ? _userProgress!.longestStreak
          : streakToRestore,
      lastCheckIn: now,
      totalXp: _userProgress!.totalXp,
      level: _userProgress!.level,
    );
    await _firestore
        .collection('users')
        .doc(firebaseUser!.uid)
        .collection('progress')
        .doc('current')
        .set(updatedProgress.toMap());
    _userProgress = updatedProgress;
    notifyListeners();
  } catch (e) {
    debugPrint('Error restoring streak with shield: $e');
  }
}

  Future<DateTime> _getServerTimestamp() async {
    final ref = _firestore.collection('_server_time').doc(firebaseUser!.uid);
    await ref.set({'timestamp': FieldValue.serverTimestamp()});
    final snap = await ref.get();
    final Timestamp ts = snap.data()!['timestamp'];
    await ref.delete();
    return ts.toDate();
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
    _errorMessage = 'Ocurrió un error. Intenta de nuevo.';
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
    _errorMessage = _getErrorMessage(e.code);
    _isLoading = false;
    notifyListeners();
    return false;
  } catch (e) {
    _errorMessage = 'Ocurrió un error. Intenta de nuevo.';
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
    await _auth.currentUser!.reload();
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
      _errorMessage = 'auth.errors.sessionExpired'.tr();
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
      _errorMessage = 'auth.errors.tooManyRequests'.tr();
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
          .collection('users').doc(userCredential.user!.uid).get();
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
    } catch (e) {
      _errorMessage = 'Error al iniciar con Google';
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
      if (isGoogleUser) {
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
      final snapshot = await ref.limit(batchSize).get();
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
  Future<bool> isUsernameTaken(String username) async {
  try {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  } catch (e) {
    debugPrint('Error checking username: $e');
    return false; // ← si falla la consulta, permitir continuar
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
    if (firebaseUser == null) return (false, 'No hay sesión activa');
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

        if (currentGender == null || currentGender.isEmpty) { _isLoading = false; notifyListeners(); return (false, 'El género es obligatorio'); }
        if (currentAge == null) { _isLoading = false; notifyListeners(); return (false, 'La edad es obligatoria'); }
        if (currentUsername == null || currentUsername.isEmpty) { _isLoading = false; notifyListeners(); return (false, 'El nombre de usuario es obligatorio'); }
        if (currentHobbies.length < 3) { _isLoading = false; notifyListeners(); return (false, 'Selecciona al menos 3 hobbies'); }
        if (currentMusic.length < 2) { _isLoading = false; notifyListeners(); return (false, 'Selecciona al menos 2 géneros musicales'); }

        updates['profileComplete'] = true;
      }

      await _firestore.collection('users').doc(firebaseUser!.uid).update(updates);
      await loadUserData();
      _isLoading = false;
      notifyListeners();
      return (true, null);
    } on FirebaseException catch (e) {
      _isLoading = false;
      notifyListeners();
      return (false, 'Error al guardar. Verifica tu conexión.');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return (false, 'Ocurrió un error inesperado.');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIARY
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> saveDiaryEntry(DiaryEntry entry) async {
    if (firebaseUser == null) return;
    try {
      await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('diary')
          .doc(entry.id).set(entry.toMap());

      if (_userProgress != null) {
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
        await _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('progress').doc('current')
            .set(updatedProgress.toMap());
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
          .limit(limit).get();
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
          .orderBy('createdAt').get();

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
      await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('diary')
          .doc(entryId).delete();
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
          .limit(1).get();
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
      await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('reminders')
          .doc(reminder.id).set(reminder.toMap());
      notifyListeners();
    } catch (e) { rethrow; }
  }

  Future<List<Reminder>> getReminders() async {
    if (firebaseUser == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('reminders')
          .orderBy('timeInMinutes').get();
      return snapshot.docs.map((doc) => Reminder.fromMap(doc.data())).toList();
    } catch (e) {
      try {
        final snapshot = await _firestore
            .collection('users').doc(firebaseUser!.uid).collection('reminders').get();
        final list = snapshot.docs.map((doc) => Reminder.fromMap(doc.data())).toList();
        list.sort((a, b) => a.timeInMinutes.compareTo(b.timeInMinutes));
        return list;
      } catch (e2) { return []; }
    }
  }

  Future<void> toggleReminder(String reminderId, bool isEnabled) async {
    if (firebaseUser == null) return;
    try {
      await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('reminders')
          .doc(reminderId).update({'isEnabled': isEnabled});
      notifyListeners();
    } catch (e) { rethrow; }
  }

  Future<void> deleteReminder(String reminderId) async {
    if (firebaseUser == null) return;
    try {
      await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('reminders')
          .doc(reminderId).delete();
      notifyListeners();
    } catch (e) { rethrow; }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HABITS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> saveHabit(Habit habit) async {
    if (firebaseUser == null) return;
    try {
      await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('habits')
          .doc(habit.id).set(habit.toMap());
      notifyListeners();
    } catch (e) { rethrow; }
  }

  Future<List<Habit>> getHabits() async {
    if (firebaseUser == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('habits')
          .orderBy('createdAt').get();
      return snapshot.docs.map((doc) => Habit.fromMap(doc.data())).toList();
    } catch (e) { return []; }
  }

  Future<void> deleteHabit(String habitId) async {
    if (firebaseUser == null) return;
    try {
      await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('habits')
          .doc(habitId).delete();
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
          .doc(checkIn.docId).get();
      final isFirstTime = !existingDoc.exists;

      await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('habit_checkins')
          .doc(checkIn.docId).set(checkIn.toMap());

      if (isFirstTime && _userProgress != null) {
        final oldProgress = _userProgress!;
        final newXp = _userProgress!.totalXp + 5;
        final newLevel = (newXp ~/ 100) + 1;
        final updatedProgress = UserProgress(
          currentStreak: _userProgress!.currentStreak,
          longestStreak: _userProgress!.longestStreak,
          lastCheckIn: _userProgress!.lastCheckIn,
          totalXp: newXp,
          level: newLevel,
        );
        await _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('progress').doc('current')
            .set(updatedProgress.toMap());
        _userProgress = updatedProgress;
        _habitsCompletedCount++;
        await _checkCelebrations(oldProgress, updatedProgress);
      }

      notifyListeners();
      return isFirstTime;
    } catch (e) { rethrow; }
  }

  Future<void> uncheckHabit(String habitId) async {
    if (firebaseUser == null) return;
    try {
      final today = DateTime.now();
      final checkIn = HabitCheckIn(habitId: habitId, date: today);
      await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('habit_checkins')
          .doc(checkIn.docId).update({'completed': false});
      notifyListeners();
    } catch (e) { rethrow; }
  }

  Future<Set<String>> getTodayHabitCheckIns() async {
    if (firebaseUser == null) return {};
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final snapshot = await _firestore
          .collection('users').doc(firebaseUser!.uid).collection('habit_checkins').get();
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
          .collection('completed_lessons').get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) { return {}; }
  }

  /// [garden] — pasar el GardenProvider para aplicar multiplicador XP si activo.
  /// Ejemplo: auth.completeLesson(id, xp, garden: context.read<GardenProvider>())
  Future<void> completeLesson(String lessonId, int xpReward,
      {GardenProvider? garden}) async {
    if (firebaseUser == null) return;
    try {
      final existing = await _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('completed_lessons').doc(lessonId).get();
      if (existing.exists) return;

      await _firestore
          .collection('users').doc(firebaseUser!.uid)
          .collection('completed_lessons').doc(lessonId).set({
        'completedAt': FieldValue.serverTimestamp(),
        'xpEarned': xpReward,
      });

      if (_userProgress != null) {
        final oldProgress = _userProgress!;

        // ── Aplicar multiplicador XP del jardín si está activo ──────────
        final multiplier = garden?.currentXpMultiplier ?? 1.0;
        final finalXp = multiplier > 1.0
            ? (xpReward * multiplier).round()
            : xpReward;
        // ────────────────────────────────────────────────────────────────

        final newXp = _userProgress!.totalXp + finalXp;
        final newLevel = (newXp ~/ 100) + 1;
        final updatedProgress = UserProgress(
          currentStreak: _userProgress!.currentStreak,
          longestStreak: _userProgress!.longestStreak,
          lastCheckIn: _userProgress!.lastCheckIn,
          totalXp: newXp,
          level: newLevel,
        );
        await _firestore
            .collection('users').doc(firebaseUser!.uid)
            .collection('progress').doc('current')
            .set(updatedProgress.toMap());
        _userProgress = updatedProgress;
        await _checkCelebrations(oldProgress, updatedProgress);
      }

      notifyListeners();
    } catch (e) { rethrow; }
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
          .limit(1).get();
      return snapshot.docs.isNotEmpty;
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
      case 'email-already-in-use': return 'Este correo ya está registrado';
      case 'invalid-email': return 'Correo electrónico inválido';
      case 'weak-password': return 'La contraseña es muy débil (mínimo 6 caracteres)';
      case 'user-not-found': return 'No existe una cuenta con este correo';
      case 'wrong-password': return 'Contraseña incorrecta';
      case 'invalid-credential': return 'Credenciales inválidas. Verifica tu correo y contraseña';
      case 'too-many-requests': return 'Demasiados intentos. Espera un momento';
      default: return 'Ocurrió un error. Intenta de nuevo.';
    }
  }
}