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
  DateTime? _selectedDay;

  // FIX: guardamos la última versión vista para detectar cambios
  int _lastKnownDiaryVersion = -1;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  /// didChangeDependencies se llama cada vez que el provider notifica.
  /// Solo recargamos si diaryVersion realmente cambió — evita recargas
  /// innecesarias por otros notifyListeners del AuthProvider.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentVersion =
        context.watch<AuthProvider>().diaryVersion;
    if (currentVersion != _lastKnownDiaryVersion) {
      _lastKnownDiaryVersion = currentVersion;
      // No recargar en la primera llamada (initState ya lo hace)
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
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
                              _selectedDay = selectedDay;
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
                              color:
                                  AppColors.primary.withValues(alpha: 0.3),
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'diary.recentEntries'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  _entries.isEmpty
                      ? SliverToBoxAdapter(
                          child: _buildEmptyState(isDark))
                      : SliverPadding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry = _entries[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 12),
                                  child: _buildEntryCard(
                                      entry, isDark, index),
                                );
                              },
                              childCount: _entries.length,
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
                  color:
                      const Color(0xFFF59E0B).withValues(alpha: 0.12),
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