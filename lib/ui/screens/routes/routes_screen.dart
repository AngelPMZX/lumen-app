import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/wellness_route.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/services/routes_service.dart';
import '../../widgets/animated_particles_background.dart';
import 'lesson_screen.dart';
import 'widgets/lesson_path_map.dart';
import '../../../domain/services/sound_service.dart';
import '../../../domain/services/analytics_service.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  WellnessRoute? _selectedRoute;
  Set<String> _completedLessons = {};
  List<WellnessRoute> _routes = [];
  bool _isLoading = true;
  String _loadedLocale = '';

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = context.locale.languageCode;
    if (_loadedLocale != currentLocale) {
      _loadedLocale = currentLocale;
      _loadRoutes();
    }
  }

  Future<void> _loadRoutes() async {
    try {
      final locale = context.locale.languageCode;
      final routes = await RoutesService().getRoutes(locale);
      if (mounted) setState(() { _routes = routes; _isLoading = false; });
    } catch (e) {
      debugPrint('Error loading routes: $e');
      if (mounted) setState(() { _routes = WellnessRoute.all; _isLoading = false; });
    }
  }

  /// Al volver de una lección: trofeo si terminó la ruta, campanita si se
  /// desbloqueó una lección nueva.
  Future<void> _celebrateProgress(WellnessRoute route, int completedBefore) async {
    await _loadProgress();
    if (!mounted) return;
    final after = route.lessons.where((l) => _completedLessons.contains(l.id)).length;
    if (after <= completedBefore) return;
    await Future.delayed(const Duration(milliseconds: 450));
    if (after == route.lessons.length) {
      SoundService.instance.play(Sfx.routeComplete, volume: 0.75);
      AnalyticsService.instance.routeComplete(route.id);
    } else {
      SoundService.instance.play(Sfx.unlock, volume: 0.6);
    }
  }

  Future<void> _loadProgress() async {
    try {
      final auth = context.read<AuthProvider>();
      final completed = await auth.getCompletedLessons();
      if (mounted) setState(() => _completedLessons = completed);
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
  }

  void _selectRoute(WellnessRoute route) {
    HapticFeedback.mediumImpact();
    setState(() => _selectedRoute = route);
  }

  void _backToRoutes() {
    HapticFeedback.lightImpact();
    setState(() => _selectedRoute = null);
  }

  Future<void> _openLesson(Lesson lesson, WellnessRoute route) async {
    HapticFeedback.mediumImpact();
    final completedBefore =
        route.lessons.where((l) => _completedLessons.contains(l.id)).length;
    final index = route.lessons.indexOf(lesson);
    final next = index >= 0 && index < route.lessons.length - 1
        ? route.lessons[index + 1]
        : null;
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(builder: (_) => LessonScreen(
        lesson: lesson,
        routeColor: route.color,
        routeEmoji: route.emoji,
        routeId: route.id,
        nextLesson: next,
      )),
    );
    if (!mounted) return;
    if (result == LessonScreen.nextResult && next != null) {
      // La siguiente ya está desbloqueada: completar esta la abrió.
      await _loadProgress();
      if (mounted) _openLesson(next, route);
    } else if (result == true) {
      _celebrateProgress(route, completedBefore);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedParticlesBackground(
            particleCount: 15, maxShootingStars: isDark ? 2 : 0,
            particleColor: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : (_selectedRoute?.color ?? AppColors.primary).withValues(alpha: 0.08),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedRoute == null
                    ? _buildRoutesList(isDark)
                    : _buildLessonMap(isDark),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // LISTA DE RUTAS
  // ═══════════════════════════════════════════
  Widget _buildRoutesList(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('routes.title'.tr(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('routes.chooseRoute'.tr(),
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ...List.generate(_routes.length, (i) {
            final route = _routes[i];
            final completed = route.lessons.where((l) => _completedLessons.contains(l.id)).length;
            final progress = route.totalLessons > 0 ? completed / route.totalLessons : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () => _selectRoute(route),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [
                        route.color.withValues(alpha: isDark ? 0.15 : 0.08),
                        route.colorDark.withValues(alpha: isDark ? 0.08 : 0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: route.color.withValues(alpha: isDark ? 0.25 : 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: route.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18)),
                        child: Center(child: Text(route.emoji, style: const TextStyle(fontSize: 28))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── FIX overflow: maxLines + ellipsis ──
                            Text(
                              route.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              route.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : route.color.withValues(alpha: 0.15),
                                      valueColor: AlwaysStoppedAnimation<Color>(route.color),
                                      minHeight: 5),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('$completed/${route.totalLessons}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                        color: route.color)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, color: route.color, size: 24),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: (80 * i).ms, duration: 400.ms)
                .slideX(begin: -0.03, end: 0);
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // MAPA DE LECCIONES — ESTILO DUOLINGO
  // ═══════════════════════════════════════════
  Widget _buildLessonMap(bool isDark) {
    final route = _selectedRoute!;
    final lessons = route.lessons;
    final completed = lessons.where((l) => _completedLessons.contains(l.id)).length;
    final progress = lessons.isEmpty ? 0.0 : completed / lessons.length;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _backToRoutes),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [route.color, route.colorDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: route.color.withValues(alpha: 0.3),
                      blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Center(child: Text(route.emoji, style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary),
                    ),
                    Text('routes.lessonsProgress'.tr(namedArgs: {
                      'completed': '$completed',
                      'total': '${lessons.length}',
                    }),
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 7,
                          backgroundColor: route.color.withValues(alpha: isDark ? 0.15 : 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(route.color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Mapa con camino serpenteante
        Expanded(
          child: Stack(
            children: [
              // Tinte del color de la ruta arriba del mapa
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          route.color.withValues(alpha: isDark ? 0.10 : 0.07),
                          route.color.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 60),
                child: LayoutBuilder(
                  builder: (context, constraints) => LessonPathMap(
                    key: ValueKey(route.id),
                    route: route,
                    completedLessons: _completedLessons,
                    isDark: isDark,
                    width: constraints.maxWidth,
                    onOpenLesson: (lesson) => _openLesson(lesson, route),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
