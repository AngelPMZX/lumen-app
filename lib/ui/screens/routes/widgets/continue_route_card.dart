import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/routes_overview.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../widgets/entrance.dart';
import '../route_theme.dart';

/// Tarjeta destacada del menú: "Continúa donde te quedaste" (o "Empieza tu
/// camino" si aún no hay progreso). Un toque abre directamente la siguiente
/// lección, sin pasar por el mapa.
class ContinueRouteCard extends StatelessWidget {
  final RouteProgress progress;
  final VoidCallback onContinue;

  const ContinueRouteCard({
    super.key,
    required this.progress,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final route = progress.route;
    final started = progress.status == RouteStatus.inProgress;
    final next = progress.nextLesson;
    final deco = RouteTheme.decorations(route.id);
    final reduced = MotionService.reduced(context);

    return Semantics(
      button: true,
      label: [
        started ? 'routes.continueTitle'.tr() : 'routes.startTitle'.tr(),
        route.title,
        if (next != null)
          'routes.lessonOf'.tr(namedArgs: {
            'n': '${progress.nextIndex + 1}',
            'total': '${progress.total}',
            'title': next.title,
          }),
      ].join('. '),
      onTap: onContinue,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onContinue();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(route.color, Colors.white, 0.08)!,
                route.colorDark,
                Color.lerp(route.colorDark, const Color(0xFF1E1B4B), 0.35)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: route.color.withValues(alpha: 0.3),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Círculos de luz
                Positioned(
                  top: -60,
                  right: -40,
                  child: _circle(180, 0.10),
                ),
                Positioned(
                  bottom: -70,
                  left: -30,
                  child: _circle(160, 0.07),
                ),
                // Emoji grande de la ruta con decoración flotando
                Positioned(
                  right: 14,
                  top: 14,
                  child: Text(route.emoji, style: const TextStyle(fontSize: 64))
                      .animate(onPlay: MotionService.loop(context, reverse: true))
                      .moveY(begin: -4, end: 4, duration: 2200.ms, curve: Curves.easeInOut)
                      .rotate(begin: -0.02, end: 0.02, duration: 2200.ms),
                ),
                for (final (i, pos) in const [
                  (0, Offset(0.62, 0.12)),
                  (2, Offset(0.9, 0.62)),
                  (4, Offset(0.72, 0.5)),
                ].indexed)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment(pos.$2.dx * 2 - 1, pos.$2.dy * 2 - 1),
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.35,
                          child: Text(
                            deco[pos.$1 % deco.length],
                            style: const TextStyle(fontSize: 18),
                          ),
                        )
                            .animate(
                              delay: (i * 500).ms,
                              onPlay: MotionService.loop(context, reverse: true),
                            )
                            .fade(begin: 0.35, end: 1, duration: 1600.ms)
                            .moveY(begin: 3, end: -3, duration: 1600.ms),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              started ? Icons.play_arrow_rounded : Icons.auto_awesome_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (started ? 'routes.continueTitle' : 'routes.startTitle').tr().toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.9,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        // Deja aire al emoji grande de la derecha
                        padding: const EdgeInsets.only(right: 74),
                        child: Text(
                          route.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (next != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(right: 74),
                          child: Text(
                            'routes.lessonOf'.tr(namedArgs: {
                              'n': '${progress.nextIndex + 1}',
                              'total': '${progress.total}',
                              'title': next.title,
                            }),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                    begin: entranceFrom(
                                        context, progress.fraction),
                                    end: progress.fraction),
                                duration: entranceDuration(
                                    context, const Duration(milliseconds: 1100)),
                                curve: Curves.easeOutCubic,
                                builder: (context, v, _) => LinearProgressIndicator(
                                  value: v,
                                  minHeight: 8,
                                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${progress.completed}/${progress.total}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ShinyButton(
                        label: started ? 'routes.continueRoute'.tr() : 'routes.startRoute'.tr(),
                        color: route.colorDark,
                        reduced: reduced,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}

/// Botón blanco con un destello que lo cruza cada pocos segundos.
class _ShinyButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool reduced;

  const _ShinyButton({
    required this.label,
    required this.color,
    required this.reduced,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      height: 48,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 20, color: color),
        ],
      ),
    );
    if (reduced) return button;
    return button
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          delay: 2400.ms,
          duration: 1100.ms,
          color: color.withValues(alpha: 0.25),
        );
  }
}
