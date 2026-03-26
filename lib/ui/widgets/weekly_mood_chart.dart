import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/mood_entry.dart';

/// Mini gráfica de ánimo semanal.
/// Muestra 7 puntos (L-D) con colores del mood registrado ese día.
/// Los días sin registro se muestran como puntos grises vacíos.
class WeeklyMoodChart extends StatelessWidget {
  final Map<int, MoodType> weeklyMoods; // weekday (1-7) → mood

  const WeeklyMoodChart({super.key, required this.weeklyMoods});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];
    final today = DateTime.now().weekday; // 1 = Monday

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded,
                  size: 18,
                  color: isDark ? Colors.white70 : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Tu semana emocional',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Puntos con línea conectora
          SizedBox(
            height: 70,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final spacing = constraints.maxWidth / 7;
                return Stack(
                  children: [
                    // Línea conectora
                    Positioned(
                      top: 20,
                      left: spacing / 2,
                      right: spacing / 2,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    // Puntos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(7, (index) {
                        final dayNum = index + 1;
                        final mood = weeklyMoods[dayNum];
                        final isToday = dayNum == today;
                        final isFuture = dayNum > today;

                        return Column(
                          children: [
                            // Punto del mood
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: isToday ? 36 : 28,
                              height: isToday ? 36 : 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: mood != null
                                    ? mood.color.withValues(
                                        alpha: isToday ? 1.0 : 0.7)
                                    : isDark
                                        ? Colors.white
                                            .withValues(alpha: 0.08)
                                        : Colors.grey.shade200,
                                border: isToday
                                    ? Border.all(
                                        color: mood?.color ??
                                            AppColors.primary,
                                        width: 2.5)
                                    : null,
                                boxShadow: mood != null && isToday
                                    ? [
                                        BoxShadow(
                                          color: mood.color
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: mood != null
                                    ? Text(
                                        mood.emoji,
                                        style: TextStyle(
                                          fontSize: isToday ? 16 : 12,
                                        ),
                                      )
                                    : isFuture
                                        ? null
                                        : Icon(
                                            Icons.remove_rounded,
                                            size: 12,
                                            color: isDark
                                                ? Colors.white24
                                                : Colors.grey.shade400,
                                          ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Label del día
                            Text(
                              days[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isToday
                                    ? (isDark
                                        ? Colors.white
                                        : AppColors.textPrimary)
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}