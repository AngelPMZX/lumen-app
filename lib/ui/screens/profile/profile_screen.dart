import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/achievement.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/theme_provider.dart';
import '../../widgets/animated_particles_background.dart';
import 'edit_profile_screen.dart';
import 'achievements_screen.dart';
import 'mood_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _diaryCount = 0;
  int _moodCount = 0;
  int _habitsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final auth = context.read<AuthProvider>();
      final diaries = await auth.getDiaryEntries(limit: 999);
      // Contamos check-ins de ánimo aproximados por las entradas de mood
      final moods = await auth.getWeeklyMoods();

      if (mounted) {
        setState(() {
          _diaryCount = diaries.length;
          _moodCount = moods.length; // Aproximación semanal
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Color> _getArchetypeGradient(String? archetype) {
    switch (archetype) {
      case 'explorador': return [const Color(0xFF6366F1), const Color(0xFF4338CA)];
      case 'guerrero':   return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case 'social':     return [const Color(0xFFEC4899), const Color(0xFFDB2777)];
      case 'sabio':      return [const Color(0xFF10B981), const Color(0xFF059669)];
      case 'libre':      return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      default:           return [AppColors.primary, AppColors.primaryDark];
    }
  }

  String _getArchetypeName(String? archetype) {
    switch (archetype) {
      case 'explorador': return 'Explorador Introspectivo';
      case 'guerrero':   return 'Guerrero Resiliente';
      case 'social':     return 'Alma Social';
      case 'sabio':      return 'Sabio Tranquilo';
      case 'libre':      return 'Espíritu Libre';
      default:           return 'Sin arquetipo';
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('¿Seguro que quieres cerrar sesión? Tu progreso está guardado en la nube.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = auth.userProgress;
    final gradient = _getArchetypeGradient(auth.userModel?.archetype);
    final streak = progress?.currentStreak ?? 0;
    final bestStreak = progress?.longestStreak ?? 0;
    final totalXp = progress?.totalXp ?? 0;
    final level = progress?.level ?? 1;
    final levelTitle = progress?.levelTitle ?? 'Novato Emocional';
    final xpForNext = progress?.xpForNextLevel ?? 100;

    // Contar logros desbloqueados
    final unlockedCount = Achievement.all.where((a) => a.isUnlocked(
      currentStreak: streak, longestStreak: bestStreak, totalXp: totalXp,
      level: level, diaryEntries: _diaryCount, habitsCompleted: _habitsCount,
      moodCheckIns: _moodCount,
    )).length;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedParticlesBackground(
            particleCount: 15,
            maxShootingStars: isDark ? 2 : 0,
            particleColor: isDark
                ? Colors.white.withValues(alpha: 0.25)
                : gradient.first.withValues(alpha: 0.1),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                children: [
                  // ══════════════════════════════
                  // AVATAR + INFO
                  // ══════════════════════════════
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          gradient.first.withValues(alpha: isDark ? 0.2 : 0.12),
                          gradient.last.withValues(alpha: isDark ? 0.08 : 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: gradient.first.withValues(alpha: isDark ? 0.25 : 0.15)),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: gradient),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: gradient.first.withValues(alpha: 0.4),
                                blurRadius: 16, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontSize: 34,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(auth.userName,
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.textPrimary)),
                        if (auth.userModel?.username != null) ...[
                          const SizedBox(height: 2),
                          Text('@${auth.userModel!.username}',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: gradient.first.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_getArchetypeName(auth.userModel?.archetype),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: gradient.first)),
                        ),
                        const SizedBox(height: 16),
                        // Nivel y XP bar
                        Row(
                          children: [
                            Text('Nv $level', style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w800, color: gradient.first)),
                            const SizedBox(width: 8),
                            Text(levelTitle, style: TextStyle(fontSize: 13,
                                color: AppColors.textSecondary)),
                            const Spacer(),
                            Text('${totalXp % xpForNext}/$xpForNext XP',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (totalXp % xpForNext) / xpForNext,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.1) : gradient.first.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(gradient.first),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 20),

                  // ══════════════════════════════
                  // STATS GRID
                  // ══════════════════════════════
                  Row(
                    children: [
                      _buildStatTile('🔥', '$streak', 'Racha\nactual', isDark),
                      const SizedBox(width: 10),
                      _buildStatTile('🏆', '$bestStreak', 'Mejor\nracha', isDark),
                      const SizedBox(width: 10),
                      _buildStatTile('⚡', '$totalXp', 'XP\ntotal', isDark),
                      const SizedBox(width: 10),
                      _buildStatTile('📝', '$_diaryCount', 'Entradas\ndiario', isDark),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                  const SizedBox(height: 20),

                  // ══════════════════════════════
                  // MEDALLAS PREVIEW
                  // ══════════════════════════════
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => AchievementsScreen(
                          currentStreak: streak, longestStreak: bestStreak,
                          totalXp: totalXp, level: level,
                          diaryEntries: _diaryCount, habitsCompleted: _habitsCount,
                          moodCheckIns: _moodCount,
                        ))),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.emoji_events_rounded,
                                    color: Color(0xFFF59E0B), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Medallas',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : AppColors.textPrimary)),
                                    Text('$unlockedCount de ${Achievement.all.length} desbloqueadas',
                                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Mini preview de medallas
                          Wrap(
                            spacing: 8,
                            children: Achievement.all.take(8).map((a) {
                              final unlocked = a.isUnlocked(
                                currentStreak: streak, longestStreak: bestStreak,
                                totalXp: totalXp, level: level,
                                diaryEntries: _diaryCount, habitsCompleted: _habitsCount,
                                moodCheckIns: _moodCount,
                              );
                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: unlocked ? 1.0 : 0.3,
                                child: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: unlocked
                                        ? a.color.withValues(alpha: 0.15)
                                        : isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: unlocked
                                        ? Border.all(color: a.color.withValues(alpha: 0.3))
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(unlocked ? a.emoji : '🔒',
                                        style: TextStyle(fontSize: unlocked ? 18 : 14)),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                  const SizedBox(height: 16),

                  // ══════════════════════════════
                  // MENU OPTIONS
                  // ══════════════════════════════
                  _buildMenuCard(
                    icon: Icons.person_rounded,
                    title: 'Editar perfil',
                    subtitle: 'Nombre, usuario, arquetipo',
                    color: gradient.first,
                    isDark: isDark,
                    onTap: () async {
                      final result = await Navigator.push<bool>(context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      if (result == true) setState(() {});
                    },
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 10),
                  _buildMenuCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Historial de ánimo',
                    subtitle: 'Tu resumen emocional',
                    color: const Color(0xFFEC4899),
                    isDark: isDark,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MoodHistoryScreen())),
                  ).animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: 10),
                  _buildMenuCard(
                    icon: Icons.dark_mode_rounded,
                    title: 'Tema',
                    subtitle: isDark ? 'Modo oscuro activado' : 'Modo claro activado',
                    color: const Color(0xFF6366F1),
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: isDark,
                      onChanged: (_) => context.read<ThemeProvider>().toggleTheme(),
                      activeColor: const Color(0xFF6366F1),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 10),
                  _buildMenuCard(
                    icon: Icons.info_outline_rounded,
                    title: 'Acerca de Lumen',
                    subtitle: 'Versión 1.0.0',
                    color: AppColors.textSecondary,
                    isDark: isDark,
                    onTap: () {},
                  ).animate().fadeIn(delay: 550.ms),
                  const SizedBox(height: 24),

                  // LOGOUT
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.08 : 0.05),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.1)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                          SizedBox(width: 10),
                          Text('Cerrar sesión',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                  color: Color(0xFFEF4444))),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String emoji, String value, String label, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.3),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon, required String title, required String subtitle,
    required Color color, required bool isDark, VoidCallback? onTap, Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}