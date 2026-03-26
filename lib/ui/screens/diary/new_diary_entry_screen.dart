import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/diary_entry.dart';
import '../../../data/models/mood_entry.dart';
import '../../../domain/providers/auth_provider.dart';

class NewDiaryEntryScreen extends StatefulWidget {
  const NewDiaryEntryScreen({super.key});

  @override
  State<NewDiaryEntryScreen> createState() => _NewDiaryEntryScreenState();
}

class _NewDiaryEntryScreenState extends State<NewDiaryEntryScreen> {
  MoodType? _selectedMood;
  final _textController = TextEditingController();
  final _gratitudeController = TextEditingController();
  bool _showGratitude = false;
  bool _isSaving = false;
  late String _gratitudePrompt;
  late String _reflectionPrompt;

  @override
  void initState() {
    super.initState();
    _gratitudePrompt = DiaryPrompts.getRandomGratitudePrompt();
    _reflectionPrompt = DiaryPrompts.getRandomReflectionPrompt();
  }

  @override
  void dispose() {
    _textController.dispose();
    _gratitudeController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _selectedMood != null && _textController.text.trim().length >= 3;

  Future<void> _saveEntry() async {
    if (!_canSave || _isSaving) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final authProvider = context.read<AuthProvider>();
      final entry = DiaryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mood: _selectedMood!,
        text: _textController.text.trim(),
        gratitude: _showGratitude && _gratitudeController.text.trim().isNotEmpty
            ? _gratitudeController.text.trim()
            : null,
        prompt: _showGratitude ? _gratitudePrompt : null,
      );

      await authProvider.saveDiaryEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text('Entrada guardada. ¡+20 XP!',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving diary entry: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva entrada',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _canSave ? _saveEntry : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                disabledBackgroundColor:
                    const Color(0xFF10B981).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mood selector
            Text(
              '¿Cómo te sientes?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200,
                ),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: MoodType.values.map((mood) {
                  final isSelected = _selectedMood == mood;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedMood = mood);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? mood.color.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? Border.all(
                                color: mood.color.withValues(alpha: 0.5),
                                width: 2)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(mood.emoji,
                              style:
                                  TextStyle(fontSize: isSelected ? 26 : 22)),
                          const SizedBox(height: 2),
                          Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? mood.color
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Prompt de reflexión
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.02),
                        ]
                      : [const Color(0xFFF0FDFA), const Color(0xFFECFDF5)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFA7F3D0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_rounded,
                      color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _reflectionPrompt,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF065F46),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Campo de texto principal
            Text(
              'Escribe sobre tu día',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              maxLines: 6,
              maxLength: 1000,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : AppColors.textPrimary,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText: 'Hoy me siento...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.grey.shade400),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: Color(0xFF10B981), width: 1.5),
                ),
                counterStyle: TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            // Toggle de gratitud
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _showGratitude = !_showGratitude);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _showGratitude
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _showGratitude
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                        : isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showGratitude
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Agregar gratitud',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '+5 XP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Campo de gratitud (expandible)
            if (_showGratitude) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.04),
                            Colors.white.withValues(alpha: 0.02),
                          ]
                        : [const Color(0xFFFEF9C3), const Color(0xFFFEF3C7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _gratitudePrompt,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _gratitudeController,
                      maxLines: 3,
                      maxLength: 500,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Escribe aquí...',
                        hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white30
                                : Colors.grey.shade400),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        counterStyle: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}