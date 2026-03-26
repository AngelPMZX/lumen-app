import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';

class ArchetypeResultStep extends StatelessWidget {
  final String archetype;
  final VoidCallback onContinue;

  const ArchetypeResultStep({
    super.key,
    required this.archetype,
    required this.onContinue,
  });

  Map<String, dynamic> get _archetypeData {
    switch (archetype) {
      case 'explorador':
        return {
          'title': 'Explorador Introspectivo',
          'emoji': '🔮',
          'description':
              'Eres reflexivo, creativo y buscas profundidad emocional. Tu mundo interior es rico y lleno de matices.',
          'strengths': 'Creatividad, empatía, autoconciencia',
          'color1': const Color(0xFF6366F1),
          'color2': const Color(0xFF4338CA),
          'icon': Icons.explore_rounded,
        };
      case 'guerrero':
        return {
          'title': 'Guerrero Resiliente',
          'emoji': '⚔️',
          'description':
              'Eres enérgico, orientado a la acción y competitivo. Enfrentas los retos de frente con determinación.',
          'strengths': 'Disciplina, fuerza mental, perseverancia',
          'color1': const Color(0xFFEF4444),
          'color2': const Color(0xFFDC2626),
          'icon': Icons.shield_rounded,
        };
      case 'social':
        return {
          'title': 'Alma Social',
          'emoji': '💝',
          'description':
              'Eres empático, conectado y te importan los demás. Tu energía viene de las relaciones humanas.',
          'strengths': 'Comunicación, generosidad, liderazgo social',
          'color1': const Color(0xFFEC4899),
          'color2': const Color(0xFFDB2777),
          'icon': Icons.people_rounded,
        };
      case 'sabio':
        return {
          'title': 'Sabio Tranquilo',
          'emoji': '🧘',
          'description':
              'Eres calmado, analítico y buscas equilibrio en todo. Tu paz interior es tu mayor fortaleza.',
          'strengths': 'Paciencia, sabiduría, equilibrio',
          'color1': const Color(0xFF10B981),
          'color2': const Color(0xFF059669),
          'icon': Icons.spa_rounded,
        };
      case 'libre':
        return {
          'title': 'Espíritu Libre',
          'emoji': '✨',
          'description':
              'Eres espontáneo, curioso y amante del cambio. Cada día es una nueva aventura para ti.',
          'strengths': 'Adaptabilidad, curiosidad, optimismo',
          'color1': const Color(0xFFF59E0B),
          'color2': const Color(0xFFD97706),
          'icon': Icons.auto_awesome_rounded,
        };
      default:
        return {
          'title': 'Explorador Introspectivo',
          'emoji': '🔮',
          'description': 'Tu perfil emocional único.',
          'strengths': 'Creatividad, empatía, autoconciencia',
          'color1': const Color(0xFF6366F1),
          'color2': const Color(0xFF4338CA),
          'icon': Icons.explore_rounded,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _archetypeData;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 30),

          Text(
            'Tu arquetipo es...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(duration: 800.ms),
          const SizedBox(height: 24),

          // Emoji grande
          Text(
            data['emoji'],
            style: const TextStyle(fontSize: 80),
          )
              .animate()
              .fadeIn(delay: 500.ms, duration: 800.ms)
              .scale(
                begin: const Offset(0.3, 0.3),
                end: const Offset(1.0, 1.0),
                duration: 800.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 20),

          // Título del arquetipo
          Text(
            data['title'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          )
              .animate()
              .fadeIn(delay: 800.ms, duration: 800.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 20),

          // Descripción
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              data['description'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.6,
              ),
            ),
          ).animate().fadeIn(delay: 1100.ms, duration: 800.ms),
          const SizedBox(height: 28),

          // Fortalezas
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  data['icon'],
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tus fortalezas',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data['strengths'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 1400.ms, duration: 800.ms),
          const SizedBox(height: 40),

          // Botón
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: data['color1'],
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¡Comenzar mi viaje!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.rocket_launch_rounded, size: 22),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 1700.ms, duration: 800.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}