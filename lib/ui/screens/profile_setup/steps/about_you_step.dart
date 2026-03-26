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

  final List<String> _ageRanges = [
    '13-17', '18-24', '25-34', '35-44', '45-54', '55+'
  ];

  final List<Map<String, dynamic>> _genders = [
    {'label': 'Masculino', 'icon': Icons.male_rounded},
    {'label': 'Femenino', 'icon': Icons.female_rounded},
    {'label': 'No binario', 'icon': Icons.transgender_rounded},
    {'label': 'Prefiero no decir', 'icon': Icons.person_rounded},
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

          // Edad
          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu rango de edad',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _ageRanges.map((range) {
                    final isSelected = _selectedAge == _getAgeFromRange(range);
                    return GestureDetector(
                      onTap: () {
                        setState(() =>
                            _selectedAge = _getAgeFromRange(range));
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
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
                        child: Text(
                          range,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 28),

          // Género
          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Género',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_genders.length, (index) {
                  final gender = _genders[index];
                  final isSelected =
                      _selectedGender == gender['label'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() =>
                            _selectedGender = gender['label']);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.15),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              gender['icon'],
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              gender['label'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 32),

          // Botón
          Container(
            constraints: const BoxConstraints(maxWidth: 420),
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_selectedAge != null)
                  ? () => widget.onNext(_selectedAge, _selectedGender)
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
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}