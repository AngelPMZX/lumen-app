import 'dart:math';
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

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen>
    with TickerProviderStateMixin {
  WellnessRoute? _selectedRoute;
  Set<String> _completedLessons = {};
  List<WellnessRoute> _routes = [];
  bool _isLoading = true;
  String _loadedLocale = '';

  // Animación de pulso para el nodo actual
  late AnimationController _pulseController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _loadProgress();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
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
    if (!_isLessonUnlocked(lesson, route)) return;
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => LessonScreen(
        lesson: lesson,
        routeColor: route.color,
        routeEmoji: route.emoji,
      )),
    );
    if (result == true) _loadProgress();
  }

  bool _isLessonUnlocked(Lesson lesson, WellnessRoute route) {
    final index = route.lessons.indexOf(lesson);
    if (index == 0) return true;
    return _completedLessons.contains(route.lessons[index - 1].id);
  }

  int _findCurrentLessonIndex(WellnessRoute route) {
    for (int i = 0; i < route.lessons.length; i++) {
      if (!_completedLessons.contains(route.lessons[i].id)) return i;
    }
    return -1; // Todas completadas
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
    final currentIndex = _findCurrentLessonIndex(route);

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
                      'completed': '${lessons.where((l) => _completedLessons.contains(l.id)).length}',
                      'total': '${lessons.length}',
                    }),
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Mapa con camino curvo
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 60),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return _buildCurvedPath(lessons, route, isDark, width, currentIndex);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurvedPath(
    List<Lesson> lessons,
    WellnessRoute route,
    bool isDark,
    double width,
    int currentIndex,
  ) {
    const nodeSize = 70.0;
    const verticalSpacing = 130.0;
    final totalHeight = (lessons.length - 1) * verticalSpacing + nodeSize + 80;
    final centerX = width / 2;
    const amplitude = 80.0;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          // Camino curvo (pintado con CustomPaint)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _CurvedPathPainter(
                    lessonCount: lessons.length,
                    completedLessons: _completedLessons,
                    lessons: lessons,
                    routeColor: route.color,
                    isDark: isDark,
                    centerX: centerX,
                    amplitude: amplitude,
                    verticalSpacing: verticalSpacing,
                    startY: nodeSize / 2 + 10,
                    glowProgress: _glowController.value,
                  ),
                );
              },
            ),
          ),

          // Nodos de lecciones
          ...List.generate(lessons.length, (index) {
            final lesson = lessons[index];
            final isCompleted = _completedLessons.contains(lesson.id);
            final isUnlocked = _isLessonUnlocked(lesson, route);
            final isCurrent = index == currentIndex;

            final t = index / (lessons.length > 1 ? lessons.length - 1 : 1);
            final sOffset = sin(t * pi * 2 - pi / 2) * amplitude;
            final x = centerX + sOffset - nodeSize / 2;
            final y = index * verticalSpacing + 10;

            return Positioned(
              left: x,
              top: y,
              child: _buildLessonNode(
                lesson: lesson,
                index: index,
                route: route,
                isCompleted: isCompleted,
                isUnlocked: isUnlocked,
                isCurrent: isCurrent,
                isDark: isDark,
                nodeSize: nodeSize,
              ).animate().fadeIn(
                delay: (120 * index).ms,
                duration: 500.ms,
              ).scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                delay: (120 * index).ms,
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLessonNode({
    required Lesson lesson,
    required int index,
    required WellnessRoute route,
    required bool isCompleted,
    required bool isUnlocked,
    required bool isCurrent,
    required bool isDark,
    required double nodeSize,
  }) {
    return GestureDetector(
      onTap: () => _openLesson(lesson, route),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: isCurrent ? _pulseController : const AlwaysStoppedAnimation(0),
            builder: (context, child) {
              final pulseScale = isCurrent ? 1.0 + _pulseController.value * 0.08 : 1.0;
              final glowAlpha = isCurrent ? 0.2 + _pulseController.value * 0.15 : 0.0;

              return Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isCompleted
                        ? LinearGradient(
                            colors: [route.color, route.colorDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : isCurrent
                            ? LinearGradient(
                                colors: [
                                  route.color.withValues(alpha: isDark ? 0.25 : 0.15),
                                  route.colorDark.withValues(alpha: isDark ? 0.15 : 0.08),
                                ],
                              )
                            : null,
                    color: !isCompleted && !isCurrent
                        ? isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.grey.shade200
                        : null,
                    border: isCurrent
                        ? Border.all(color: route.color, width: 3)
                        : isCompleted
                            ? null
                            : Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                    boxShadow: [
                      if (isCompleted)
                        BoxShadow(
                          color: route.color.withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      if (isCurrent)
                        BoxShadow(
                          color: route.color.withValues(alpha: glowAlpha),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                    ],
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 32)
                        : isCurrent
                            ? Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: route.color,
                                ),
                              )
                            : Icon(
                                Icons.lock_rounded,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : Colors.grey.shade400,
                                size: 24,
                              ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isUnlocked ? 1.0 : 0.4,
            child: SizedBox(
              width: 160,
              child: Column(
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isCompleted
                          ? route.color
                          : isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (isCurrent)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: route.color.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: route.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded,
                              color: const Color(0xFFFBBF24), size: 14),
                          const SizedBox(width: 3),
                          Text(
                            '+${lesson.xpReward} XP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: route.color,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!isCompleted)
                    Text(
                      lesson.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: route.color.withValues(alpha: 0.6), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+${lesson.xpReward} XP',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: route.color.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// CustomPainter para el camino curvo
// ═══════════════════════════════════════════
class _CurvedPathPainter extends CustomPainter {
  final int lessonCount;
  final Set<String> completedLessons;
  final List<Lesson> lessons;
  final Color routeColor;
  final bool isDark;
  final double centerX;
  final double amplitude;
  final double verticalSpacing;
  final double startY;
  final double glowProgress;

  _CurvedPathPainter({
    required this.lessonCount,
    required this.completedLessons,
    required this.lessons,
    required this.routeColor,
    required this.isDark,
    required this.centerX,
    required this.amplitude,
    required this.verticalSpacing,
    required this.startY,
    required this.glowProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lessonCount < 2) return;

    final nodeRadius = 35.0;

    for (int i = 0; i < lessonCount - 1; i++) {
      final isSegmentCompleted =
          completedLessons.contains(lessons[i].id);
      final isNextUnlocked = i == 0 ||
          completedLessons.contains(lessons[i].id);

      final t1 = i / (lessonCount - 1);
      final t2 = (i + 1) / (lessonCount - 1);
      final x1 = centerX + sin(t1 * pi * 2 - pi / 2) * amplitude;
      final y1 = i * verticalSpacing + startY;
      final x2 = centerX + sin(t2 * pi * 2 - pi / 2) * amplitude;
      final y2 = (i + 1) * verticalSpacing + startY;

      final midY = (y1 + y2) / 2;
      final cp1x = x1;
      final cp1y = midY;
      final cp2x = x2;
      final cp2y = midY;

      final path = Path()
        ..moveTo(x1, y1 + nodeRadius)
        ..cubicTo(cp1x, cp1y, cp2x, cp2y, x2, y2 - nodeRadius);

      // ── GLOW: multi-stroke sin MaskFilter.blur (safe en web) ────────
      // Simula el blur dibujando 3 trazos concéntricos con alpha decreciente
      if (isSegmentCompleted) {
        final baseAlpha = 0.06 + glowProgress * 0.04;
        // Trazo más ancho, más transparente (outer glow)
        final glowOuter = Paint()
          ..color = routeColor.withValues(alpha: baseAlpha)
          ..strokeWidth = 18
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, glowOuter);
        // Trazo intermedio
        final glowMid = Paint()
          ..color = routeColor.withValues(alpha: baseAlpha * 1.5)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, glowMid);
        // Trazo interior, más opaco
        final glowInner = Paint()
          ..color = routeColor.withValues(alpha: baseAlpha * 2.2)
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, glowInner);
      }

      // Camino principal
      final paint = Paint()
        ..color = isSegmentCompleted
            ? routeColor.withValues(alpha: 0.5)
            : isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade300
        ..strokeWidth = isSegmentCompleted ? 4 : 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Camino punteado para segmentos no desbloqueados
      if (!isNextUnlocked && !isSegmentCompleted) {
        paint.strokeWidth = 2;
        final pathMetrics = path.computeMetrics();
        for (final metric in pathMetrics) {
          final totalLength = metric.length;
          const dashLength = 8.0;
          const gapLength = 6.0;
          var distance = 0.0;
          while (distance < totalLength) {
            final end = (distance + dashLength).clamp(0.0, totalLength);
            final extractedPath = metric.extractPath(distance, end);
            canvas.drawPath(extractedPath, paint);
            distance += dashLength + gapLength;
          }
        }
      } else {
        canvas.drawPath(path, paint);
      }

      // Estrellas decorativas
      if (isSegmentCompleted) {
        final starPaint = Paint()
          ..color = routeColor.withValues(alpha: 0.15 + glowProgress * 0.1);
        final midX = (x1 + x2) / 2 + (i.isEven ? 25 : -25);
        canvas.drawCircle(Offset(midX, midY), 3, starPaint);
        canvas.drawCircle(
          Offset(midX + (i.isEven ? 12 : -12), midY - 8),
          2,
          starPaint..color = routeColor.withValues(alpha: 0.1),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurvedPathPainter oldDelegate) =>
      oldDelegate.glowProgress != glowProgress ||
      oldDelegate.completedLessons != completedLessons;
}