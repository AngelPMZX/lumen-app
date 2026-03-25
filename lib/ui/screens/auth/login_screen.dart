import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  Future<void> _loginWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithGoogle();
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente
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

          // Partículas sutiles
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _LoginBgPainter(progress: _bgController.value),
              );
            },
          ),

          // Contenido
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
                      const SizedBox(height: 40),

                      // Logo y nombre
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
                        child: const Icon(
                          Icons.self_improvement_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 800.ms)
                          .scale(
                            begin: const Offset(0.5, 0.5),
                            end: const Offset(1.0, 1.0),
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 12),
                      const Text(
                        'Lumen',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 40),

                      // Card de login
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.login,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '¡Tu racha te espera! 🔥',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Error message
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                if (auth.errorMessage != null) {
                                  return Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    margin:
                                        const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline,
                                            color: AppColors.accent,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            auth.errorMessage!,
                                            style: const TextStyle(
                                                color: AppColors.accent,
                                                fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().shake(duration: 400.ms);
                                }
                                return const SizedBox.shrink();
                              },
                            ),

                            // Formulario
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _emailController,
                                    hint: AppStrings.email,
                                    icon: Icons.email_rounded,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                    validator: Validators.email,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hint: AppStrings.password,
                                    icon: Icons.lock_rounded,
                                    obscure: _obscurePassword,
                                    validator: Validators.password,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons
                                                .visibility_off_rounded
                                            : Icons
                                                .visibility_rounded,
                                        color: AppColors.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  AppStrings.forgotPassword,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Login button
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed:
                                        auth.isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor: AppColors.primary
                                          .withValues(alpha: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            AppStrings.login,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                        color: Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'o',
                                    style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13),
                                  ),
                                ),
                                Expanded(
                                    child: Divider(
                                        color: Colors.grey.shade300)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Google button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton(
                                onPressed: _loginWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'G',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4285F4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      AppStrings.continueWithGoogle,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                                    .brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 800.ms)
                          .slideY(begin: 0.15, end: 0, duration: 800.ms),

                      const SizedBox(height: 28),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.noAccount,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                                context, AppRoutes.register),
                            child: const Text(
                              AppStrings.register,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 600.ms),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _LoginBgPainter extends CustomPainter {
  final double progress;
  _LoginBgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(99);

    for (int i = 0; i < 25; i++) {
      final x = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height * 0.6;
      final radius = 2 + random.nextDouble() * 5;
      final phase = random.nextDouble() * pi * 2;

      final y = baseY + sin(progress * pi * 2 + phase) * 30;
      final opacity =
          (0.15 + 0.2 * sin(progress * pi * 2 + phase)).clamp(0.0, 1.0);

      paint.color = Colors.white.withValues(alpha: opacity);
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.7);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoginBgPainter oldDelegate) => true;
}