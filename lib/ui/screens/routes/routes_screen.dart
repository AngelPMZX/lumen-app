import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/lumi.dart';
import '../../../data/models/routes_overview.dart';
import '../../../data/models/wellness_route.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/app_review_service.dart';
import '../../../domain/services/motion_service.dart';
import '../../../domain/services/routes_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/animated_particles_background.dart';
import '../../widgets/entrance.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import '../../widgets/route_complete_dialog.dart';
import 'lesson_screen.dart';
import 'widgets/continue_route_card.dart';
import 'widgets/lesson_path_map.dart';
import 'widgets/route_card.dart';
import 'widgets/route_progress_ring.dart';
import '../../widgets/min_tap_target.dart';

/// Pestaña de rutas: el menú (resumen, "continúa", filtros y tarjetas) y,
/// al elegir una ruta, su mapa de lecciones.
class RoutesScreen extends StatefulWidget {
  /// Solo para pruebas: rutas y progreso fijos, sin Firebase.
  @visibleForTesting
  final List<WellnessRoute>? previewRoutes;
  @visibleForTesting
  final Set<String>? previewCompleted;

  const RoutesScreen({super.key, this.previewRoutes, this.previewCompleted});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  WellnessRoute? _selectedRoute;
  Set<String> _completedLessons = {};
  List<WellnessRoute> _routes = [];
  bool _isLoading = true;
  String _loadedLocale = '';
  RouteFilter _filter = RouteFilter.all;

  bool get _preview => widget.previewRoutes != null;

  @override
  void initState() {
    super.initState();
    if (_preview) {
      _routes = widget.previewRoutes!;
      _completedLessons = widget.previewCompleted ?? {};
      _isLoading = false;
      return;
    }
    _loadProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_preview) return;
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

  Future<void> _loadProgress() async {
    if (_preview) return;
    try {
      final auth = context.read<AuthProvider>();
      final completed = await auth.getCompletedLessons();
      if (mounted) setState(() => _completedLessons = completed);
    } catch (e) {
      debugPrint('Error loading progress: $e');
    }
  }

  /// Al volver de una lección: trofeo si terminó la ruta, campanita si se
  /// desbloqueó una lección nueva.
  Future<void> _celebrateProgress(WellnessRoute route, int completedBefore) async {
    await _loadProgress();
    if (!mounted) return;
    final after = route.lessons.where((l) => _completedLessons.contains(l.id)).length;
    if (after <= completedBefore) return;
    final auth = context.read<AuthProvider>();
    await Future.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    if (after == route.lessons.length) {
      SoundService.instance.play(Sfx.routeComplete, volume: 0.75);
      AnalyticsService.instance.routeComplete(route.id);
      await RouteCompleteDialog.show(context, route);
      AppReviewService.instance.onHappyMoment('route_complete', auth);
    } else {
      SoundService.instance.play(Sfx.unlock, volume: 0.6);
    }
  }

  void _selectRoute(WellnessRoute route) {
    HapticFeedback.mediumImpact();
    SoundService.instance.play(Sfx.tapNode, volume: 0.6);
    setState(() => _selectedRoute = route);
  }

  void _backToRoutes() {
    HapticFeedback.lightImpact();
    setState(() => _selectedRoute = null);
  }

  /// "Continúa donde te quedaste": abre el mapa de fondo y la lección encima,
  /// así al volver se ve el desbloqueo en el mapa.
  void _continue(RouteProgress progress) {
    final next = progress.nextLesson;
    if (next == null) return;
    SoundService.instance.play(Sfx.tapNode, volume: 0.6);
    setState(() => _selectedRoute = progress.route);
    _openLesson(next, progress.route);
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
    final selected = _selectedRoute;

    return PopScope(
      // Atrás desde el mapa vuelve al menú en vez de salir de la app.
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && selected != null) _backToRoutes();
      },
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedParticlesBackground(
              particleCount: 15,
              maxShootingStars: isDark ? 2 : 0,
              particleColor: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : (selected?.color ?? AppColors.primary).withValues(alpha: 0.08),
            ),
            SafeArea(
              child: AnimatedSwitcher(
                duration: MotionService.reduced(context)
                    ? const Duration(milliseconds: 120)
                    : const Duration(milliseconds: 380),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(
                      begin: MotionService.reduced(context) ? 1.0 : 0.97,
                      end: 1.0,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _isLoading
                    ? _RoutesSkeleton(key: const ValueKey('loading'), isDark: isDark)
                    : selected == null
                        ? KeyedSubtree(
                            key: const ValueKey('menu'),
                            child: _buildMenu(isDark),
                          )
                        : KeyedSubtree(
                            key: ValueKey('map_${selected.id}'),
                            child: _buildLessonMap(selected, isDark),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MENÚ
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMenu(bool isDark) {
    final overview = RoutesOverview.compute(
      _routes,
      _completedLessons,
      archetypeId: _preview
          ? null
          : context.read<AuthProvider>().userModel?.archetype,
    );
    final suggested = overview.suggested;
    final visible = overview.filtered(_filter);
    final ink = isDark ? Colors.white : AppColors.textPrimary;

    return EntranceScope(
      // Al cambiar de filtro la lista se rehace: ahí sí vuelve a escalonarse.
      restartOn: _filter,
      child: RefreshIndicator(
        onRefresh: _loadProgress,
        child: CustomScrollView(
          key: const PageStorageKey('routes_menu'),
          physics: const AlwaysScrollableScrollPhysics(),
          // Construir un poco antes de que entren a la vista: al desplazarse
          // rápido no se ve el hueco mientras la tarjeta se arma.
          cacheExtent: 900,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              sliver: SliverList.list(
                children: [
                  // Encabezado con Lumi
                  Entrance(
                    slideY: -0.1,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  'routes.title'.tr(),
                                  style: TextStyle(
                                    fontSize: 26,
                                    height: 1.15,
                                    fontWeight: FontWeight.w900,
                                    color: ink,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'routes.chooseRoute'.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        LumiAvatar(
                          mood: overview.allDone ? LumiMood.proud : LumiMood.happy,
                          size: 62,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStats(overview, isDark),
                  const SizedBox(height: 18),
                  if (suggested != null)
                    Entrance(
                      delay: const Duration(milliseconds: 120),
                      duration: const Duration(milliseconds: 450),
                      slideY: 0.08,
                      child: ContinueRouteCard(
                        progress: suggested,
                        onContinue: () => _continue(suggested),
                      ),
                    )
                  else
                    Entrance(
                      delay: const Duration(milliseconds: 120),
                      duration: const Duration(milliseconds: 450),
                      child: _buildAllDone(isDark),
                    ),
                  const SizedBox(height: 24),
                  Semantics(
                    header: true,
                    child: Text(
                      'routes.allRoutes'.tr(),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildFilters(overview, isDark),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (visible.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyFilter(isDark))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final progress = visible[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ListEntrance(
                        index: i,
                        duration: const Duration(milliseconds: 380),
                        slideY: 0.06,
                        child: RouteCard(
                          key: ValueKey('${_filter.name}_${progress.route.id}'),
                          progress: progress,
                          isDark: isDark,
                          onTap: () => _selectRoute(progress.route),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(RoutesOverview overview, bool isDark) {
    final tiles = [
      (
        '📚',
        '${overview.lessonsCompleted}/${overview.lessonsTotal}',
        'routes.statLessons'.tr(),
        const Color(0xFF6366F1),
      ),
      (
        '🏆',
        '${overview.routesCompleted}',
        'routes.statRoutes'.tr(),
        const Color(0xFFF59E0B),
      ),
      (
        '⚡',
        '${overview.xpEarned}',
        'routes.statXp'.tr(),
        const Color(0xFF10B981),
      ),
    ];
    return Row(
      children: [
        for (int i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: ListEntrance(
              index: i,
              base: const Duration(milliseconds: 60),
              scaleFrom: 0.92,
              scaleCurve: Curves.easeOutBack,
              child: Semantics(
                label: '${tiles[i].$2} ${tiles[i].$3}',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: tiles[i].$4.withValues(alpha: isDark ? 0.25 : 0.15),
                    ),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: tiles[i].$4.withValues(alpha: 0.07),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Column(
                    children: [
                      Text(tiles[i].$1, style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tiles[i].$2,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tiles[i].$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilters(RoutesOverview overview, bool isDark) {
    final labels = {
      RouteFilter.all: 'routes.filterAll'.tr(),
      RouteFilter.inProgress: 'routes.filterInProgress'.tr(),
      RouteFilter.notStarted: 'routes.filterNew'.tr(),
      RouteFilter.completed: 'routes.filterDone'.tr(),
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final f in RouteFilter.values) ...[
            _FilterChip(
              label: labels[f]!,
              count: overview.count(f),
              selected: _filter == f,
              isDark: isDark,
              onTap: () {
                if (_filter == f) return;
                HapticFeedback.selectionClick();
                SoundService.instance.play(Sfx.toggleOn, volume: 0.4);
                setState(() => _filter = f);
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        children: [
          const LumiAvatar(mood: LumiMood.curious, size: 76),
          const SizedBox(height: 10),
          Text(
            'routes.emptyFilter'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildAllDone(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 52))
              .animate(onPlay: MotionService.loop(context, reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 1300.ms),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'routes.allDoneTitle'.tr(),
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'routes.allDoneBody'.tr(),
                  style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.white.withValues(alpha: 0.92)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAPA DE LECCIONES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLessonMap(WellnessRoute route, bool isDark) {
    final progress = RouteProgress.compute(route, _completedLessons);
    final ink = isDark ? Colors.white : AppColors.textPrimary;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 20, 0),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: MaterialLocalizations.of(context).backButtonTooltip,
                onTap: _backToRoutes,
                excludeSemantics: true,
                child: MinTapTarget(
                  onTap: _backToRoutes,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                      border: Border.all(color: route.color.withValues(alpha: 0.25)),
                      boxShadow: isDark
                          ? null
                          : [BoxShadow(color: route.color.withValues(alpha: 0.12), blurRadius: 10)],
                    ),
                    child: Icon(Icons.arrow_back_rounded, size: 20, color: ink),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              RouteProgressRing(
                progress: progress.fraction,
                color: progress.status == RouteStatus.completed ? const Color(0xFFF59E0B) : route.color,
                track: route.color.withValues(alpha: isDark ? 0.2 : 0.14),
                size: 52,
                stroke: 4,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [route.color, route.colorDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(child: Text(route.emoji, style: const TextStyle(fontSize: 20))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        route.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'routes.lessonsProgress'.tr(namedArgs: {
                            'completed': '${progress.completed}',
                            'total': '${progress.total}',
                          }),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.bolt_rounded, size: 14, color: const Color(0xFFF59E0B)),
                        Text(
                          '${progress.xpEarned}/${progress.xpTotal}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
                    onTrophyTap: () => RouteCompleteDialog.show(context, route),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.primary;
    final fg = selected
        ? Colors.white
        : (isDark ? Colors.white70 : AppColors.textPrimary);
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count',
      onTap: onTap,
      excludeSemantics: true,
      child: MinTapTarget(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(colors: [AppColors.primaryLight, primary])
                : null,
            color: selected ? null : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : (isDark ? Colors.white.withValues(alpha: 0.1) : primary.withValues(alpha: 0.12)),
            ),
            boxShadow: selected
                ? [BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
                : [BoxShadow(color: primary.withValues(alpha: 0), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : primary.withValues(alpha: isDark ? 0.25 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : (isDark ? Colors.white : primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mientras cargan las rutas: siluetas con un brillo que las recorre.
class _RoutesSkeleton extends StatelessWidget {
  final bool isDark;

  const _RoutesSkeleton({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);
    Widget block(double h, {double? w, double r = 18}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(r)),
        );
    final reduced = MotionService.reduced(context);
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(28, w: 220, r: 10),
          const SizedBox(height: 8),
          block(14, w: 260, r: 8),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: block(78)),
            const SizedBox(width: 10),
            Expanded(child: block(78)),
            const SizedBox(width: 10),
            Expanded(child: block(78)),
          ]),
          const SizedBox(height: 18),
          block(210, r: 28),
          const SizedBox(height: 24),
          block(112, r: 26),
          const SizedBox(height: 14),
          block(112, r: 26),
        ],
      ),
    );
    return Semantics(
      label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
      child: reduced
          ? content
          : content.animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 1400.ms,
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.7),
              ),
    );
  }
}
