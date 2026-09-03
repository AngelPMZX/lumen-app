import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/habit.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/services/notification_service.dart';
import '../../widgets/animated_particles_background.dart';
import 'edit_reminder_screen.dart';
import 'add_habit_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> _reminders = [];
  List<Habit> _habits = [];
  Set<String> _todayCheckIns = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
    // Pedir permisos de notificación al abrir esta pantalla.
    // Si ya están concedidos, no-op silencioso.
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      final granted =
          await NotificationService.instance.requestAllPermissions();
      debugPrint('🔔 Notification permissions granted: $granted');
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> _loadAll() async {
    try {
      final auth = context.read<AuthProvider>();
      final reminders = await auth.getReminders();
      final habits = await auth.getHabits();
      final checkIns = await auth.getTodayHabitCheckIns();
      if (mounted) {
        setState(() {
          _reminders = reminders;
          _habits = habits;
          _todayCheckIns = checkIns;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _localizedHabitTitle(Habit habit) {
    switch (habit.title) {
      case 'Hacer ejercicio':
      case 'Exercise':
        return 'habits.exercise'.tr();
      case 'Tomar 2L de agua':
      case 'Drink 2L of water':
        return 'habits.water'.tr();
      case 'Escribir en el diario':
      case 'Write in diary':
        return 'habits.writeDiary'.tr();
      case 'Meditar 5 minutos':
      case 'Meditate 5 minutes':
        return 'habits.meditate'.tr();
      case 'Leer 15 minutos':
      case 'Read 15 minutes':
        return 'habits.read'.tr();
      case 'Dormir 8 horas':
      case 'Sleep 8 hours':
        return 'habits.sleep'.tr();
      case 'Sin redes 1 hora':
      case 'No social media 1 hour':
        return 'habits.noSocial'.tr();
      case 'Practicar gratitud':
      case 'Practice gratitude':
        return 'habits.gratitude'.tr();
      default:
        return habit.title;
    }
  }

  String? _localizedHabitDescription(Habit habit) {
    switch (habit.description) {
      case '30 min de actividad física':
      case '30 min of physical activity':
        return 'habits.exerciseDesc'.tr();
      case 'Hidrátate durante el día':
      case 'Stay hydrated throughout the day':
        return 'habits.waterDesc'.tr();
      case 'Reflexiona sobre tu día':
      case 'Reflect on your day':
        return 'habits.writeDiaryDesc'.tr();
      case 'Un momento de calma':
      case 'A moment of calm':
        return 'habits.meditateDesc'.tr();
      case 'Alimenta tu mente':
      case 'Feed your mind':
        return 'habits.readDesc'.tr();
      case 'Descansa bien':
      case 'Rest well':
        return 'habits.sleepDesc'.tr();
      case 'Desconéctate un rato':
      case 'Disconnect for a while':
        return 'habits.noSocialDesc'.tr();
      case '3 cosas que agradeces':
      case "3 things you're grateful for":
        return 'habits.gratitudeDesc'.tr();
      case null:
        return null;
      default:
        return habit.description;
    }
  }

  String _repeatLabel(Reminder reminder) {
    if (reminder.repeatDays.isEmpty) return 'reminders.once'.tr();
    if (reminder.repeatDays.length == 7) return 'reminders.everyday'.tr();
    final weekdays = [1, 2, 3, 4, 5];
    final weekend = [6, 7];
    if (reminder.repeatDays.length == 5 &&
        weekdays.every((d) => reminder.repeatDays.contains(d))) {
      return 'reminders.weekdaysShort'.tr();
    }
    if (reminder.repeatDays.length == 2 &&
        weekend.every((d) => reminder.repeatDays.contains(d))) {
      return 'reminders.weekends'.tr();
    }
    final dayNames = {
      1: 'days.monShort'.tr(),
      2: 'days.tueShort'.tr(),
      3: 'days.wedShort'.tr(),
      4: 'days.thuShort'.tr(),
      5: 'days.friShort'.tr(),
      6: 'days.satShort'.tr(),
      7: 'days.sunShort'.tr(),
    };
    final sorted = List<int>.from(reminder.repeatDays)..sort();
    return sorted.map((d) => dayNames[d] ?? '').join(', ');
  }

  Future<void> _toggleHabitCheckIn(Habit habit) async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthProvider>();
    final isChecked = _todayCheckIns.contains(habit.id);
    final localizedTitle = _localizedHabitTitle(habit);

    try {
      if (isChecked) {
        await auth.uncheckHabit(habit.id);
        setState(() => _todayCheckIns.remove(habit.id));
      } else {
        final earnedXp = await auth.checkInHabit(habit.id);
        setState(() => _todayCheckIns.add(habit.id));
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(habit.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    earnedXp
                        ? 'habits.completedNamedXp'.tr(namedArgs: {'title': localizedTitle})
                        : 'habits.completedNamed'.tr(namedArgs: {'title': localizedTitle}),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: habit.color.withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling habit: $e');
    }
  }

  Future<void> _deleteHabit(Habit habit) async {
    final localizedTitle = _localizedHabitTitle(habit);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('habits.deleteHabit'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text('habits.deleteConfirmWithHistory'
            .tr(namedArgs: {'title': localizedTitle})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr(),
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<AuthProvider>().deleteHabit(habit.id);
      _loadAll();
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('reminders.deleteReminder'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text('reminders.deleteConfirmNamed'
            .tr(namedArgs: {'title': reminder.title})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr(),
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // Cancelar notificación local antes de borrar de Firestore
      await NotificationService.instance.cancelReminder(reminder.id);
      await context.read<AuthProvider>().deleteReminder(reminder.id);
      _loadAll();
    }
  }

  // ── Toggle con integración de NotificationService ─────────────────────────
  Future<void> _toggleReminder(Reminder reminder) async {
    HapticFeedback.lightImpact();
    final newEnabled = !reminder.isEnabled;

    // Actualizar en Firestore
    await context.read<AuthProvider>().toggleReminder(reminder.id, newEnabled);

    // Programar o cancelar la notificación local
    try {
      if (newEnabled) {
        final hour = reminder.timeInMinutes ~/ 60;
        final minute = reminder.timeInMinutes % 60;
        final body = (reminder.message != null && reminder.message!.isNotEmpty)
            ? reminder.message!
            : 'reminders.defaultBody'.tr();

        await NotificationService.instance.scheduleReminder(
          reminderId: reminder.id,
          title: reminder.title,
          body: body,
          hour: hour,
          minute: minute,
          repeatDays: reminder.repeatDays,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Text('🔔', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'reminders.scheduled'.tr(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ));
        }
      } else {
        await NotificationService.instance.cancelReminder(reminder.id);
      }
    } catch (e) {
      debugPrint('Error scheduling/canceling notification: $e');
    }

    _loadAll();
  }

  Future<void> _navigateToAddHabit() async {
    final existingTitles = _habits.map((h) => h.title).toSet();
    final result = await Navigator.push<bool>(context,
        MaterialPageRoute(
            builder: (_) =>
                AddHabitScreen(existingHabitTitles: existingTitles)));
    if (result == true) _loadAll();
  }

  Future<void> _navigateToCreateReminder() async {
    final result = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => const EditReminderScreen()));
    // Al crear un recordatorio, si viene habilitado lo programamos
    if (result == true) {
      await _loadAll();
      // Programar notificaciones de los recordatorios activos recién cargados
      for (final r in _reminders.where((r) => r.isEnabled)) {
        try {
          await NotificationService.instance.scheduleReminder(
            reminderId: r.id,
            title: r.title,
            body: (r.message != null && r.message!.isNotEmpty)
                ? r.message!
                : 'reminders.defaultBody'.tr(),
            hour: r.timeInMinutes ~/ 60,
            minute: r.timeInMinutes % 60,
            repeatDays: r.repeatDays,
          );
        } catch (e) {
          debugPrint('Error scheduling new reminder: $e');
        }
      }
    }
  }

  Future<void> _navigateToEditReminder(Reminder reminder) async {
    final result = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => EditReminderScreen(reminder: reminder)));
    if (result == true) {
      await _loadAll();
      // Re-programar este recordatorio con los nuevos datos
      final updated = _reminders.firstWhere(
        (r) => r.id == reminder.id,
        orElse: () => reminder,
      );
      if (updated.isEnabled) {
        try {
          await NotificationService.instance.scheduleReminder(
            reminderId: updated.id,
            title: updated.title,
            body: (updated.message != null && updated.message!.isNotEmpty)
                ? updated.message!
                : 'reminders.defaultBody'.tr(),
            hour: updated.timeInMinutes ~/ 60,
            minute: updated.timeInMinutes % 60,
            repeatDays: updated.repeatDays,
          );
        } catch (e) {
          debugPrint('Error rescheduling reminder: $e');
        }
      } else {
        await NotificationService.instance.cancelReminder(updated.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedCount =
        _habits.where((h) => _todayCheckIns.contains(h.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'home.habitsReminders'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          AnimatedParticlesBackground(
            particleCount: 12,
            maxShootingStars: 0,
            particleColor: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── HÁBITOS HEADER ─────────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFF10B981)
                                        .withValues(alpha: 0.12),
                                    const Color(0xFF10B981)
                                        .withValues(alpha: 0.04)
                                  ]
                                : [
                                    const Color(0xFFECFDF5),
                                    const Color(0xFFF0FDF4)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: isDark ? 0.2 : 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.track_changes_rounded,
                                  color: Color(0xFF10B981), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'home.habitsToday'.tr(),
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _habits.isEmpty
                                        ? 'habits.emptyStateDesc'.tr()
                                        : 'habits.todayProgress'.tr(namedArgs: {
                                            'completed': '$completedCount',
                                            'total': '${_habits.length}',
                                          }),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (_habits.isNotEmpty)
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: completedCount == _habits.length &&
                                          _habits.isNotEmpty
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF10B981)
                                          .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$completedCount/${_habits.length}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: completedCount == _habits.length &&
                                              _habits.isNotEmpty
                                          ? Colors.white
                                          : const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms),
                      if (_habits.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _habits.isEmpty
                                ? 0
                                : completedCount / _habits.length,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF10B981)),
                            minHeight: 6,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── LISTA DE HÁBITOS ────────────────────────────────────
                      if (_habits.isEmpty)
                        _buildEmptyState(
                          isDark: isDark,
                          icon: Icons.track_changes_rounded,
                          title: 'habits.emptyState'.tr(),
                          subtitle: 'habits.emptyTrackingDesc'.tr(),
                          color: const Color(0xFF10B981),
                        )
                      else
                        ...List.generate(_habits.length, (i) {
                          final habit = _habits[i];
                          final isChecked =
                              _todayCheckIns.contains(habit.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Dismissible(
                              key: Key(habit.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.end,
                                  children: [
                                    const Icon(Icons.delete_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 22),
                                    const SizedBox(width: 6),
                                    Text(
                                      'common.delete'.tr(),
                                      style: const TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              confirmDismiss: (_) async {
                                _deleteHabit(habit);
                                return false;
                              },
                              child: _buildHabitCard(
                                  habit, isChecked, isDark, i),
                            ),
                          );
                        }),

                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _navigateToAddHabit,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(
                                  alpha: isDark ? 0.3 : 0.2),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            color: const Color(0xFF10B981)
                                .withValues(alpha: isDark ? 0.05 : 0.03),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: Color(0xFF10B981), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'habits.addHabit'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'habits.swipeToDelete'.tr(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── RECORDATORIOS HEADER ────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    AppColors.primary
                                        .withValues(alpha: 0.12),
                                    AppColors.primary
                                        .withValues(alpha: 0.04)
                                  ]
                                : [
                                    const Color(0xFFEEF2FF),
                                    const Color(0xFFF5F3FF)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: AppColors.primary
                                  .withValues(alpha: isDark ? 0.2 : 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                  Icons.notifications_active_rounded,
                                  color: AppColors.primary,
                                  size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'reminders.title'.tr(),
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _reminders.isEmpty
                                        ? 'reminders.scheduleWellbeingAlerts'
                                            .tr()
                                        : 'reminders.activeCount'.tr(
                                            namedArgs: {
                                                'count':
                                                    '${_reminders.where((r) => r.isEnabled).length}',
                                              }),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _navigateToCreateReminder,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_rounded,
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'common.new'.tr(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                      const SizedBox(height: 12),

                      const SizedBox(height: 14),

                      // ── LISTA DE RECORDATORIOS ──────────────────────────────
                      if (_reminders.isEmpty)
                        _buildEmptyState(
                          isDark: isDark,
                          icon: Icons.notifications_none_rounded,
                          title: 'reminders.emptyState'.tr(),
                          subtitle: 'reminders.mobileInstallNote'.tr(),
                          color: AppColors.primary,
                        )
                      else
                        ...List.generate(_reminders.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Dismissible(
                              key: Key(_reminders[i].id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_rounded,
                                    color: Color(0xFFEF4444), size: 22),
                              ),
                              confirmDismiss: (_) async {
                                _deleteReminder(_reminders[i]);
                                return false;
                              },
                              child: _buildReminderCard(
                                  _reminders[i], isDark, i),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(
      Habit habit, bool isChecked, bool isDark, int index) {
    final localizedTitle = _localizedHabitTitle(habit);
    final localizedDescription = _localizedHabitDescription(habit);

    return GestureDetector(
      onTap: () => _toggleHabitCheckIn(habit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isChecked
              ? LinearGradient(colors: [
                  habit.color.withValues(alpha: isDark ? 0.2 : 0.12),
                  habit.color.withValues(alpha: isDark ? 0.1 : 0.06),
                ])
              : null,
          color: isChecked
              ? null
              : isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isChecked
                  ? habit.color.withValues(alpha: 0.3)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade200),
          boxShadow: isChecked
              ? [
                  BoxShadow(
                      color: habit.color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ]
              : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isChecked
                    ? habit.color
                    : habit.color
                        .withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isChecked
                    ? [
                        BoxShadow(
                            color: habit.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                      ]
                    : [],
              ),
              child: Center(
                child: isChecked
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 24)
                    : Text(habit.emoji,
                        style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizedTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      decoration:
                          isChecked ? TextDecoration.lineThrough : null,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                  if (localizedDescription != null &&
                      localizedDescription.isNotEmpty)
                    Text(
                      localizedDescription,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            if (!isChecked)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: habit.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'habits.checkInXp'.tr(),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: habit.color),
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: habit.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: habit.color, size: 20),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (80 * index).ms, duration: 400.ms)
        .slideX(begin: -0.05, end: 0);
  }

  Widget _buildReminderCard(Reminder reminder, bool isDark, int index) {
    return GestureDetector(
      onTap: () => _navigateToEditReminder(reminder),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: reminder.isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: reminder.isEnabled
                    ? reminder.timeColor
                        .withValues(alpha: isDark ? 0.2 : 0.15)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    reminder.timeColor
                        .withValues(alpha: isDark ? 0.25 : 0.15),
                    reminder.timeColor
                        .withValues(alpha: isDark ? 0.1 : 0.05),
                  ]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(reminder.timeIcon,
                    color: reminder.timeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          reminder.timeLabel,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: reminder.isEnabled
                                ? reminder.timeColor
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reminder.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.repeat_rounded,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _repeatLabel(reminder),
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                        if (reminder.message != null &&
                            reminder.message!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 12,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              reminder.message!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: reminder.isEnabled,
                onChanged: (_) => _toggleReminder(reminder),
                activeColor: reminder.timeColor,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (80 * index).ms, duration: 400.ms);
  }

  Widget _buildEmptyState({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child:
                Icon(icon, color: color.withValues(alpha: 0.5), size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}