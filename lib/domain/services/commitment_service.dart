import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/commitment.dart';

/// Guarda los micro-retos de las lecciones y decide cuándo preguntar por ellos.
///
/// Reglas:
/// - Máximo un reto pendiente por día: elegir otro el mismo día reemplaza al
///   anterior (así la recompensa por cumplirlo no se puede repetir).
/// - Se pregunta a partir del día siguiente.
/// - Si pasan más de [maxDaysToAsk] días sin respuesta, se marca `expired` sin
///   molestar: preguntar por un reto de hace una semana se siente a regaño.
class CommitmentService {
  CommitmentService._();
  static final CommitmentService instance = CommitmentService._();

  static const maxDaysToAsk = 3;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('commitments');

  Future<void> save({
    required String uid,
    required String text,
    required String lessonId,
    required String lessonTitle,
    String? routeId,
  }) async {
    try {
      final today = Commitment.dayKeyFor(DateTime.now());
      final data = {
        'text': text,
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'routeId': routeId,
        'dayKey': today,
        'status': CommitmentStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final todays = await _col(uid)
          .where('dayKey', isEqualTo: today)
          .limit(5)
          .get();
      final pendingToday = todays.docs
          .where((d) => d.data()['status'] == CommitmentStatus.pending.name)
          .toList();

      if (pendingToday.isNotEmpty) {
        await pendingToday.first.reference.set(data);
      } else {
        await _col(uid).add(data);
      }
    } catch (e) {
      debugPrint('Error saving commitment: $e');
    }
  }

  /// El reto por el que hay que preguntar hoy, si existe.
  Future<Commitment?> pendingToAsk(String uid) async {
    try {
      final snap = await _col(uid)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      final now = DateTime.now();
      final batch = _firestore.batch();
      var expiredAny = false;
      Commitment? toAsk;

      for (final doc in snap.docs) {
        final c = Commitment.fromDoc(doc);
        if (c.status != CommitmentStatus.pending) continue;
        final days = c.daysAgo(now);
        if (days < 1) continue; // de hoy: se pregunta mañana
        if (days > maxDaysToAsk) {
          batch.update(doc.reference, {'status': CommitmentStatus.expired.name});
          expiredAny = true;
          continue;
        }
        toAsk ??= c;
      }
      if (expiredAny) await batch.commit();
      return toAsk;
    } catch (e) {
      debugPrint('Error loading pending commitment: $e');
      return null;
    }
  }

  Future<void> answer(String uid, String id, CommitmentStatus status) async {
    try {
      await _col(uid).doc(id).update({
        'status': status.name,
        'answeredAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error answering commitment: $e');
    }
  }

  /// "Lo intento hoy": el mismo reto vuelve a quedar pendiente con fecha de hoy.
  Future<void> retryToday(String uid, String id) async {
    try {
      await _col(uid).doc(id).update({
        'status': CommitmentStatus.pending.name,
        'dayKey': Commitment.dayKeyFor(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error retrying commitment: $e');
    }
  }
}
