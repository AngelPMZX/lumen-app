import '../../core/utils/firestore_access.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/mood_entry.dart';
import '../../data/models/weekly_summary.dart';

/// Carga los datos de los últimos 28 días y arma el [WeeklySummary].
///
/// Todo se calcula en el teléfono: el ánimo y las actividades del usuario no
/// salen de su propia cuenta de Firestore.
class WeeklySummaryService {
  WeeklySummaryService._();
  static final WeeklySummaryService instance = WeeklySummaryService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<WeeklySummary> build(String uid, {DateTime? now}) async {
    final today = now ?? DateTime.now();
    final since = Timestamp.fromDate(DateTime(today.year, today.month, today.day - 27));
    final weekStart = DateTime(today.year, today.month, today.day - 6);
    final user = _firestore.collection('users').doc(uid);

    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> since28(
        String collection, String field) async {
      try {
        final snap = await user
            .collection(collection)
            .where(field, isGreaterThanOrEqualTo: since)
            .getFast();
        return snap.docs;
      } catch (e) {
        debugPrint('Weekly summary: error loading $collection: $e');
        return [];
      }
    }

    DateTime? dateOf(Map<String, dynamic> data, String field) {
      final v = data[field];
      return v is Timestamp ? v.toDate() : null;
    }

    final results = await Future.wait([
      since28('moods', 'timestamp'),
      since28('completed_lessons', 'completedAt'),
      since28('breathing_sessions', 'at'),
      since28('diary', 'createdAt'),
      since28('habit_checkins', 'date'),
    ]);

    final moods = <(DateTime, MoodType)>[
      for (final doc in results[0])
        if (dateOf(doc.data(), 'timestamp') case final date?)
          (date, MoodType.fromKey(doc.data()['mood'] ?? 'neutral')),
    ];

    // Los retos diarios del Home también se guardan en completed_lessons
    // (`challenge_*`): no son lecciones de rutas.
    final lessons = [
      for (final doc in results[1])
        if (!doc.id.startsWith('challenge_')) ?dateOf(doc.data(), 'completedAt'),
    ];

    List<DateTime> datesFrom(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String field,
            {bool Function(Map<String, dynamic>)? where}) =>
        [
          for (final doc in docs)
            if (where == null || where(doc.data())) ?dateOf(doc.data(), field),
        ];

    var commitmentsDone = 0;
    try {
      final snap = await user
          .collection('commitments')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .getFast();
      for (final doc in snap.docs) {
        final data = doc.data();
        final answered = dateOf(data, 'answeredAt');
        final status = data['status'];
        if (answered != null &&
            !answered.isBefore(weekStart) &&
            (status == 'done' || status == 'partial')) {
          commitmentsDone++;
        }
      }
    } catch (e) {
      debugPrint('Weekly summary: error loading commitments: $e');
    }

    return WeeklySummary.compute(
      now: today,
      moods: moods,
      lessons: lessons,
      breathing: datesFrom(results[2], 'at'),
      diary: datesFrom(results[3], 'createdAt'),
      habits: datesFrom(results[4], 'date', where: (d) => d['completed'] == true),
      commitmentsDone: commitmentsDone,
    );
  }
}
