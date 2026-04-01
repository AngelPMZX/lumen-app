import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/habit.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../widgets/animated_particles_background.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedEmoji = '✅';
  Color _selectedColor = const Color(0xFF6366F1);
  bool _isSaving = false;
  bool _showCustomForm = false;

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  final _emojiOptions = [
    '✅', '💪', '💧', '📝', '🧘', '📖', '😴', '📵',
    '🙏', '🏃', '🍎', '🎯', '🌿', '🎵', '💤', '🧠',
  ];

  final _colorOptions = [
    const Color(0xFF6366F1),
    const Color(0xFFEF4444),
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFFF97316),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _presetTitle(Habit habit) {
    switch (habit.id) {
      case 'preset_exercise':
        return 'habits.exercise'.tr();
      case 'preset_water':
        return 'habits.water'.tr();
      case 'preset_diary':
        return 'habits.writeDiary'.tr();
      case 'preset_meditate':
        return 'habits.meditate'.tr();
      case 'preset_read':
        return 'habits.read'.tr();
      case 'preset_sleep':
        return 'habits.sleep'.tr();
      case 'preset_no_social':
        return 'habits.noSocial'.tr();
      case 'preset_gratitude':
        return 'habits.gratitude'.tr();
      default:
        return habit.title;
    }
  }

  String? _presetDescription(Habit habit) {
    switch (habit.id) {
      case 'preset_exercise':
        return 'habits.exerciseDesc'.tr();
      case 'preset_water':
        return 'habits.waterDesc'.tr();
      case 'preset_diary':
        return 'habits.writeDiaryDesc'.tr();
      case 'preset_meditate':
        return 'habits.meditateDesc'.tr();
      case 'preset_read':
        return 'habits.readDesc'.tr();
      case 'preset_sleep':
        return 'habits.sleepDesc'.tr();
      case 'preset_no_social':
        return 'habits.noSocialDesc'.tr();
      case 'preset_gratitude':
        return 'habits.gratitudeDesc'.tr();
      default:
        return habit.description;
    }
  }

  Future<void> _savePreset(Habit preset) async {
    HapticFeedback.mediumImpact();
    try {
      final auth = context.read<AuthProvider>();
      final habit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: preset.title,
        description: preset.description,
        emoji: preset.emoji,
        color: preset.color,
      );
      await auth.saveHabit(habit);
      if (mounted) {
        final translatedTitle = _presetTitle(preset);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(preset.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(
                  'habits.addedNamed'.tr(namedArgs: {'title': translatedTitle}),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: preset.color.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving preset: $e');
    }
  }

  Future<void> _saveCustom() async {
    if (!_canSave || _isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    try {
      final auth = context.read<AuthProvider>();
      final habit = Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descController.text.trim().isNotEmpty
            ? _descController.text.trim() : null,
        emoji: _selectedEmoji,
        color: _selectedColor,
      );
      await auth.saveHabit(habit);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error saving custom habit: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedParticlesBackground(
            particleCount: 15,
            maxShootingStars: isDark ? 2 : 0,
            particleColor: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : const Color(0xFF10B981).withValues(alpha: 0.12),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'habits.addHabit'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [const Color(0xFF10B981).withValues(alpha: 0.15),
                                     const Color(0xFF059669).withValues(alpha: 0.08)]
                                  : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.15)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 64, height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.add_task_rounded,
                                    color: Color(0xFF10B981), size: 32),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'habits.chooseHabit'.tr(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF065F46),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'habits.chooseSuggestedOrCustom'.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white60 : const Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 24),

                        Text(
                          'habits.suggestedShort'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...List.generate(Habit.presets.length, (index) {
                          final preset = Habit.presets[index];
                          final translatedTitle = _presetTitle(preset);
                          final translatedDescription = _presetDescription(preset);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                              onTap: () => _savePreset(preset),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      preset.color.withValues(alpha: isDark ? 0.12 : 0.06),
                                      preset.color.withValues(alpha: isDark ? 0.06 : 0.02),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: preset.color.withValues(alpha: isDark ? 0.2 : 0.12)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46, height: 46,
                                      decoration: BoxDecoration(
                                        color: preset.color.withValues(alpha: isDark ? 0.2 : 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Text(preset.emoji,
                                            style: const TextStyle(fontSize: 22)),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            translatedTitle,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : AppColors.textPrimary,
                                            ),
                                          ),
                                          if (translatedDescription != null)
                                            Text(
                                              translatedDescription,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 34, height: 34,
                                      decoration: BoxDecoration(
                                        color: preset.color.withValues(alpha: isDark ? 0.15 : 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.add_rounded, color: preset.color, size: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: (60 * index).ms, duration: 400.ms)
                              .slideX(begin: -0.03, end: 0);
                        }),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'habits.orCreateYours'.tr(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if (!_showCustomForm)
                          GestureDetector(
                            onTap: () => setState(() => _showCustomForm = true),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [AppColors.primary.withValues(alpha: 0.1),
                                         AppColors.primary.withValues(alpha: 0.05)]
                                      : [const Color(0xFFEEF2FF), const Color(0xFFF5F3FF)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.15),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(Icons.edit_rounded, color: AppColors.primary, size: 24),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'habits.createCustomHabit'.tr(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'habits.chooseEmojiColorName'.tr(),
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _selectedColor.withValues(alpha: isDark ? 0.2 : 0.15)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'habits.customize'.tr(),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Text(
                                  'habits.iconLabel'.tr(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8, runSpacing: 8,
                                  children: _emojiOptions.map((emoji) {
                                    final sel = _selectedEmoji == emoji;
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setState(() => _selectedEmoji = emoji);
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(
                                          color: sel ? _selectedColor.withValues(alpha: 0.15)
                                              : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                          border: sel ? Border.all(color: _selectedColor.withValues(alpha: 0.5), width: 2) : null,
                                        ),
                                        child: Center(child: Text(emoji, style: TextStyle(fontSize: sel ? 22 : 18))),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),

                                Text(
                                  'habits.habitColor'.tr(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: _colorOptions.map((color) {
                                    final sel = _selectedColor == color;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 10),
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          setState(() => _selectedColor = color);
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: sel ? 38 : 30, height: sel ? 38 : 30,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: sel ? Border.all(color: isDark ? Colors.white : Colors.white, width: 3) : null,
                                            boxShadow: sel ? [
                                              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1),
                                            ] : [],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 20),

                                TextField(
                                  controller: _titleController,
                                  onChanged: (_) => setState(() {}),
                                  maxLength: 40,
                                  style: TextStyle(fontSize: 15,
                                      color: isDark ? Colors.white : AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    labelText: 'habits.habitName'.tr(),
                                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                                    hintText: 'habits.nameHintCustom'.tr(),
                                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                                    filled: true,
                                    fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: _selectedColor, width: 1.5),
                                    ),
                                    counterStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                TextField(
                                  controller: _descController,
                                  maxLength: 80,
                                  style: TextStyle(fontSize: 15,
                                      color: isDark ? Colors.white : AppColors.textPrimary),
                                  decoration: InputDecoration(
                                    labelText: 'habits.habitDesc'.tr(),
                                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                                    hintText: 'habits.descHintCustom'.tr(),
                                    hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                                    filled: true,
                                    fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: _selectedColor, width: 1.5),
                                    ),
                                    counterStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      _selectedColor.withValues(alpha: isDark ? 0.12 : 0.08),
                                      _selectedColor.withValues(alpha: isDark ? 0.06 : 0.03),
                                    ]),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _selectedColor.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 46, height: 46,
                                        decoration: BoxDecoration(
                                          color: _selectedColor.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 24))),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _titleController.text.isNotEmpty ? _titleController.text : 'habits.preview'.tr(),
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : AppColors.textPrimary,
                                              ),
                                            ),
                                            if (_descController.text.isNotEmpty)
                                              Text(
                                                _descController.text,
                                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _selectedColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'habits.checkInXp'.tr(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _selectedColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                SizedBox(
                                  width: double.infinity, height: 52,
                                  child: FilledButton(
                                    onPressed: _canSave ? _saveCustom : null,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _selectedColor,
                                      disabledBackgroundColor: _selectedColor.withValues(alpha: 0.3),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: _isSaving
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : Text(
                                            'habits.createHabit'.tr(),
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
