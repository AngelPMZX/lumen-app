import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';

class MusicStep extends StatefulWidget {
  final Function(List<String>) onNext;

  const MusicStep({super.key, required this.onNext});

  @override
  State<MusicStep> createState() => _MusicStepState();
}

class _MusicStepState extends State<MusicStep> {
  final Set<String> _selected = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _genres = [
    {'name': 'Pop', 'emoji': '🎤'},
    {'name': 'Rock', 'emoji': '🎸'},
    {'name': 'Hip Hop', 'emoji': '🎧'},
    {'name': 'Electrónica', 'emoji': '🎹'},
    {'name': 'Reggaetón', 'emoji': '💃'},
    {'name': 'Lo-fi', 'emoji': '🌙'},
    {'name': 'Jazz', 'emoji': '🎷'},
    {'name': 'Clásica', 'emoji': '🎻'},
    {'name': 'Indie', 'emoji': '🎵'},
    {'name': 'Metal', 'emoji': '🤘'},
    {'name': 'K-Pop', 'emoji': '⭐'},
    {'name': 'Cumbia', 'emoji': '🪗'},
    {'name': 'Alternativa', 'emoji': '🎶'},
    {'name': 'Ambient', 'emoji': '🌊'},
    {'name': 'New Age', 'emoji': '🧘'},
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
              Icons.headphones_rounded,
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
            '¿Qué música te mueve?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Selecciona al menos 2 géneros',
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
              children: List.generate(_genres.length, (index) {
                final genre = _genres[index];
                final isSelected = _selected.contains(genre['name']);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(genre['name']);
                      } else {
                        _selected.add(genre['name']);
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
                        Text(
                          genre['emoji'],
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          genre['name'],
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
              onPressed: _selected.length >= 2 && !_isLoading
                  ? () {
                      setState(() => _isLoading = true);
                      widget.onNext(_selected.toList());
                    }
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
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      _selected.length >= 2
                          ? 'Descubrir mi arquetipo'
                          : 'Selecciona ${2 - _selected.length} más',
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