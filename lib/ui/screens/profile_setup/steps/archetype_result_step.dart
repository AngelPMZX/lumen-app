import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
 
class ArchetypeResultStep extends StatefulWidget {
  final String archetype;
  final VoidCallback onContinue;
 
  const ArchetypeResultStep({
    super.key,
    required this.archetype,
    required this.onContinue,
  });
 
  @override
  State<ArchetypeResultStep> createState() => _ArchetypeResultStepState();
}
 
class _ArchetypeResultStepState extends State<ArchetypeResultStep>
    with TickerProviderStateMixin {
  bool _showContent = false;
  bool _showCard = false;
  bool _showButton = false;
 
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;
 
  @override
  void initState() {
    super.initState();
 
    // Controlador para el pulso del ícono
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
 
    // Controlador para la rotación del halo
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
 
    // Secuencia de revelación dramática
    _startRevealSequence();
  }
 
  void _startRevealSequence() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _showContent = true);
 
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _showCard = true);
 
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _showButton = true);
  }
 
  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }
 
  Map<String, dynamic> get _archetypeData {
    switch (widget.archetype) {
      case 'explorador':
        return {
          'title': 'Explorador Introspectivo',
          'emoji': '🔮',
          'icon': Icons.explore_rounded,
          'description':
              'Eres reflexivo, creativo y buscas profundidad emocional. '
              'Tu mundo interior es rico y lleno de matices. Ves lo que otros '
              'pasan por alto y encuentras belleza en la complejidad.',
          'strengths': ['Creatividad', 'Empatía', 'Autoconciencia'],
          'tip': 'Tu superpoder es la introspección. Lumen te ayudará a '
              'canalizar esa profundidad en crecimiento personal.',
          'color1': const Color(0xFF6366F1),
          'color2': const Color(0xFF4338CA),
          'accentColor': const Color(0xFFA5B4FC),
        };
      case 'guerrero':
        return {
          'title': 'Guerrero Resiliente',
          'emoji': '⚔️',
          'icon': Icons.shield_rounded,
          'description':
              'Eres enérgico, orientado a la acción y determinado. '
              'Enfrentas los retos de frente y no te rindes fácilmente. '
              'Tu disciplina es tu mayor arma.',
          'strengths': ['Disciplina', 'Fuerza mental', 'Perseverancia'],
          'tip': 'Tu superpoder es la resiliencia. Lumen potenciará tu '
              'fortaleza mental con retos a tu medida.',
          'color1': const Color(0xFFEF4444),
          'color2': const Color(0xFFDC2626),
          'accentColor': const Color(0xFFFCA5A5),
        };
      case 'social':
        return {
          'title': 'Alma Social',
          'emoji': '💝',
          'icon': Icons.people_rounded,
          'description':
              'Eres empático, conectado y te importan los demás. '
              'Tu energía viene de las relaciones humanas y sabes '
              'hacer que todos se sientan bienvenidos.',
          'strengths': ['Comunicación', 'Generosidad', 'Liderazgo social'],
          'tip': 'Tu superpoder es la conexión. Lumen te ayudará a '
              'mantener relaciones saludables mientras cuidas de ti.',
          'color1': const Color(0xFFEC4899),
          'color2': const Color(0xFFDB2777),
          'accentColor': const Color(0xFFF9A8D4),
        };
      case 'sabio':
        return {
          'title': 'Sabio Tranquilo',
          'emoji': '🧘',
          'icon': Icons.spa_rounded,
          'description':
              'Eres calmado, analítico y buscas equilibrio en todo. '
              'Tu paz interior es contagiosa y eres un ancla para '
              'quienes te rodean.',
          'strengths': ['Paciencia', 'Sabiduría', 'Equilibrio'],
          'tip': 'Tu superpoder es la serenidad. Lumen profundizará tu '
              'camino hacia la armonía interior.',
          'color1': const Color(0xFF10B981),
          'color2': const Color(0xFF059669),
          'accentColor': const Color(0xFF6EE7B7),
        };
      case 'libre':
        return {
          'title': 'Espíritu Libre',
          'emoji': '✨',
          'icon': Icons.auto_awesome_rounded,
          'description':
              'Eres espontáneo, curioso y amante del cambio. '
              'Cada día es una nueva aventura y tu optimismo '
              'ilumina cualquier habitación.',
          'strengths': ['Adaptabilidad', 'Curiosidad', 'Optimismo'],
          'tip': 'Tu superpoder es la libertad. Lumen será tu compañero '
              'de aventuras en el crecimiento emocional.',
          'color1': const Color(0xFFF59E0B),
          'color2': const Color(0xFFD97706),
          'accentColor': const Color(0xFFFCD34D),
        };
      default:
        return {
          'title': 'Explorador Introspectivo',
          'emoji': '🔮',
          'icon': Icons.explore_rounded,
          'description': 'Tu perfil emocional único.',
          'strengths': ['Creatividad', 'Empatía', 'Autoconciencia'],
          'tip': 'Lumen te acompañará en tu viaje.',
          'color1': const Color(0xFF6366F1),
          'color2': const Color(0xFF4338CA),
          'accentColor': const Color(0xFFA5B4FC),
        };
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final data = _archetypeData;
    final Color color1 = data['color1'];
    final Color color2 = data['color2'];
    final Color accent = data['accentColor'];
 
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 30),
 
          // ═══════════════════════════════════
          // FASE 1: Texto introductorio
          // ═══════════════════════════════════
          Text(
            'Hemos analizado tu perfil...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(duration: 600.ms),
          const SizedBox(height: 8),
 
          if (!_showContent)
            // ── Loading shimmer ──
            Column(
              children: [
                const SizedBox(height: 40),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Descubriendo tu arquetipo...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 15,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(duration: 800.ms)
                    .then()
                    .fadeOut(duration: 800.ms),
              ],
            ),
 
          // ═══════════════════════════════════
          // FASE 2: Revelación del arquetipo
          // ═══════════════════════════════════
          if (_showContent) ...[
            Text(
              'Tu arquetipo es',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 24),
 
            // ── Ícono principal con halo giratorio ──
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Halo giratorio
                  AnimatedBuilder(
                    animation: _rotateController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotateController.value * 2 * pi,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              colors: [
                                color1.withValues(alpha: 0.0),
                                color1.withValues(alpha: 0.4),
                                accent.withValues(alpha: 0.6),
                                color2.withValues(alpha: 0.4),
                                color1.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Círculo central
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [color1, color2],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color1.withValues(alpha: 0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              data['emoji'],
                              style: const TextStyle(fontSize: 52),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(
                  begin: const Offset(0.2, 0.2),
                  end: const Offset(1.0, 1.0),
                  duration: 1000.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 24),
 
            // ── Título del arquetipo ──
            Text(
              data['title'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: color1.withValues(alpha: 0.5),
                    blurRadius: 20,
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 800.ms)
                .slideY(begin: 0.4, end: 0),
            const SizedBox(height: 16),
 
            // ── Descripción ──
            Container(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                data['description'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.6,
                ),
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 800.ms),
          ],
 
          // ═══════════════════════════════════
          // FASE 3: Card de fortalezas
          // ═══════════════════════════════════
          if (_showCard) ...[
            const SizedBox(height: 28),
            Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: accent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Ícono
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color1.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(data['icon'], color: accent, size: 28),
                  ),
                  const SizedBox(height: 16),
 
                  const Text(
                    'Tus fortalezas',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
 
                  // ── Chips de fortalezas ──
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: (data['strengths'] as List<String>)
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: color1.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                s,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
 
                  // ── Tip personalizado ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_rounded,
                            color: accent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            data['tip'],
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms)
                .slideY(begin: 0.3, end: 0)
                .scale(begin: const Offset(0.95, 0.95)),
          ],
 
          // ═══════════════════════════════════
          // FASE 4: Botón de continuar
          // ═══════════════════════════════════
          if (_showButton) ...[
            const SizedBox(height: 36),
            Container(
              constraints: const BoxConstraints(maxWidth: 380),
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: widget.onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color1,
                  elevation: 8,
                  shadowColor: color1.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(data['icon'], size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      '¡Comenzar mi viaje!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.5, end: 0),
            const SizedBox(height: 36),
          ],
        ],
      ),
    );
  }
}
