import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/wellness_route.dart';
import '../../../../domain/services/sound_service.dart';
import '../lesson_palette.dart';
import 'step_common.dart';

/// SORT — clasificar cada item en su categoría. Al colocarlo se ve si acertó.
///
/// Dos formas equivalentes: arrastrar el item a la categoría, o tocar el item
/// y luego la categoría. La segunda existe para TalkBack (arrastrar no es
/// accesible con lector de pantalla) y para usar el teléfono con una mano.
class SortStep extends StatefulWidget {
  final LessonStep step;
  final Color routeColor;
  final StepCallbacks callbacks;

  const SortStep({
    super.key,
    required this.step,
    required this.routeColor,
    required this.callbacks,
  });

  @override
  State<SortStep> createState() => _SortStepState();
}

class _SortStepState extends State<SortStep> {
  static const _accent = Color(0xFF06B6D4);

  /// item → categoría donde lo colocó.
  final Map<int, int> _assignments = {};

  /// Item elegido con un toque, esperando que toque su categoría.
  int? _selected;

  List<String> get _items => widget.step.items ?? const [];
  List<String> get _categories => widget.step.categories ?? const [];

  bool _isCorrect(int item, int category) {
    final expected = widget.step.itemCategory;
    if (expected == null || item >= expected.length) return true;
    return expected[item] == category;
  }

  void _toggleSelected(int item) {
    HapticFeedback.selectionClick();
    final turningOn = _selected != item;
    SoundService.instance.play(
      turningOn ? Sfx.toggleOn : Sfx.toggleOff,
      volume: 0.45,
    );
    setState(() => _selected = turningOn ? item : null);
  }

  void _assign(int item, int category) {
    if (_assignments.containsKey(item)) return;
    final correct = _isCorrect(item, category);
    HapticFeedback.mediumImpact();
    setState(() {
      _assignments[item] = category;
      _selected = null;
    });
    widget.callbacks.onAnswer(correct, correct ? 3 : 0);
    if (_assignments.length == _items.length) widget.callbacks.onReady();
    SemanticsService.sendAnnouncement(
      View.of(context),
      correct ? 'routes.sortCorrectA11y'.tr() : 'routes.sortWrongA11y'.tr(),
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = LessonPalette.of(context);
    final pending = [
      for (int i = 0; i < _items.length; i++)
        if (!_assignments.containsKey(i)) i,
    ];
    final finished = pending.isEmpty && _items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepChip(
          icon: Icons.drag_indicator_rounded,
          label: 'routes.sortLabel'.tr(),
          color: _accent,
        ),
        const SizedBox(height: 16),
        StepHeading(
          text: widget.step.title,
          glow: widget.routeColor,
          fontSize: 23,
        ),
        const SizedBox(height: 10),
        StepBody(widget.step.instruction ?? ''),
        if (!finished) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 14, color: p.inkA(0.45)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'routes.sortTapHint'.tr(),
                  style: TextStyle(fontSize: 12.5, color: p.inkA(0.5)),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        // Items por clasificar
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.card(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.line(0.1)),
          ),
          child: pending.isEmpty
              ? Center(
                  child: Text(
                    'routes.sortAllPlaced'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.accent(StepColors.correct),
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: pending.map((i) {
                    final selected = _selected == i;
                    final chip = Semantics(
                      button: true,
                      selected: selected,
                      hint: 'routes.sortChipA11y'.tr(),
                      child: GestureDetector(
                        onTap: () => _toggleSelected(i),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 160),
                          scale: selected ? 1.06 : 1,
                          child: _chip(_items[i], _accent, lifted: selected),
                        ),
                      ),
                    );
                    return Draggable<int>(
                      data: i,
                      feedback: Material(
                        color: Colors.transparent,
                        child: LessonPaletteScope(
                          palette: p,
                          child: Transform.scale(
                            scale: 1.08,
                            child: _chip(
                              _items[i],
                              _accent,
                              lifted: true,
                              palette: p,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(opacity: 0.25, child: chip),
                      onDragStarted: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selected = null);
                      },
                      child: chip,
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),

        // Categorías destino
        ...List.generate(_categories.length, (c) {
          final placed = _assignments.entries
              .where((e) => e.value == c)
              .map((e) => e.key)
              .toList();
          final waiting = _selected != null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DragTarget<int>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (details) => _assign(details.data, c),
              builder: (context, candidates, _) {
                final hover = candidates.isNotEmpty;
                final highlight = hover || waiting;
                return Semantics(
                  button: waiting,
                  label: _categories[c],
                  hint: waiting ? 'routes.sortPlaceHereA11y'.tr() : null,
                  child: GestureDetector(
                    onTap: waiting ? () => _assign(_selected!, c) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: hover
                            ? _accent.withValues(alpha: 0.18)
                            : waiting
                            ? _accent.withValues(alpha: p.isDark ? 0.08 : 0.06)
                            : p.card(0.05),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: highlight ? _accent : p.line(0.12),
                          width: hover ? 2 : (waiting ? 1.5 : 1),
                        ),
                        boxShadow: p.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ExcludeSemantics(
                                  child: Text(
                                    _categories[c],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: p.ink,
                                    ),
                                  ),
                                ),
                              ),
                              if (waiting)
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 18,
                                  color: p.accent(_accent),
                                ).animate().fadeIn(duration: 200.ms),
                            ],
                          ),
                          if (placed.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: placed.map((i) {
                                final ok = _isCorrect(i, c);
                                return Semantics(
                                  label:
                                      '${_items[i]}, ${ok ? 'routes.sortCorrectA11y'.tr() : 'routes.sortWrongA11y'.tr()}',
                                  child: ExcludeSemantics(
                                    child: _chip(
                                      _items[i],
                                      ok
                                          ? StepColors.correct
                                          : StepColors.wrong,
                                      icon: ok
                                          ? Icons.check_rounded
                                          : Icons.close_rounded,
                                    ),
                                  ),
                                ).animate().scale(
                                  begin: const Offset(0.7, 0.7),
                                  end: const Offset(1, 1),
                                  duration: 280.ms,
                                  curve: Curves.easeOutBack,
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),

        if (finished && widget.step.explanation != null) ...[
          const SizedBox(height: 4),
          StepNote(
            text: widget.step.explanation!,
            color: StepColors.correct,
            icon: Icons.school_rounded,
          ),
        ],
      ],
    );
  }

  /// [palette] se pasa explícito para el `feedback` del arrastre, que se
  /// dibuja en el Overlay, fuera del árbol de la lección.
  Widget _chip(
    String text,
    Color color, {
    IconData? icon,
    bool lifted = false,
    LessonPalette? palette,
  }) {
    final p = palette ?? LessonPalette.of(context);
    final fg = p.isDark ? Colors.white : p.accent(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: p.isDark
            ? color.withValues(alpha: lifted ? 0.35 : 0.18)
            : Color.lerp(Colors.white, color, lifted ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withValues(alpha: lifted ? 0.9 : 0.55),
          width: lifted ? 1.8 : 1,
        ),
        boxShadow: lifted
            ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 16)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
