import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgress {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastCheckIn;
  final int totalXp;
  final int level;

  UserProgress({
    this.currentStreak = 0,
    this.longestStreak = 0,
    DateTime? lastCheckIn,
    this.totalXp = 0,
    this.level = 1,
  }) : lastCheckIn = lastCheckIn ?? DateTime(2000);

  Map<String, dynamic> toMap() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastCheckIn': Timestamp.fromDate(lastCheckIn),
        'totalXp': totalXp,
        'level': level,
      };

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastCheckIn: _parseDateTime(map['lastCheckIn']),
      totalXp: map['totalXp'] ?? 0,
      level: map['level'] ?? 1,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime(2000);
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime(2000);
    }
    return DateTime(2000);
  }

  /// Calcula la nueva racha usando server timestamp (anti-trampa).
  /// [serverNow] viene de Firebase, NO del reloj del dispositivo.
  UserProgress calculateStreak(DateTime serverNow) {
    final lastDate = DateTime(
      lastCheckIn.year,
      lastCheckIn.month,
      lastCheckIn.day,
    );
    final todayDate = DateTime(
      serverNow.year,
      serverNow.month,
      serverNow.day,
    );

    final diffDays = todayDate.difference(lastDate).inDays;

    if (diffDays == 0) return this;

    int newStreak;
    if (diffDays == 1) {
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
    }

    final newLongest = newStreak > longestStreak ? newStreak : longestStreak;

    return UserProgress(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastCheckIn: serverNow,
      totalXp: totalXp,
      level: level,
    );
  }

  /// Verifica si ya hizo check-in hoy (usando server time)
  bool hasCheckedInToday(DateTime serverNow) {
    return lastCheckIn.year == serverNow.year &&
        lastCheckIn.month == serverNow.month &&
        lastCheckIn.day == serverNow.day;
  }

  String get levelTitle {
    if (level <= 3) return 'Novato Emocional';
    if (level <= 7) return 'Aprendiz Consciente';
    if (level <= 12) return 'Explorador Interior';
    if (level <= 18) return 'Guerrero Resiliente';
    return 'Maestro Zen';
  }

  String get levelTitleKey {
    if (level <= 3) return 'userProgress.levelTitles.emotionalNovice';
    if (level <= 7) return 'userProgress.levelTitles.consciousApprentice';
    if (level <= 12) return 'userProgress.levelTitles.innerExplorer';
    if (level <= 18) return 'userProgress.levelTitles.resilientWarrior';
    return 'userProgress.levelTitles.zenMaster';
  }

  int get xpForNextLevel => level * 100;
  double get levelProgress => totalXp / xpForNextLevel;
}