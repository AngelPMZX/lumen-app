import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../../domain/services/motion_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bgController;

  // Auto-check cada 5s
  Timer? _autoCheckTimer;

  // Cooldown para reenvío (30s)
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  static const int _cooldownDuration = 30;

  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeatUnlessReduced();

    // Auto-check periódico
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _autoCheck();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = _cooldownDuration);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _cooldownSeconds--);
      if (_cooldownSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _autoCheck() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final verified = await auth.checkEmailVerified();
    if (verified && mounted) {
      _autoCheckTimer?.cancel();
      _navigateAfterVerification();
    }
  }

  Future<void> _manualCheck() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    final auth = context.read<AuthProvider>();
    final verified = await auth.checkEmailVerified();
    if (!mounted) return;
    setState(() => _isChecking = false);
    if (verified) {
      _autoCheckTimer?.cancel();
      _navigateAfterVerification();
    } else {
      // Mostrar hint que aún no está verificado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'auth.verifyEmailNotYetVerified'.tr(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _resendEmail() async {
    if (_cooldownSeconds > 0) return;
    final auth = context.read<AuthProvider>();
    final locale = context.locale.languageCode;
    final success = await auth.resendEmailVerification(languageCode: locale);
    if (!mounted) return;
    if (success) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('auth.verifyEmailResendSuccess'.tr(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _backToLogin() async {
    final auth = context.read<AuthProvider>();
    final garden = context.read<GardenProvider>();
    await auth.logout();
    garden.resetOnLogout();
    auth.clearVerificationState();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  void _navigateAfterVerification() {
    // Snackbar de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.verified_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text('auth.verifyEmailSuccess'.tr(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );

    // Decidir a dónde ir según si el perfil está completo
    final auth = context.read<AuthProvider>();
    final destination = auth.isProfileComplete
        ? AppRoutes.home
        : AppRoutes.profileSetup;

    // Pequeño delay para que se vea el snackbar antes de navegar
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        destination,
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final email = auth.pendingVerificationEmail ?? '';
    final onCooldown = _cooldownSeconds > 0;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo gradiente lila
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6C63FF),
                  Color(0xFF5A4FCF),
                  Color(0xFF1E1157),
                ],
                stops: [0.0, 0.3, 1.0],
              ),
            ),
          ),

          // Partículas de fondo
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _VerifyBgPainter(progress: _bgController.value),
              );
            },
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 460),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
                      const SizedBox(height: 40),

                      // Icono grande — email con reloj
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.25),
                              Colors.white.withValues(alpha: 0.08),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      )
                          .animate(onPlay: MotionService.loop(context, reverse: true))
                          .scale(
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1.05, 1.05),
                            duration: 2000.ms,
                            curve: Curves.easeInOut,
                          )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.0, 1.0),
                            duration: 700.ms,
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 24),

                      Text(
                        'auth.verifyEmailTitle'.tr(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                      const SizedBox(height: 8),

                      Text(
                        'auth.verifyEmailSubtitle'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

                      const SizedBox(height: 28),

                      // Card
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Icono central de estado
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.email_rounded,
                                  color: AppColors.primary,
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Instrucciones con email
                            Text(
                              'auth.verifyEmailInstructions'.tr(
                                  namedArgs: {'email': email}),
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),

                            // Hint auto-check
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          const AlwaysStoppedAnimation(
                                              AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'auth.verifyEmailWaitingHint'.tr(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: isDark
                                            ? Colors.white60
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Botón principal: "Ya verifiqué mi correo"
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isChecking ? null : _manualCheck,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor:
                                      AppColors.primary.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isChecking
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'auth.verifyEmailCta'.tr(),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Botón secundario: "Reenviar correo" con cooldown
                            TextButton(
                              onPressed: onCooldown ? null : _resendEmail,
                              child: Text(
                                onCooldown
                                    ? 'auth.resendEmailCooldown'.tr(
                                        namedArgs: {
                                            'seconds': '$_cooldownSeconds'
                                          })
                                    : 'auth.verifyEmailResend'.tr(),
                                style: TextStyle(
                                  color: onCooldown
                                      ? AppColors.textSecondary
                                      : AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),

                            // Info spam
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        Colors.orange.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded,
                                      color: Colors.orange, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'auth.checkSpamFolder'.tr(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.4,
                                        color: isDark
                                            ? Colors.white60
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 700.ms)
                          .slideY(begin: 0.1, end: 0, duration: 700.ms),

                      const SizedBox(height: 20),

                      // Volver al login
                      TextButton(
                        onPressed: _backToLogin,
                        child: Text(
                          'auth.verifyEmailBackToLogin'.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate(delay: 700.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: 20),
                    ],
                  ),),),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fondo: partículas SIN MaskFilter.blur (safe en web) ─────────────────────
class _VerifyBgPainter extends CustomPainter {
  final double progress;
  _VerifyBgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(99);

    for (int i = 0; i < 25; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height * 0.6;
      final radius = 2 + random.nextDouble() * 5;
      final phase = random.nextDouble() * pi * 2;

      final y = baseY + sin(progress * pi * 2 + phase) * 30;
      final baseOpacity = (0.15 + 0.2 * sin(progress * pi * 2 + phase))
          .clamp(0.0, 1.0);

      final glowOuter = Paint()
        ..color = Colors.white.withValues(alpha: baseOpacity * 0.15);
      canvas.drawCircle(Offset(x, y), radius * 2.4, glowOuter);

      final glowMid = Paint()
        ..color = Colors.white.withValues(alpha: baseOpacity * 0.3);
      canvas.drawCircle(Offset(x, y), radius * 1.6, glowMid);

      final core = Paint()
        ..color = Colors.white.withValues(alpha: baseOpacity);
      canvas.drawCircle(Offset(x, y), radius, core);
    }
  }

  @override
  bool shouldRepaint(covariant _VerifyBgPainter oldDelegate) => true;
}