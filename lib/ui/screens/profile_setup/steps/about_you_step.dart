import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
 
class AboutYouStep extends StatefulWidget {
  final Function(int?, String?) onNext;
 
  const AboutYouStep({super.key, required this.onNext});
 
  @override
  State<AboutYouStep> createState() => _AboutYouStepState();
}
 
class _AboutYouStepState extends State<AboutYouStep> {
  int? _selectedAge;
  String? _selectedGender;
  bool _showGenderError = false; // NUEVO: para validación de género
 
  final List<String> _ageRanges = [
    '13-17', '18-24', '25-34', '35-44', '45-54', '55+'
  ];
 
  final List<Map<String, dynamic>> _genders = [
    {'label': 'Masculino', 'icon': Icons.male_rounded, 'color': const Color(0xFF3B82F6)},
    {'label': 'Femenino', 'icon': Icons.female_rounded, 'color': const Color(0xFFEC4899)},
    {'label': 'No binario', 'icon': Icons.transgender_rounded, 'color': const Color(0xFF8B5CF6)},
    {'label': 'Prefiero no decir', 'icon': Icons.person_rounded, 'color': const Color(0xFF6B7280)},
  ];
 
  int? _getAgeFromRange(String range) {
    switch (range) {
      case '13-17': return 15;
      case '18-24': return 21;
      case '25-34': return 30;
      case '35-44': return 40;
      case '45-54': return 50;
      case '55+': return 60;
      default: return null;
    }
  }
 
  String? _getSelectedAgeRange() {
    if (_selectedAge == null) return null;
    for (final range in _ageRanges) {
      if (_getAgeFromRange(range) == _selectedAge) return range;
    }
    return null;
  }
 
  void _handleContinue() {
    if (_selectedGender == null) {
      setState(() => _showGenderError = true);
      // Scroll hacia abajo para que vea el error
      return;
    }
    widget.onNext(_selectedAge, _selectedGender);
  }
 
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
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.person_search_rounded,
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
            'Cuéntanos de ti',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Esto nos ayuda a personalizar tu experiencia',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 32),
 
          // ═══════════════════════════════════
          // SECCIÓN EDAD - Mejorada con chips
          // ═══════════════════════════════════
          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cake_rounded,
                        color: Colors.white.withValues(alpha: 0.8), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tu rango de edad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const Text(' *',
                        style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _ageRanges.map((range) {
                    final isSelected = _selectedAge == _getAgeFromRange(range);
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedAge = _getAgeFromRange(range));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          range,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: 28),
 
          // ═══════════════════════════════════
          // SECCIÓN GÉNERO - Obligatorio + Error
          // ═══════════════════════════════════
          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wc_rounded,
                        color: Colors.white.withValues(alpha: 0.8), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Género',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const Text(' *',
                        style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 16)),
                  ],
                ),
                // ── Mensaje de error animado ──
                if (_showGenderError && _selectedGender == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Color(0xFFFF6B6B), size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Por favor selecciona una opción',
                          style: TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 300.ms).shakeX(
                          hz: 4, amount: 4, duration: 400.ms),
                  ),
                const SizedBox(height: 12),
                ...List.generate(_genders.length, (index) {
                  final gender = _genders[index];
                  final isSelected = _selectedGender == gender['label'];
                  final hasError =
                      _showGenderError && _selectedGender == null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGender = gender['label'];
                          _showGenderError = false;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: hasError
                                ? const Color(0xFFFF6B6B).withValues(alpha: 0.6)
                                : isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.15),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (gender['color'] as Color)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            // Ícono con color temático
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (gender['color'] as Color)
                                        .withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                gender['icon'],
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.7),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              gender['label'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(Icons.check_rounded,
                                      size: 16, color: gender['color'])
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (500 + index * 80).ms, duration: 400.ms)
                      .slideX(begin: 0.1, end: 0);
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),
 
          // ── Botón: requiere edad Y género ──
          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedAge != null ? _handleContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.15),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                elevation: (_selectedAge != null && _selectedGender != null) ? 4 : 0,
                shadowColor: Colors.white.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 700.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
