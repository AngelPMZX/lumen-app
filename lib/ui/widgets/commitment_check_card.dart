import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/models/commitment.dart';

/// Tarjeta del Home: "¿Cumpliste tu reto?".
///
/// Tres respuestas, ninguna castiga. Cumplirlo (o a medias) da recompensa;
/// no poder se recibe con amabilidad y ofrece intentarlo hoy o soltarlo.
class CommitmentCheckCard extends StatefulWidget {
  final Commitment commitment;
  final bool isDark;

  /// Guarda la respuesta. [done] y [partial] dan recompensa en el Home.
  final Future<void> Function(CommitmentStatus status) onAnswer;

  /// Después de "no pude": volver a intentarlo hoy.
  final Future<void> Function() onRetry;

  /// La tarjeta terminó su ciclo y puede desaparecer.
  final VoidCallback onClose;

  const CommitmentCheckCard({
    super.key,
    required this.commitment,
    required this.isDark,
    required this.onAnswer,
    required this.onRetry,
    required this.onClose,
  });

  @override
  State<CommitmentCheckCard> createState() => _CommitmentCheckCardState();
}

class _CommitmentCheckCardState extends State<CommitmentCheckCard> {
  static const _gold = Color(0xFFF59E0B);
  static const _green = Color(0xFF10B981);
  static const _blue = Color(0xFF6C8FE8);

  CommitmentStatus? _answer;
  bool _busy = false;

  Future<void> _choose(CommitmentStatus status) async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _answer = status;
    });
    await widget.onAnswer(status);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _retry() async {
    HapticFeedback.lightImpact();
    await widget.onRetry();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (_answer) {
      CommitmentStatus.done => _green,
      CommitmentStatus.partial => _gold,
      CommitmentStatus.skipped => _blue,
      _ => _gold,
    };
    final titleColor = widget.isDark ? Colors.white : const Color(0xFF1F2937);
    final bodyColor = widget.isDark ? Colors.white70 : const Color(0xFF4B5563);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: widget.isDark ? 0.2 : 0.14),
            color.withValues(alpha: widget.isDark ? 0.06 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _answer == null
            ? _buildQuestion(titleColor, bodyColor)
            : _buildResult(_answer!, color, titleColor, bodyColor),
      ),
    );
  }

  Widget _buildQuestion(Color titleColor, Color bodyColor) {
    final days = widget.commitment.daysAgo(DateTime.now());
    return Column(
      key: const ValueKey('question'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🤝', style: TextStyle(fontSize: 24))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .rotate(begin: -0.03, end: 0.03, duration: 900.ms),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                days <= 1
                    ? 'commitments.questionYesterday'.tr()
                    : 'commitments.questionDaysAgo'.tr(namedArgs: {'n': '$days'}),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: titleColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"${widget.commitment.text}"',
                style: TextStyle(fontSize: 14.5, height: 1.4, fontWeight: FontWeight.w600, color: titleColor),
              ),
              if (widget.commitment.lessonTitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.commitment.lessonTitle,
                  style: TextStyle(fontSize: 11.5, color: bodyColor),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _answerButton('commitments.done'.tr(), '🎉', _green, CommitmentStatus.done),
            const SizedBox(width: 8),
            _answerButton('commitments.partial'.tr(), '🌗', _gold, CommitmentStatus.partial),
            const SizedBox(width: 8),
            _answerButton('commitments.skipped'.tr(), '🌧️', _blue, CommitmentStatus.skipped),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _answerButton(String label, String emoji, Color color, CommitmentStatus status) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _choose(status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(CommitmentStatus status, Color color, Color titleColor, Color bodyColor) {
    final (emoji, titleKey, bodyKey) = switch (status) {
      CommitmentStatus.done => ('🏆', 'commitments.doneTitle', 'commitments.doneBody'),
      CommitmentStatus.partial => ('🌱', 'commitments.partialTitle', 'commitments.partialBody'),
      _ => ('🫶', 'commitments.skippedTitle', 'commitments.skippedBody'),
    };

    return Column(
      key: ValueKey('result_${status.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28))
                .animate()
                .scale(begin: const Offset(0.4, 0.4), end: const Offset(1, 1), duration: 450.ms, curve: Curves.easeOutBack),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                titleKey.tr(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: titleColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(bodyKey.tr(), style: TextStyle(fontSize: 14, height: 1.5, color: bodyColor)),
        const SizedBox(height: 12),
        if (status == CommitmentStatus.skipped)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _retry,
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('commitments.retryToday'.tr()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : widget.onClose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    side: BorderSide(color: _blue.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('commitments.letGo'.tr()),
                ),
              ),
            ],
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : widget.onClose,
              child: Text('common.close'.tr(), style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }
}
