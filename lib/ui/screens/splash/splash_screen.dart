import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late List<_Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();

    _particles = List.generate(30, (_) => _Particle(_random));

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isLoggedIn) {
      await authProvider.loadUserData();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      Future.microtask(() {
        if (!mounted) return;
        if (authProvider.isProfileComplete) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
        }
      });
    } else {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;

      Future.microtask(() {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      });
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF7B6CF6),
                  Color(0xFF5A4FCF),
                  Color(0xFF3A2FA8),
                  Color(0xFF1E1157),
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              );
            },
          ),

          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.15);
                final opacity = 0.08 + (_pulseController.value * 0.06);
                return Container(
                  width: 300 * scale,
                  height: 300 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: opacity),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.self_improvement_rounded,
                      size: 68,
                      color: Colors.white,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 1000.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      duration: 1200.ms,
                      curve: Curves.easeOutBack,
                    ),
                const SizedBox(height: 40),

                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFD4D0FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: const Text(
                    'Lumen',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 8,
                      height: 1,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 1000.ms)
                    .slideY(
                      begin: 0.4, end: 0,
                      duration: 1000.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 12),

                Text(
                  'app.tagline'.tr(),
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1200.ms, duration: 800.ms)
                    .slideY(begin: 0.3, end: 0, duration: 800.ms),
                const SizedBox(height: 80),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fadeIn(delay: (1800 + index * 200).ms)
                        .then()
                        .scaleXY(
                          begin: 1.0, end: 1.5,
                          duration: 600.ms,
                          delay: (index * 200).ms,
                        )
                        .fadeOut(
                          begin: 1.0,
                          duration: 600.ms,
                          delay: (index * 200).ms,
                        );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double opacity;
  late double drift;

  _Particle(Random random) {
    x = random.nextDouble();
    y = random.nextDouble();
    size = 2 + random.nextDouble() * 4;
    speed = 0.02 + random.nextDouble() * 0.04;
    opacity = 0.1 + random.nextDouble() * 0.4;
    drift = -0.5 + random.nextDouble();
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentY = (p.y - progress * p.speed * 3) % 1.0;
      final currentX = (p.x + sin(progress * pi * 2 + p.drift) * 0.02);

      final paint = Paint()
        ..color = Colors.white.withValues(
          alpha: p.opacity * (0.5 + 0.5 * sin(progress * pi * 2 + p.x * 10)),
        )
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.8);

      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}