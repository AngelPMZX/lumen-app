import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/providers/auth_provider.dart';
import 'steps/username_step.dart';
import 'steps/about_you_step.dart';
import 'steps/hobbies_step.dart';
import 'steps/music_step.dart';
import 'steps/archetype_result_step.dart';
import '../../widgets/animated_particles_background.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  String _username = '';
  int? _age;
  String? _gender;
  List<String> _hobbies = [];
  List<String> _musicGenres = [];

  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1 / (_totalSteps - 1))
        .animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeInOutCubic,
          ),
        );
    _progressController.forward();
  }

  void _updateProgress(int step) {
    final newProgress = (step + 1) / (_totalSteps - 1);
    _progressAnimation =
        Tween<double>(
          begin: _previousProgress,
          end: newProgress.clamp(0.0, 1.0),
        ).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeInOutCubic,
          ),
        );
    _progressController.forward(from: 0);
    _previousProgress = newProgress.clamp(0.0, 1.0);
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _completeProfile() async {
    final authProvider = context.read<AuthProvider>();
    final archetype = _calculateArchetype();

    final (success, error) = await authProvider.updateUserProfile(
      username: _username,
      age: _age,
      gender: _gender,
      hobbies: _hobbies,
      musicGenres: _musicGenres,
      archetype: archetype,
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error ?? 'profileSetup.errorSaveProfile'.tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    final (completeSuccess, completeError) = await authProvider
        .updateUserProfile(markComplete: true);

    if (!completeSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              completeError ?? 'profileSetup.errorCompleteProfile'.tr(),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    if (mounted) {
      _nextStep();
    }
  }

  String _calculateArchetype() {
    Map<String, int> scores = {
      'explorador': 0,
      'guerrero': 0,
      'social': 0,
      'sabio': 0,
      'libre': 0,
    };

    // NOTA: Los valores internos de hobbies se mantienen en español
    // porque así están guardados en Firestore. Se migrarán en fase posterior.
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

  String _getStepLabel(int step) {
    switch (step) {
      case 0:
        return 'profileSetup.stepUser'.tr();
      case 1:
        return 'profileSetup.stepAboutYou'.tr();
      case 2:
        return 'profileSetup.stepHobbies'.tr();
      case 3:
        return 'profileSetup.stepMusic'.tr();
      default:
        return '';
    }
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.alternate_email_rounded;
      case 1:
        return Icons.person_rounded;
      case 2:
        return Icons.interests_rounded;
      case 3:
        return Icons.headphones_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _currentStep < _totalSteps - 1
                    ? const [
                        Color(0xFF6C63FF),
                        Color(0xFF4A42DB),
                        Color(0xFF1E1157),
                      ]
                    : [
                        _getArchetypeColors().$1,
                        _getArchetypeColors().$2,
                        const Color(0xFF1A1A2E),
                      ],
              ),
            ),
          ),

          const AnimatedParticlesBackground(
            particleCount: 35,
            maxShootingStars: 3,
            particleColor: Colors.white,
          ),

          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                if (_currentStep < _totalSteps - 1)
                  _buildProgressHeader()
                else
                  const SizedBox(height: 16),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentStep = index);
                      if (index < _totalSteps - 1) {
                        _updateProgress(index);
                      }
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
                            context,
                            AppRoutes.home,
                          );
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

  Widget _buildProgressHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedOpacity(
                opacity: _currentStep > 0 ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: _currentStep > 0 ? _previousStep : null,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progressAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFFE0DDFF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentStep + 1}/${_totalSteps - 1}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps - 1, (index) {
              final isActive = index == _currentStep;
              final isCompleted = index < _currentStep;
              return Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isActive ? 36 : 28,
                          height: isActive ? 36 : 28,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white
                                : isCompleted
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isActive || isCompleted
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.2),
                              width: 2,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_rounded
                                : _getStepIcon(index),
                            size: isActive ? 18 : 14,
                            color: isActive || isCompleted
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStepLabel(index),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive || isCompleted
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  (Color, Color) _getArchetypeColors() {
    final arch = _calculateArchetype();
    switch (arch) {
      case 'explorador':
        return (const Color(0xFF6366F1), const Color(0xFF4338CA));
      case 'guerrero':
        return (const Color(0xFFEF4444), const Color(0xFFDC2626));
      case 'social':
        return (const Color(0xFFEC4899), const Color(0xFFDB2777));
      case 'sabio':
        return (const Color(0xFF10B981), const Color(0xFF059669));
      case 'libre':
        return (const Color(0xFFF59E0B), const Color(0xFFD97706));
      default:
        return (const Color(0xFF6366F1), const Color(0xFF4338CA));
    }
  }
}
