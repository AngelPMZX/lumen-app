import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late AnimationController _bgController;
  bool _emailSent = false;
  String? _sentToEmail; // guarda a qué email se envió (independiente del controller)

  // Cooldown para reenvío (Firebase rate-limita ~1 email/min por IP)
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;
  static const int _cooldownDuration = 30;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _bgController.dispose();
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

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final authProvider = context.read<AuthProvider>();
    final locale = context.locale.languageCode;
    final success = await authProvider.sendPasswordResetEmail(
      email,
      languageCode: locale,
    );
    if (success && mounted) {
      setState(() {
        _emailSent = true;
        _sentToEmail = email;
      });
      _startCooldown();
    }
  }

  Future<void> _resendEmail() async {
    if (_cooldownSeconds > 0) return; // cooldown activo
    if (_sentToEmail == null) return;
    final authProvider = context.read<AuthProvider>();
    final locale = context.locale.languageCode;
    final success = await authProvider.sendPasswordResetEmail(
      _sentToEmail!,
      languageCode: locale,
    );
    if (success && mounted) {
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('auth.emailResent'.tr(),
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

  void _goBackToForm() {
    context.read<AuthProvider>().clearError();
    setState(() => _emailSent = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo gradiente
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

          // Partículas
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ForgotBgPainter(progress: _bgController.value),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // Header con back button
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 40),

                      // Icono
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
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
                        child: Icon(
                          _emailSent
                              ? Icons.mark_email_read_rounded
                              : Icons.lock_reset_rounded,
                          size: 46,
                          color: Colors.white,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 700.ms)
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.0, 1.0),
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 20),

                      Text(
                        _emailSent
                            ? 'auth.emailSentTitle'.tr()
                            : 'auth.forgotPasswordTitle'.tr(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 200.ms).fadeIn(duration: 500.ms),

                      const SizedBox(height: 8),

                      Text(
                        _emailSent
                            ? 'auth.emailSentSubtitle'.tr()
                            : 'auth.forgotPasswordSubtitle'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ).animate(delay: 300.ms).fadeIn(duration: 500.ms),

                      const SizedBox(height: 32),

                      // Card
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _emailSent
                            ? _buildSuccessContent(isDark)
                            : _buildFormContent(isDark),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 700.ms)
                          .slideY(begin: 0.1, end: 0, duration: 700.ms),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auth.enterYourEmail'.tr(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Error message
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.errorMessage != null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(
                            color: AppColors.accent, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ).animate().shake(duration: 400.ms);
            }
            return const SizedBox.shrink();
          },
        ),

        Form(
          key: _formKey,
          child: TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'auth.email'.tr(),
              hintStyle: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.email_rounded,
                  color: AppColors.primary, size: 20),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF5F4FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
              errorMaxLines: 3,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _sendResetEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'auth.sendResetLink'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSuccessContent(bool isDark) {
    final onCooldown = _cooldownSeconds > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'auth.checkYourInbox'.tr(namedArgs: {
            'email': _sentToEmail ?? '',
          }),
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'auth.checkSpamFolder'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'auth.backToLogin'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // ── BOTÓN DE REENVÍO REAL con cooldown ─────────────────────────
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            final disabled = onCooldown || auth.isLoading;
            return TextButton(
              onPressed: disabled ? null : _resendEmail,
              child: Text(
                onCooldown
                    ? 'auth.resendEmailCooldown'.tr(
                        namedArgs: {'seconds': '$_cooldownSeconds'})
                    : 'auth.resendEmail'.tr(),
                style: TextStyle(
                  color: disabled
                      ? AppColors.textSecondary
                      : AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _goBackToForm,
          child: Text(
            'auth.useAnotherEmail'.tr(),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Fondo: partículas SIN MaskFilter.blur (safe en web) ─────────────────────
class _ForgotBgPainter extends CustomPainter {
  final double progress;
  _ForgotBgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(88);

    for (int i = 0; i < 25; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height * 0.6;
      final radius = 2 + random.nextDouble() * 5;
      final phase = random.nextDouble() * pi * 2;

      final y = baseY + sin(progress * pi * 2 + phase) * 30;
      final baseOpacity = (0.15 + 0.2 * sin(progress * pi * 2 + phase))
          .clamp(0.0, 1.0);

      // Simula el blur pintando 3 círculos concéntricos con alpha decreciente
      // (evita MaskFilter.blur que rompe WebGL en Flutter web)
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
  bool shouldRepaint(covariant _ForgotBgPainter oldDelegate) => true;
}