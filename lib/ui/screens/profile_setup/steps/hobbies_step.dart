import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';

class HobbiesStep extends StatefulWidget {
  final Function(List<String>) onNext;

  const HobbiesStep({super.key, required this.onNext});

  @override
  State<HobbiesStep> createState() => _HobbiesStepState();
}

class _HobbiesStepState extends State<HobbiesStep> {
  final Set<String> _selected = {};

  final List<Map<String, dynamic>> _hobbies = [
    {'name': 'Lectura', 'icon': Icons.menu_book_rounded},
    {'name': 'Deportes', 'icon': Icons.sports_soccer_rounded},
    {'name': 'Meditación', 'icon': Icons.self_improvement_rounded},
    {'name': 'Cocina', 'icon': Icons.restaurant_rounded},
    {'name': 'Arte', 'icon': Icons.palette_rounded},
    {'name': 'Viajar', 'icon': Icons.flight_rounded},
    {'name': 'Fotografía', 'icon': Icons.camera_alt_rounded},
    {'name': 'Videojuegos', 'icon': Icons.sports_esports_rounded},
    {'name': 'Gym', 'icon': Icons.fitness_center_rounded},
    {'name': 'Escritura', 'icon': Icons.edit_note_rounded},
    {'name': 'Yoga', 'icon': Icons.spa_rounded},
    {'name': 'Naturaleza', 'icon': Icons.park_rounded},
    {'name': 'Voluntariado', 'icon': Icons.volunteer_activism_rounded},
    {'name': 'Fiestas', 'icon': Icons.celebration_rounded},
    {'name': 'Artes marciales', 'icon': Icons.sports_martial_arts_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.interests_rounded,
              size: 50,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 600.ms).scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 24),

          const Text(
            '¿Qué te gusta hacer?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Selecciona al menos 3 actividades',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 28),

          Container(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(_hobbies.length, (index) {
                final hobby = _hobbies[index];
                final isSelected = _selected.contains(hobby['name']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(hobby['name']);
                      } else {
                        _selected.add(hobby['name']);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hobby['icon'],
                          size: 20,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hobby['name'],
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: (400 + index * 50).ms, duration: 400.ms);
              }),
            ),
          ),
          const SizedBox(height: 32),

          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _selected.length >= 3
                  ? () => widget.onNext(_selected.toList())
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor:
                    Colors.white.withValues(alpha: 0.2),
                disabledForegroundColor:
                    Colors.white.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _selected.length >= 3
                    ? 'Continuar (${_selected.length} seleccionados)'
                    : 'Selecciona ${3 - _selected.length} más',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}