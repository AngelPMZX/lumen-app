import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/wellness_route.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../widgets/animated_particles_background.dart';
import 'lesson_screen.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  WellnessRoute? _selectedRoute;
  Set<String> _completedLessons = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final auth = context.read<AuthProvider>();
      final completed = await auth.getCompletedLessons();
      if (mounted) setState(() { _completedLessons = completed; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
    final routes = WellnessRoute.all;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Rutas de Bienestar',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('Elige una ruta y comienza tu viaje',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          ...List.generate(routes.length, (i) {
            final route = routes[i];
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
                            Text(route.title, style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(route.description, style: TextStyle(fontSize: 13,
                                color: AppColors.textSecondary)),
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
  // MAPA DE LECCIONES (estilo Duolingo)
  // ═══════════════════════════════════════════
  Widget _buildLessonMap(bool isDark) {
    final route = _selectedRoute!;
    final lessons = route.lessons;

    return Column(
      children: [
        // Header de la ruta
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _backToRoutes),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: route.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(route.emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(route.title, style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary)),
                    Text('${lessons.where((l) => _completedLessons.contains(l.id)).length}/${lessons.length} lecciones',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Mapa vertical
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              children: List.generate(lessons.length, (index) {
                final lesson = lessons[index];
                final isCompleted = _completedLessons.contains(lesson.id);
                final isUnlocked = _isLessonUnlocked(lesson, route);
                final isLast = index == lessons.length - 1;

                // Alternar posición (zigzag)
                final alignment = index % 2 == 0
                    ? Alignment.centerLeft : Alignment.centerRight;
                final offset = index % 2 == 0 ? -0.15 : 0.15;

                return Column(
                  children: [
                    // Línea conectora
                    if (index > 0)
                      Container(
                        width: 3, height: 40,
                        decoration: BoxDecoration(
                          color: isUnlocked
                              ? route.color.withValues(alpha: 0.4)
                              : isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                    // Nodo de lección
                    FractionallySizedBox(
                      widthFactor: 0.85,
                      alignment: alignment,
                      child: GestureDetector(
                        onTap: () => _openLesson(lesson, route),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isUnlocked ? 1.0 : 0.45,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: isCompleted
                                  ? LinearGradient(colors: [
                                      route.color.withValues(alpha: isDark ? 0.25 : 0.15),
                                      route.colorDark.withValues(alpha: isDark ? 0.12 : 0.06)])
                                  : null,
                              color: isCompleted ? null
                                  : isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCompleted
                                    ? route.color.withValues(alpha: 0.4)
                                    : isUnlocked
                                        ? route.color.withValues(alpha: isDark ? 0.2 : 0.15)
                                        : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                                width: isCompleted ? 2 : 1),
                              boxShadow: isCompleted ? [
                                BoxShadow(color: route.color.withValues(alpha: 0.15),
                                    blurRadius: 12, offset: const Offset(0, 4)),
                              ] : [],
                            ),
                            child: Row(
                              children: [
                                // Nodo circular
                                Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? route.color
                                        : isUnlocked
                                            ? route.color.withValues(alpha: isDark ? 0.2 : 0.12)
                                            : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                    boxShadow: isCompleted ? [
                                      BoxShadow(color: route.color.withValues(alpha: 0.3),
                                          blurRadius: 8),
                                    ] : [],
                                  ),
                                  child: Center(
                                    child: isCompleted
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                                        : isUnlocked
                                            ? Text('${index + 1}', style: TextStyle(
                                                fontSize: 18, fontWeight: FontWeight.w800,
                                                color: route.color))
                                            : const Icon(Icons.lock_rounded,
                                                color: Colors.grey, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(lesson.title, style: TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w700,
                                          color: isCompleted
                                              ? route.color
                                              : isDark ? Colors.white : AppColors.textPrimary)),
                                      const SizedBox(height: 2),
                                      Text(lesson.subtitle, style: TextStyle(
                                          fontSize: 13, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                // XP badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? route.color.withValues(alpha: 0.15)
                                        : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    isCompleted ? '✓' : '+${lesson.xpReward}',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                        color: isCompleted ? route.color : AppColors.textSecondary)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (100 * index).ms, duration: 500.ms)
                        .slideY(begin: 0.1, end: 0),

                    // Línea final
                    if (!isLast)
                      Container(
                        width: 3, height: 20,
                        decoration: BoxDecoration(
                          color: _completedLessons.contains(lesson.id)
                              ? route.color.withValues(alpha: 0.4)
                              : isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}