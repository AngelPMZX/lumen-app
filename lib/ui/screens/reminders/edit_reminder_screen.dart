import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reminder.dart';
import '../../../domain/providers/auth_provider.dart';

class EditReminderScreen extends StatefulWidget {
  final Reminder? reminder; // null = crear nuevo

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
    _titleController =
        TextEditingController(text: widget.reminder?.title ?? '');
    _messageController =
        TextEditingController(text: widget.reminder?.message ?? '');
    _selectedTime =
        widget.reminder?.time ?? const TimeOfDay(hour: 9, minute: 0);
    _selectedDays = List<int>.from(widget.reminder?.repeatDays ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      HapticFeedback.lightImpact();
      setState(() => _selectedTime = picked);
    }
  }

  void _toggleDay(int day) {
    HapticFeedback.lightImpact();
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
        id: widget.reminder?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
        time: _selectedTime,
        repeatDays: _selectedDays,
        isEnabled: widget.reminder?.isEnabled ?? true,
        createdAt: widget.reminder?.createdAt,
      );

      await authProvider.saveReminder(reminder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  _isEditing
                      ? 'Recordatorio actualizado'
                      : 'Recordatorio creado',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            content: Text('Error: $e'),
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
    final h = _selectedTime.hour.toString().padLeft(2, '0');
    final m = _selectedTime.minute.toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar recordatorio' : 'Nuevo recordatorio',
            style: const TextStyle(fontWeight: FontWeight.w700)),
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
              onPressed: _canSave ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.3),
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
                          strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Guardar' : 'Crear',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Selector de hora ──
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                      AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.15)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$h:$m',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.primary,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Toca para cambiar la hora',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Nombre del recordatorio ──
            Text(
              'Nombre',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              maxLength: 50,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Ej: Check-in de la mañana',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.grey.shade400),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 1.5),
                ),
                counterStyle:
                    TextStyle(color: AppColors.textSecondary, fontSize: 11),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            // ── Mensaje personalizado ──
            Text(
              'Mensaje (opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              maxLines: 2,
              maxLength: 150,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Ej: Recuerda respirar y sonreír',
                hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.grey.shade400),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 1.5),
                ),
                counterStyle:
                    TextStyle(color: AppColors.textSecondary, fontSize: 11),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // ── Repetición ──
            Text(
              'Repetir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Presets rápidos
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('Todos los días', 'everyday',
                    _selectedDays.length == 7, isDark),
                _buildPresetChip('Lun-Vie', 'weekdays',
                    _selectedDays.length == 5 &&
                        [1, 2, 3, 4, 5]
                            .every((d) => _selectedDays.contains(d)),
                    isDark),
                _buildPresetChip(
                    'Fines de semana',
                    'weekends',
                    _selectedDays.length == 2 &&
                        [6, 7].every((d) => _selectedDays.contains(d)),
                    isDark),
                _buildPresetChip(
                    'Una sola vez', 'once', _selectedDays.isEmpty, isDark),
              ],
            ),
            const SizedBox(height: 16),

            // Selector de días individual
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDayCircle('L', 1, isDark),
                _buildDayCircle('M', 2, isDark),
                _buildDayCircle('Mi', 3, isDark),
                _buildDayCircle('J', 4, isDark),
                _buildDayCircle('V', 5, isDark),
                _buildDayCircle('S', 6, isDark),
                _buildDayCircle('D', 7, isDark),
              ],
            ),
            const SizedBox(height: 24),

            // ── Info sobre notificaciones en web ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Las notificaciones se activarán cuando instales la app en tu celular.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF1E40AF),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(
      String label, String preset, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () => _selectPreset(preset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary,
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? AppColors.primary
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.surface,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? Colors.white60
                      : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}