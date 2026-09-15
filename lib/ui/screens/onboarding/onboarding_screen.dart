import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/providers/auth_provider.dart';

class _SlideData {
  final String asset;
  final String titleKey;
  final String descriptionKey;
  final Color topColor;
  final Color midColor;
  final Color bottomColor;
  final Color accentColor;
  final String fallbackEmoji;

  const _SlideData({
    required this.asset,
    required this.titleKey,
    required this.descriptionKey,
    required this.topColor,
    required this.midColor,
    required this.bottomColor,
    required this.accentColor,
    required this.fallbackEmoji,
  });
}

const List<_SlideData> _slides = [
  _SlideData(
    asset: 'assets/images/onboarding/slide_welcome.png',
    titleKey: 'onboarding.slide1.title',
    descriptionKey: 'onboarding.slide1.description',
    topColor: Color(0xFF10B981),
    midColor: Color(0xFF065F46),
    bottomColor: Color(0xFF022C22),
    accentColor: Color(0xFF34D399),
    fallbackEmoji: '🌱',
  ),
  _SlideData(
    asset: 'assets/images/onboarding/slide_routes.png',
    titleKey: 'onboarding.slide2.title',
    descriptionKey: 'onboarding.slide2.description',
    topColor: Color(0xFFF97316),
    midColor: Color(0xFF9A3412),
    bottomColor: Color(0xFF431407),
    accentColor: Color(0xFFFBBF24),
    fallbackEmoji: '🔥',
  ),
  _SlideData(
    asset: 'assets/images/onboarding/slide_diary.png',
    titleKey: 'onboarding.slide3.title',
    descriptionKey: 'onboarding.slide3.description',
    topColor: Color(0xFF3B82F6),
    midColor: Color(0xFF1E40AF),
    bottomColor: Color(0xFF172554),
    accentColor: Color(0xFF60A5FA),
    fallbackEmoji: '📖',
  ),
  _SlideData(
    asset: 'assets/images/onboarding/slide_garden.png',
    titleKey: 'onboarding.slide4.title',
    descriptionKey: 'onboarding.slide4.description',
    topColor: Color(0xFF8B5CF6),
    midColor: Color(0xFF6D28D9),
    bottomColor: Color(0xFF2E1065),
    accentColor: Color(0xFFC084FC),
    fallbackEmoji: '🌿',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController();
  late AnimationController _bgCtrl;
  double _pageValue = 0.0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _pageCtrl.addListener(() {
      setState(() => _pageValue = _pageCtrl.page ?? 0.0);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  // Interpola entre los colores del slide actual y el siguiente
  Color _interpolatedColor(Color Function(_SlideData) getter) {
    final currentIdx = _pageValue.floor().clamp(0, _slides.length - 1);
    final nextIdx = (currentIdx + 1).clamp(0, _slides.length - 1);
    final t = _pageValue - currentIdx;
    return Color.lerp(getter(_slides[currentIdx]), getter(_slides[nextIdx]), t)!;
  }

  int get _currentPage => _pageValue.round().clamp(0, _slides.length - 1);
  bool get _isLastPage => _currentPage == _slides.length - 1;

  Future<void> _next() async {
    HapticFeedback.lightImpact();
    if (_isLastPage) {
      await _finish();
    } else {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _skip() async {
    HapticFeedback.selectionClick();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'onboarding.skipConfirmTitle'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text('onboarding.skipConfirmMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'onboarding.skipConfirmNo'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: _interpolatedColor((s) => s.topColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('onboarding.skipConfirmYes'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _finish();
    }
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    HapticFeedback.mediumImpact();
    try {
      await context.read<AuthProvider>().markOnboardingCompleted();
    } catch (e) {
      debugPrint('Error marking onboarding: $e');
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topColor = _interpolatedColor((s) => s.topColor);
    final midColor = _interpolatedColor((s) => s.midColor);
    final bottomColor = _interpolatedColor((s) => s.bottomColor);
    final accentColor = _interpolatedColor((s) => s.accentColor);

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente dinámico (interpolado según el slide)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, midColor, bottomColor],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Partículas flotantes
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _OnboardingBgPainter(progress: _bgCtrl.value),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // ── HEADER: Skip button ─────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isLastPage ? 0 : 1,
                        child: TextButton(
                          onPressed: _isLastPage ? null : _skip,
                          child: Text(
                            'onboarding.skip'.tr(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── PAGEVIEW ────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: _slides.length,
                    itemBuilder: (context, i) => _buildSlide(_slides[i]),
                  ),
                ),

                // ── INDICADORES DE PROGRESO ─────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: isActive ? 32 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                ),

                // ── BOTÓN SIGUIENTE / EMPEZAR ───────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FilledButton(
                      onPressed: _finishing ? null : _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: midColor,
                        elevation: 8,
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _finishing
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: midColor,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLastPage
                                      ? 'onboarding.start'.tr()
                                      : 'onboarding.next'.tr(),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: midColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _isLastPage
                                      ? Icons.rocket_launch_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: midColor,
                                  size: 22,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_SlideData slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Ilustración con glow
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: slide.accentColor.withValues(alpha: 0.35),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Image.asset(
              slide.asset,
              width: 280,
              height: 280,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Text(
                    slide.fallbackEmoji,
                    style: const TextStyle(fontSize: 120),
                  ),
                ),
              ),
            ),
          )
              .animate(key: ValueKey(slide.asset))
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                duration: 700.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 40),

          // Título
          Text(
            slide.titleKey.tr(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('title-${slide.titleKey}'))
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .slideY(begin: 0.15, end: 0),

          const SizedBox(height: 16),

          // Descripción
          Text(
            slide.descriptionKey.tr(),
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('desc-${slide.descriptionKey}'))
              .fadeIn(delay: 350.ms, duration: 500.ms)
              .slideY(begin: 0.15, end: 0),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ─── Fondo con partículas flotantes ──────────────────────────────────────────
class _OnboardingBgPainter extends CustomPainter {
  final double progress;
  _OnboardingBgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final radius = 1.5 + random.nextDouble() * 4;
      final phase = random.nextDouble() * pi * 2;

      final y = baseY + sin(progress * pi * 2 + phase) * 25;
      final baseOpacity =
          (0.1 + 0.2 * sin(progress * pi * 2 + phase)).clamp(0.0, 1.0);

      // Simulación de blur con círculos concéntricos (safe en web)
      final glow = Paint()
        ..color = Colors.white.withValues(alpha: baseOpacity * 0.15);
      canvas.drawCircle(Offset(x, y), radius * 2.4, glow);

      final mid = Paint()
        ..color = Colors.white.withValues(alpha: baseOpacity * 0.3);
      canvas.drawCircle(Offset(x, y), radius * 1.5, mid);

      final core = Paint()
        ..color = Colors.white.withValues(alpha: baseOpacity);
      canvas.drawCircle(Offset(x, y), radius, core);
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingBgPainter old) => true;
}