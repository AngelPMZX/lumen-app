import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../data/models/habit.dart';
import '../../../data/models/journal_insights.dart';
import '../../../data/models/lumi.dart';
import '../../../data/models/reminder.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/notification_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/discovery_dialog.dart';
import '../../widgets/entrance.dart';
import '../../widgets/journal/journal_style.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import '../../widgets/min_tap_target.dart';
import '../routes/widgets/route_progress_ring.dart';
import 'add_habit_screen.dart';
import 'edit_reminder_screen.dart';
import 'reminder_sky.dart';

/// Hábitos del día (con racha y semana) y recordatorios con su "cielo".
class RemindersScreen extends StatefulWidget {
  /// Solo para pruebas: datos fijos, sin Firebase ni notificaciones.
  @visibleForTesting
  final List<Habit>? previewHabits;
  @visibleForTesting
  final Map<String, HabitHistory>? previewHistory;
  @visibleForTesting
  final List<Reminder>? previewReminders;

  const RemindersScreen({
    super.key,
    this.previewHabits,
    this.previewHistory,
    this.previewReminders,
  });

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> _reminders = [];
  List<Habit> _habits = [];
  Map<String, HabitHistory> _history = {};

  /// Marcados hoy (se actualiza al instante al tocar, antes de recargar).
  Set<String> _todayCheckIns = {};
  bool _isLoading = true;

  /// Hábito recién marcado: muestra destellos en su tarjeta.
  String? _burstHabit;
  int _burstSeed = 0;

  bool get _preview => widget.previewHabits != null;

  @override
  void initState() {
    super.initState();
    if (_preview) {
      _habits = widget.previewHabits!;
      _history = widget.previewHistory ?? {};
      _reminders = widget.previewReminders ?? [];
      _todayCheckIns = {for (final e in _history.entries) if (e.value.doneToday) e.key};
      _isLoading = false;
      return;
    }
    _loadAll();
    // Pedir permisos de notificación al abrir esta pantalla (no-op si ya están).
    _requestNotificationPermissions().then((_) {
      if (mounted) DiscoveryDialog.maybeShow(context, DiscoveryFeature.reminders);
    });
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      await NotificationService.instance.requestAllPermissions();
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> _loadAll() async {
    if (_preview) return;
    try {
      final auth = context.read<AuthProvider>();
      final results = await Future.wait([
        auth.getReminders(),
        auth.getHabits(),
        auth.getHabitHistory(),
      ]);
      if (!mounted) return;
      final history = results[2] as Map<String, HabitHistory>;
      setState(() {
        _reminders = results[0] as List<Reminder>;
        _habits = results[1] as List<Habit>;
        _history = history;
        _todayCheckIns = {for (final e in history.entries) if (e.value.doneToday) e.key};
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading habits/reminders: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Textos de hábitos predeterminados guardados en otro idioma ─────────────
  static const _presetKeys = {
    'Hacer ejercicio': 'habits.exercise',
    'Exercise': 'habits.exercise',
    'Tomar 2L de agua': 'habits.water',
    'Drink 2L of water': 'habits.water',
    'Escribir en el diario': 'habits.writeDiary',
    'Write in diary': 'habits.writeDiary',
    'Meditar 5 minutos': 'habits.meditate',
    'Meditate 5 minutes': 'habits.meditate',
    'Leer 15 minutos': 'habits.read',
    'Read 15 minutes': 'habits.read',
    'Dormir 8 horas': 'habits.sleep',
    'Sleep 8 hours': 'habits.sleep',
    'Sin redes 1 hora': 'habits.noSocial',
    'No social media 1 hour': 'habits.noSocial',
    'Practicar gratitud': 'habits.gratitude',
    'Practice gratitude': 'habits.gratitude',
  };

  static const _presetDescKeys = {
    '30 min de actividad física': 'habits.exerciseDesc',
    '30 min of physical activity': 'habits.exerciseDesc',
    'Hidrátate durante el día': 'habits.waterDesc',
    'Stay hydrated throughout the day': 'habits.waterDesc',
    'Reflexiona sobre tu día': 'habits.writeDiaryDesc',
    'Reflect on your day': 'habits.writeDiaryDesc',
    'Un momento de calma': 'habits.meditateDesc',
    'A moment of calm': 'habits.meditateDesc',
    'Alimenta tu mente': 'habits.readDesc',
    'Feed your mind': 'habits.readDesc',
    'Descansa bien': 'habits.sleepDesc',
    'Rest well': 'habits.sleepDesc',
    'Desconéctate un rato': 'habits.noSocialDesc',
    'Disconnect for a while': 'habits.noSocialDesc',
    '3 cosas que agradeces': 'habits.gratitudeDesc',
    "3 things you're grateful for": 'habits.gratitudeDesc',
  };

  String _habitTitle(Habit h) => _presetKeys[h.title]?.tr() ?? h.title;

  String? _habitDescription(Habit h) {
    final d = h.description;
    if (d == null) return null;
    return _presetDescKeys[d]?.tr() ?? d;
  }

  // ── Acciones: hábitos ──────────────────────────────────────────────────────
  Future<void> _toggleHabit(Habit habit) async {
    final wasChecked = _todayCheckIns.contains(habit.id);
    final allBefore = _habits.isNotEmpty && _habits.every((h) => _todayCheckIns.contains(h.id));

    // Respuesta inmediata en pantalla; si falla se revierte.
    setState(() {
      if (wasChecked) {
        _todayCheckIns.remove(habit.id);
      } else {
        _todayCheckIns.add(habit.id);
        _burstHabit = habit.id;
        _burstSeed++;
      }
    });

    final allNow = _habits.isNotEmpty && _habits.every((h) => _todayCheckIns.contains(h.id));
    if (wasChecked) {
      HapticFeedback.lightImpact();
      SoundService.instance.play(Sfx.toggleOff, volume: 0.45);
    } else if (allNow && !allBefore) {
      HapticFeedback.heavyImpact();
      SoundService.instance.play(Sfx.achievement, volume: 0.65);
    } else {
      HapticFeedback.mediumImpact();
      SoundService.instance.play(Sfx.habit, volume: 0.6);
    }

    if (_preview) return;
    final auth = context.read<AuthProvider>();
    try {
      if (wasChecked) {
        await auth.uncheckHabit(habit.id);
      } else {
        await auth.checkInHabit(habit.id);
        AnalyticsService.instance.habitCheckIn();
      }
      final history = await auth.getHabitHistory();
      if (mounted) setState(() => _history = history);
    } catch (e) {
      debugPrint('Error toggling habit: $e');
      if (mounted) {
        setState(() {
          if (wasChecked) {
            _todayCheckIns.add(habit.id);
          } else {
            _todayCheckIns.remove(habit.id);
          }
        });
      }
    }
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirm = await _confirmDelete(
      title: 'habits.deleteHabit'.tr(),
      body: 'habits.deleteConfirmWithHistory'.tr(namedArgs: {'title': _habitTitle(habit)}),
    );
    if (confirm != true || !mounted) return;
    await context.read<AuthProvider>().deleteHabit(habit.id);
    if (mounted) _loadAll();
  }

  Future<void> _addHabit() async {
    HapticFeedback.selectionClick();
    final existing = _habits.map((h) => h.title).toSet();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddHabitScreen(existingHabitTitles: existing)),
    );
    if (result == true) _loadAll();
  }

  // ── Acciones: recordatorios ────────────────────────────────────────────────
  Future<void> _schedule(Reminder r) => NotificationService.instance.scheduleReminder(
        reminderId: r.id,
        title: r.title,
        body: (r.message != null && r.message!.isNotEmpty) ? r.message! : 'reminders.defaultBody'.tr(),
        hour: r.timeInMinutes ~/ 60,
        minute: r.timeInMinutes % 60,
        repeatDays: r.repeatDays,
      );

  Future<void> _toggleReminder(Reminder reminder) async {
    HapticFeedback.lightImpact();
    final enable = !reminder.isEnabled;
    SoundService.instance.play(enable ? Sfx.toggleOn : Sfx.toggleOff, volume: 0.5);
    if (_preview) return;
    await context.read<AuthProvider>().toggleReminder(reminder.id, enable);
    try {
      if (enable) {
        await _schedule(reminder);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Text('🔔', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text('reminders.scheduled'.tr(), style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirm = await _confirmDelete(
      title: 'reminders.deleteReminder'.tr(),
      body: 'reminders.deleteConfirmNamed'.tr(namedArgs: {'title': reminder.title}),
    );
    if (confirm != true || !mounted) return;
    final auth = context.read<AuthProvider>();
    await NotificationService.instance.cancelReminder(reminder.id);
    await auth.deleteReminder(reminder.id);
    if (mounted) _loadAll();
  }

  Future<void> _editReminder([Reminder? reminder]) async {
    HapticFeedback.selectionClick();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditReminderScreen(reminder: reminder)),
    );
    if (result != true) return;
    await _loadAll();
    // Programa lo creado o reprograma lo editado
    final targets = reminder == null
        ? _reminders.where((r) => r.isEnabled)
        : _reminders.where((r) => r.id == reminder.id);
    for (final r in targets) {
      try {
        if (r.isEnabled) {
          await _schedule(r);
        } else {
          await NotificationService.instance.cancelReminder(r.id);
        }
      } catch (e) {
        debugPrint('Error scheduling reminder: $e');
      }
    }
  }

  Future<bool?> _confirmDelete({required String title, required String body}) {
    HapticFeedback.mediumImpact();
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('common.cancel'.tr())),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final s = JournalStyle.of(context);

    return Scaffold(
      backgroundColor: s.isDark ? null : const Color(0xFFFBF8F2),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: JournalStyle.accent))
            : RefreshIndicator(
                color: JournalStyle.accent,
                onRefresh: _loadAll,
                child: EntranceScope(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    // Construir un poco antes de que entren a la vista.
                    cacheExtent: 900,
                    children: [
                      _buildTopBar(s),
                      const SizedBox(height: 12),
                      Entrance(
                        delay: const Duration(milliseconds: 80),
                        duration: const Duration(milliseconds: 400),
                        slideY: 0.06,
                        child: _buildHabitsHero(s),
                      ),
                      const SizedBox(height: 16),
                      if (_habits.isEmpty)
                        _buildEmpty(
                          s,
                          mood: LumiMood.curious,
                          title: 'habits.emptyState'.tr(),
                          body: 'journal.habitsEmptyBody'.tr(),
                        )
                      else
                        for (int i = 0; i < _habits.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: Key(_habits[i].id),
                              direction: DismissDirection.endToStart,
                              background: _deleteBackground(),
                              confirmDismiss: (_) async {
                                _deleteHabit(_habits[i]);
                                return false;
                              },
                              child: _buildHabitCard(s, _habits[i], i),
                            ),
                          ),
                      _AddButton(
                        label: 'habits.addHabit'.tr(),
                        color: JournalStyle.accent,
                        onTap: _addHabit,
                      ),
                      if (_habits.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'habits.swipeToDelete'.tr(),
                            style: TextStyle(fontSize: 11.5, color: s.inkSoft, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                      _buildRemindersHeader(s),
                      const SizedBox(height: 12),
                      if (_reminders.isEmpty)
                        _buildEmpty(
                          s,
                          mood: LumiMood.sleepy,
                          title: 'reminders.emptyState'.tr(),
                          body: 'journal.remindersEmptyBody'.tr(),
                        )
                      else
                        for (int i = 0; i < _reminders.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: Key(_reminders[i].id),
                              direction: DismissDirection.endToStart,
                              background: _deleteBackground(),
                              confirmDismiss: (_) async {
                                _deleteReminder(_reminders[i]);
                                return false;
                              },
                              child: _buildReminderCard(s, _reminders[i], i),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar(JournalStyle s) {
    return Row(
      children: [
        if (Navigator.of(context).canPop())
          MinTapTarget(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back_rounded, color: s.ink, semanticLabel: MaterialLocalizations.of(context).backButtonTooltip),
          ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'journal.routinesKicker'.tr(),
                style: JournalStyle.hand(const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: JournalStyle.accent)),
              ),
              Semantics(
                header: true,
                child: Text(
                  'home.habitsReminders'.tr(),
                  style: TextStyle(fontSize: 23, height: 1.15, fontWeight: FontWeight.w900, color: s.ink),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildHabitsHero(JournalStyle s) {
    final total = _habits.length;
    final done = _habits.where((h) => _todayCheckIns.contains(h.id)).length;
    final allDone = total > 0 && done == total;
    final message = total == 0
        ? 'journal.habitsNone'.tr()
        : allDone
            ? 'journal.habitsAllDone'.tr()
            : done == 0
                ? 'journal.habitsStart'.tr()
                : 'journal.habitsLeft'.plural(total - done);
    final lumi = allDone ? LumiMood.excited : (done > 0 ? LumiMood.happy : LumiMood.curious);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: allDone
              ? const [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFEA580C)]
              : const [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF0F766E)],
        ),
        boxShadow: [
          BoxShadow(
            color: (allDone ? const Color(0xFFF59E0B) : JournalStyle.accent).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Semantics(
            label: 'habits.todayProgress'.tr(namedArgs: {'completed': '$done', 'total': '$total'}),
            excludeSemantics: true,
            child: RouteProgressRing(
              progress: total == 0 ? 0 : done / total,
              color: Colors.white,
              track: Colors.white.withValues(alpha: 0.25),
              size: 78,
              stroke: 7,
              child: Text(
                '$done/$total',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home.habitsToday'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    message,
                    key: ValueKey(message),
                    style: JournalStyle.hand(const TextStyle(fontSize: 20, height: 1.1, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
          LumiAvatar(mood: lumi, size: 58),
        ],
      ),
    );
  }

  Widget _buildHabitCard(JournalStyle s, Habit habit, int index) {
    final checked = _todayCheckIns.contains(habit.id);
    // Historial con hoy según lo que se ve en pantalla (se marca al instante,
    // antes de que termine de recargar).
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = {...?_history[habit.id]?.doneDays};
    checked ? days.add(today) : days.remove(today);
    final history = HabitHistory(days, now: now);
    final streak = history.streak;
    final week = history.lastWeek;
    final title = _habitTitle(habit);
    final description = _habitDescription(habit);
    final color = habit.color;
    const dayKeys = ['days.monMini', 'days.tueMini', 'days.wedMini', 'days.thuMini', 'days.friMini', 'days.satMini', 'days.sunMini'];

    return ListEntrance(
      index: index,
      slideY: 0.06,
      child: Semantics(
        button: true,
        checked: checked,
        label: '$title${description == null ? '' : ', $description'}',
        hint: streak >= 2 ? 'journal.streakDays'.plural(streak) : null,
        onTap: () => _toggleHabit(habit),
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () => _toggleHabit(habit),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            decoration: BoxDecoration(
              color: checked
                  ? Color.lerp(s.paper, color, s.isDark ? 0.16 : 0.1)
                  : s.paper,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: checked ? color.withValues(alpha: 0.5) : s.paperEdge,
                width: checked ? 1.6 : 1,
              ),
              boxShadow: s.paperShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(17),
                              color: checked ? color : color.withValues(alpha: s.isDark ? 0.18 : 0.12),
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                                child: checked
                                    ? const Icon(Icons.check_rounded, key: ValueKey('c'), color: Colors.white, size: 30)
                                    : Text(habit.emoji, key: const ValueKey('e'), style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                          ),
                          if (_burstHabit == habit.id && checked)
                            Positioned(
                              child: SparkleBurst(key: ValueKey('burst_$_burstSeed'), color: color, size: 110, seed: _burstSeed),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: s.ink),
                          ),
                          if (description != null && description.isNotEmpty)
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12.5, color: s.inkSoft),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (streak >= 2)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withValues(alpha: s.isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '🔥 $streak',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: s.isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
                          ),
                        ),
                      )
                    else if (!checked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'habits.checkInXp'.tr(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color.lerp(color, s.isDark ? Colors.white : Colors.black, 0.2)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Semana: 7 puntos, hoy a la derecha
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int i = 0; i < 7; i++)
                      () {
                        final (day, done) = week[i];
                        final isToday = i == 6;
                        return Column(
                          children: [
                            Text(
                              dayKeys[day.weekday - 1].tr(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                                color: isToday ? s.ink : s.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 3),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              width: isToday ? 22 : 18,
                              height: isToday ? 22 : 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done ? color : Colors.transparent,
                                border: Border.all(
                                  color: done ? color : s.inkSoft.withValues(alpha: 0.3),
                                  width: isToday ? 2 : 1.3,
                                ),
                              ),
                              child: done ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
                            ),
                          ],
                        );
                      }(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemindersHeader(JournalStyle s) {
    final active = _reminders.where((r) => r.isEnabled).length;
    return Row(
      children: [
        const Text('🔔', style: TextStyle(fontSize: 22)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text('reminders.title'.tr(), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: s.ink)),
              ),
              Text(
                _reminders.isEmpty
                    ? 'reminders.scheduleWellbeingAlerts'.tr()
                    : 'reminders.activeCount'.tr(namedArgs: {'count': '$active'}),
                style: TextStyle(fontSize: 12.5, color: s.inkSoft),
              ),
            ],
          ),
        ),
        MinTapTarget(
          onTap: () => _editReminder(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF818CF8), Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_alarm_rounded, color: Colors.white, size: 17),
                const SizedBox(width: 5),
                Text('common.new'.tr(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(JournalStyle s, Reminder reminder, int index) {
    final sky = ReminderSky.of(reminder.time.hour, isDark: s.isDark);
    final enabled = reminder.isEnabled;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(reminder.time, alwaysUse24HourFormat: false);
    const dayKeys = ['days.monMini', 'days.tueMini', 'days.wedMini', 'days.thuMini', 'days.friMini', 'days.satMini', 'days.sunMini'];
    // Sin días de repetición = una sola vez
    final onceOnly = reminder.repeatDays.isEmpty;

    return ListEntrance(
      index: index,
      slideY: 0.06,
      child: Semantics(
        button: true,
        label: '$time, ${reminder.title}',
        child: GestureDetector(
          onTap: () => _editReminder(reminder),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: enabled ? 1 : 0.55,
            child: Container(
              decoration: BoxDecoration(
                color: s.paper,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: enabled ? sky.colors.last.withValues(alpha: 0.35) : s.paperEdge),
                boxShadow: s.paperShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Row(
                  children: [
                    ReminderSkyTile(sky: sky, width: 78, height: 110, enabled: enabled),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              time,
                              style: TextStyle(fontSize: 24, height: 1.1, fontWeight: FontWeight.w900, color: s.ink),
                            ),
                            Text(
                              reminder.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: s.ink),
                            ),
                            if (reminder.message != null && reminder.message!.isNotEmpty)
                              Text(
                                reminder.message!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: JournalStyle.hand(TextStyle(fontSize: 16, color: s.inkSoft)),
                              ),
                            const SizedBox(height: 6),
                            if (onceOnly)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: sky.accent.withValues(alpha: s.isDark ? 0.3 : 0.16),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'reminders.once'.tr(),
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.ink),
                                ),
                              )
                            else
                              Row(
                                children: [
                                  for (int d = 1; d <= 7; d++)
                                    Container(
                                      margin: const EdgeInsets.only(right: 3),
                                      width: 19,
                                      height: 19,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: reminder.repeatDays.contains(d)
                                            ? sky.accent.withValues(alpha: s.isDark ? 0.4 : 0.22)
                                            : Colors.transparent,
                                      ),
                                      child: Center(
                                        child: Text(
                                          dayKeys[d - 1].tr(),
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: reminder.repeatDays.contains(d) ? s.ink : s.inkSoft.withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: enabled,
                      onChanged: (_) => _toggleReminder(reminder),
                      activeThumbColor: sky.accent,
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(JournalStyle s, {required LumiMood mood, required String title, required String body}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          LumiAvatar(mood: mood, size: 72),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: JournalStyle.hand(TextStyle(fontSize: 23, fontWeight: FontWeight.w700, color: s.ink)),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.45, color: s.inkSoft),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _deleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 24),
    );
  }
}

/// Botón punteado para agregar.
class _AddButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AddButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = JournalStyle.of(context);
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedBorderPainter(color: color.withValues(alpha: 0.55)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: s.isDark ? 0.06 : 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_rounded, color: color, size: 22),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color.lerp(color, Colors.black, s.isDark ? 0 : 0.2))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20));
    final path = Path()..addRRect(rrect.deflate(1));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 12) {
        canvas.drawPath(m.extractPath(d, d + 7), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
