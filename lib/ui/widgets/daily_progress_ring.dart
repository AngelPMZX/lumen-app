import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';

class DailyProgressRing extends StatelessWidget {
  final bool checkInDone;
  final bool lessonDone;
  final bool diaryDone;

  const DailyProgressRing({
    super.key,
    this.checkInDone = false,
    this.lessonDone = false,
    this.diaryDone = false,
  });

  int get completedCount =>
      (checkInDone ? 1 : 0) + (lessonDone ? 1 : 0) + (diaryDone ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: _RingPainter(
                checkIn: checkInDone,
                lesson: lessonDone,
                diary: diaryDone,
                isDark: isDark,
              ),
              child: Center(
                child: Text(
                  '$completedCount/3',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home.dailyProgress'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTask('home.taskCheckIn'.tr(), checkInDone,
                    const Color(0xFF10B981), isDark),
                const SizedBox(height: 8),
                _buildTask('home.taskLesson'.tr(), lessonDone,
                    const Color(0xFF6366F1), isDark),
                const SizedBox(height: 8),
                _buildTask('home.taskDiary'.tr(), diaryDone,
                    const Color(0xFFF59E0B), isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTask(String label, bool done, Color color, bool isDark) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? color : Colors.transparent,
            border: Border.all(
              color: done
                  ? color
                  : isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: done ? FontWeight.w600 : FontWeight.w400,
            color: done
                ? (isDark ? Colors.white : AppColors.textPrimary)
                : AppColors.textSecondary,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final bool checkIn;
  final bool lesson;
  final bool diary;
  final bool isDark;

  _RingPainter({
    required this.checkIn,
    required this.lesson,
    required this.diary,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    _drawRing(canvas, center, 36, const Color(0xFF10B981), checkIn);
    _drawRing(canvas, center, 26, const Color(0xFF6366F1), lesson);
    _drawRing(canvas, center, 16, const Color(0xFFF59E0B), diary);
  }

  void _drawRing(
      Canvas canvas, Offset center, double radius, Color color, bool filled) {
    final bgPaint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.12 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (filled) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, 2 * pi, false, progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return checkIn != oldDelegate.checkIn ||
        lesson != oldDelegate.lesson ||
        diary != oldDelegate.diary;
  }
}