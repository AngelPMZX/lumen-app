/// Cuántos hábitos dan XP en un mismo día.
///
/// Marcar un hábito daba +5 XP la primera vez que se marcaba **ese** hábito
/// ese día, y el registro vive en `habit_checkins/{habitId}_{fecha}`. Como un
/// hábito nuevo estrena id, se podía farmear XP sin límite: crear un hábito,
/// marcarlo, borrarlo y repetir. Lo encontró un tester.
///
/// El tope es por **día**, no por hábito, así que crear hábitos nuevos ya no
/// abre más XP. Quien de verdad lleva cinco hábitos sigue ganando lo mismo que
/// antes hasta el tercero; marcar los demás sigue contando para su racha, su
/// historial y las misiones de la semana.
class HabitXpQuota {
  /// Cuántos hábitos del día dan XP.
  static const maxPerDay = 3;

  /// XP por hábito marcado, mientras quede cupo.
  static const xpPerHabit = 5;

  /// Día al que pertenece el contador (`yyyy-M-d`, hora local).
  final String day;

  /// Cuántos hábitos han dado XP ese día.
  final int rewarded;

  const HabitXpQuota({required this.day, required this.rewarded});

  /// Lee el documento `progress/habits`. Si es de otro día, el cupo arranca
  /// de cero: lo que cuenta es el día de hoy.
  factory HabitXpQuota.fromMap(Map<String, dynamic>? map, {required String today}) {
    final day = map?['rewardDate'] as String?;
    if (day != today) return HabitXpQuota(day: today, rewarded: 0);
    final rewarded = (map?['rewarded'] as num?)?.toInt() ?? 0;
    return HabitXpQuota(day: today, rewarded: rewarded.clamp(0, maxPerDay));
  }

  /// Queda cupo hoy.
  bool get hasRoom => rewarded < maxPerDay;

  /// Cuántos hábitos más darán XP hoy.
  int get left => (maxPerDay - rewarded).clamp(0, maxPerDay);

  /// El cupo después de cobrar uno. Sin cupo, se queda igual.
  HabitXpQuota get next =>
      hasRoom ? HabitXpQuota(day: day, rewarded: rewarded + 1) : this;

  Map<String, dynamic> toMap() => {'rewardDate': day, 'rewarded': rewarded};

  /// La clave de día que se guarda, en hora local (igual que el resto de la
  /// app: `progress/breathing` y `progress/review` usan este mismo formato).
  static String dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';
}
