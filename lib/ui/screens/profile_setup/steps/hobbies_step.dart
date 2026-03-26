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
    {'name': 'Lectura', 'icon': Icons.menu_book_rounded, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Deportes', 'icon': Icons.sports_soccer_rounded, 'color': const Color(0xFF10B981)},
    {'name': 'Meditación', 'icon': Icons.self_improvement_rounded, 'color': const Color(0xFF06B6D4)},
    {'name': 'Cocina', 'icon': Icons.restaurant_rounded, 'color': const Color(0xFFF59E0B)},
    {'name': 'Arte', 'icon': Icons.palette_rounded, 'color': const Color(0xFFEC4899)},
    {'name': 'Viajar', 'icon': Icons.flight_rounded, 'color': const Color(0xFF3B82F6)},
    {'name': 'Fotografía', 'icon': Icons.camera_alt_rounded, 'color': const Color(0xFFF97316)},
    {'name': 'Videojuegos', 'icon': Icons.sports_esports_rounded, 'color': const Color(0xFF6366F1)},
    {'name': 'Gym', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFFEF4444)},
    {'name': 'Escritura', 'icon': Icons.edit_note_rounded, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Yoga', 'icon': Icons.spa_rounded, 'color': const Color(0xFF14B8A6)},
    {'name': 'Naturaleza', 'icon': Icons.park_rounded, 'color': const Color(0xFF22C55E)},
    {'name': 'Voluntariado', 'icon': Icons.volunteer_activism_rounded, 'color': const Color(0xFFEC4899)},
    {'name': 'Fiestas', 'icon': Icons.celebration_rounded, 'color': const Color(0xFFF59E0B)},
    {'name': 'Artes marciales', 'icon': Icons.sports_martial_arts_rounded, 'color': const Color(0xFFEF4444)},
  ];
 
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
 
          // ── Ícono header ──
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.interests_rounded, size: 50, color: Colors.white),
          ).animate().fadeIn(duration: 600.ms).scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 24),
 
          const Text(
            '¿Qué te gusta hacer?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Selecciona al menos 3 actividades',
            style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.7)),
          ).animate().fadeIn(delay: 300.ms),
 
          // ── Contador visual ──
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _selected.length >= 3
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selected.length >= 3
                    ? const Color(0xFF10B981).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _selected.length >= 3
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: _selected.length >= 3
                      ? const Color(0xFF10B981)
                      : Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_selected.length} seleccionados',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _selected.length >= 3
                        ? const Color(0xFF10B981)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
 
          // ── Grid de hobbies con colores ──
          Container(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(_hobbies.length, (index) {
                final hobby = _hobbies[index];
                final isSelected = _selected.contains(hobby['name']);
                final Color hobbyColor = hobby['color'];
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
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? hobbyColor.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? hobbyColor.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.15),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: hobbyColor.withValues(alpha: 0.2), blurRadius: 8)]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(hobby['icon'], size: 20,
                            color: isSelected ? hobbyColor : Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 8),
                        Text(
                          hobby['name'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.check_rounded, size: 16, color: hobbyColor),
                        ],
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: (300 + index * 40).ms, duration: 350.ms);
              }),
            ),
          ),
          const SizedBox(height: 32),
 
          // ── Botón ──
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
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.15),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                elevation: _selected.length >= 3 ? 4 : 0,
                shadowColor: Colors.white.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selected.length >= 3 ? 'Continuar' : 'Selecciona ${3 - _selected.length} más',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  if (_selected.length >= 3) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
