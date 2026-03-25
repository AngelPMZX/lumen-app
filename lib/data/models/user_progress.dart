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
        'lastCheckIn': lastCheckIn.toIso8601String(),
        'totalXp': totalXp,
        'level': level,
      };

  factory UserProgress.fromMap(Map<String, dynamic> map) {
    return UserProgress(
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastCheckIn: DateTime.parse(
          map['lastCheckIn'] ?? DateTime(2000).toIso8601String()),
      totalXp: map['totalXp'] ?? 0,
      level: map['level'] ?? 1,
    );
  }

  String get levelTitle {
    if (level <= 3) return 'Novato Emocional';
    if (level <= 7) return 'Aprendiz Consciente';
    if (level <= 12) return 'Explorador Interior';
    if (level <= 18) return 'Guerrero Resiliente';
    return 'Maestro Zen';
  }

  int get xpForNextLevel => level * 100;
  double get levelProgress => totalXp / xpForNextLevel;
}