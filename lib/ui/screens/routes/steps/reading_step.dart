import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/wellness_route.dart';
import '../lesson_palette.dart';
import 'step_common.dart';

/// READING — una lectura breve. Se puede continuar de inmediato.
class ReadingStep extends StatelessWidget {
  final LessonStep step;
  final Color routeColor;

  const ReadingStep({
    super.key,
    required this.step,
    required this.routeColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = LessonPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepChip(
          icon: Icons.menu_book_rounded,
          label: 'routes.readingTitle'.tr(),
          color: routeColor,
        ),
        const SizedBox(height: 16),
        StepHeading(text: step.title, glow: routeColor, fontSize: 26),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: p.card(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: routeColor.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: routeColor.withValues(alpha: p.isDark ? 0.1 : 0.08),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            step.content ?? '',
            style: TextStyle(fontSize: 16, height: 1.85, color: p.inkA(0.88)),
          ),
        ),
      ],
    );
  }
}
