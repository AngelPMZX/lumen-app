import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/lumi.dart';
import '../../../../data/models/wellness_route.dart';
import '../../../widgets/lumi/lumi_avatar.dart';
import '../lesson_palette.dart';

/// Pantalla final de una lección: Lumi orgullosa, XP ganada (con el
/// multiplicador si lo hubo), el reto elegido y los botones para seguir.
class LessonCompleteView extends StatelessWidget {
  final Lesson lesson;
  final Color routeColor;
  final Lesson? nextLesson;

  /// XP sumada durante la lección (se muestra si no hubo multiplicador).
  final int xpEarned;

  /// XP de la lección ya multiplicada, y el multiplicador aplicado.
  final int finalXpAwarded;
  final double multiplier;

  final String? commitment;
  final VoidCallback onNext;
  final VoidCallback onBackToMap;

  const LessonCompleteView({
    super.key,
    required this.lesson,
    required this.routeColor,
    required this.nextLesson,
    required this.xpEarned,
    required this.finalXpAwarded,
    required this.multiplier,
    required this.commitment,
    required this.onNext,
    required this.onBackToMap,
  });

  static const _gold = Color(0xFFFBBF24);
  static const _violet = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final p = LessonPalette.of(context);
    final wasMultiplied = multiplier > 1.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 160,
              child: Center(child: LumiAvatar(mood: LumiMood.proud, size: 160)),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            Text(
              'routes.lessonComplete'.tr(),
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: p.ink),
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 8),
            Text(
              lesson.title,
              style: TextStyle(fontSize: 15, color: p.inkA(0.55)),
              textAlign: TextAlign.center,
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 28),
            _buildXpCard(p, wasMultiplied),
            if (commitment != null) ...[
              const SizedBox(height: 18),
              _buildCommitment(p),
            ],
            const SizedBox(height: 36),
            ..._buildButtons(p),
          ],
        ),
      ),
    );
  }

  Widget _buildXpCard(LessonPalette p, bool wasMultiplied) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: p.isDark
              ? [routeColor.withValues(alpha: 0.22), _gold.withValues(alpha: 0.12)]
              : [
                  Color.lerp(Colors.white, routeColor, 0.14)!,
                  Color.lerp(Colors.white, _gold, 0.14)!,
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: routeColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: routeColor.withValues(alpha: p.isDark ? 0.25 : 0.18),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          // Con multiplicador: XP base tachada + XP real
          if (wasMultiplied) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${lesson.xpReward}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: p.inkA(0.45),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: p.inkA(0.54),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '+$finalXpAwarded XP',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: p.accent(routeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _violet.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _violet.withValues(alpha: 0.4)),
              ),
              child: Text(
                'routes.multiplierApplied'.tr(
                  namedArgs: {'mult': multiplier.toStringAsFixed(1)},
                ),
                style: TextStyle(
                  color: p.accent(_violet),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else
            Text(
              '+$xpEarned XP',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: p.accent(routeColor),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'routes.xpEarned'.tr(),
            style: TextStyle(fontSize: 13, color: p.inkA(0.5)),
          ),
        ],
      ),
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 500.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildCommitment(LessonPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.isDark
            ? _gold.withValues(alpha: 0.1)
            : Color.lerp(Colors.white, _gold, 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Text('🤝', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'routes.yourCommitment'.tr(),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: p.accent(_gold),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  commitment!,
                  style: TextStyle(fontSize: 14.5, height: 1.45, color: p.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 500.ms).fadeIn(duration: 400.ms);
  }

  List<Widget> _buildButtons(LessonPalette p) {
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: routeColor,
      elevation: 8,
      shadowColor: routeColor.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );

    if (nextLesson == null) {
      return [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton(
            onPressed: onBackToMap,
            style: buttonStyle,
            child: Text(
              'routes.backToMap'.tr(),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
      ];
    }

    return [
      // Seguir sin pasar por el mapa: menos fricción, sesiones más largas
      SizedBox(
        width: double.infinity,
        height: 58,
        child: FilledButton(
          onPressed: onNext,
          style: buttonStyle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'routes.nextLesson'.tr(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ).animate(delay: 600.ms).fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),
      const SizedBox(height: 6),
      Text(
        nextLesson!.title,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: p.inkA(0.55)),
      ).animate(delay: 650.ms).fadeIn(duration: 400.ms),
      const SizedBox(height: 10),
      TextButton(
        onPressed: onBackToMap,
        child: Text(
          'routes.backToMap'.tr(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: p.inkA(0.7),
          ),
        ),
      ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
    ];
  }
}
