import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
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

  // 'value' es lo que se guarda en Firestore (se mantiene en español por ahora)
  // 'trKey' es la key del JSON de traducción para el texto visible
  List<Map<String, dynamic>> _buildGenres() {
    return [
      {
        'value': 'Pop',
        'trKey': 'musicGenres.pop',
        'emoji': '🎤',
        'color': const Color(0xFFEC4899),
      },
      {
        'value': 'Rock',
        'trKey': 'musicGenres.rock',
        'emoji': '🎸',
        'color': const Color(0xFFEF4444),
      },
      {
        'value': 'Hip Hop',
        'trKey': 'musicGenres.hipHop',
        'emoji': '🎧',
        'color': const Color(0xFFF59E0B),
      },
      {
        'value': 'Electrónica',
        'trKey': 'musicGenres.electronic',
        'emoji': '🎹',
        'color': const Color(0xFF3B82F6),
      },
      {
        'value': 'Reggaetón',
        'trKey': 'musicGenres.reggaeton',
        'emoji': '💃',
        'color': const Color(0xFFF97316),
      },
      {
        'value': 'Lo-fi',
        'trKey': 'musicGenres.lofi',
        'emoji': '🌙',
        'color': const Color(0xFF8B5CF6),
      },
      {
        'value': 'Jazz',
        'trKey': 'musicGenres.jazz',
        'emoji': '🎷',
        'color': const Color(0xFFF59E0B),
      },
      {
        'value': 'Clásica',
        'trKey': 'musicGenres.classical',
        'emoji': '🎻',
        'color': const Color(0xFF6366F1),
      },
      {
        'value': 'Indie',
        'trKey': 'musicGenres.indie',
        'emoji': '🎵',
        'color': const Color(0xFF14B8A6),
      },
      {
        'value': 'Metal',
        'trKey': 'musicGenres.metal',
        'emoji': '🤘',
        'color': const Color(0xFFDC2626),
      },
      {
        'value': 'K-Pop',
        'trKey': 'musicGenres.kpop',
        'emoji': '⭐',
        'color': const Color(0xFFEC4899),
      },
      {
        'value': 'Cumbia',
        'trKey': 'musicGenres.cumbia',
        'emoji': '🪗',
        'color': const Color(0xFF22C55E),
      },
      {
        'value': 'Alternativa',
        'trKey': 'musicGenres.alternative',
        'emoji': '🎶',
        'color': const Color(0xFF06B6D4),
      },
      {
        'value': 'Ambient',
        'trKey': 'musicGenres.ambient',
        'emoji': '🌊',
        'color': const Color(0xFF0EA5E9),
      },
      {
        'value': 'New Age',
        'trKey': 'musicGenres.newAge',
        'emoji': '🧘',
        'color': const Color(0xFF10B981),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final genres = _buildGenres();
    final remaining = 2 - _selected.length;

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
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 24),

          Text(
            'profileSetup.whatMusic'.tr(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'profileSetup.selectAtLeast2'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: _selected.length >= 2
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _selected.length >= 2
                    ? const Color(0xFF10B981).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _selected.length >= 2
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: _selected.length >= 2
                      ? const Color(0xFF10B981)
                      : Colors.white.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  'profileSetup.selected'.tr(
                    namedArgs: {'count': '${_selected.length}'},
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _selected.length >= 2
                        ? const Color(0xFF10B981)
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Container(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(genres.length, (index) {
                final genre = genres[index];
                final isSelected = _selected.contains(genre['value']);
                final Color genreColor = genre['color'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selected.remove(genre['value']);
                      } else {
                        _selected.add(genre['value']);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? genreColor.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? genreColor.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.15),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: genreColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
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
                          (genre['trKey'] as String).tr(),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.8),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: genreColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                  delay: (300 + index * 40).ms,
                  duration: 350.ms,
                );
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
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.15),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                elevation: _selected.length >= 2 ? 4 : 0,
                shadowColor: Colors.white.withValues(alpha: 0.3),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selected.length >= 2
                              ? Icons.auto_awesome_rounded
                              : Icons.music_note_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selected.length >= 2
                              ? 'profileSetup.discoverArchetype'.tr()
                              : 'profileSetup.selectMore'.tr(
                                  namedArgs: {'count': '$remaining'},
                                ),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
