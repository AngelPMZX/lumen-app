import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/achievement.dart';
import '../../widgets/animated_particles_background.dart';

class AchievementsScreen extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final int totalXp;
  final int level;
  final int diaryEntries;
  final int habitsCompleted;
  final int moodCheckIns;

  const AchievementsScreen({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalXp,
    required this.level,
    required this.diaryEntries,
    required this.habitsCompleted,
    required this.moodCheckIns,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final achievements = Achievement.all;
    final unlocked = achievements.where((a) => a.isUnlocked(
      currentStreak: currentStreak, longestStreak: longestStreak,
      totalXp: totalXp, level: level, diaryEntries: diaryEntries,
      habitsCompleted: habitsCompleted, moodCheckIns: moodCheckIns,
    )).toList();
    final locked = achievements.where((a) => !a.isUnlocked(
      currentStreak: currentStreak, longestStreak: longestStreak,
      totalXp: totalXp, level: level, diaryEntries: diaryEntries,
      habitsCompleted: habitsCompleted, moodCheckIns: moodCheckIns,
    )).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medallas', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          AnimatedParticlesBackground(
            particleCount: 12,
            maxShootingStars: isDark ? 2 : 0,
            particleColor: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : const Color(0xFFF59E0B).withValues(alpha: 0.1),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: isDark
                        ? [const Color(0xFFF59E0B).withValues(alpha: 0.15),
                           const Color(0xFFF59E0B).withValues(alpha: 0.05)]
                        : [const Color(0xFFFEF3C7), const Color(0xFFFDE68A).withValues(alpha: 0.3)]),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18)),
                        child: const Center(child: Text('🏆', style: TextStyle(fontSize: 28))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${unlocked.length} de ${achievements.length}',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF92400E))),
                            Text('medallas desbloqueadas',
                                style: TextStyle(fontSize: 14,
                                    color: isDark ? Colors.white60 : const Color(0xFFB45309))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 24),

                // Desbloqueadas
                if (unlocked.isNotEmpty) ...[
                  Text('Desbloqueadas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ...List.generate(unlocked.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildAchievementCard(unlocked[i], true, isDark, i),
                    );
                  }),
                  const SizedBox(height: 20),
                ],

                // Bloqueadas
                if (locked.isNotEmpty) ...[
                  Text('Por desbloquear', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ...List.generate(locked.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildAchievementCard(locked[i], false, isDark, i + unlocked.length),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement a, bool unlocked, bool isDark, int index) {
    final prog = a.progress(
      currentStreak: currentStreak, longestStreak: longestStreak,
      totalXp: totalXp, level: level, diaryEntries: diaryEntries,
      habitsCompleted: habitsCompleted, moodCheckIns: moodCheckIns,
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: unlocked ? 1.0 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: unlocked
              ? LinearGradient(colors: [
                  a.color.withValues(alpha: isDark ? 0.15 : 0.08),
                  a.color.withValues(alpha: isDark ? 0.06 : 0.03)])
              : null,
          color: unlocked ? null
              : isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: unlocked
                ? a.color.withValues(alpha: 0.25)
                : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: unlocked
                    ? a.color.withValues(alpha: 0.2)
                    : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(unlocked ? a.emoji : '🔒',
                    style: TextStyle(fontSize: unlocked ? 24 : 20)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: unlocked ? a.color
                              : isDark ? Colors.white54 : AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(a.description,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  if (!unlocked) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: prog,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(a.color.withValues(alpha: 0.5)),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${(prog * 100).toInt()}%',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            if (unlocked)
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, color: a.color, size: 18),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (60 * index).ms, duration: 400.ms)
        .slideX(begin: -0.03, end: 0);
  }
}