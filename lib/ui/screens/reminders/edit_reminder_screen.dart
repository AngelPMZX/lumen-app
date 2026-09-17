import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reminder.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/animated_particles_background.dart';
import '../../widgets/journal/journal_style.dart';
import 'reminder_sky.dart';

class EditReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const EditReminderScreen({super.key, this.reminder});

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  late TimeOfDay _selectedTime;
  late List<int> _selectedDays;
  bool _isSaving = false;

  bool get _isEditing => widget.reminder != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder?.title ?? '');
    _messageController = TextEditingController(text: widget.reminder?.message ?? '');
    _selectedTime = widget.reminder?.time ?? const TimeOfDay(hour: 9, minute: 0);
    _selectedDays = List<int>.from(widget.reminder?.repeatDays ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  ReminderSky get _sky => ReminderSky.of(
        _selectedTime.hour,
        isDark: Theme.of(context).brightness == Brightness.dark,
      );

  Color get _currentTimeColor => _sky.accent;

  /// Mensajes sugeridos para no empezar en blanco.
  static const _suggestionKeys = [
    'journal.suggestBreathe',
    'journal.suggestCheckIn',
    'journal.suggestLesson',
    'journal.suggestWater',
    'journal.suggestDiary',
  ];

  IconData get _currentTimeIcon {
    if (_selectedTime.hour < 12) return Icons.wb_sunny_rounded;
    if (_selectedTime.hour < 18) return Icons.wb_twilight_rounded;
    return Icons.nightlight_round;
  }

  String get _currentTimePeriod => _sky.labelKey.tr();

  /// Devuelve 'AM' o 'PM' según la hora seleccionada (formato 12h)
  String get _amPmLabel => _selectedTime.hour < 12 ? 'AM' : 'PM';

  /// Convierte hora 24h a 12h para mostrar (1-12)
  int get _hour12 {
    final h = _selectedTime.hour % 12;
    return h == 0 ? 12 : h;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      // Forzar formato 12h con AM/PM sin importar el ajuste del sistema
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                hourMinuteTextStyle: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                ),
                dayPeriodTextStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      HapticFeedback.lightImpact();
      SoundService.instance.play(Sfx.pop, volume: 0.5);
      setState(() => _selectedTime = picked);
    }
  }

  void _toggleDay(int day) {
    HapticFeedback.lightImpact();
    SoundService.instance.play(_selectedDays.contains(day) ? Sfx.toggleOff : Sfx.toggleOn, volume: 0.4);
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  void _selectPreset(String preset) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (preset) {
        case 'everyday':
          _selectedDays = [1, 2, 3, 4, 5, 6, 7];
          break;
        case 'weekdays':
          _selectedDays = [1, 2, 3, 4, 5];
          break;
        case 'weekends':
          _selectedDays = [6, 7];
          break;
        case 'once':
          _selectedDays = [];
          break;
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave || _isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    try {
      final authProvider = context.read<AuthProvider>();
      final reminder = Reminder(
        id: widget.reminder?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim() : null,
        time: _selectedTime,
        repeatDays: _selectedDays,
        isEnabled: widget.reminder?.isEnabled ?? true,
        createdAt: widget.reminder?.createdAt,
      );
      await authProvider.saveReminder(reminder);
      SoundService.instance.play(Sfx.save, volume: 0.6);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(_currentTimeIcon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  _isEditing ? 'reminders.updated'.tr() : 'reminders.created'.tr(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: _currentTimeColor.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving reminder: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.errorWithDetails'.tr(namedArgs: {'error': '$e'})),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final h12 = _hour12.toString().padLeft(2, '0');
    final m = _selectedTime.minute.toString().padLeft(2, '0');

    return Scaffold(
      body: Stack(
        children: [
          AnimatedParticlesBackground(
            particleCount: 12,
            maxShootingStars: isDark ? 1 : 0,
            particleColor: isDark
                ? Colors.white.withValues(alpha: 0.25)
                : _currentTimeColor.withValues(alpha: 0.1),
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
                          _isEditing ? 'reminders.editReminder'.tr() : 'reminders.newReminderTitle'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: FilledButton(
                          onPressed: _canSave ? _save : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _currentTimeColor,
                            disabledBackgroundColor: _currentTimeColor.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _isEditing ? 'common.save'.tr() : 'common.create'.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          button: true,
                          label: '$_currentTimePeriod, $h12:$m $_amPmLabel. ${'reminders.tapToChangeTime'.tr()}',
                          onTap: _pickTime,
                          excludeSemantics: true,
                          child: GestureDetector(
                            onTap: _pickTime,
                            child: Container(
                              width: double.infinity,
                              height: 210,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: _currentTimeColor.withValues(alpha: 0.3),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 500),
                                      child: ReminderSkyTile(
                                        key: ValueKey(_sky.period),
                                        sky: _sky,
                                        width: double.infinity,
                                        height: 210,
                                        radius: 28,
                                      ),
                                    ),
                                  ),
                                  // Velo para que la hora se lea sobre cualquier cielo
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Colors.black.withValues(alpha: 0.0), Colors.black.withValues(alpha: 0.28)],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 20,
                                    top: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(_currentTimeIcon, color: Colors.white, size: 15),
                                          const SizedBox(width: 6),
                                          Text(
                                            _currentTimePeriod,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 20,
                                    right: 20,
                                    bottom: 18,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '$h12:$m',
                                              style: const TextStyle(
                                                fontSize: 60,
                                                height: 1,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                shadows: [Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Text(
                                                _amPmLabel,
                                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.touch_app_rounded, size: 14, color: Colors.white70),
                                            const SizedBox(width: 4),
                                            Text(
                                              'reminders.tapToChangeTime'.tr(),
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 350.ms).scale(
                              begin: const Offset(0.97, 0.97),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutCubic,
                            ),
                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.label_rounded, size: 18, color: _currentTimeColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'reminders.nameLabel'.tr(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _titleController,
                                onChanged: (_) => setState(() {}),
                                maxLength: 50,
                                style: TextStyle(fontSize: 15,
                                    color: isDark ? Colors.white : AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'reminders.customTitleHint'.tr(),
                                  hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: _currentTimeColor, width: 1.5),
                                  ),
                                  counterStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.chat_rounded, size: 18, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'reminders.reminderMessage'.tr(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _messageController,
                                onChanged: (_) => setState(() {}),
                                maxLines: 2,
                                maxLength: 150,
                                style: TextStyle(fontSize: 15,
                                    color: isDark ? Colors.white : AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'reminders.customMessageHint'.tr(),
                                  hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.grey.shade400),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: _currentTimeColor, width: 1.5),
                                  ),
                                  counterStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                              Text(
                                'journal.suggestionsLabel'.tr(),
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final key in _suggestionKeys)
                                    ActionChip(
                                      label: Text(key.tr()),
                                      labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary),
                                      backgroundColor: _currentTimeColor.withValues(alpha: isDark ? 0.14 : 0.08),
                                      side: BorderSide(color: _currentTimeColor.withValues(alpha: 0.25)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        SoundService.instance.play(Sfx.pop, volume: 0.4);
                                        setState(() {
                                          _messageController.text = key.tr();
                                          if (_titleController.text.trim().isEmpty) {
                                            _titleController.text = 'journal.suggestTitle'.tr();
                                          }
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.repeat_rounded, size: 18, color: _currentTimeColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'reminders.repeatLabelShort'.tr(),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                children: [
                                  _buildPresetChip('reminders.everyday'.tr(), 'everyday', _selectedDays.length == 7, isDark),
                                  _buildPresetChip(
                                    'reminders.weekdaysShort'.tr(),
                                    'weekdays',
                                    _selectedDays.length == 5 && [1, 2, 3, 4, 5].every((d) => _selectedDays.contains(d)),
                                    isDark,
                                  ),
                                  _buildPresetChip(
                                    'reminders.weekends'.tr(),
                                    'weekends',
                                    _selectedDays.length == 2 && [6, 7].every((d) => _selectedDays.contains(d)),
                                    isDark,
                                  ),
                                  _buildPresetChip('reminders.once'.tr(), 'once', _selectedDays.isEmpty, isDark),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildDayCircle('days.monMini'.tr(), 1, isDark),
                                  _buildDayCircle('days.tueMini'.tr(), 2, isDark),
                                  _buildDayCircle('days.wedMini'.tr(), 3, isDark),
                                  _buildDayCircle('days.thuMini'.tr(), 4, isDark),
                                  _buildDayCircle('days.friMini'.tr(), 5, isDark),
                                  _buildDayCircle('days.satMini'.tr(), 6, isDark),
                                  _buildDayCircle('days.sunMini'.tr(), 7, isDark),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'journal.previewLabel'.tr(),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        _buildNotificationPreview(isDark),
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

  /// Así se verá la notificación en el teléfono.
  Widget _buildNotificationPreview(bool isDark) {
    final title = _titleController.text.trim().isEmpty ? 'reminders.customTitleHint'.tr() : _titleController.text.trim();
    final body = _messageController.text.trim().isEmpty ? 'reminders.defaultBody'.tr() : _messageController.text.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2B3D) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF34D399), JournalStyle.accentDeep]),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Center(child: Text('🌱', style: TextStyle(fontSize: 19))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Lumen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                    const SizedBox(width: 6),
                    Text('· $_hour12:${_selectedTime.minute.toString().padLeft(2, '0')} $_amPmLabel',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(body, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13.5, height: 1.35, color: isDark ? Colors.white70 : AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPresetChip(String label, String preset, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () => _selectPreset(preset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _currentTimeColor.withValues(alpha: 0.15)
              : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _currentTimeColor.withValues(alpha: 0.4)
                : isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? _currentTimeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDayCircle(String label, int day, bool isDark) {
    final isSelected = _selectedDays.contains(day);
    return GestureDetector(
      onTap: () => _toggleDay(day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 42, height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? _currentTimeColor
              : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? _currentTimeColor
                : isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
            width: 1.5),
          boxShadow: isSelected ? [
            BoxShadow(color: _currentTimeColor.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1),
          ] : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}