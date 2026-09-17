import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/weekly_missions.dart';

/// Estado de las misiones de la semana en curso.
class MissionsState {
  final String weekKey;
  final List<Mission> missions;
  final bool chestClaimed;

  const MissionsState({
    required this.weekKey,
    required this.missions,
    required this.chestClaimed,
  });

  int get claimedCount => missions.where((m) => m.claimed).length;
  int get claimableCount => missions.where((m) => m.claimable).length;
  bool get chestReady => missions.isNotEmpty && missions.every((m) => m.claimed) && !chestClaimed;
}

/// Misiones semanales en `users/{uid}/progress/missions`:
/// `{weekKey, types, claimed, chestClaimed}`. Las misiones se eligen al primer
/// acceso de la semana y se guardan, así no cambian aunque cambie el catálogo.
/// El avance se calcula con los datos reales de la semana (lunes a hoy).
class MissionService {
  MissionService._();
  static final MissionService instance = MissionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid).collection('progress').doc('missions');

  Future<MissionsState> load({
    required String uid,
    required bool hasHabits,
    required bool reviewAvailable,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final weekKey = WeeklyMissions.weekKey(today);

    var types = <MissionType>[];
    var claimed = <String>{};
    var chestClaimed = false;

    try {
      final data = (await _doc(uid).get()).data();
      if (data != null && data['weekKey'] == weekKey) {
        types = [
          for (final name in List<String>.from(data['types'] ?? const []))
            ...MissionType.values.where((t) => t.name == name),
        ];
        claimed = Set<String>.from(data['claimed'] ?? const []);
        chestClaimed = data['chestClaimed'] == true;
      }
      if (types.length != WeeklyMissions.missionsPerWeek) {
        types = WeeklyMissions.pick(
          weekKey: weekKey,
          uid: uid,
          hasHabits: hasHabits,
          reviewAvailable: reviewAvailable,
        );
        claimed = {};
        chestClaimed = false;
        await _doc(uid).set({
          'weekKey': weekKey,
          'types': types.map((t) => t.name).toList(),
          'claimed': <String>[],
          'chestClaimed': false,
        });
      }
    } catch (e) {
      debugPrint('Error loading missions: $e');
      if (types.isEmpty) {
        types = WeeklyMissions.pick(
            weekKey: weekKey, uid: uid, hasHabits: hasHabits, reviewAvailable: reviewAvailable);
      }
    }

    final activity = await _activitySince(uid, WeeklyMissions.weekStart(today));
    return MissionsState(
      weekKey: weekKey,
      missions: WeeklyMissions.build(types: types, activity: activity, claimed: claimed),
      chestClaimed: chestClaimed,
    );
  }

  /// Marca la misión como reclamada. Devuelve false si ya lo estaba o si la
  /// semana cambió (evita cobrar dos veces con toques rápidos).
  Future<bool> claim(String uid, String weekKey, MissionType type) async {
    try {
      return await _firestore.runTransaction<bool>((tx) async {
        final snap = await tx.get(_doc(uid));
        final data = snap.data();
        if (data == null || data['weekKey'] != weekKey) return false;
        final claimed = List<String>.from(data['claimed'] ?? const []);
        if (claimed.contains(type.name)) return false;
        tx.update(_doc(uid), {'claimed': [...claimed, type.name]});
        return true;
      });
    } catch (e) {
      debugPrint('Error claiming mission: $e');
      return false;
    }
  }

  /// Abre el cofre si las 3 misiones están reclamadas. Devuelve false si no
  /// corresponde o si ya se abrió.
  Future<bool> openChest(String uid, String weekKey) async {
    try {
      return await _firestore.runTransaction<bool>((tx) async {
        final snap = await tx.get(_doc(uid));
        final data = snap.data();
        if (data == null || data['weekKey'] != weekKey || data['chestClaimed'] == true) return false;
        final claimed = List<String>.from(data['claimed'] ?? const []);
        final types = List<String>.from(data['types'] ?? const []);
        if (types.isEmpty || !types.every(claimed.contains)) return false;
        tx.update(_doc(uid), {'chestClaimed': true});
        return true;
      });
    } catch (e) {
      debugPrint('Error opening chest: $e');
      return false;
    }
  }

  Future<WeekActivity> _activitySince(String uid, DateTime start) async {
    final user = _firestore.collection('users').doc(uid);
    final since = Timestamp.fromDate(start);

    Future<List<Map<String, dynamic>>> query(String collection, String field) async {
      try {
        final snap = await user.collection(collection).where(field, isGreaterThanOrEqualTo: since).get();
        return snap.docs.map((d) => {...d.data(), '_id': d.id}).toList();
      } catch (e) {
        debugPrint('Missions: error loading $collection: $e');
        return [];
      }
    }

    final r = await Future.wait([
      query('moods', 'timestamp'),
      query('completed_lessons', 'completedAt'),
      query('breathing_sessions', 'at'),
      query('diary', 'createdAt'),
      query('review_sessions', 'at'),
      query('habit_checkins', 'date'),
      query('commitments', 'answeredAt'),
    ]);

    String dayOf(dynamic ts) {
      final d = (ts as Timestamp).toDate();
      return '${d.year}-${d.month}-${d.day}';
    }

    return WeekActivity(
      checkInDays: r[0].where((m) => m['timestamp'] is Timestamp).map((m) => dayOf(m['timestamp'])).toSet().length,
      lessons: r[1].where((m) => !(m['_id'] as String).startsWith('challenge_')).length,
      breathing: r[2].length,
      diary: r[3].length,
      reviews: r[4].length,
      habits: r[5].where((m) => m['completed'] == true).length,
      commitments: r[6].where((m) => m['status'] == 'done' || m['status'] == 'partial').length,
    );
  }
}
