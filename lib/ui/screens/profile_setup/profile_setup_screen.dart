import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/providers/auth_provider.dart';
import 'steps/username_step.dart';
import 'steps/about_you_step.dart';
import 'steps/hobbies_step.dart';
import 'steps/music_step.dart';
import 'steps/archetype_result_step.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Datos recopilados
  String _username = '';
  int? _age;
  String? _gender;
  List<String> _hobbies = [];
  List<String> _musicGenres = [];

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeProfile() async {
    final authProvider = context.read<AuthProvider>();

    // Calcular arquetipo
    final archetype = _calculateArchetype();

    final success = await authProvider.updateUserProfile(
      username: _username,
      age: _age,
      gender: _gender,
      hobbies: _hobbies,
      musicGenres: _musicGenres,
      archetype: archetype,
    );

    // Marcar perfil como completo
    if (success) {
      await authProvider.updateUserProfile();
    }

    if (mounted) {
      // Ir al resultado del arquetipo
      _nextStep();
    }
  }

  String _calculateArchetype() {
    // Sistema de puntos por arquetipo
    Map<String, int> scores = {
      'explorador': 0,
      'guerrero': 0,
      'social': 0,
      'sabio': 0,
      'libre': 0,
    };

    // Puntos por hobbies
    for (final hobby in _hobbies) {
      switch (hobby) {
        case 'Lectura':
        case 'Escritura':
        case 'Arte':
          scores['explorador'] = scores['explorador']! + 2;
          break;
        case 'Deportes':
        case 'Gym':
        case 'Artes marciales':
          scores['guerrero'] = scores['guerrero']! + 2;
          break;
        case 'Cocina':
        case 'Voluntariado':
        case 'Fiestas':
          scores['social'] = scores['social']! + 2;
          break;
        case 'Meditación':
        case 'Yoga':
        case 'Naturaleza':
          scores['sabio'] = scores['sabio']! + 2;
          break;
        case 'Viajar':
        case 'Fotografía':
        case 'Videojuegos':
          scores['libre'] = scores['libre']! + 2;
          break;
      }
    }

    // Puntos por música
    for (final genre in _musicGenres) {
      switch (genre) {
        case 'Lo-fi':
        case 'Clásica':
        case 'Indie':
          scores['explorador'] = scores['explorador']! + 1;
          break;
        case 'Rock':
        case 'Metal':
        case 'Hip Hop':
          scores['guerrero'] = scores['guerrero']! + 1;
          break;
        case 'Pop':
        case 'Reggaetón':
        case 'Cumbia':
          scores['social'] = scores['social']! + 1;
          break;
        case 'Jazz':
        case 'Ambient':
        case 'New Age':
          scores['sabio'] = scores['sabio']! + 1;
          break;
        case 'Electrónica':
        case 'Alternativa':
        case 'K-Pop':
          scores['libre'] = scores['libre']! + 1;
          break;
      }
    }

    // Encontrar el arquetipo dominante
    String dominant = 'explorador';
    int maxScore = 0;
    scores.forEach((key, value) {
      if (value > maxScore) {
        maxScore = value;
        dominant = key;
      }
    });

    return dominant;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6C63FF),
                  Color(0xFF3A2FA8),
                  Color(0xFF1E1157),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (_currentStep > 0 && _currentStep < _totalSteps - 1)
                            GestureDetector(
                              onTap: _previousStep,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _currentStep < _totalSteps - 1
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                     child: LinearProgressIndicator(
                                      value: (_currentStep + 1) / (_totalSteps - 1),
                                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      minHeight: 6,
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                          const SizedBox(width: 16),
                          if (_currentStep < _totalSteps - 1)
                            Text(
                              '${_currentStep + 1}/${_totalSteps - 1}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            const SizedBox(width: 40),
                        ],
                      ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentStep = index);
                    },
                    children: [
                      UsernameStep(
                        onNext: (username) {
                          _username = username;
                          _nextStep();
                        },
                      ),
                      AboutYouStep(
                        onNext: (age, gender) {
                          _age = age;
                          _gender = gender;
                          _nextStep();
                        },
                      ),
                      HobbiesStep(
                        onNext: (hobbies) {
                          _hobbies = hobbies;
                          _nextStep();
                        },
                      ),
                      MusicStep(
                        onNext: (genres) {
                          _musicGenres = genres;
                          _completeProfile();
                        },
                      ),
                      ArchetypeResultStep(
                        archetype: _calculateArchetype(),
                        onContinue: () {
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.home);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}