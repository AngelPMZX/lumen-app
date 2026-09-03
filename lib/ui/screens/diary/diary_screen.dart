import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/diary_entry.dart';
import '../../../data/models/mood_entry.dart';
import '../../../domain/providers/auth_provider.dart';
import 'new_diary_entry_screen.dart';
import 'diary_detail_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<DiaryEntry> _entries = [];
  Map<DateTime, MoodType> _calendarMoods = {};
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  DateTime _focusedDay = DateTime.now();
  // Inicia con hoy seleccionado — muestra solo las entradas de hoy al abrir
  DateTime? _selectedDay = DateTime.now();

  int _lastKnownDiaryVersion = -1;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentVersion = context.watch<AuthProvider>().diaryVersion;
    if (currentVersion != _lastKnownDiaryVersion) {
      _lastKnownDiaryVersion = currentVersion;
      if (currentVersion > 0) {
        _loadEntries();
      }
    }
  }

  Future<void> _loadEntries() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final entries = await authProvider.getDiaryEntries();
      final moods = await authProvider.getDiaryCalendarMoods(
        DateTime(_focusedDay.year, _focusedDay.month, 1),
        DateTime(_focusedDay.year, _focusedDay.month + 1, 0),
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

  Future<void> _navigateToNewEntry() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NewDiaryEntryScreen()),
    );
    if (result == true) {
      _loadEntries();
    }
  }

  Future<void> _navigateToDetail(DiaryEntry entry) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DiaryDetailScreen(entry: entry)),
    );
    if (result == true) {
      _loadEntries();
    }
  }

  String _calendarLocale() {
    final locale = context.locale;
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode}';
    }
    return locale.languageCode == 'es' ? 'es_ES' : 'en_US';
  }

  String _moodLabel(MoodType mood) {
    final key = 'mood.${mood.name}';
    final translated = key.tr();
    return translated == key ? mood.label : translated;
  }

  String _entryCountText() {
    if (_entries.length == 1) {
      return 'diary.entrySingular'.tr(namedArgs: {'count': '1'});
    }
    return 'diary.entryPlural'.tr(
      namedArgs: {'count': _entries.length.toString()},
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'diary.timeAgoMinutes'.tr(
          namedArgs: {'count': diff.inMinutes.toString()},
        );
      }
      return 'diary.timeAgoHours'.tr(
        namedArgs: {'count': diff.inHours.toString()},
      );
    }

    if (diff.inDays == 1) return 'diary.yesterday'.tr();
    if (diff.inDays < 7) {
      return 'diary.timeAgoDays'.tr(
        namedArgs: {'count': diff.inDays.toString()},
      );
    }

    return DateFormat('d MMM', _calendarLocale()).format(date);
  }

  // Título de la sección según el filtro activo
  String get _sectionTitle {
    if (_selectedDay == null) return 'diary.recentEntries'.tr();
    if (_isToday(_selectedDay!)) {
      return context.locale.languageCode == 'es' ? 'Hoy' : 'Today';
    }
    return DateFormat('d MMMM', _calendarLocale()).format(_selectedDay!);
  }

  // Texto del botón toggle
  String get _toggleButtonLabel {
    if (_selectedDay == null) {
      return context.locale.languageCode == 'es' ? 'Ver hoy' : 'Today';
    }
    return context.locale.languageCode == 'es' ? 'Ver todas' : 'See all';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtrar entradas por fecha seleccionada
    final displayEntries = _selectedDay == null
        ? _entries
        : _entries
            .where((e) =>
                e.createdAt.year == _selectedDay!.year &&
                e.createdAt.month == _selectedDay!.month &&
                e.createdAt.day == _selectedDay!.day)
            .toList();

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // ── Header ─────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.book_rounded,
                              color: Color(0xFF10B981),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'diary.screenTitle'.tr(),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  _entryCountText(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Calendario ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
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
                        child: TableCalendar(
                          locale: _calendarLocale(),
                          firstDay: DateTime(2024, 1, 1),
                          lastDay: DateTime(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              // Toca la misma fecha → quita el filtro
                              if (isSameDay(_selectedDay, selectedDay)) {
                                _selectedDay = null;
                              } else {
                                _selectedDay = selectedDay;
                              }
                              _focusedDay = focusedDay;
                            });
                          },
                          onFormatChanged: (format) {
                            setState(() => _calendarFormat = format);
                          },
                          onPageChanged: (focusedDay) {
                            _focusedDay = focusedDay;
                            _loadEntries();
                          },
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            defaultTextStyle: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textPrimary,
                              fontSize: 13,
                            ),
                            weekendTextStyle: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            outsideTextStyle: TextStyle(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            todayTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            selectedTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: true,
                            titleCentered: true,
                            formatButtonDecoration: BoxDecoration(
                              border: Border.all(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            formatButtonTextStyle: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                            titleTextStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left_rounded,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right_rounded,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.textSecondary,
                            ),
                            weekendStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.grey.shade400,
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              final normalizedDate = DateTime(
                                  date.year, date.month, date.day);
                              final mood = _calendarMoods[normalizedDate];
                              if (mood != null) {
                                return Positioned(
                                  bottom: 1,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: mood.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Título + botón toggle ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _sectionTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          // Toggle: "Ver todas" ↔ "Ver hoy"
                          GestureDetector(
                            onTap: () => setState(() {
                              if (_selectedDay == null) {
                                _selectedDay = DateTime.now();
                                _focusedDay = _selectedDay!;
                              } else {
                                _selectedDay = null;
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _toggleButtonLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Lista de entradas ──────────────────────────────────────
                  displayEntries.isEmpty
                      ? SliverToBoxAdapter(
                          child: _selectedDay != null
                              ? _buildEmptyFilterState(isDark)
                              : _buildEmptyState(isDark),
                        )
                      : SliverPadding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry = displayEntries[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: _buildEntryCard(
                                      entry, isDark, index),
                                );
                              },
                              childCount: displayEntries.length,
                            ),
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToNewEntry,
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded),
        label: Text(
          'diary.newEntry'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981)
                  .withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Color(0xFF10B981),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'diary.emptyState'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'diary.emptyStateLongDesc'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.textSecondary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'diary.noEntriesMonth'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('d MMMM yyyy', _calendarLocale())
                .format(_selectedDay!),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(DiaryEntry entry, bool isDark, int index) {
    final timeAgo = _formatTimeAgo(entry.createdAt);

    return GestureDetector(
      onTap: () => _navigateToDetail(entry),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: entry.mood.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      entry.mood.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _moodLabel(entry.mood),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: entry.mood.color,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.text.length > 120
                  ? '${entry.text.substring(0, 120)}...'
                  : entry.text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            if (entry.gratitude != null &&
                entry.gratitude!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFF59E0B),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'diary.gratitudeTitle'.tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (100 * index).ms, duration: 400.ms)
        .slideX(begin: -0.05, end: 0);
  }
}