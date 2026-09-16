import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado de un micro-reto elegido al final de una lección.
enum CommitmentStatus { pending, done, partial, skipped, expired }

/// Un micro-reto (paso `commit` de una lección) guardado para preguntarle al
/// usuario al día siguiente si lo cumplió.
///
/// Vive en `users/{uid}/commitments/{id}`.
class Commitment {
  final String id;
  final String text;
  final String lessonId;
  final String lessonTitle;
  final String? routeId;

  /// Día local en que se eligió (o se volvió a intentar), `yyyy-MM-dd`.
  /// Se guarda como texto para comparar días de calendario sin depender de
  /// zonas horarias ni de cambios de horario.
  final String dayKey;
  final CommitmentStatus status;
  final DateTime? createdAt;

  const Commitment({
    required this.id,
    required this.text,
    required this.lessonId,
    required this.lessonTitle,
    this.routeId,
    required this.dayKey,
    required this.status,
    this.createdAt,
  });

  static String dayKeyFor(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Días de calendario desde [dayKey] hasta [today]. Usa fechas UTC para
  /// que un día con cambio de horario no cuente como 0.
  int daysAgo(DateTime today) {
    final parts = dayKey.split('-').map(int.parse).toList();
    final then = DateTime.utc(parts[0], parts[1], parts[2]);
    final now = DateTime.utc(today.year, today.month, today.day);
    return now.difference(then).inDays;
  }

  factory Commitment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final created = data['createdAt'];
    return Commitment(
      id: doc.id,
      text: data['text'] ?? '',
      lessonId: data['lessonId'] ?? '',
      lessonTitle: data['lessonTitle'] ?? '',
      routeId: data['routeId'],
      dayKey: data['dayKey'] ?? dayKeyFor(DateTime.now()),
      status: CommitmentStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => CommitmentStatus.pending,
      ),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
