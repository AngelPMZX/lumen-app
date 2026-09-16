import 'dart:math' as math;
import 'dart:ui' show PathMetric;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/wellness_route.dart';
import '../../../../domain/services/sound_service.dart';

/// Mapa de lecciones estilo Duolingo: un camino serpenteante con nodos 3D,
/// decoración temática por ruta, destellos que fluyen por lo completado y un
/// trofeo al final.
///
/// La forma del camino depende solo del índice de cada nodo (no del total de
/// lecciones), así que rutas cortas y largas serpentean igual. Antes se usaba
/// `sin(i / (n - 1) · 2π)`, que con 2 lecciones dejaba ambos nodos en la misma
/// X y el camino salía recto.
class LessonPathMap extends StatefulWidget {
  final WellnessRoute route;
  final Set<String> completedLessons;
  final bool isDark;
  final double width;
  final void Function(Lesson lesson) onOpenLesson;

  const LessonPathMap({
    super.key,
    required this.route,
    required this.completedLessons,
    required this.isDark,
    required this.width,
    required this.onOpenLesson,
  });

  @override
  State<LessonPathMap> createState() => _LessonPathMapState();
}

class _LessonPathMapState extends State<LessonPathMap>
    with TickerProviderStateMixin {
  static const _nodeSize = 76.0;
  static const _box = _nodeSize + 26; // caja común de todos los nodos
  static const _faceCenter = (_box - (_nodeSize + 7)) / 2 + _nodeSize / 2;
  static const _spacing = 185.0;
  static const _topPad = 64.0; // espacio para el globo "Empezar"
  static const _trophyGap = 175.0;

  late final AnimationController _flow; // destellos y anillo giratorio
  late final AnimationController _pulse; // latido del nodo actual

  List<Lesson> get _lessons => widget.route.lessons;

  @override
  void initState() {
    super.initState();
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flow.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ── Geometría ──────────────────────────────────────────────────────────────
  double get _amplitude => math.min(92.0, math.max(30.0, (widget.width - 180) / 2));

  /// Centro del nodo [i]. El índice [_lessons.length] es el trofeo.
  Offset _center(int i) {
    final y = _topPad + _nodeSize / 2 + i * _spacing;
    // El trofeo siempre al centro: cierra la curva venga de donde venga.
    if (i == _lessons.length) {
      return Offset(widget.width / 2, y - _spacing + _trophyGap);
    }
    // sin(i · 0.9) no repite valores seguidos, así nunca hay tramos rectos.
    final x = widget.width / 2 + math.sin(i * 0.9) * _amplitude;
    return Offset(x, y);
  }

  int get _completedCount =>
      _lessons.where((l) => widget.completedLessons.contains(l.id)).length;

  /// Primer índice sin completar (-1 si ya terminó todo).
  int get _currentIndex {
    for (int i = 0; i < _lessons.length; i++) {
      if (!widget.completedLessons.contains(_lessons[i].id)) return i;
    }
    return -1;
  }

  bool _isUnlocked(int i) =>
      i == 0 || widget.completedLessons.contains(_lessons[i - 1].id);

  @override
  Widget build(BuildContext context) {
    final count = _lessons.length;
    if (count == 0) return const SizedBox.shrink();

    final routeDone = _completedCount == count;
    final trophy = _center(count);
    final height = trophy.dy + _nodeSize / 2 + 90;
    final current = _currentIndex;
    final points = List.generate(count + 1, _center);

    return SizedBox(
      width: widget.width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decoración temática a los costados del camino
          ..._buildDecorations(count),

          // Camino
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _flow,
                builder: (context, _) => CustomPaint(
                  painter: _TrailPainter(
                    points: points,
                    completedCount: _completedCount,
                    currentIndex: current,
                    color: widget.route.color,
                    isDark: widget.isDark,
                    flow: _flow.value,
                  ),
                ),
              ),
            ),
          ),

          // Cartel de mitad de camino
          if (count >= 6) _buildHalfwaySign(count),

          // Nodos
          for (int i = 0; i < count; i++) _positionedNode(i, current),

          // Globo "Empezar" sobre el nodo actual
          if (current >= 0)
            Positioned(
              left: _center(current).dx - 85,
              bottom: height - (_center(current).dy - _faceCenter) - 10,
              width: 170,
              child: Center(child: _buildStartBubble()),
            ),

          // Trofeo final
          Positioned(
            left: trophy.dx - 60,
            top: trophy.dy - 45,
            width: 120,
            child: _buildTrophy(routeDone),
          ),
        ],
      ),
    );
  }

  // ── Nodos ──────────────────────────────────────────────────────────────────
  Widget _positionedNode(int i, int current) {
    final c = _center(i);
    final lesson = _lessons[i];
    final completed = widget.completedLessons.contains(lesson.id);
    final unlocked = _isUnlocked(i);
    final isCurrent = i == current;

    return Positioned(
      left: c.dx - 85,
      top: c.dy - _faceCenter,
      width: 170,
      child: Column(
        children: [
          _PressableNode(
            enabled: unlocked,
            onTap: () {
              if (!unlocked) {
                HapticFeedback.heavyImpact();
                SoundService.instance.play(Sfx.toggleOff, volume: 0.4);
                return;
              }
              SoundService.instance.play(Sfx.tapNode, volume: 0.7);
              widget.onOpenLesson(lesson);
            },
            child: _buildNodeFace(i, completed, unlocked, isCurrent),
          ),
          _buildLabel(lesson, completed, unlocked, isCurrent),
        ],
      )
          .animate()
          .fadeIn(delay: (70 * i).ms, duration: 450.ms)
          .scale(
            begin: const Offset(0.6, 0.6),
            end: const Offset(1, 1),
            delay: (70 * i).ms,
            duration: 450.ms,
            curve: Curves.easeOutBack,
          ),
    );
  }

  Widget _buildNodeFace(int i, bool completed, bool unlocked, bool isCurrent) {
    final color = widget.route.color;
    final dark = widget.route.colorDark;
    final lockedTop = widget.isDark ? const Color(0xFF2A2D3A) : const Color(0xFFE5E7EB);
    final lockedBottom = widget.isDark ? const Color(0xFF1B1D27) : const Color(0xFFC8CCD3);

    final top = completed || isCurrent ? color : lockedTop;
    final bottom = completed || isCurrent ? dark : lockedBottom;

    Widget face = SizedBox(
      width: _nodeSize,
      height: _nodeSize + 7,
      child: Stack(
        children: [
          // Base (da la sensación de botón 3D)
          Positioned(
            top: 7,
            child: Container(
              width: _nodeSize,
              height: _nodeSize,
              decoration: BoxDecoration(shape: BoxShape.circle, color: bottom),
            ),
          ),
          // Cara superior
          Container(
            width: _nodeSize,
            height: _nodeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(top, Colors.white, completed || isCurrent ? 0.18 : 0.04)!, top],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Brillo
                Positioned(
                  top: 10,
                  left: 16,
                  child: Container(
                    width: 22,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: completed || isCurrent ? 0.35 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (completed)
                  const Icon(Icons.check_rounded, color: Colors.white, size: 36)
                else if (isCurrent)
                  Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    Icons.lock_rounded,
                    size: 26,
                    color: widget.isDark ? Colors.white30 : Colors.grey.shade500,
                  ),
              ],
            ),
          ),
          if (completed)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFBBF24),
                  border: Border.all(
                    color: widget.isDark ? const Color(0xFF0F1020) : Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.star_rounded, size: 14, color: Colors.white),
              ),
            ),
        ],
      ),
    );

    if (!isCurrent) {
      return SizedBox(width: _box, height: _box, child: Center(child: face));
    }

    // Nodo actual: anillo punteado que gira + latido
    return AnimatedBuilder(
      animation: Listenable.merge([_flow, _pulse]),
      builder: (context, child) {
        return SizedBox(
          width: _box,
          height: _box,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: _flow.value * math.pi * 2,
                child: CustomPaint(
                  size: Size.square(_nodeSize + 24),
                  painter: _DashedRingPainter(
                    color: color.withValues(alpha: 0.55 + _pulse.value * 0.35),
                  ),
                ),
              ),
              Transform.scale(scale: 1 + _pulse.value * 0.05, child: child),
            ],
          ),
        );
      },
      child: face,
    );
  }

  Widget _buildStartBubble() {
    final color = widget.route.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF1E2030) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            ),
            child: Text(
              'routes.startLesson'.tr().toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: color,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(14, 7),
            painter: _BubbleTailPainter(color: color.withValues(alpha: 0.6)),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -5, duration: 900.ms, curve: Curves.easeInOut);
  }

  Widget _buildLabel(Lesson lesson, bool completed, bool unlocked, bool isCurrent) {
    final color = widget.route.color;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: unlocked ? 1 : 0.45,
      child: Column(
        children: [
          Text(
            lesson.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: completed
                  ? color
                  : widget.isDark
                      ? Colors.white
                      : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          if (isCurrent || completed)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  completed ? Icons.check_circle_rounded : Icons.bolt_rounded,
                  size: 13,
                  color: completed ? color.withValues(alpha: 0.7) : const Color(0xFFFBBF24),
                ),
                const SizedBox(width: 3),
                Text(
                  '+${lesson.xpReward} XP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color.withValues(alpha: completed ? 0.7 : 1),
                  ),
                ),
              ],
            )
          else
            Text(
              lesson.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }

  // ── Trofeo y cartel ────────────────────────────────────────────────────────
  Widget _buildTrophy(bool done) {
    final color = widget.route.color;
    final trophy = Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: done
            ? const RadialGradient(colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)])
            : null,
        color: done
            ? null
            : widget.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade200,
        border: Border.all(
          color: done ? const Color(0xFFFBBF24) : color.withValues(alpha: 0.25),
          width: 3,
        ),
        boxShadow: done
            ? [BoxShadow(color: const Color(0xFFFBBF24).withValues(alpha: 0.5), blurRadius: 26, spreadRadius: 2)]
            : null,
      ),
      child: Center(
        child: Opacity(
          opacity: done ? 1 : 0.35,
          child: const Text('🏆', style: TextStyle(fontSize: 42)),
        ),
      ),
    );

    return Column(
      children: [
        done
            ? trophy
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.07, 1.07),
                  duration: 1200.ms,
                  curve: Curves.easeInOut,
                )
            : trophy,
        const SizedBox(height: 8),
        Text(
          done ? 'routes.routeCompleted'.tr() : 'routes.trophyLocked'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: done
                ? const Color(0xFFF59E0B)
                : widget.isDark
                    ? Colors.white38
                    : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHalfwaySign(int count) {
    final half = count ~/ 2;
    final a = _center(half - 1);
    final b = _center(half);
    // En el hueco entre la etiqueta de una lección y el siguiente nodo.
    final y = a.dy + (b.dy - a.dy) * 0.64;
    // El cartel va del lado contrario hacia donde se curva el camino.
    final midX = (a.dx + b.dx) / 2;
    final onLeft = midX > widget.width / 2;
    final reached = _completedCount >= half;
    final color = widget.route.color;

    return Positioned(
      top: y - 18,
      left: onLeft ? 8 : null,
      right: onLeft ? null : 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: reached
              ? color.withValues(alpha: 0.18)
              : (widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: reached ? 0.5 : 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(reached ? '🚩' : '🏳️', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              'routes.halfway'.tr(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: reached
                    ? color
                    : widget.isDark
                        ? Colors.white38
                        : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Decoración ─────────────────────────────────────────────────────────────
  static const Map<String, List<String>> _themes = {
    'emociones': ['🌈', '☁️', '🎈', '✨', '🌤️', '💭'],
    'autoconocimiento': ['🧭', '🔮', '🗝️', '✨', '🌙', '📜'],
    'mindfulness': ['🍃', '🪷', '🌿', '🫧', '🕊️', '🌸'],
    'resiliencia': ['⛰️', '🎋', '🌱', '🔥', '🌄', '🪨'],
    'autoestima': ['⭐', '🌟', '💫', '🌻', '👑', '✨'],
    'relaciones': ['💬', '🫶', '🤝', '🌷', '🎶', '☕'],
    'amor': ['💗', '🌹', '💌', '🦋', '💞', '🌸'],
  };

  List<Widget> _buildDecorations(int count) {
    final set = _themes[widget.route.id] ?? const ['✨', '🌿', '☁️', '⭐'];
    final rnd = math.Random(widget.route.id.hashCode);
    final widgets = <Widget>[];

    final halfGap = count >= 6 ? count ~/ 2 - 1 : -1;

    for (int i = 0; i <= count; i++) {
      final a = _center(i);
      final b = i < count ? _center(i + 1) : a + const Offset(0, 90);
      final midY = (a.dy + b.dy) / 2 + rnd.nextDouble() * 30 - 15;
      final midX = (a.dx + b.dx) / 2;
      // Del lado donde hay más espacio libre
      final leftSide = midX > widget.width / 2;
      final size = 22.0 + rnd.nextDouble() * 12;
      final edge = 6 + rnd.nextDouble() * 22;
      final emoji = set[rnd.nextInt(set.length)];
      final floatMs = 1800 + rnd.nextInt(1400);
      final opacity = 0.45 + rnd.nextDouble() * 0.35;
      // Ese hueco lo ocupa el cartel de mitad de camino
      if (i == halfGap) continue;

      widgets.add(Positioned(
        top: midY - size / 2,
        left: leftSide ? edge : null,
        right: leftSide ? null : edge,
        child: IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Text(emoji, style: TextStyle(fontSize: size)),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -4, end: 4, duration: floatMs.ms, curve: Curves.easeInOut)
              .rotate(begin: -0.02, end: 0.02, duration: floatMs.ms),
        ),
      ));

      // Brillitos pequeños extra en el otro lado, más tenues
      if (i.isEven) {
        widgets.add(Positioned(
          top: midY + 20,
          left: leftSide ? null : 18 + rnd.nextDouble() * 20,
          right: leftSide ? 18 + rnd.nextDouble() * 20 : null,
          child: IgnorePointer(
            child: Icon(
              Icons.auto_awesome,
              size: 12 + rnd.nextDouble() * 6,
              color: widget.route.color.withValues(alpha: 0.35),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 0.2, end: 1, duration: (1200 + rnd.nextInt(900)).ms),
          ),
        ));
      }
    }
    return widgets;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Nodo presionable: se hunde al tocarlo, como un botón físico
// ═════════════════════════════════════════════════════════════════════════════
class _PressableNode extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  const _PressableNode({
    required this.child,
    required this.onTap,
    required this.enabled,
  });

  @override
  State<_PressableNode> createState() => _PressableNodeState();
}

class _PressableNodeState extends State<_PressableNode> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.enabled) setState(() => _down = true);
      },
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 90),
        offset: Offset(0, _down ? 0.06 : 0),
        child: widget.child,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Painters
// ═════════════════════════════════════════════════════════════════════════════
class _TrailPainter extends CustomPainter {
  final List<Offset> points; // nodos + trofeo
  final int completedCount;
  final int currentIndex;
  final Color color;
  final bool isDark;
  final double flow;

  _TrailPainter({
    required this.points,
    required this.completedCount,
    required this.currentIndex,
    required this.color,
    required this.isDark,
    required this.flow,
  });

  Path _segment(Offset a, Offset b) {
    final dy = (b.dy - a.dy) * 0.5;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, a.dy + dy, b.dx, b.dy - dy, b.dx, b.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // 1. La "carretera": banda ancha y suave a todo lo largo
    final road = Path();
    for (int i = 0; i < points.length - 1; i++) {
      road.addPath(_segment(points[i], points[i + 1]), Offset.zero);
    }
    canvas.drawPath(
      road,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 30
        ..color = color.withValues(alpha: isDark ? 0.07 : 0.09),
    );
    canvas.drawPath(
      road,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 20
        ..color = isDark ? Colors.white.withValues(alpha: 0.035) : Colors.white.withValues(alpha: 0.7),
    );

    for (int i = 0; i < points.length - 1; i++) {
      final seg = _segment(points[i], points[i + 1]);
      final done = i < completedCount; // el tramo que sale de un nodo completado
      final active = i == completedCount && currentIndex >= 0;

      if (done) {
        _drawGlowLine(canvas, seg);
      } else if (active) {
        _drawMarchingDashes(canvas, seg);
      } else {
        _drawDots(canvas, seg);
      }
    }

    // 2. Destellos que fluyen por todo lo completado
    if (completedCount > 0) {
      final donePath = Path();
      final last = math.min(completedCount, points.length - 1);
      for (int i = 0; i < last; i++) {
        donePath.addPath(_segment(points[i], points[i + 1]), Offset.zero);
      }
      final sparkle = Paint()..color = Colors.white.withValues(alpha: 0.85);
      final halo = Paint()..color = color.withValues(alpha: 0.35);
      for (final metric in donePath.computeMetrics()) {
        final n = math.max(1, (metric.length / 90).floor());
        for (int k = 0; k < n; k++) {
          final d = ((k / n + flow) % 1.0) * metric.length;
          final t = metric.getTangentForOffset(d);
          if (t == null) continue;
          canvas.drawCircle(t.position, 5, halo);
          canvas.drawCircle(t.position, 2.2, sparkle);
        }
      }
    }
  }

  void _drawGlowLine(Canvas canvas, Path seg) {
    // Resplandor con trazos concéntricos (sin MaskFilter.blur: rompe WebGL)
    for (final layer in const [
      [22.0, 0.08],
      [15.0, 0.14],
      [10.0, 0.9],
    ]) {
      canvas.drawPath(
        seg,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = layer[0]
          ..color = color.withValues(alpha: layer[1]),
      );
    }
    canvas.drawPath(
      seg,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  void _drawMarchingDashes(Canvas canvas, Path seg) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..color = color.withValues(alpha: 0.75);
    const dash = 14.0;
    const gap = 12.0;
    for (final PathMetric m in seg.computeMetrics()) {
      var d = -((flow * 4) % 1.0) * (dash + gap);
      while (d < m.length) {
        final start = math.max(0.0, d);
        final end = math.min(m.length, d + dash);
        if (end > start) canvas.drawPath(m.extractPath(start, end), paint);
        d += dash + gap;
      }
    }
  }

  void _drawDots(Canvas canvas, Path seg) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.16) : Colors.grey.shade400;
    for (final m in seg.computeMetrics()) {
      for (double d = 8; d < m.length; d += 18) {
        final t = m.getTangentForOffset(d);
        if (t != null) canvas.drawCircle(t.position, 3.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.flow != flow ||
      old.completedCount != completedCount ||
      old.currentIndex != currentIndex ||
      old.isDark != isDark ||
      old.color != color ||
      old.points.length != points.length ||
      (old.points.isNotEmpty && points.isNotEmpty && old.points.last != points.last);
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  _DashedRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = color;
    final rect = Offset.zero & size;
    const segments = 12;
    const sweep = math.pi * 2 / segments;
    for (int i = 0; i < segments; i++) {
      canvas.drawArc(rect.deflate(2), i * sweep, sweep * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => old.color != color;
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  _BubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => old.color != color;
}
