import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../data/models/archetype.dart';
import '../../../../data/models/lumi.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../../domain/services/sound_service.dart';
import '../../../widgets/lumi/lumi_avatar.dart';

/// El mini test que decide el arquetipo: cuatro preguntas sobre cómo llevas lo
/// que sientes.
///
/// Antes el arquetipo salía solo de los gustos y la música, que no dicen nada
/// del bienestar emocional, y el resultado se sentía a horóscopo pegado con
/// cinta. Aquí se lo gana la persona respondiendo.
///
/// Una pregunta a la vez, con una opción por arquetipo y ninguna correcta. Al
/// elegir suena una nota de la escala —las cuatro respuestas arman una frase
/// que sube— y pasa sola a la siguiente.
class ArchetypeQuizStep extends StatefulWidget {
  final ValueChanged<List<Archetype>> onNext;

  const ArchetypeQuizStep({super.key, required this.onNext});

  @override
  State<ArchetypeQuizStep> createState() => _ArchetypeQuizStepState();
}

class _ArchetypeQuizStepState extends State<ArchetypeQuizStep> {
  final List<Archetype> _answers = [];
  int _index = 0;

  /// Qué opción se acaba de tocar, para marcarla antes de pasar de pregunta.
  int? _chosen;
  bool _leaving = false;

  List<ArchetypeQuestion> get _questions => ArchetypeQuiz.questions;

  void _choose(int optionIndex) {
    if (_leaving) return;
    final question = _questions[_index];
    HapticFeedback.selectionClick();
    // Una nota por pregunta: juntas suben, como en el paso de ordenar.
    SoundService.instance.note(_index.clamp(0, 7), volume: 0.5);
    setState(() {
      _chosen = optionIndex;
      _leaving = true;
    });

    final delay = MotionService.reduced(context)
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 420);
    Future.delayed(delay, () {
      if (!mounted) return;
      _answers.add(question.options[optionIndex].archetype);
      if (_index + 1 >= _questions.length) {
        SoundService.instance.play(Sfx.complete, volume: 0.55);
        widget.onNext(List.unmodifiable(_answers));
        return;
      }
      setState(() {
        _index++;
        _chosen = null;
        _leaving = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_index];
    final total = _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          LumiAvatar(
            mood: _index == 0 ? LumiMood.curious : LumiMood.happy,
            size: 78,
          ),
          const SizedBox(height: 14),
          Text(
            'archetypeQuiz.title'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'archetypeQuiz.subtitle'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 20),

          _QuizProgress(current: _index, total: total),
          const SizedBox(height: 22),

          // La pregunta y sus opciones entran juntas al cambiar de una a otra.
          AnimatedSwitcher(
            duration: Duration(
              milliseconds: MotionService.reduced(context) ? 120 : 320,
            ),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: MotionService.reduced(context)
                      ? Offset.zero
                      : const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(_index),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    question.promptKey.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                for (int i = 0; i < question.options.length; i++) ...[
                  _OptionCard(
                    option: question.options[i],
                    position: i,
                    total: question.options.length,
                    chosen: _chosen == i,
                    dimmed: _chosen != null && _chosen != i,
                    onTap: () => _choose(i),
                  )
                      .animate()
                      .fadeIn(delay: (60 * i).ms, duration: 280.ms)
                      .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
                  if (i < question.options.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

/// Cuántas preguntas van: un punto por pregunta, el de ahora alargado.
class _QuizProgress extends StatelessWidget {
  final int current;
  final int total;

  const _QuizProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'archetypeQuiz.progress'.tr(
        namedArgs: {'n': '${current + 1}', 'total': '$total'},
      ),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 7),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: i == current ? 26 : 9,
              height: 9,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: i < current
                      ? 0.85
                      : i == current
                          ? 1
                          : 0.28,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Una respuesta. Se hunde al tocarla y se marca antes de pasar de pregunta;
/// las demás se apagan un poco para que se vea cuál eligió.
class _OptionCard extends StatefulWidget {
  final ArchetypeOption option;
  final int position;
  final int total;
  final bool chosen;
  final bool dimmed;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.position,
    required this.total,
    required this.chosen,
    required this.dimmed,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final chosen = widget.chosen;
    return Semantics(
      button: true,
      selected: chosen,
      inMutuallyExclusiveGroup: true,
      label: 'archetypeQuiz.a11yOption'.tr(namedArgs: {
        'n': '${widget.position + 1}',
        'total': '${widget.total}',
        'text': widget.option.textKey.tr(),
      }),
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedOpacity(
          opacity: widget.dimmed ? 0.45 : 1,
          duration: const Duration(milliseconds: 250),
          child: AnimatedScale(
            scale: _down ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              // Nada de rebote aquí: interpola la sombra por debajo de 0.
              curve: Curves.easeOutCubic,
              constraints: const BoxConstraints(maxWidth: 460),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: chosen ? 0.24 : 0.09),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  // Siempre 2: si cambiara de grosor, la tarjeta cambiaría de
                  // tamaño y las de abajo se moverían.
                  color: Colors.white.withValues(alpha: chosen ? 0.75 : 0.18),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.option.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.option.textKey.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // El hueco del check está siempre reservado.
                  AnimatedOpacity(
                    opacity: chosen ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 17,
                        color: Color(0xFF4A42DB),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
