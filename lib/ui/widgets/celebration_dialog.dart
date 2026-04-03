import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/achievement.dart';
import '../../../data/models/user_progress.dart';
import '../../../domain/services/achievement_service.dart';

/// Dialog de celebración estilo Duolingo con confetti
/// Usado para achievements, level ups y streak milestones
class CelebrationDialog extends StatefulWidget {
  final CelebrationEvent event;

  const CelebrationDialog({super.key, required this.event});

  /// Muestra una secuencia de eventos de celebración
  static Future<void> showCelebrations(
    BuildContext context,
    List<CelebrationEvent> events,
  ) async {
    for (final event in events) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        builder: (ctx) => CelebrationDialog(event: event),
      );
      // Pequeña pausa entre dialogs si hay varios
      if (events.length > 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  @override
  State<CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<CelebrationDialog>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late List<_ConfettiParticle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    _particles = List.generate(40, (_) => _ConfettiParticle(_random));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Confetti layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                  ),
                );
              },
            ),
          ),

          // Dialog content
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _getEventColor().withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji/Icon grande
                _buildEventIcon()
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 20),

                // Título
                Text(
                  _getTitle(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),

                // Subtítulo
                Text(
                  _getSubtitle(),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 500.ms),
                const SizedBox(height: 20),

                // Badge/extra info
                _buildBadge(isDark)
                    .animate()
                    .fadeIn(delay: 700.ms, duration: 500.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 24),

                // Botón
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _getEventColor(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'celebration.awesome'.tr(),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 400.ms)
                    .slideY(begin: 0.2, end: 0),
              ],
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 300.ms),
        ],
      ),
    );
  }

  Widget _buildEventIcon() {
    switch (widget.event.type) {
      case CelebrationEventType.achievement:
        final achievement = _getAchievement();
        return Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                (achievement?.color ?? _getEventColor()).withValues(alpha: 0.2),
                (achievement?.color ?? _getEventColor()).withValues(alpha: 0.05),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (achievement?.color ?? _getEventColor()).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Text(
              achievement?.emoji ?? '🏆',
              style: const TextStyle(fontSize: 44),
            ),
          ),
        );

      case CelebrationEventType.levelUp:
        return Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⬆️', style: TextStyle(fontSize: 28)),
              Text(
                '${widget.event.newLevel}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        );

      case CelebrationEventType.streakMilestone:
        return Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Center(
            child: Text('🔥', style: TextStyle(fontSize: 44)),
          ),
        );
    }
  }

  String _getTitle() {
    switch (widget.event.type) {
      case CelebrationEventType.achievement:
        return 'celebration.achievementUnlocked'.tr();
      case CelebrationEventType.levelUp:
        return 'celebration.levelUp'.tr();
      case CelebrationEventType.streakMilestone:
        return 'celebration.streakMilestone'.tr();
    }
  }

  String _getSubtitle() {
    switch (widget.event.type) {
      case CelebrationEventType.achievement:
        final achievement = _getAchievement();
        final titleKey = 'achievementData.${widget.event.achievementId}.title';
        final descKey = 'achievementData.${widget.event.achievementId}.description';
        final title = titleKey.tr();
        final desc = descKey.tr();
        final displayTitle = title != titleKey ? title : (achievement?.title ?? '');
        final displayDesc = desc != descKey ? desc : (achievement?.description ?? '');
        return '$displayTitle\n$displayDesc';

      case CelebrationEventType.levelUp:
        final progress = UserProgress(level: widget.event.newLevel ?? 1);
        final titleKey = progress.levelTitleKey;
        final levelTitle = titleKey.tr();
        final displayTitle = levelTitle != titleKey ? levelTitle : progress.levelTitle;
        return 'celebration.levelUpDesc'.tr(namedArgs: {'title': displayTitle});

      case CelebrationEventType.streakMilestone:
        return 'celebration.streakDays'.tr(
          namedArgs: {'count': '${widget.event.streakDays}'},
        );
    }
  }

  Widget _buildBadge(bool isDark) {
    switch (widget.event.type) {
      case CelebrationEventType.achievement:
        final achievement = _getAchievement();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: (achievement?.color ?? _getEventColor()).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (achievement?.color ?? _getEventColor()).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(achievement?.emoji ?? '🏆', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                _getAchievementTitle(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: achievement?.color ?? _getEventColor(),
                ),
              ),
            ],
          ),
        );

      case CelebrationEventType.levelUp:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6366F1).withValues(alpha: 0.12),
                const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'celebration.newLevel'.tr(namedArgs: {'level': '${widget.event.newLevel}'}),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6366F1),
            ),
          ),
        );

      case CelebrationEventType.streakMilestone:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            'celebration.streakKeepGoing'.tr(),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : const Color(0xFF92400E),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        );
    }
  }

  Achievement? _getAchievement() {
    if (widget.event.achievementId == null) return null;
    try {
      return Achievement.all.firstWhere((a) => a.id == widget.event.achievementId);
    } catch (_) {
      return null;
    }
  }

  String _getAchievementTitle() {
    final achievement = _getAchievement();
    if (achievement == null) return '';
    final key = 'achievementData.${achievement.id}.title';
    final translated = key.tr();
    return translated != key ? translated : achievement.title;
  }

  Color _getEventColor() {
    switch (widget.event.type) {
      case CelebrationEventType.achievement:
        return _getAchievement()?.color ?? const Color(0xFFF59E0B);
      case CelebrationEventType.levelUp:
        return const Color(0xFF6366F1);
      case CelebrationEventType.streakMilestone:
        return const Color(0xFFF59E0B);
    }
  }
}

// ═══════════════════════════════════════════
// Confetti particles
// ═══════════════════════════════════════════

class _ConfettiParticle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double rotation;
  final double wobble;
  final double wobbleSpeed;

  _ConfettiParticle(Random r)
      : x = r.nextDouble(),
        startY = -0.1 - r.nextDouble() * 0.3,
        speed = 0.3 + r.nextDouble() * 0.7,
        size = 4 + r.nextDouble() * 8,
        color = _confettiColors[r.nextInt(_confettiColors.length)],
        rotation = r.nextDouble() * pi * 2,
        wobble = r.nextDouble() * 0.05,
        wobbleSpeed = 2 + r.nextDouble() * 4;

  static const _confettiColors = [
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFF6366F1),
  ];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = p.startY + progress * p.speed * 1.5;
      if (y > 1.1) continue;

      final x = p.x + sin(progress * p.wobbleSpeed * pi * 2) * p.wobble;
      final opacity = progress < 0.1
          ? progress / 0.1
          : progress > 0.7
              ? (1.0 - progress) / 0.3
              : 1.0;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0) * 0.8)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(p.rotation + progress * 5);

      // Dibujar rectángulo/confetti
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}