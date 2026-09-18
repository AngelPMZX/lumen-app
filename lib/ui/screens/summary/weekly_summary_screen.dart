import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/weekly_summary.dart';
import '../../../data/models/wellness_route.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/routes_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../../domain/services/weekly_summary_service.dart';
import '../../widgets/crisis_support_card.dart';
import '../../widgets/entrance.dart';
import '../routes/lesson_screen.dart';
import '../../../domain/services/motion_service.dart';

/// "Tu semana en Lumen": ánimo, actividad, patrones personales y una lección
/// recomendada. Se calcula en el teléfono con los datos del usuario.
class WeeklySummaryScreen extends StatefulWidget {
  /// De dónde se abrió (home, profile), solo para Analytics.
  final String source;

  /// Solo para pruebas: muestra este resumen sin cargar nada de Firestore.
  @visibleForTesting
  final WeeklySummary? previewSummary;

  const WeeklySummaryScreen({super.key, this.source = 'unknown', this.previewSummary});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  static const _accent = Color(0xFF8B5CF6);

  WeeklySummary? _summary;
  (WellnessRoute, Lesson, Lesson?)? _recommendation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.previewSummary != null) {
      _summary = widget.previewSummary;
      _loading = false;
      return;
    }
    AnalyticsService.instance.weeklySummaryOpened(widget.source);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final locale = context.locale.languageCode;
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return;
    try {
      final results = await Future.wait([
        WeeklySummaryService.instance.build(uid),
        RoutesService().getRoutes(locale),
        auth.getCompletedLessons(),
      ]);
      final summary = results[0] as WeeklySummary;
      final routes = results[1] as List<WellnessRoute>;
      final completed = results[2] as Set<String>;
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _recommendation = _pickRecommendation(summary, routes, completed);
        _loading = false;
      });
      SoundService.instance.play(Sfx.unlock, volume: 0.45);
    } catch (e) {
      debugPrint('Weekly summary error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Primera lección sugerida para la emoción que más se repitió que el
  /// usuario pueda abrir (desbloqueada). Si ninguna lo está, la lección
  /// actual de esa ruta. Sin emoción difícil repetida: seguir donde se quedó.
  (WellnessRoute, Lesson, Lesson?)? _pickRecommendation(
    WeeklySummary summary,
    List<WellnessRoute> routes,
    Set<String> completed,
  ) {
    (WellnessRoute, int)? find(String lessonId) {
      for (final r in routes) {
        final i = r.lessons.indexWhere((l) => l.id == lessonId);
        if (i >= 0) return (r, i);
      }
      return null;
    }

    (WellnessRoute, Lesson, Lesson?) entry(WellnessRoute r, int i) =>
        (r, r.lessons[i], i + 1 < r.lessons.length ? r.lessons[i + 1] : null);

    int? currentIndex(WellnessRoute r) {
      final i = r.lessons.indexWhere((l) => !completed.contains(l.id));
      return i < 0 ? null : i;
    }

    final ids = WeeklySummary.recommendedLessons[summary.recurringHardMood];
    if (ids != null) {
      for (final id in ids) {
        final found = find(id);
        if (found == null) continue;
        final (route, i) = found;
        final unlocked = i == 0 || completed.contains(route.lessons[i - 1].id);
        if (unlocked && !completed.contains(route.lessons[i].id)) return entry(route, i);
      }
      // Todas completadas o bloqueadas: repasar la primera, o avanzar en su ruta
      final first = find(ids.first);
      if (first != null) {
        final (route, i) = first;
        if (completed.contains(route.lessons[i].id)) return entry(route, i);
        final current = currentIndex(route);
        if (current != null) return entry(route, current);
      }
    }

    // Seguir la ruta que ya tiene avance y no está terminada
    for (final r in routes) {
      final current = currentIndex(r);
      if (current != null && current > 0) return entry(r, current);
    }
    for (final r in routes) {
      final current = currentIndex(r);
      if (current != null) return entry(r, current);
    }
    return null;
  }

  Future<void> _openRecommendation() async {
    final rec = _recommendation;
    if (rec == null) return;
    final (route, lesson, next) = rec;
    HapticFeedback.mediumImpact();
    AnalyticsService.instance.weeklyRecommendationTapped(lesson.id);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          lesson: lesson,
          routeColor: route.color,
          routeEmoji: route.emoji,
          routeId: route.id,
        ),
      ),
    );
    if (next != null && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? Colors.white : AppColors.textPrimary;
    final sub = isDark ? Colors.white60 : AppColors.textSecondary;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _summary == null
                ? Center(child: Text('errors.loadFailed'.tr(), style: TextStyle(color: sub)))
                : _buildContent(_summary!, isDark, text, sub),
      ),
    );
  }

  Widget _buildContent(WeeklySummary s, bool isDark, Color text, Color sub) {
    final locale = Localizations.localeOf(context).toString();
    final firstDay = DateTime.parse(s.days.first);
    final lastDay = DateTime.parse(s.days.last);
    final range = '${DateFormat.MMMd(locale).format(firstDay)} – ${DateFormat.MMMd(locale).format(lastDay)}';

    var delay = 0;
    Widget reveal(Widget child) {
      delay += 90;
      return Entrance(
        delay: Duration(milliseconds: delay),
        duration: const Duration(milliseconds: 450),
        slideY: 0.08,
        child: child,
      );
    }

    return EntranceScope(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: text),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('summary.title'.tr(),
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: text)),
                    Text(range, style: TextStyle(fontSize: 13, color: sub)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          reveal(_buildHero(s, isDark)),
          const SizedBox(height: 16),
          reveal(_buildMoodStrip(s, isDark, text, sub)),
          const SizedBox(height: 22),
          reveal(_sectionTitle('summary.activityTitle'.tr(), text)),
          const SizedBox(height: 10),
          reveal(_buildStats(s, isDark, text, sub)),
          const SizedBox(height: 22),
          reveal(_sectionTitle('summary.insightsTitle'.tr(), text)),
          const SizedBox(height: 10),
          ..._buildInsights(s, isDark, text, sub).map(reveal),
          if (_recommendation != null) ...[
            const SizedBox(height: 22),
            reveal(_sectionTitle('summary.recommendationTitle'.tr(), text)),
            const SizedBox(height: 10),
            reveal(_buildRecommendation(s, isDark, text, sub)),
          ],
          if (s.negativeDays >= 4) ...[
            const SizedBox(height: 22),
            reveal(CrisisSupportCard(isDark: isDark)),
          ],
          const SizedBox(height: 22),
          reveal(_buildClosing(s, text, sub)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) => Text(
        title,
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
      );

  // ── Tarjeta principal ─────────────────────────────────────────────────────
  Widget _buildHero(WeeklySummary s, bool isDark) {
    final mood = s.dominantMood;
    final color = mood?.color ?? _accent;
    final (emoji, messageKey) = switch (s.trend) {
      MoodTrend.up => ('📈', 'summary.trend.up'),
      MoodTrend.same => ('〰️', 'summary.trend.same'),
      MoodTrend.down => ('🫂', 'summary.trend.down'),
      MoodTrend.unknown => (s.hasMoodData ? '🌱' : '🌤️', s.hasMoodData ? 'summary.trend.unknown' : 'summary.trend.noData'),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isDark ? 0.35 : 0.22),
            _accent.withValues(alpha: isDark ? 0.18 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.7),
            ),
            child: Center(
              child: Text(mood?.emoji ?? emoji, style: const TextStyle(fontSize: 38)),
            ),
          )
              .animate(onPlay: MotionService.loop(context, reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 1600.ms),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mood != null)
                  Text(
                    'summary.dominantMood'.tr(namedArgs: {'mood': mood.labelKey.tr()}),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '$emoji ${messageKey.tr()}',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Ánimo día a día ───────────────────────────────────────────────────────
  Widget _buildMoodStrip(WeeklySummary s, bool isDark, Color text, Color sub) {
    final locale = Localizations.localeOf(context).toString();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final day in s.days) _dayBubble(day, s, isDark, sub, locale),
            ],
          ),
          if (s.bestDay != null && s.checkInDays >= 3) ...[
            const SizedBox(height: 10),
            Text(
              'summary.bestDay'.tr(namedArgs: {
                'day': DateFormat.EEEE(locale).format(DateTime.parse(s.bestDay!)),
              }),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: sub),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dayBubble(String day, WeeklySummary s, bool isDark, Color sub, String locale) {
    final mood = s.dayMoods[day];
    final date = DateTime.parse(day);
    final isBest = day == s.bestDay && s.checkInDays >= 3;
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mood?.color.withValues(alpha: 0.18) ??
                (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100),
            border: Border.all(
              color: isBest
                  ? const Color(0xFFFBBF24)
                  : mood?.color.withValues(alpha: 0.5) ?? (isDark ? Colors.white12 : Colors.grey.shade300),
              width: isBest ? 2.5 : 1,
            ),
          ),
          child: Center(
            child: mood == null
                ? Icon(Icons.remove_rounded, size: 14, color: sub)
                : Text(mood.emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat.E(locale).format(date).substring(0, 2),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sub),
        ),
      ],
    );
  }

  // ── Actividad ─────────────────────────────────────────────────────────────
  Widget _buildStats(WeeklySummary s, bool isDark, Color text, Color sub) {
    final stats = [
      ('😊', '${s.checkInDays}/7', 'summary.stats.checkIns'.tr(), const Color(0xFF10B981)),
      ('📚', '${s.lessons}', 'summary.stats.lessons'.tr(), const Color(0xFF6366F1)),
      ('🌬️', '${s.breathingSessions}', 'summary.stats.breathing'.tr(), const Color(0xFF0EA5E9)),
      ('📔', '${s.diaryEntries}', 'summary.stats.diary'.tr(), const Color(0xFFF59E0B)),
      ('✅', '${s.habitsDone}', 'summary.stats.habits'.tr(), const Color(0xFF14B8A6)),
      ('🤝', '${s.commitmentsDone}', 'summary.stats.commitments'.tr(), const Color(0xFFEC4899)),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (emoji, value, label, color) in stats)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.14 : 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: text)),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(fontSize: 11, height: 1.2, color: sub),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Patrones ──────────────────────────────────────────────────────────────
  List<Widget> _buildInsights(WeeklySummary s, bool isDark, Color text, Color sub) {
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.grey.shade200;

    if (s.insights.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              const Text('🔭', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'summary.noInsights'.tr(),
                  style: TextStyle(fontSize: 14, height: 1.5, color: sub),
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      for (final insight in s.insights)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_activityEmoji(insight.activity), style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'summary.insight.${insight.activity.name}'.tr(),
                        style: TextStyle(fontSize: 15, height: 1.35, fontWeight: FontWeight.w800, color: text),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _comparisonBar('summary.withActivity'.tr(namedArgs: {'n': '${insight.daysWith}'}),
                    insight.moodWith, const Color(0xFF10B981), sub),
                const SizedBox(height: 6),
                _comparisonBar('summary.withoutActivity'.tr(namedArgs: {'n': '${insight.daysWithout}'}),
                    insight.moodWithout, Colors.grey, sub),
              ],
            ),
          ),
        ),
      Text(
        'summary.insightsDisclaimer'.tr(),
        style: TextStyle(fontSize: 11.5, height: 1.45, fontStyle: FontStyle.italic, color: sub),
      ),
    ];
  }

  Widget _comparisonBar(String label, double score, Color color, Color sub) {
    // Escala 1 (difícil) a 3 (positivo)
    final fraction = ((score - 1) / 2).clamp(0.05, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(fontSize: 11.5, color: sub)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                  begin: entranceFrom(context, fraction), end: fraction),
              duration:
                  entranceDuration(context, const Duration(milliseconds: 900)),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 9,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _activityEmoji(SummaryActivity a) => switch (a) {
        SummaryActivity.breathing => '🌬️',
        SummaryActivity.lesson => '📚',
        SummaryActivity.diary => '📔',
        SummaryActivity.habit => '✅',
      };

  // ── Recomendación ─────────────────────────────────────────────────────────
  Widget _buildRecommendation(WeeklySummary s, bool isDark, Color text, Color sub) {
    final (route, lesson, _) = _recommendation!;
    final mood = s.recurringHardMood;
    final reason = mood != null
        ? 'summary.recommendationReason'.tr(namedArgs: {'mood': mood.labelKey.tr().toLowerCase()})
        : 'summary.recommendationContinue'.tr();

    return GestureDetector(
      onTap: _openRecommendation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            route.color.withValues(alpha: isDark ? 0.3 : 0.18),
            route.colorDark.withValues(alpha: isDark ? 0.15 : 0.06),
          ]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: route.color.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason, style: TextStyle(fontSize: 13, height: 1.4, color: sub)),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [route.color, route.colorDark]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: Text(route.emoji, style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lesson.title,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: text)),
                      Text(route.title, style: TextStyle(fontSize: 12.5, color: sub)),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: route.color, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Cierre ────────────────────────────────────────────────────────────────
  Widget _buildClosing(WeeklySummary s, Color text, Color sub) {
    final key = s.totalActivities == 0
        ? 'summary.closing.quiet'
        : s.totalActivities < 6
            ? 'summary.closing.steps'
            : 'summary.closing.great';
    return Column(
      children: [
        Text(
          key.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w700, color: text),
        ),
        const SizedBox(height: 8),
        Text(
          'summary.privacy'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: sub),
        ),
      ],
    );
  }
}
