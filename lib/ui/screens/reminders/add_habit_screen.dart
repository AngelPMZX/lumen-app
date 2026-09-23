import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import 'widgets/habit_color_picker.dart';
import '../../../data/models/habit.dart';
import '../../../data/models/habit_xp_quota.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../data/models/lumi.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/animated_particles_background.dart';
import '../../widgets/journal/journal_style.dart';

class AddHabitScreen extends StatefulWidget {
  /// Títulos de hábitos que el usuario ya tiene (para evitar duplicados)
  final Set<String> existingHabitTitles;

  const AddHabitScreen({super.key, this.existingHabitTitles = const {}});

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

  /// Verifica si un preset ya está en los hábitos del usuario
  bool _isPresetAlreadyAdded(Habit preset) {
    return widget.existingHabitTitles.contains(preset.title);
  }

  String _presetTitle(Habit habit) {
    switch (habit.id) {
      case 'preset_exercise': return 'habits.exercise'.tr();
      case 'preset_water': return 'habits.water'.tr();
      case 'preset_diary': return 'habits.writeDiary'.tr();
      case 'preset_meditate': return 'habits.meditate'.tr();
      case 'preset_read': return 'habits.read'.tr();
      case 'preset_sleep': return 'habits.sleep'.tr();
      case 'preset_no_social': return 'habits.noSocial'.tr();
      case 'preset_gratitude': return 'habits.gratitude'.tr();
      default: return habit.title;
    }
  }

  String? _presetDescription(Habit habit) {
    switch (habit.id) {
      case 'preset_exercise': return 'habits.exerciseDesc'.tr();
      case 'preset_water': return 'habits.waterDesc'.tr();
      case 'preset_diary': return 'habits.writeDiaryDesc'.tr();
      case 'preset_meditate': return 'habits.meditateDesc'.tr();
      case 'preset_read': return 'habits.readDesc'.tr();
      case 'preset_sleep': return 'habits.sleepDesc'.tr();
      case 'preset_no_social': return 'habits.noSocialDesc'.tr();
      case 'preset_gratitude': return 'habits.gratitudeDesc'.tr();
      default: return habit.description;
    }
  }

  Future<void> _savePreset(Habit preset) async {
    if (_isPresetAlreadyAdded(preset)) return; // No permitir duplicados
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
      SoundService.instance.play(Sfx.plant, volume: 0.6);
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
      SoundService.instance.play(Sfx.plant, volume: 0.6);
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
                        // Lumi presenta la pantalla
                        LumiNote(
                          text: 'journal.habitsLumi'.tr(),
                          mood: LumiMood.excited,
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 24),

                        // Presets section
                        Text(
                          'habits.suggestedShort'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final tileWidth = (constraints.maxWidth - 12) / 2;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: List.generate(Habit.presets.length, (index) {
                                final preset = Habit.presets[index];
                                return SizedBox(
                                  width: tileWidth,
                                  child: _PresetTile(
                                    emoji: preset.emoji,
                                    title: _presetTitle(preset),
                                    description: _presetDescription(preset),
                                    color: preset.color,
                                    added: _isPresetAlreadyAdded(preset),
                                    onTap: () => _savePreset(preset),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: (50 * index).ms, duration: 350.ms)
                                    .scale(
                                      begin: const Offset(0.9, 0.9),
                                      end: const Offset(1, 1),
                                      delay: (50 * index).ms,
                                      duration: 350.ms,
                                      curve: Curves.easeOutBack,
                                    );
                              }),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Divider
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

                        // Custom form toggle / form
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
                          _buildCustomForm(isDark),
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

  Widget _buildCustomForm(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _selectedColor.withValues(alpha: isDark ? 0.2 : 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('habits.customize'.tr(),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 16),

          Text('habits.iconLabel'.tr(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _emojiOptions.map((emoji) {
              final sel = _selectedEmoji == emoji;
              return GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedEmoji = emoji); },
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

          Text('habits.habitColor'.tr(),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          HabitColorPicker(
            colors: _colorOptions,
            selected: _selectedColor,
            onSelected: (color) => setState(() => _selectedColor = color),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _titleController, onChanged: (_) => setState(() {}), maxLength: 40,
            style: TextStyle(fontSize: 15, color: isDark ? Colors.white : AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'habits.habitName'.tr(), labelStyle: const TextStyle(color: AppColors.textSecondary),
              hintText: 'habits.nameHintCustom'.tr(),
              hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
              filled: true, fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _selectedColor, width: 1.5)),
              counterStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _descController, maxLength: 80,
            style: TextStyle(fontSize: 15, color: isDark ? Colors.white : AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'habits.habitDesc'.tr(), labelStyle: const TextStyle(color: AppColors.textSecondary),
              hintText: 'habits.descHintCustom'.tr(),
              hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
              filled: true, fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _selectedColor, width: 1.5)),
              counterStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),

          // Preview
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
                    color: _selectedColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(_selectedEmoji, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_titleController.text.isNotEmpty ? _titleController.text : 'habits.preview'.tr(),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary)),
                      if (_descController.text.isNotEmpty)
                        Text(_descController.text,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _selectedColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text('habits.checkInXp'.tr(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _selectedColor)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Se dice el tope: si no, marcar el cuarto hábito y no ver XP
          // parece un fallo (y el XP de hábitos tiene tope por día para que
          // no se pueda farmear creando y borrando hábitos).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'habits.xpDailyCap'.tr(
                namedArgs: {'count': '${HabitXpQuota.maxPerDay}'},
              ),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('habits.createHabit'.tr(),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

/// Hábito sugerido como tarjeta: emoji grande, nombre y descripción.
class _PresetTile extends StatefulWidget {
  final String emoji;
  final String title;
  final String? description;
  final Color color;
  final bool added;
  final VoidCallback onTap;

  const _PresetTile({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.added,
    required this.onTap,
  });

  @override
  State<_PresetTile> createState() => _PresetTileState();
}

class _PresetTileState extends State<_PresetTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = JournalStyle.of(context);
    final color = widget.color;
    return Semantics(
      button: true,
      enabled: !widget.added,
      label: '${widget.title}. ${widget.description ?? ''}',
      hint: widget.added ? 'habits.alreadyAdded'.tr() : null,
      onTap: widget.added ? null : widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: widget.added ? null : (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.added ? null : widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.95 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: widget.added ? 0.55 : 1,
            child: Container(
              height: 150,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(s.paper, color, s.isDark ? 0.22 : 0.14)!,
                    s.paper,
                  ],
                ),
                border: Border.all(color: color.withValues(alpha: s.isDark ? 0.3 : 0.2)),
                boxShadow: s.paperShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: s.isDark ? 0.25 : 0.16),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 24))),
                      ),
                      const Spacer(),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.added ? s.inkSoft.withValues(alpha: 0.15) : color,
                        ),
                        child: Icon(
                          widget.added ? Icons.check_rounded : Icons.add_rounded,
                          size: 17,
                          color: widget.added ? s.inkSoft : Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, height: 1.2, fontWeight: FontWeight.w800, color: s.ink),
                  ),
                  if (widget.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.added ? 'habits.alreadyAdded'.tr() : widget.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: s.inkSoft),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
