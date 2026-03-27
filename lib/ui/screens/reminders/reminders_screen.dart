import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/reminder.dart';
import '../../../data/models/habit.dart';
import '../../../domain/providers/auth_provider.dart';
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

  Future<void> _toggleHabitCheckIn(Habit habit) async {
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthProvider>();
    final isChecked = _todayCheckIns.contains(habit.id);
    try {
      if (isChecked) {
        await auth.uncheckHabit(habit.id);
        setState(() => _todayCheckIns.remove(habit.id));
      } else {
        await auth.checkInHabit(habit.id);
        setState(() => _todayCheckIns.add(habit.id));
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(habit.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text('${habit.title} completado. ¡+5 XP!',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
              backgroundColor: habit.color.withValues(alpha: 0.9),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar hábito', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('¿Eliminar "${habit.title}"? Se perderá el historial de este hábito.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Eliminar'),
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
        title: const Text('Eliminar recordatorio', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('¿Eliminar "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<AuthProvider>().deleteReminder(reminder.id);
      _loadAll();
    }
  }

  Future<void> _toggleReminder(Reminder reminder) async {
    HapticFeedback.lightImpact();
    await context.read<AuthProvider>().toggleReminder(reminder.id, !reminder.isEnabled);
    _loadAll();
  }

  Future<void> _navigateToAddHabit() async {
    final result = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => const AddHabitScreen()));
    if (result == true) _loadAll();
  }

  Future<void> _navigateToCreateReminder() async {
    final result = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => const EditReminderScreen()));
    if (result == true) _loadAll();
  }

  Future<void> _navigateToEditReminder(Reminder reminder) async {
    final result = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => EditReminderScreen(reminder: reminder)));
    if (result == true) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedCount = _habits.where((h) => _todayCheckIns.contains(h.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hábitos y Recordatorios',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Partículas de fondo
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
                      // ══════════════════════════════
                      // HÁBITOS HEADER
                      // ══════════════════════════════
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [const Color(0xFF10B981).withValues(alpha: 0.12),
                                   const Color(0xFF10B981).withValues(alpha: 0.04)]
                                : [const Color(0xFFECFDF5), const Color(0xFFF0FDF4)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
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
                                  Text('Hábitos de hoy',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _habits.isEmpty
                                        ? 'Agrega tu primer hábito'
                                        : '$completedCount de ${_habits.length} completados',
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (_habits.isNotEmpty)
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: completedCount == _habits.length && _habits.isNotEmpty
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$completedCount/${_habits.length}',
                                    style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w800,
                                      color: completedCount == _habits.length && _habits.isNotEmpty
                                          ? Colors.white
                                          : const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 500.ms),

                      // Progress bar
                      if (_habits.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: _habits.isEmpty ? 0 : completedCount / _habits.length,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            minHeight: 6,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Habit cards ──
                      if (_habits.isEmpty)
                        _buildEmptyState(
                          isDark: isDark,
                          icon: Icons.track_changes_rounded,
                          title: 'Aún no tienes hábitos',
                          subtitle: 'Crea hábitos para seguir tu progreso diario',
                          color: const Color(0xFF10B981),
                        )
                      else
                        ...List.generate(_habits.length, (i) {
                          final habit = _habits[i];
                          final isChecked = _todayCheckIns.contains(habit.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Dismissible(
                              key: Key(habit.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Icon(Icons.delete_rounded,
                                        color: Color(0xFFEF4444), size: 22),
                                    const SizedBox(width: 6),
                                    const Text('Eliminar',
                                        style: TextStyle(color: Color(0xFFEF4444),
                                            fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ),
                              confirmDismiss: (_) async {
                                _deleteHabit(habit);
                                return false;
                              },
                              child: _buildHabitCard(habit, isChecked, isDark, i),
                            ),
                          );
                        }),

                      // Botón agregar hábito
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _navigateToAddHabit,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.3 : 0.2),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.05 : 0.03),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_rounded, color: Color(0xFF10B981), size: 20),
                              const SizedBox(width: 8),
                              const Text('Agregar hábito',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text('Desliza a la izquierda para eliminar',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic)),
                      ),
                      const SizedBox(height: 32),

                      // ══════════════════════════════
                      // RECORDATORIOS HEADER
                      // ══════════════════════════════
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [AppColors.primary.withValues(alpha: 0.12),
                                   AppColors.primary.withValues(alpha: 0.04)]
                                : [const Color(0xFFEEF2FF), const Color(0xFFF5F3FF)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.notifications_active_rounded,
                                  color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Recordatorios',
                                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : AppColors.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _reminders.isEmpty
                                        ? 'Programa alertas de bienestar'
                                        : '${_reminders.where((r) => r.isEnabled).length} activos',
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _navigateToCreateReminder,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('Nuevo', style: TextStyle(fontSize: 12,
                                        fontWeight: FontWeight.w700, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                      const SizedBox(height: 14),

                      if (_reminders.isEmpty)
                        _buildEmptyState(
                          isDark: isDark,
                          icon: Icons.notifications_none_rounded,
                          title: 'Sin recordatorios',
                          subtitle: 'Las notificaciones se activarán en móvil',
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
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_rounded,
                                    color: Color(0xFFEF4444), size: 22),
                              ),
                              confirmDismiss: (_) async {
                                _deleteReminder(_reminders[i]);
                                return false;
                              },
                              child: _buildReminderCard(_reminders[i], isDark, i),
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

  Widget _buildHabitCard(Habit habit, bool isChecked, bool isDark, int index) {
    return GestureDetector(
      onTap: () => _toggleHabitCheckIn(habit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isChecked
              ? LinearGradient(colors: [
                  habit.color.withValues(alpha: isDark ? 0.2 : 0.12),
                  habit.color.withValues(alpha: isDark ? 0.1 : 0.06)])
              : null,
          color: isChecked ? null
              : isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isChecked
                ? habit.color.withValues(alpha: 0.3)
                : isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
          boxShadow: isChecked ? [
            BoxShadow(color: habit.color.withValues(alpha: 0.1),
                blurRadius: 8, offset: const Offset(0, 2)),
          ] : [],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isChecked ? habit.color
                    : habit.color.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isChecked ? [
                  BoxShadow(color: habit.color.withValues(alpha: 0.3),
                      blurRadius: 8, offset: const Offset(0, 2)),
                ] : [],
              ),
              child: Center(
                child: isChecked
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                    : Text(habit.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          decoration: isChecked ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.textSecondary)),
                  if (habit.description != null && habit.description!.isNotEmpty)
                    Text(habit.description!,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (!isChecked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: habit.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('+5 XP',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                        color: habit.color)),
              )
            else
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: habit.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: habit.color, size: 20),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (80 * index).ms, duration: 400.ms)
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
            color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: reminder.isEnabled
                  ? reminder.timeColor.withValues(alpha: isDark ? 0.2 : 0.15)
                  : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    reminder.timeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    reminder.timeColor.withValues(alpha: isDark ? 0.1 : 0.05)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(reminder.timeIcon, color: reminder.timeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(reminder.timeLabel,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                                color: reminder.isEnabled
                                    ? reminder.timeColor : AppColors.textSecondary)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(reminder.title,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.repeat_rounded, size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(reminder.repeatLabel,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        if (reminder.message != null && reminder.message!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(reminder.message!,
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic),
                                overflow: TextOverflow.ellipsis),
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
    required bool isDark, required IconData icon,
    required String title, required String subtitle, required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color.withValues(alpha: 0.5), size: 28),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}