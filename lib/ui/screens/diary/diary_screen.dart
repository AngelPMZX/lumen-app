import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../data/models/diary_entry.dart';
import '../../../data/models/journal_insights.dart';
import '../../../data/models/lumi.dart';
import '../../../data/models/mood_entry.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/services/motion_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/journal/journal_style.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import '../../widgets/min_tap_target.dart';
import '../crisis/crisis_support_screen.dart';
import 'diary_detail_screen.dart';
import 'new_diary_entry_screen.dart';

/// El diario: un rincón personal. Saludo de Lumi, la página de hoy, racha,
/// calendario de ánimo y las páginas agrupadas por día.
class DiaryScreen extends StatefulWidget {
  /// Solo para pruebas: entradas fijas, sin Firebase.
  @visibleForTesting
  final List<DiaryEntry>? previewEntries;
  @visibleForTesting
  final String? previewName;

  const DiaryScreen({super.key, this.previewEntries, this.previewName});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<DiaryEntry> _entries = [];
  Map<DateTime, MoodType> _calendarMoods = {};
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();

  /// null = ver todas las páginas.
  DateTime? _selectedDay;
  int _lastKnownDiaryVersion = -1;

  bool get _preview => widget.previewEntries != null;

  @override
  void initState() {
    super.initState();
    if (_preview) {
      _entries = widget.previewEntries!;
      _calendarMoods = {
        for (final e in _entries)
          DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day): e.mood,
      };
      _isLoading = false;
      return;
    }
    _loadEntries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preview) return;
    final currentVersion = context.watch<AuthProvider>().diaryVersion;
    if (currentVersion != _lastKnownDiaryVersion) {
      _lastKnownDiaryVersion = currentVersion;
      if (currentVersion > 0) _loadEntries();
    }
  }

  Future<void> _loadEntries() async {
    if (_preview) return;
    try {
      final auth = context.read<AuthProvider>();
      final entries = await auth.getDiaryEntries(limit: 120);
      final moods = await auth.getDiaryCalendarMoods(
        DateTime(_focusedDay.year, _focusedDay.month, 1),
        DateTime(_focusedDay.year, _focusedDay.month + 1, 1),
      );
      if (mounted) {
        setState(() {
          _entries = entries;
          _calendarMoods = moods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading diary entries: $e');
    }
  }

  Future<void> _write({String? promptKey}) async {
    HapticFeedback.mediumImpact();
    SoundService.instance.play(Sfx.pageTurn, volume: 0.7);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NewDiaryEntryScreen(initialPromptKey: promptKey)),
    );
    if (result == true) _loadEntries();
  }

  Future<void> _openEntry(DiaryEntry entry) async {
    HapticFeedback.selectionClick();
    SoundService.instance.play(Sfx.pageTurn, volume: 0.5);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DiaryDetailScreen(entry: entry)),
    );
    if (result == true) _loadEntries();
  }

  String get _locale {
    final l = context.locale;
    return l.countryCode?.isNotEmpty == true ? '${l.languageCode}_${l.countryCode}' : l.languageCode;
  }

  String _moodLabel(MoodType mood) {
    final key = 'mood.${mood.name}';
    final translated = key.tr();
    return translated == key ? mood.label : translated;
  }

  String get _greeting {
    final name = _preview
        ? (widget.previewName ?? '')
        : context.read<AuthProvider>().userName.split(' ').first;
    final hour = DateTime.now().hour;
    final key = hour < 12
        ? 'journal.greetingMorning'
        : hour < 19
            ? 'journal.greetingAfternoon'
            : 'journal.greetingNight';
    return name.isEmpty ? '${key}Plain'.tr() : key.tr(namedArgs: {'name': name});
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'journal.today'.tr();
    if (day == today.subtract(const Duration(days: 1))) return 'diary.yesterday'.tr();
    final text = DateFormat('EEEE d MMMM', _locale).format(day);
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final s = JournalStyle.of(context);
    final insights = DiaryInsights(_entries);
    final promptKey = DiaryPrompts.getRandomReflectionPromptKey();

    final groups = insights.groupedByDay
        .where((g) => _selectedDay == null || isSameDay(g.$1, _selectedDay))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: JournalStyle.accent))
            : RefreshIndicator(
                color: JournalStyle.accent,
                onRefresh: _loadEntries,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                      sliver: SliverToBoxAdapter(child: _buildHeader(s)),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      sliver: SliverList.list(children: [
                        LumiNote(
                          text: insights.wroteToday
                              ? 'journal.lumiThanks'.tr()
                              : promptKey.tr(),
                          mood: insights.wroteToday ? LumiMood.proud : LumiMood.curious,
                          onTap: insights.wroteToday ? null : () => _write(promptKey: promptKey),
                        ).animate().fadeIn(delay: 80.ms, duration: 400.ms).slideX(begin: -0.04, end: 0),
                        const SizedBox(height: 18),
                        _buildTodayPage(s, insights, promptKey),
                        const SizedBox(height: 18),
                        _buildStats(s, insights),
                        const SizedBox(height: 18),
                        _buildCalendar(s),
                        const SizedBox(height: 22),
                        _buildSectionHeader(s),
                        const SizedBox(height: 6),
                      ]),
                    ),
                    if (_entries.isEmpty)
                      SliverToBoxAdapter(child: _buildEmpty(s))
                    else if (groups.isEmpty)
                      SliverToBoxAdapter(child: _buildEmptyDay(s))
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                        sliver: SliverList.builder(
                          itemCount: groups.length,
                          itemBuilder: (context, gi) => _buildDayGroup(s, groups[gi], gi),
                        ),
                      ),
                    if (_entries.isEmpty || groups.isEmpty)
                      const SliverToBoxAdapter(child: SizedBox(height: 110)),
                  ],
                ),
              ),
      ),
      floatingActionButton: _isLoading ? null : _WriteButton(onTap: () => _write()),
    );
  }

  Widget _buildHeader(JournalStyle s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: JournalStyle.hand(const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: JournalStyle.accent,
                )),
              ),
              Semantics(
                header: true,
                child: Text(
                  'journal.title'.tr(),
                  style: TextStyle(fontSize: 26, height: 1.15, fontWeight: FontWeight.w900, color: s.ink),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.lock_rounded, size: 13, color: s.inkSoft),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'journal.privateSpace'.tr(),
                      style: TextStyle(fontSize: 13, color: s.inkSoft),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Acceso discreto a las líneas de ayuda
        IconButton(
          tooltip: 'crisis.card.title'.tr(),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrisisSupportScreen()),
          ),
          icon: Icon(
            Icons.volunteer_activism_rounded,
            size: 22,
            color: const Color(0xFF6C8FE8).withValues(alpha: s.isDark ? 0.9 : 0.8),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 350.ms);
  }

  /// La hoja de hoy: invita a escribir, o muestra lo que ya escribió.
  Widget _buildTodayPage(JournalStyle s, DiaryInsights insights, String promptKey) {
    final now = DateTime.now();
    final dateText = DateFormat('EEEE d MMMM', _locale).format(now);
    final todayGroup = insights.groupedByDay.where((g) => isSameDay(g.$1, now)).firstOrNull;
    final latest = todayGroup?.$2.first;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        JournalPaper(
          tint: s.paperFor(latest?.mood),
          padding: const EdgeInsets.fromLTRB(26, 22, 18, 18),
          firstLine: 58,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateText[0].toUpperCase() + dateText.substring(1),
                      style: JournalStyle.hand(TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: s.ink)),
                    ),
                  ),
                  if (latest != null)
                    Text(latest.mood.emoji, style: const TextStyle(fontSize: 26)),
                ],
              ),
              const SizedBox(height: 8),
              if (latest == null) ...[
                Text(
                  'journal.todayEmpty'.tr(),
                  style: JournalStyle.serif(TextStyle(fontSize: 15.5, height: 1.9, color: s.inkSoft)),
                ),
                const SizedBox(height: 14),
                _PenButton(
                  label: 'journal.writeToday'.tr(),
                  onTap: () => _write(promptKey: promptKey),
                ),
              ] else ...[
                Text(
                  latest.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: JournalStyle.serif(TextStyle(fontSize: 15.5, height: 1.9, color: s.ink)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, size: 15, color: JournalStyle.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        todayGroup!.$2.length == 1
                            ? 'journal.todayWrittenOne'.tr()
                            : 'journal.todayWrittenMany'.tr(namedArgs: {'n': '${todayGroup.$2.length}'}),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.inkSoft),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _write(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text('journal.writeAnother'.tr()),
                      style: TextButton.styleFrom(foregroundColor: JournalStyle.accentDeep),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Positioned(
          top: -9,
          left: 24,
          child: WashiTape(color: latest?.mood.color ?? JournalStyle.accent),
        ),
      ],
    ).animate().fadeIn(delay: 140.ms, duration: 450.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildStats(JournalStyle s, DiaryInsights insights) {
    final top = insights.topMood;
    final tiles = [
      ('🔥', '${insights.streak}', 'journal.statStreak'.tr()),
      ('📖', '${insights.entriesThisMonth}', 'journal.statMonth'.tr()),
      (top?.emoji ?? '🌱', top == null ? '—' : _moodLabel(top), 'journal.statMood'.tr()),
    ];
    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: '${tiles[i].$2} ${tiles[i].$3}',
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: s.paper,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: s.paperEdge),
                  boxShadow: s.paperShadow,
                ),
                child: Column(
                  children: [
                    Text(tiles[i].$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        tiles[i].$2,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: s.ink),
                      ),
                    ),
                    Text(
                      tiles[i].$3,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: s.inkSoft),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (200 + 60 * i).ms, duration: 350.ms).scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1, 1),
                  delay: (200 + 60 * i).ms,
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildCalendar(JournalStyle s) {
    Widget dayCell(DateTime day, {bool today = false, bool selected = false, bool outside = false}) {
      final mood = _calendarMoods[DateTime(day.year, day.month, day.day)];
      final fill = selected
          ? JournalStyle.accent
          : mood?.color.withValues(alpha: s.isDark ? 0.32 : 0.22);
      return Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: today && !selected ? Border.all(color: JournalStyle.accent, width: 2) : null,
          ),
          child: Center(
            child: mood != null && !selected
                ? Text(mood.emoji, style: const TextStyle(fontSize: 17))
                : Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: today || selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : outside
                              ? s.inkSoft.withValues(alpha: 0.4)
                              : s.ink,
                    ),
                  ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        color: s.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: s.paperEdge),
        boxShadow: s.paperShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('🗓️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'journal.calendarTitle'.tr(),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: s.ink),
                  ),
                ),
              ],
            ),
          ),
          TableCalendar(
            locale: _locale,
            firstDay: DateTime(2024, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            rowHeight: 44,
            availableCalendarFormats: {
              CalendarFormat.month: 'journal.calendarMonth'.tr(),
              CalendarFormat.twoWeeks: 'journal.calendarTwoWeeks'.tr(),
            },
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              HapticFeedback.selectionClick();
              SoundService.instance.play(Sfx.tick, volume: 0.35);
              setState(() {
                _selectedDay = isSameDay(_selectedDay, selected) ? null : selected;
                _focusedDay = focused;
              });
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            onPageChanged: (focused) {
              _focusedDay = focused;
              _loadEntries();
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) => dayCell(day),
              todayBuilder: (context, day, _) => dayCell(day, today: true),
              selectedBuilder: (context, day, _) =>
                  dayCell(day, selected: true, today: isSameDay(day, DateTime.now())),
              outsideBuilder: (context, day, _) => dayCell(day, outside: true),
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: true,
              formatButtonDecoration: BoxDecoration(
                color: JournalStyle.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              formatButtonTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: JournalStyle.accentDeep,
              ),
              titleTextStyle: JournalStyle.hand(TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: s.ink)),
              leftChevronIcon: Icon(Icons.chevron_left_rounded, color: s.inkSoft),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: s.inkSoft),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.inkSoft),
              weekendStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.inkSoft.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 260.ms, duration: 400.ms);
  }

  Widget _buildSectionHeader(JournalStyle s) {
    final filtering = _selectedDay != null;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              filtering ? _dayLabel(DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)) : 'journal.yourPages'.tr(),
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: s.ink),
            ),
          ),
        ),
        if (filtering)
          MinTapTarget(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDay = null);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: JournalStyle.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close_rounded, size: 14, color: JournalStyle.accentDeep),
                  const SizedBox(width: 4),
                  Text(
                    'journal.seeAll'.tr(),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: JournalStyle.accentDeep),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDayGroup(JournalStyle s, (DateTime, List<DiaryEntry>) group, int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _dayLabel(group.$1),
                style: JournalStyle.hand(const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: JournalStyle.accentDeep,
                )),
              ),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 1, color: s.paperEdge)),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in group.$2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EntryCard(
                entry: entry,
                moodLabel: _moodLabel(entry.mood),
                time: DateFormat.jm(_locale).format(entry.createdAt),
                onTap: () => _openEntry(entry),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: (60 * index.clamp(0, 6)).ms, duration: 380.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildEmpty(JournalStyle s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
      child: Column(
        children: [
          const LumiAvatar(mood: LumiMood.calm, size: 90),
          const SizedBox(height: 10),
          Text(
            'journal.emptyTitle'.tr(),
            textAlign: TextAlign.center,
            style: JournalStyle.hand(TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: s.ink)),
          ),
          const SizedBox(height: 6),
          Text(
            'journal.emptyBody'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: s.inkSoft),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildEmptyDay(JournalStyle s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
      child: Column(
        children: [
          const LumiAvatar(mood: LumiMood.sleepy, size: 70),
          const SizedBox(height: 8),
          Text(
            'journal.emptyDay'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: s.inkSoft),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// Una página del diario en la lista.
class _EntryCard extends StatefulWidget {
  final DiaryEntry entry;
  final String moodLabel;
  final String time;
  final VoidCallback onTap;

  const _EntryCard({
    required this.entry,
    required this.moodLabel,
    required this.time,
    required this.onTap,
  });

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = JournalStyle.of(context);
    final e = widget.entry;
    final hasGratitude = e.gratitude != null && e.gratitude!.isNotEmpty;

    return Semantics(
      button: true,
      label: '${widget.moodLabel}, ${widget.time}. ${e.text}',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            decoration: BoxDecoration(
              color: s.paperFor(e.mood),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: s.paperEdge),
              boxShadow: s.paperShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cinta del color del ánimo
                    Container(width: 6, color: e.mood.color.withValues(alpha: 0.75)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: e.mood.color.withValues(alpha: s.isDark ? 0.22 : 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(e.mood.emoji, style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 5),
                                      Text(
                                        widget.moodLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: s.isDark ? Color.lerp(e.mood.color, Colors.white, 0.3) : Color.lerp(e.mood.color, Colors.black, 0.25),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  widget.time,
                                  style: JournalStyle.hand(TextStyle(fontSize: 17, color: s.inkSoft)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              e.text,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: JournalStyle.serif(TextStyle(fontSize: 14.5, height: 1.6, color: s.ink)),
                            ),
                            if (hasGratitude) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: JournalStyle.sticky.withValues(alpha: s.isDark ? 0.18 : 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('💛', style: TextStyle(fontSize: 11)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'diary.gratitudeTitle'.tr(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: s.isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón con forma de pluma para empezar a escribir.
class _PenButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PenButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF34D399), JournalStyle.accentDeep]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: JournalStyle.accent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón flotante "Escribir" que respira suavemente.
class _WriteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _WriteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'diary.newEntry'.tr(),
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF34D399), JournalStyle.accentDeep]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: JournalStyle.accentDeep.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.draw_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                'journal.write'.tr(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
        ),
      )
          .animate(onPlay: MotionService.loop(context, reverse: true))
          .scale(begin: const Offset(1, 1), end: const Offset(1.04, 1.04), duration: 1600.ms, curve: Curves.easeInOut),
    );
  }
}

