import 'diary_entry.dart';
import 'mood_entry.dart';

/// Resumen del diario para la pantalla principal. Lógica pura y probada.
class DiaryInsights {
  final List<DiaryEntry> entries;
  final DateTime now;

  DiaryInsights(this.entries, {DateTime? now}) : now = now ?? DateTime.now();

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Días distintos (locales) con al menos una entrada.
  Set<DateTime> get _days => {for (final e in entries) _day(e.createdAt)};

  bool get wroteToday => _days.contains(_day(now));

  /// Días seguidos escribiendo. Si hoy aún no escribe, cuenta desde ayer:
  /// la racha sigue viva hasta que termine el día.
  int get streak {
    final days = _days;
    var cursor = _day(now);
    if (!days.contains(cursor)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  int get entriesThisMonth => entries
      .where((e) => e.createdAt.year == now.year && e.createdAt.month == now.month)
      .length;

  /// Ánimo más frecuente en los últimos 30 días (null sin entradas).
  MoodType? get topMood {
    final since = _day(now).subtract(const Duration(days: 30));
    final counts = <MoodType, int>{};
    for (final e in entries) {
      if (e.createdAt.isBefore(since)) continue;
      counts[e.mood] = (counts[e.mood] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  /// Entradas agrupadas por día, del más reciente al más antiguo.
  List<(DateTime day, List<DiaryEntry> entries)> get groupedByDay {
    final map = <DateTime, List<DiaryEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(_day(e.createdAt), () => []).add(e);
    }
    final days = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final d in days)
        (d, map[d]!..sort((a, b) => b.createdAt.compareTo(a.createdAt))),
    ];
  }
}

/// Historial de un hábito: racha y últimos 7 días.
class HabitHistory {
  /// Días completados (fechas locales sin hora).
  final Set<DateTime> doneDays;
  final DateTime now;

  HabitHistory(Iterable<DateTime> doneDays, {DateTime? now})
      : doneDays = {for (final d in doneDays) DateTime(d.year, d.month, d.day)},
        now = now ?? DateTime.now();

  DateTime get _today => DateTime(now.year, now.month, now.day);

  bool get doneToday => doneDays.contains(_today);

  /// Días seguidos cumplidos; si hoy aún no, cuenta hasta ayer.
  int get streak {
    var cursor = _today;
    if (!doneDays.contains(cursor)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var count = 0;
    while (doneDays.contains(cursor)) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  /// Los últimos 7 días, de hace 6 días a hoy: (fecha, cumplido).
  List<(DateTime day, bool done)> get lastWeek => [
        for (int i = 6; i >= 0; i--)
          () {
            final d = DateTime(_today.year, _today.month, _today.day - i);
            return (d, doneDays.contains(d));
          }(),
      ];

  /// Parsea el id de documento `habitId_YYYY-MM-DD` de `habit_checkins`.
  static (String habitId, DateTime day)? parseDocId(String docId) {
    final sep = docId.lastIndexOf('_');
    if (sep <= 0) return null;
    final parts = docId.substring(sep + 1).split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return (docId.substring(0, sep), DateTime(y, m, d));
  }
}
