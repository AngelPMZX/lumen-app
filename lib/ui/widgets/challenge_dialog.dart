import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../data/models/daily_challenge.dart';
import '../../../domain/providers/auth_provider.dart';
import '../screens/breathing/breathing_screen.dart';
import '../screens/diary/new_diary_entry_screen.dart';

/// Maneja la acción de un reto diario según su tipo.
/// Llamar: ChallengeAction.execute(context, challenge)
class ChallengeAction {
  static Future<bool> execute(
      BuildContext context, DailyChallenge challenge) async {
    switch (challenge.actionType) {
      case ChallengeActionType.breathing:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BreathingScreen()),
        );
        return true; // breathing screen awards its own XP

      case ChallengeActionType.diary:
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const NewDiaryEntryScreen()),
        );
        return result == true;

      case ChallengeActionType.timedGuide:
        final completed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _TimedGuideDialog(challenge: challenge),
        );
        return completed == true;

      case ChallengeActionType.infoComplete:
        final completed = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => _InfoCompleteDialog(challenge: challenge),
        );
        return completed == true;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TIMED GUIDE DIALOG
// Muestra pasos uno por uno con un timer visual. Al terminar = completado.
// ═════════════════════════════════════════════════════════════════════════════
class _TimedGuideDialog extends StatefulWidget {
  final DailyChallenge challenge;
  const _TimedGuideDialog({required this.challenge});

  @override
  State<_TimedGuideDialog> createState() => _TimedGuideDialogState();
}

class _TimedGuideDialogState extends State<_TimedGuideDialog>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _finished = false;
  late AnimationController _progressCtrl;
  Timer? _timer;
  int _secondsLeft = 0;
  int _stepDuration = 0;

  List<String> get _steps => widget.challenge.stepKeys;
  bool get _hasSteps => _steps.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(vsync: this);
    if (_hasSteps) _startStep(0);
  }

  void _startStep(int index) {
    _timer?.cancel();
    // Each step gets equal time based on total duration string
    // Parse minutes from duration like "5 min", "1 min"
    final totalSeconds = _parseDurationToSeconds(widget.challenge.duration);
    _stepDuration = (totalSeconds / _steps.length).round();
    if (_stepDuration < 10) _stepDuration = 10; // min 10s per step

    setState(() {
      _currentStep = index;
      _secondsLeft = _stepDuration;
    });

    _progressCtrl.duration = Duration(seconds: _stepDuration);
    _progressCtrl.forward(from: 0);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        if (_currentStep < _steps.length - 1) {
          HapticFeedback.lightImpact();
          _startStep(_currentStep + 1);
        } else {
          HapticFeedback.heavyImpact();
          setState(() => _finished = true);
          _progressCtrl.stop();
        }
      }
    });
  }

  int _parseDurationToSeconds(String duration) {
    // "5 min" → 300, "1 min" → 60, "2 hrs" → 120 (cap at 5min for UX)
    if (duration.contains('hr')) return 300;
    final match = RegExp(r'(\d+)').firstMatch(duration);
    if (match == null) return 180;
    final n = int.parse(match.group(1)!);
    if (duration.contains('min')) return n * 60;
    return n * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressCtrl.dispose();
    super.dispose();
  }

  String _stepText(String key) {
    final t = key.tr();
    return t == key ? key : t;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.challenge.color;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: _finished ? _buildFinished(isDark, color) : _buildGuide(isDark, color),
      ).animate().scale(
        begin: const Offset(0.85, 0.85),
        end: const Offset(1, 1),
        duration: 350.ms,
        curve: Curves.easeOutBack,
      ).fadeIn(duration: 250.ms),
    );
  }

  Widget _buildGuide(bool isDark, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(widget.challenge.icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_challengeTitle(), style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            Text(widget.challenge.duration, style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ])),
          GestureDetector(
            onTap: () { _timer?.cancel(); Navigator.pop(context, false); },
            child: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 22),
          ),
        ]),

        const SizedBox(height: 20),

        // Step indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_steps.length, (i) {
            final isDone = i < _currentStep;
            final isCurrent = i == _currentStep;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 20 : 8, height: 8,
              decoration: BoxDecoration(
                color: isDone || isCurrent
                    ? color : color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),

        const SizedBox(height: 20),

        // Timer circle
        SizedBox(
          width: 100, height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _progressCtrl,
                builder: (_, __) => CircularProgressIndicator(
                  value: _progressCtrl.value,
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$_secondsLeft', style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, color: color)),
                Text('seg', style: TextStyle(
                    fontSize: 10, color: color.withOpacity(0.7))),
              ]),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Step text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(_currentStep),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.1 : 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Text(
              _stepText(_steps[_currentStep]),
              style: TextStyle(
                fontSize: 15, height: 1.5, fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withOpacity(0.9)
                    : const Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ).animate().fadeIn(duration: 300.ms),

        const SizedBox(height: 20),

        // Skip button
        TextButton(
          onPressed: () {
            if (_currentStep < _steps.length - 1) {
              HapticFeedback.lightImpact();
              _startStep(_currentStep + 1);
            } else {
              HapticFeedback.mediumImpact();
              setState(() => _finished = true);
              _timer?.cancel();
              _progressCtrl.stop();
            }
          },
          child: Text(
            _currentStep < _steps.length - 1
                ? 'challenge.nextStep'.tr()
                : 'challenge.finish'.tr(),
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildFinished(bool isDark, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [
              color.withOpacity(0.25), color.withOpacity(0.05),
            ]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: color.withOpacity(0.3), blurRadius: 20, spreadRadius: 4,
            )],
          ),
          child: const Center(child: Text('✨', style: TextStyle(fontSize: 38))),
        ).animate().scale(
          begin: const Offset(0.5, 0.5), end: const Offset(1, 1),
          duration: 500.ms, curve: Curves.easeOutBack,
        ),

        const SizedBox(height: 20),

        Text('challenge.completed'.tr(), style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        )).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 8),

        Text(_challengeTitle(), style: TextStyle(
          fontSize: 14, color: color, fontWeight: FontWeight.w600,
        )).animate(delay: 250.ms).fadeIn(duration: 400.ms),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity, height: 52,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('challenge.awesome'.tr(), style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  String _challengeTitle() {
    if (widget.challenge.titleKey == null) return widget.challenge.title;
    final t = widget.challenge.titleKey!.tr();
    return t == widget.challenge.titleKey ? widget.challenge.title : t;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INFO COMPLETE DIALOG
// Muestra los pasos como lista. El usuario los lee y presiona "Lo hice".
// ═════════════════════════════════════════════════════════════════════════════
class _InfoCompleteDialog extends StatefulWidget {
  final DailyChallenge challenge;
  const _InfoCompleteDialog({required this.challenge});

  @override
  State<_InfoCompleteDialog> createState() => _InfoCompleteDialogState();
}

class _InfoCompleteDialogState extends State<_InfoCompleteDialog> {
  bool _completed = false;

  String _stepText(String key) {
    final t = key.tr();
    return t == key ? key : t;
  }

  String _challengeTitle() {
    if (widget.challenge.titleKey == null) return widget.challenge.title;
    final t = widget.challenge.titleKey!.tr();
    return t == widget.challenge.titleKey ? widget.challenge.title : t;
  }

  String _challengeDesc() {
    if (widget.challenge.descriptionKey == null) return widget.challenge.description;
    final t = widget.challenge.descriptionKey!.tr();
    return t == widget.challenge.descriptionKey ? widget.challenge.description : t;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.challenge.color;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 30, spreadRadius: 4,
            ),
          ],
        ),
        child: _completed ? _buildCompleted(isDark, color) : _buildInfo(isDark, color),
      ).animate().scale(
        begin: const Offset(0.85, 0.85),
        end: const Offset(1, 1),
        duration: 350.ms,
        curve: Curves.easeOutBack,
      ).fadeIn(duration: 250.ms),
    );
  }

  Widget _buildInfo(bool isDark, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(widget.challenge.icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_challengeTitle(), style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E))),
            Text(widget.challenge.duration, style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ])),
          GestureDetector(
            onTap: () => Navigator.pop(context, false),
            child: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 22),
          ),
        ]),

        const SizedBox(height: 16),

        // Description
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.1 : 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Text(_challengeDesc(), style: TextStyle(
            fontSize: 14, height: 1.5,
            color: isDark ? Colors.white.withOpacity(0.85)
                : const Color(0xFF1A1A2E),
          )),
        ),

        if (widget.challenge.stepKeys.isNotEmpty) ...[
          const SizedBox(height: 16),
          // Steps as checklist
          ...widget.challenge.stepKeys.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${e.key + 1}', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_stepText(e.value), style: TextStyle(
                    fontSize: 14, height: 1.4,
                    color: isDark ? Colors.white.withOpacity(0.8)
                        : const Color(0xFF374151),
                  )),
                ),
              ],
            ).animate(delay: (e.key * 80).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0),
          )),
        ],

        const SizedBox(height: 20),

        // CTA
        SizedBox(
          width: double.infinity, height: 52,
          child: FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              setState(() => _completed = true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('challenge.didIt'.tr(), style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),

        const SizedBox(height: 8),

        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('challenge.later'.tr(), style: TextStyle(
              color: Colors.grey.shade500, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildCompleted(bool isDark, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [
              color.withOpacity(0.25), color.withOpacity(0.05),
            ]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: color.withOpacity(0.3), blurRadius: 20, spreadRadius: 4,
            )],
          ),
          child: Center(child: Text(
            widget.challenge.icon == Icons.volunteer_activism_rounded ? '🤝'
                : widget.challenge.icon == Icons.headphones_rounded ? '🎵'
                : widget.challenge.icon == Icons.park_rounded ? '🌿'
                : '✅',
            style: const TextStyle(fontSize: 38),
          )),
        ).animate().scale(
          begin: const Offset(0.5, 0.5), end: const Offset(1, 1),
          duration: 500.ms, curve: Curves.easeOutBack,
        ),

        const SizedBox(height: 20),

        Text('challenge.completed'.tr(), style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        )).animate(delay: 150.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 8),

        Text(_challengeTitle(), style: TextStyle(
          fontSize: 14, color: color, fontWeight: FontWeight.w600,
        )).animate(delay: 250.ms).fadeIn(duration: 400.ms),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity, height: 52,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('challenge.awesome'.tr(), style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }
}