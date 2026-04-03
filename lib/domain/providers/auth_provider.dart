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

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get firebaseUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  UserProgress? _userProgress;
  UserProgress? get userProgress => _userProgress;

  // Cola de celebraciones pendientes
  List<CelebrationEvent> _pendingCelebrations = [];
  List<CelebrationEvent> get pendingCelebrations => _pendingCelebrations;

  /// Consume (y limpia) las celebraciones pendientes
  List<CelebrationEvent> consumeCelebrations() {
    final events = List<CelebrationEvent>.from(_pendingCelebrations);
    _pendingCelebrations = [];
    return events;
  }
 
  // Contadores para verificación de achievements
  int _diaryEntryCount = 0;
  int _habitsCompletedCount = 0;
  int _moodCheckInCount = 0;

  /// Helper para verificar si el perfil está completo
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

  // ═══════════════════════════════════════════
  // Cargar datos del usuario desde Firestore
  // ═══════════════════════════════════════════
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
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

    /// Guarda una entrada de ánimo en Firestore y suma XP
  // ═══════════════════════════════════════════
  // REEMPLAZAR el método saveMoodEntry() existente
  // en auth_provider.dart con este:
  // ═══════════════════════════════════════════

  /// Guarda una entrada de ánimo en Firestore.
  /// Solo suma XP la PRIMERA vez del día. Cambios posteriores
  /// actualizan el mood sin dar XP adicional.
  Future<bool> saveMoodEntry(MoodEntry entry) async {
    if (firebaseUser == null) return false;

    try {
      // Verificar si ya hay un mood registrado hoy
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingMoods = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('moods')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp',
              isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      final isFirstMoodToday = existingMoods.docs.isEmpty;

      if (isFirstMoodToday) {
        // Primera vez hoy: guardar nuevo + sumar XP
        await _firestore
            .collection('users')
            .doc(firebaseUser!.uid)
            .collection('moods')
            .doc(entry.id)
            .set(entry.toMap());

        // Sumar XP solo la primera vez
         if (_userProgress != null) {
          final oldProgress = _userProgress!; // ← AGREGAR esta línea
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
              .collection('users')
              .doc(firebaseUser!.uid)
              .collection('progress')
              .doc('current')
              .set(updatedProgress.toMap());

          _userProgress = updatedProgress;
           _moodCheckInCount++;
          _checkCelebrations(oldProgress, updatedProgress);
        }
      } else {
        // Ya registró hoy: solo actualizar el mood, SIN sumar XP
        final existingDocId = existingMoods.docs.first.id;
        await _firestore
            .collection('users')
            .doc(firebaseUser!.uid)
            .collection('moods')
            .doc(existingDocId)
            .update({
          'mood': entry.mood.key,
          'intensity': entry.intensity,
          'note': entry.note,
        });
      }

      notifyListeners();
      return isFirstMoodToday; // true = ganó XP, false = solo actualizó
    } catch (e) {
      debugPrint('Error saving mood entry: $e');
      rethrow;
    }
  }

  /// Obtiene los moods de la semana actual para la gráfica
  Future<Map<int, MoodType>> getWeeklyMoods() async {
    if (firebaseUser == null) return {};

    try {
      final now = DateTime.now();
      // Inicio de la semana (lunes)
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('moods')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('timestamp',
              isLessThan: Timestamp.fromDate(endOfWeek))
          .orderBy('timestamp')
          .get();

      final Map<int, MoodType> weeklyMoods = {};
      for (final doc in snapshot.docs) {
        final entry = MoodEntry.fromMap(doc.data());
        final weekday = entry.timestamp.weekday; // 1 = Monday
        weeklyMoods[weekday] = entry.mood; // Último mood del día gana
      }

      return weeklyMoods;
    } catch (e) {
      debugPrint('Error loading weekly moods: $e');
      return {};
    }
  }

  /// Obtiene el mood registrado HOY (si existe).
  /// Se usa para restaurar la selección al recargar la app.
  Future<MoodType?> getTodayMood() async {
    if (firebaseUser == null) return null;
 
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
 
      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('moods')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp',
              isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
 
      if (snapshot.docs.isNotEmpty) {
        final entry = MoodEntry.fromMap(snapshot.docs.first.data());
        return entry.mood;
      }
    } catch (e) {
      debugPrint('Error getting today mood: $e');
    }
    return null;
  }


  // ═══════════════════════════════════════════
  // Cargar progreso (racha, XP, nivel)
  // ═══════════════════════════════════════════
  Future<void> _loadUserProgress() async {
    if (firebaseUser == null) return;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('progress')
          .doc('current')
          .get();

      if (doc.exists) {
        _userProgress = UserProgress.fromMap(doc.data()!);
      } else {
        _userProgress = UserProgress();
        await _firestore
            .collection('users')
            .doc(firebaseUser!.uid)
            .collection('progress')
            .doc('current')
            .set(_userProgress!.toMap());
      }
    } catch (e) {
      debugPrint('Error loading user progress: $e');
      _userProgress = UserProgress();
    }
  }

   /// Verifica si hay logros nuevos después de una acción
  void _checkCelebrations(UserProgress? before, UserProgress after) {
    final events = AchievementService.checkForCelebrations(
      progressBefore: before,
      progressAfter: after,
      diaryEntries: _diaryEntryCount,
      habitsCompleted: _habitsCompletedCount,
      moodCheckIns: _moodCheckInCount,
    );
    if (events.isNotEmpty) {
      _pendingCelebrations.addAll(events);
    }
  }

  // ═══════════════════════════════════════════
  // Registrar check-in con server timestamp (anti-trampa)
  // ═══════════════════════════════════════════
  Future<bool> recordCheckIn() async {
    if (firebaseUser == null || _userProgress == null) return false;
    try {
      final serverTime = await _getServerTimestamp();

      if (_userProgress!.hasCheckedInToday(serverTime)) {
        return false; // Ya hizo check-in hoy
      }
      final oldProgress = _userProgress!; 
      final updatedProgress = _userProgress!.calculateStreak(serverTime);

      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('progress')
          .doc('current')
          .set(updatedProgress.toMap());

      _userProgress = updatedProgress;
       _checkCelebrations(oldProgress, updatedProgress);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error recording check-in: $e');
      return false;
    }
  }

  /// Obtiene el timestamp del servidor de Firebase (anti-trampa)
  Future<DateTime> _getServerTimestamp() async {
    final ref = _firestore
        .collection('_server_time')
        .doc(firebaseUser!.uid);

    await ref.set({'timestamp': FieldValue.serverTimestamp()});
    final snap = await ref.get();
    final Timestamp ts = snap.data()!['timestamp'];
    await ref.delete();

    return ts.toDate();
  }

  // ═══════════════════════════════════════════
  // Registro con email y contraseña
  // ═══════════════════════════════════════════
  Future<bool> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);

      final userModel = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
      );

      // FIX: usar toFirestoreMap() para .set() — usa serverTimestamp
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toFirestoreMap());

      _userModel = userModel;

      // Crear progreso inicial
      _userProgress = UserProgress();
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .collection('progress')
          .doc('current')
          .set(_userProgress!.toMap());

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

  // ═══════════════════════════════════════════
  // Login con email y contraseña
  // ═══════════════════════════════════════════
  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

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

  // ═══════════════════════════════════════════
  // Login con Google
  // ═══════════════════════════════════════════
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
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        final userModel = UserModel(
          uid: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'Usuario',
          email: userCredential.user!.email ?? '',
        );
        // FIX: usar toFirestoreMap() para .set()
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toFirestoreMap());
        _userModel = userModel;

        _userProgress = UserProgress();
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .collection('progress')
            .doc('current')
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

  // ═══════════════════════════════════════════
  // Verificar si un username ya existe
  // ═══════════════════════════════════════════
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
      return true;
    }
  }

  // ═══════════════════════════════════════════
  // Actualizar perfil con validación y error handling
  // Retorna (éxito, mensajeError)
  // ═══════════════════════════════════════════
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
    if (firebaseUser == null) {
      return (false, 'No hay sesión activa');
    }

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

        if (currentGender == null || currentGender.isEmpty) {
          _isLoading = false;
          notifyListeners();
          return (false, 'El género es obligatorio');
        }
        if (currentAge == null) {
          _isLoading = false;
          notifyListeners();
          return (false, 'La edad es obligatoria');
        }
        if (currentUsername == null || currentUsername.isEmpty) {
          _isLoading = false;
          notifyListeners();
          return (false, 'El nombre de usuario es obligatorio');
        }
        if (currentHobbies.length < 3) {
          _isLoading = false;
          notifyListeners();
          return (false, 'Selecciona al menos 3 hobbies');
        }
        if (currentMusic.length < 2) {
          _isLoading = false;
          notifyListeners();
          return (false, 'Selecciona al menos 2 géneros musicales');
        }

        updates['profileComplete'] = true;
      }

      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .update(updates);

      await loadUserData();

      _isLoading = false;
      notifyListeners();
      return (true, null);
    } on FirebaseException catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Firestore error: $e');
      return (false, 'Error al guardar. Verifica tu conexión.');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Error updating profile: $e');
      return (false, 'Ocurrió un error inesperado.');
    }
  }


  /// Guarda una entrada del diario y suma XP
  Future<void> saveDiaryEntry(DiaryEntry entry) async {
    if (firebaseUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('diary')
          .doc(entry.id)
          .set(entry.toMap());

      // Sumar XP: 20 por entrada + 5 extra si tiene gratitud
      if (_userProgress != null) {
        final oldProgress = _userProgress!;
        int xpGain = 20;
        if (entry.gratitude != null && entry.gratitude!.isNotEmpty) {
          xpGain += 5;
        }

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
            .collection('users')
            .doc(firebaseUser!.uid)
            .collection('progress')
            .doc('current')
            .set(updatedProgress.toMap());

        _userProgress = updatedProgress;
         _diaryEntryCount++;                               // ← AGREGAR
        _checkCelebrations(oldProgress, updatedProgress); 
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving diary entry: $e');
      rethrow;
    }
  }

  /// Obtiene las entradas del diario ordenadas por fecha (más reciente primero)
  Future<List<DiaryEntry>> getDiaryEntries({int limit = 50}) async {
    if (firebaseUser == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('diary')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => DiaryEntry.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading diary entries: $e');
      return [];
    }
  }

  /// Obtiene un mapa de fecha → mood para el calendario heatmap
  Future<Map<DateTime, MoodType>> getDiaryCalendarMoods(
      DateTime start, DateTime end) async {
    if (firebaseUser == null) return {};

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('diary')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('createdAt')
          .get();

      final Map<DateTime, MoodType> moods = {};
      for (final doc in snapshot.docs) {
        final entry = DiaryEntry.fromMap(doc.data());
        final normalized = DateTime(
          entry.createdAt.year,
          entry.createdAt.month,
          entry.createdAt.day,
        );
        moods[normalized] = entry.mood; // Último mood del día gana
      }

      return moods;
    } catch (e) {
      debugPrint('Error loading diary calendar moods: $e');
      return {};
    }
  }

  /// Elimina una entrada del diario
  Future<void> deleteDiaryEntry(String entryId) async {
    if (firebaseUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('diary')
          .doc(entryId)
          .delete();

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting diary entry: $e');
      rethrow;
    }
  }

  // ── RECORDATORIOS (fix: orderBy single field) ──
 
  Future<void> saveReminder(Reminder reminder) async {
    if (firebaseUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('reminders')
          .doc(reminder.id)
          .set(reminder.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving reminder: $e');
      rethrow;
    }
  }
 
  Future<List<Reminder>> getReminders() async {
    if (firebaseUser == null) return [];
    try {
      // FIX: usar timeInMinutes en vez de orderBy doble (hour + minute)
      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('reminders')
          .orderBy('timeInMinutes')
          .get();
      return snapshot.docs
          .map((doc) => Reminder.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading reminders: $e');
      // Fallback sin orderBy si el índice no existe aún
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(firebaseUser!.uid)
            .collection('reminders')
            .get();
        final list = snapshot.docs
            .map((doc) => Reminder.fromMap(doc.data()))
            .toList();
        list.sort((a, b) => a.timeInMinutes.compareTo(b.timeInMinutes));
        return list;
      } catch (e2) {
        debugPrint('Fallback also failed: $e2');
        return [];
      }
    }
  }
 
  Future<void> toggleReminder(String reminderId, bool isEnabled) async {
    if (firebaseUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('reminders')
          .doc(reminderId)
          .update({'isEnabled': isEnabled});
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling reminder: $e');
      rethrow;
    }
  }
 
  Future<void> deleteReminder(String reminderId) async {
    if (firebaseUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('reminders')
          .doc(reminderId)
          .delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
      rethrow;
    }
  }
 
  // ── HÁBITOS ──
 
  Future<void> saveHabit(Habit habit) async {
    if (firebaseUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('habits')
          .doc(habit.id)
          .set(habit.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving habit: $e');
      rethrow;
    }
  }
 
  Future<List<Habit>> getHabits() async {
    if (firebaseUser == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('habits')
          .orderBy('createdAt')
          .get();
      return snapshot.docs
          .map((doc) => Habit.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading habits: $e');
      return [];
    }
  }
 
  Future<void> deleteHabit(String habitId) async {
    if (firebaseUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('habits')
          .doc(habitId)
          .delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting habit: $e');
      rethrow;
    }
  }
 
   /// Check-in de un hábito para hoy.
  /// Solo da XP la PRIMERA vez que se marca en el día.
  /// Retorna true si dio XP, false si solo restauró.
  Future<bool> checkInHabit(String habitId) async {
    if (firebaseUser == null) return false;
    try {
      final today = DateTime.now();
      final checkIn = HabitCheckIn(habitId: habitId, date: today);
 
      // Verificar si ya existía un check-in hoy para este hábito
      final existingDoc = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('habit_checkins')
          .doc(checkIn.docId)
          .get();
 
      final isFirstTime = !existingDoc.exists;
 
      // Guardar/restaurar el check-in (siempre con completed: true)
      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('habit_checkins')
          .doc(checkIn.docId)
          .set(checkIn.toMap());
 
      // Solo dar XP la primera vez del día (doc no existía antes)
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
            .collection('users')
            .doc(firebaseUser!.uid)
            .collection('progress')
            .doc('current')
            .set(updatedProgress.toMap());
        _userProgress = updatedProgress;
        _habitsCompletedCount++;                            
        _checkCelebrations(oldProgress, updatedProgress);
      }
 
      notifyListeners();
      return isFirstTime;
    } catch (e) {
      debugPrint('Error checking in habit: $e');
      rethrow;
    }
  }
 
  /// Deshacer check-in de un hábito para hoy.
  /// NO elimina el documento — solo lo marca como completed: false.
  /// Así al volver a marcar, el doc ya existe y no da XP de nuevo.
  Future<void> uncheckHabit(String habitId) async {
    if (firebaseUser == null) return;
    try {
      final today = DateTime.now();
      final checkIn = HabitCheckIn(habitId: habitId, date: today);
 
      // En vez de eliminar, marcar como no completado
      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('habit_checkins')
          .doc(checkIn.docId)
          .update({'completed': false});
 
      notifyListeners();
    } catch (e) {
      debugPrint('Error unchecking habit: $e');
      rethrow;
    }
  }
 
  /// Obtiene los IDs de hábitos completados hoy.
  /// Solo cuenta los que tienen completed: true.
  Future<Set<String>> getTodayHabitCheckIns() async {
    if (firebaseUser == null) return {};
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
 
      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('habit_checkins')
          .get();
 
      return snapshot.docs
          .where((doc) => doc.id.endsWith(dateStr))
          .where((doc) {
            final data = doc.data();
            // Solo contar los que están completed: true
            return data['completed'] == true;
          })
          .map((doc) {
            final data = doc.data();
            return data['habitId'] as String? ?? '';
          })
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('Error loading today checkins: $e');
      return {};
    }
  }

  /// Verifica si el usuario ya escribió en el diario hoy
  /// (para el progress ring del Home)
  Future<bool> hasDiaryEntryToday() async {
    if (firebaseUser == null) return false;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('diary')
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt',
              isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking today diary: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════
  // AGREGAR ESTOS MÉTODOS al auth_provider.dart
  // (dentro de la clase AuthProvider, antes del cierre })
  // ═══════════════════════════════════════════════════════

  /// Obtiene los IDs de lecciones completadas
  Future<Set<String>> getCompletedLessons() async {
    if (firebaseUser == null) return {};
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('completed_lessons')
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      debugPrint('Error loading completed lessons: $e');
      return {};
    }
  }

  /// Completa una lección y suma XP
  Future<void> completeLesson(String lessonId, int xpReward) async {
    if (firebaseUser == null) return;
    try {
      // Verificar si ya la completó antes
      final existing = await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('completed_lessons')
          .doc(lessonId)
          .get();

      if (existing.exists) return; // Ya la completó, no dar XP de nuevo

      // Marcar como completada
      await _firestore
          .collection('users')
          .doc(firebaseUser!.uid)
          .collection('completed_lessons')
          .doc(lessonId)
          .set({
        'completedAt': FieldValue.serverTimestamp(),
        'xpEarned': xpReward,
      });

      // Sumar XP
      if (_userProgress != null) {
         final oldProgress = _userProgress!;
        final newXp = _userProgress!.totalXp + xpReward;
        final newLevel = (newXp ~/ 100) + 1;
        final updatedProgress = UserProgress(
          currentStreak: _userProgress!.currentStreak,
          longestStreak: _userProgress!.longestStreak,
          lastCheckIn: _userProgress!.lastCheckIn,
          totalXp: newXp,
          level: newLevel,
        );
        await _firestore
            .collection('users')
            .doc(firebaseUser!.uid)
            .collection('progress')
            .doc('current')
            .set(updatedProgress.toMap());
         _userProgress = updatedProgress;
        _checkCelebrations(oldProgress, updatedProgress);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error completing lesson: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════
  // Cerrar sesión
  // ═══════════════════════════════════════════
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google sign out error (ignorable): $e');
    }
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Firebase sign out error: $e');
    }
    _userModel = null;
    _userProgress = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres)';
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tu correo y contraseña';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento';
      default:
        return 'Ocurrió un error. Intenta de nuevo.';
    }
  }
}