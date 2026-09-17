import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/lumi.dart';
import '../../../widgets/lumi/lumi_companion_card.dart';
import '../../reminders/reminder_sky.dart';
import '../../routes/widgets/route_progress_ring.dart';

/// Escena principal del Home: el cielo del momento del día, Lumi hablando y
/// el progreso de hoy (ánimo, lección y diario).
class HomeHero extends StatelessWidget {
  final LumiLine? line;
  final bool isDark;
  final VoidCallback? onIntroSeen;
  final bool checkInDone;
  final bool lessonDone;
  final bool diaryDone;

  /// Hora para elegir el cielo (se puede fijar en pruebas).
  final int hour;

  const HomeHero({
    super.key,
    required this.line,
    required this.isDark,
    required this.checkInDone,
    required this.lessonDone,
    required this.diaryDone,
    required this.hour,
    this.onIntroSeen,
  });

  @override
  Widget build(BuildContext context) {
    final sky = ReminderSky.of(hour, isDark: isDark);
    final done = [checkInDone, lessonDone, diaryDone].where((d) => d).length;
    final tasks = [
      ('😊', 'home.taskMoodShort'.tr(), checkInDone),
      ('📚', 'home.taskLessonShort'.tr(), lessonDone),
      ('📝', 'home.taskDiaryShort'.tr(), diaryDone),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: sky.colors.last.withValues(alpha: isDark ? 0.35 : 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: ReminderSkyTile(sky: sky, width: double.infinity, height: double.infinity),
            ),
            // Velo: suaviza el cielo para que el globo y el progreso se lean
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.35)]
                        : [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.25)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 12, 14),
              child: Column(
                children: [
                  if (line != null)
                    LumiCompanionCard(
                      line: line!,
                      isDark: isDark,
                      onIntroSeen: onIntroSeen,
                      transparent: true,
                    )
                  else
                    const SizedBox(height: 112),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Semantics(
                      label: '${'home.dailyProgress'.tr()}: $done/3',
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.6)),
                        ),
                        child: Row(
                          children: [
                            RouteProgressRing(
                              progress: done / 3,
                              color: done == 3 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                              track: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
                              size: 46,
                              stroke: 5,
                              child: Text(
                                done == 3 ? '🎉' : '$done/3',
                                style: TextStyle(
                                  fontSize: done == 3 ? 18 : 13,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF2D2D3A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            for (final (emoji, label, isDone) in tasks)
                              Expanded(
                                child: ExcludeSemantics(
                                  child: _TaskPill(emoji: emoji, label: label, done: isDone, isDark: isDark),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 80.ms, duration: 450.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}

class _TaskPill extends StatelessWidget {
  final String emoji;
  final String label;
  final bool done;
  final bool isDark;

  const _TaskPill({required this.emoji, required this.label, required this.done, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF10B981);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? green : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: done
                    ? const Icon(Icons.check_rounded, key: ValueKey('d'), size: 18, color: Colors.white)
                    : Text(emoji, key: const ValueKey('e'), style: const TextStyle(fontSize: 15)),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: done ? FontWeight.w800 : FontWeight.w600,
              color: isDark ? Colors.white.withValues(alpha: done ? 1 : 0.7) : const Color(0xFF2D2D3A).withValues(alpha: done ? 1 : 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
