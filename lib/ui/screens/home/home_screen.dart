import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _streakGlow;

  @override
  void initState() {
    super.initState();
    _streakGlow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _streakGlow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final greeting = _getGreeting();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting,',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authProvider.userName.isNotEmpty
                              ? authProvider.userName
                              : 'Usuario',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification bell
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color:
                          isDark ? Colors.white70 : AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Profile avatar
                  GestureDetector(
                    onTap: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.login);
                      }
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Text(
                          authProvider.userName.isNotEmpty
                              ? authProvider.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 24),

              // Streak card con glow
              AnimatedBuilder(
                animation: _streakGlow,
                builder: (context, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6C63FF),
                          Color(0xFF5A4FCF),
                          Color(0xFF4A3AB5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(
                              alpha: 0.2 + _streakGlow.value * 0.15),
                          blurRadius: 20 + _streakGlow.value * 10,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Fire icon with glow
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.streak
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: AppColors.streak,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '0 días',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Racha actual',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Best streak
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: const Column(
                                children: [
                                  Text(
                                    '0',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Mejor',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Week progress
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: List.generate(7, (index) {
                              final days = [
                                'L', 'M', 'M', 'J', 'V', 'S', 'D'
                              ];
                              final today =
                                  DateTime.now().weekday - 1;
                              final isToday = index == today;

                              return Column(
                                children: [
                                  Text(
                                    days[index],
                                    style: TextStyle(
                                      color: isToday
                                          ? Colors.white
                                          : Colors.white54,
                                      fontSize: 12,
                                      fontWeight: isToday
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isToday
                                          ? AppColors.streak
                                          : Colors.white.withValues(
                                              alpha: 0.1),
                                      border: isToday
                                          ? Border.all(
                                              color: AppColors.streak
                                                  .withValues(
                                                      alpha: 0.5),
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Icon(
                                      isToday
                                          ? Icons.today_rounded
                                          : Icons.circle_outlined,
                                      color: isToday
                                          ? Colors.white
                                          : Colors.white24,
                                      size: isToday ? 16 : 8,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 700.ms)
                  .slideY(begin: 0.15, end: 0),
              const SizedBox(height: 24),

              // Mood question
              Text(
                '¿Cómo te sientes hoy?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 14),

              // Mood selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMoodOption('😊', 'Feliz', AppColors.moodHappy),
                    _buildMoodOption('😌', 'Calma', AppColors.moodCalm),
                    _buildMoodOption('😐', 'Normal', AppColors.moodNeutral),
                    _buildMoodOption('😢', 'Triste', AppColors.moodSad),
                    _buildMoodOption(
                        '😰', 'Ansioso', AppColors.moodAnxious),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 600.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 28),

              // Section title
              Text(
                'Tu entrenamiento de hoy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 14),

              // Action cards
              _buildActionCard(
                icon: Icons.emoji_emotions_rounded,
                title: 'Check-in de ánimo',
                subtitle: 'Registra cómo te sientes',
                color: AppColors.secondary,
                iconBg: const Color(0xFFD1FAE5),
                isDark: isDark,
              )
                  .animate()
                  .fadeIn(delay: 700.ms)
                  .slideX(begin: -0.05, end: 0),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.menu_book_rounded,
                title: 'Lección del día',
                subtitle: 'Manejo de emociones difíciles',
                color: AppColors.primary,
                iconBg: const Color(0xFFE8E5FF),
                isDark: isDark,
              )
                  .animate()
                  .fadeIn(delay: 800.ms)
                  .slideX(begin: -0.05, end: 0),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.air_rounded,
                title: 'Respiración guiada',
                subtitle: '3 minutos de calma',
                color: AppColors.moodCalm,
                iconBg: const Color(0xFFDBEAFE),
                isDark: isDark,
              )
                  .animate()
                  .fadeIn(delay: 900.ms)
                  .slideX(begin: -0.05, end: 0),
              const SizedBox(height: 12),
              _buildActionCard(
                icon: Icons.format_quote_rounded,
                title: 'Frase del día',
                subtitle: 'Tu dosis de inspiración',
                color: AppColors.streak,
                iconBg: const Color(0xFFFEF3C7),
                isDark: isDark,
              )
                  .animate()
                  .fadeIn(delay: 1000.ms)
                  .slideX(begin: -0.05, end: 0),
              const SizedBox(height: 28),

              // Level progress
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.06),
                            Colors.white.withValues(alpha: 0.03),
                          ]
                        : [
                            const Color(0xFFF5F3FF),
                            const Color(0xFFEDE9FE),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFDDD6FE),
                  ),
                ),
                child: Row(
                  children: [
                    // Level badge
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Nv',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Novato Emocional',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: 0.0,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : const Color(0xFFDDD6FE),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '0 / 100 XP para el siguiente nivel',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1100.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodOption(String emoji, String label, Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: Fase 3 - Check-in de ánimo
      },
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconBg,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark
                    ? color.withValues(alpha: 0.15)
                    : iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
}