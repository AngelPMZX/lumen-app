import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/wellness_route.dart';
import '../../../domain/providers/auth_provider.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  final Color routeColor;
  final String routeEmoji;

  const LessonScreen({
    super.key,
    required this.lesson,
    required this.routeColor,
    required this.routeEmoji,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _currentStep = 0;
  int? _selectedQuizOption;
  bool _quizAnswered = false;
  final _exerciseController = TextEditingController();
  bool _isSaving = false;

  LessonStep get _step => widget.lesson.steps[_currentStep];
  bool get _isLastStep => _currentStep == widget.lesson.steps.length - 1;
  double get _progress => (_currentStep + 1) / widget.lesson.steps.length;

  @override
  void dispose() {
    _exerciseController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    switch (_step.type) {
      case LessonStepType.reading:
        return true;
      case LessonStepType.quiz:
        return _quizAnswered;
      case LessonStepType.exercise:
        return _exerciseController.text.trim().length >= 10;
    }
  }

  void _nextStep() {
    HapticFeedback.mediumImpact();
    if (_isLastStep) {
      _completeLesson();
    } else {
      setState(() {
        _currentStep++;
        _selectedQuizOption = null;
        _quizAnswered = false;
        _exerciseController.clear();
      });
    }
  }

  void _selectQuizOption(int index) {
    if (_quizAnswered) return;
    HapticFeedback.lightImpact();
    setState(() {
      _selectedQuizOption = index;
      _quizAnswered = true;
    });
  }

  Future<void> _completeLesson() async {
    setState(() => _isSaving = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.completeLesson(widget.lesson.id, widget.lesson.xpReward);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => _buildCompletionDialog(ctx),
        );
      }
    } catch (e) {
      debugPrint('Error completing lesson: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildCompletionDialog(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: widget.routeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle),
              child: const Icon(Icons.celebration_rounded, color: Color(0xFFF59E0B), size: 36),
            ),
            const SizedBox(height: 20),
            Text('routes.lessonComplete'.tr(), style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(widget.lesson.title, style: TextStyle(fontSize: 15,
                color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: widget.routeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: Color(0xFFFBBF24), size: 22),
                  const SizedBox(width: 6),
                  Text('+${widget.lesson.xpReward} XP', style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w800, color: widget.routeColor)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 50,
              child: FilledButton(
                onPressed: () { Navigator.pop(ctx); Navigator.pop(context, true); },
                style: FilledButton.styleFrom(
                  backgroundColor: widget.routeColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: Text('common.continue'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(widget.routeColor),
                        minHeight: 8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${_currentStep + 1}/${widget.lesson.steps.length}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                          color: widget.routeColor)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStepContent(isDark),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity, height: 56,
                child: FilledButton(
                  onPressed: _canContinue ? _nextStep : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.routeColor,
                    disabledBackgroundColor: widget.routeColor.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLastStep ? 'common.done'.tr() : 'common.continue'.tr(),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            Icon(_isLastStep ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isDark) {
    switch (_step.type) {
      case LessonStepType.reading:
        return _buildReading(isDark);
      case LessonStepType.quiz:
        return _buildQuiz(isDark);
      case LessonStepType.exercise:
        return _buildExercise(isDark);
    }
  }

  Widget _buildReading(bool isDark) {
    return Column(
      key: ValueKey('reading_$_currentStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: widget.routeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_rounded, color: widget.routeColor, size: 14),
              const SizedBox(width: 6),
              Text('routes.readingTitle'.tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: widget.routeColor)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(_step.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: 16),
        Text(_step.content ?? '', style: TextStyle(fontSize: 16, height: 1.8,
            color: isDark ? Colors.white.withValues(alpha: 0.85) : AppColors.textPrimary)),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildQuiz(bool isDark) {
    return Column(
      key: ValueKey('quiz_$_currentStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_rounded, color: Color(0xFFF59E0B), size: 14),
              const SizedBox(width: 6),
              Text('routes.questionLabel'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: Color(0xFFF59E0B))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(_step.question!, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: 20),

        ...List.generate(_step.options!.length, (i) {
          final isSelected = _selectedQuizOption == i;
          final isCorrect = i == _step.correctIndex;
          final showResult = _quizAnswered;

          Color borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300;
          Color bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface;

          if (showResult && isCorrect) {
            borderColor = const Color(0xFF10B981);
            bgColor = const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08);
          } else if (showResult && isSelected && !isCorrect) {
            borderColor = const Color(0xFFEF4444);
            bgColor = const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08);
          } else if (isSelected) {
            borderColor = widget.routeColor;
            bgColor = widget.routeColor.withValues(alpha: isDark ? 0.1 : 0.05);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => _selectQuizOption(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: isSelected || (showResult && isCorrect) ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: showResult && isCorrect
                            ? const Color(0xFF10B981)
                            : showResult && isSelected && !isCorrect
                                ? const Color(0xFFEF4444)
                                : borderColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                      child: Center(
                        child: showResult
                            ? Icon(isCorrect ? Icons.check_rounded : isSelected ? Icons.close_rounded : null,
                                color: Colors.white, size: 18)
                            : Text(String.fromCharCode(65 + i), style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14,
                                color: isDark ? Colors.white60 : AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_step.options![i], style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary))),
                  ],
                ),
              ),
            ),
          );
        }),

        if (_quizAnswered && _step.explanation != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (_selectedQuizOption == _step.correctIndex
                  ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                  .withValues(alpha: isDark ? 0.1 : 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (_selectedQuizOption == _step.correctIndex
                  ? const Color(0xFF10B981) : const Color(0xFFF59E0B))
                  .withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_selectedQuizOption == _step.correctIndex
                    ? Icons.check_circle_rounded : Icons.info_rounded,
                    color: _selectedQuizOption == _step.correctIndex
                        ? const Color(0xFF10B981) : const Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_step.explanation!, style: TextStyle(
                    fontSize: 14, color: isDark ? Colors.white70 : AppColors.textPrimary, height: 1.5))),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildExercise(bool isDark) {
    return Column(
      key: ValueKey('exercise_$_currentStep'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_rounded, color: Color(0xFF10B981), size: 14),
              const SizedBox(width: 6),
              Text('routes.exerciseLabel'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(_step.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.15)),
          ),
          child: Text(_step.instruction!, style: TextStyle(fontSize: 15, height: 1.6,
              color: isDark ? Colors.white.withValues(alpha: 0.8) : AppColors.textPrimary)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _exerciseController,
          onChanged: (_) => setState(() {}),
          maxLines: 5,
          maxLength: 500,
          style: TextStyle(fontSize: 15, color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: _step.placeholder ?? 'routes.exercisePlaceholder'.tr(),
            hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: widget.routeColor, width: 1.5)),
            counterStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            contentPadding: const EdgeInsets.all(18),
          ),
        ),
        const SizedBox(height: 8),
        Text('routes.exerciseMinChars'.tr(),
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}