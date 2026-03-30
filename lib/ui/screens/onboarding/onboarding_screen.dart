import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _bgController;

  // ── Ahora es un método que recibe context para poder usar .tr() ──
  List<_OnboardingData> _buildPages() {
    return [
      _OnboardingData(
        title: 'onboarding.title1'.tr(),
        description: 'onboarding.desc1'.tr(),
        gradientColors: [
          const Color(0xFF6C63FF),
          const Color(0xFF5A4FCF),
          const Color(0xFF3D2DB5),
        ],
        iconData: Icons.spa_rounded,
        orbitIcons: [
          Icons.favorite_rounded,
          Icons.star_rounded,
          Icons.brightness_7_rounded,
          Icons.water_drop_rounded,
        ],
        accentColor: const Color(0xFF9D97FF),
      ),
      _OnboardingData(
        title: 'onboarding.title2'.tr(),
        description: 'onboarding.desc2'.tr(),
        gradientColors: [
          const Color(0xFF10B981),
          const Color(0xFF059669),
          const Color(0xFF065F46),
        ],
        iconData: Icons.psychology_rounded,
        orbitIcons: [
          Icons.lightbulb_rounded,
          Icons.auto_awesome_rounded,
          Icons.emoji_objects_rounded,
          Icons.hub_rounded,
        ],
        accentColor: const Color(0xFF6EE7B7),
      ),
      _OnboardingData(
        title: 'onboarding.title3'.tr(),
        description: 'onboarding.desc3'.tr(),
        gradientColors: [
          const Color(0xFFFF9500),
          const Color(0xFFE8700A),
          const Color(0xFFC2410C),
        ],
        iconData: Icons.local_fire_department_rounded,
        orbitIcons: [
          Icons.bolt_rounded,
          Icons.military_tech_rounded,
          Icons.trending_up_rounded,
          Icons.diamond_rounded,
        ],
        accentColor: const Color(0xFFFCD34D),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final pages = _buildPages();
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final data = pages[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          // Fondo animado con gradiente
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.gradientColors,
              ),
            ),
          ),

          // Partículas de fondo
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _BgPatternPainter(
                  progress: _bgController.value,
                  color: data.accentColor,
                ),
              );
            },
          ),

          // Contenido
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'onboarding.skip'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(pages[index]);
                    },
                  ),
                ),

                // Bottom section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: _currentPage == index ? 36 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: data.gradientColors.first,
                            elevation: 8,
                            shadowColor: Colors.black.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage < pages.length - 1
                                    ? 'common.next'.tr()
                                    : 'onboarding.getStarted'.tr(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage < pages.length - 1
                                    ? Icons.arrow_forward_rounded
                                    : Icons.rocket_launch_rounded,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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

  Widget _buildPage(_OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustración compuesta con órbitas
          SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Anillo exterior
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
                // Anillo interior
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                ),
                // Íconos orbitando
                ...List.generate(data.orbitIcons.length, (index) {
                  final angle = (index * pi / 2) + (pi / 4);
                  final radius = 100.0;
                  return Positioned(
                    left: 130 + cos(angle) * radius - 18,
                    top: 130 + sin(angle) * radius - 18,
                    child:
                        Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(
                                data.orbitIcons[index],
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 18,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(
                              begin: 0.9,
                              end: 1.1,
                              duration: (1500 + index * 300).ms,
                            )
                            .fadeIn(
                              delay: (300 + index * 150).ms,
                              duration: 600.ms,
                            ),
                  );
                }),
                // Ícono central
                Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.08),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: data.accentColor.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(data.iconData, size: 56, color: Colors.white),
                    )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Título
          Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 700.ms)
              .slideY(begin: 0.3, end: 0, duration: 700.ms),
          const SizedBox(height: 20),

          // Descripción
          Text(
                data.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.6,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.3,
                ),
              )
              .animate()
              .fadeIn(delay: 500.ms, duration: 700.ms)
              .slideY(begin: 0.3, end: 0, duration: 700.ms),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final List<Color> gradientColors;
  final IconData iconData;
  final List<IconData> orbitIcons;
  final Color accentColor;

  _OnboardingData({
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.iconData,
    required this.orbitIcons,
    required this.accentColor,
  });
}

// Painter para patrón de fondo
class _BgPatternPainter extends CustomPainter {
  final double progress;
  final Color color;

  _BgPatternPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final random = Random(42);

    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final radius = 1.5 + random.nextDouble() * 3;
      final speed = 0.3 + random.nextDouble() * 0.7;
      final phase = random.nextDouble() * pi * 2;

      final y = (baseY - progress * speed * size.height * 0.3) % size.height;
      final currentOpacity = (0.08 + 0.12 * sin(progress * pi * 2 + phase))
          .clamp(0.0, 1.0);

      paint.color = color.withValues(alpha: currentOpacity);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, radius);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BgPatternPainter oldDelegate) => true;
}
