import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.registerWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF10B981),
                  Color(0xFF059669),
                  Color(0xFF064E3B),
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
                painter:
                    _RegisterBgPainter(progress: _bgController.value),
              );
            },
          ),

          // Contenido
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, AppRoutes.login),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color:
                                    Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Únete a Lumen',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Tu viaje comienza aquí ✨',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: 28),

                    // Card de registro
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
                            color:
                                Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.register,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completa tus datos para crear tu cuenta',
                            style: TextStyle(
                              fontSize: 14,
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
                                  margin: const EdgeInsets.only(
                                      bottom: 16),
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

                          // Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _nameController,
                                  hint: AppStrings.name,
                                  icon: Icons.person_rounded,
                                  validator: Validators.name,
                                  capitalization:
                                      TextCapitalization.words,
                                ),
                                const SizedBox(height: 14),
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
                                const SizedBox(height: 14),
                                _buildTextField(
                                  controller:
                                      _confirmPasswordController,
                                  hint: AppStrings.confirmPassword,
                                  icon: Icons.lock_rounded,
                                  obscure: _obscureConfirm,
                                  validator: (v) =>
                                      Validators.confirmPassword(
                                          v,
                                          _passwordController.text),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons
                                              .visibility_off_rounded
                                          : Icons
                                              .visibility_rounded,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirm =
                                            !_obscureConfirm),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Register button
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading
                                      ? null
                                      : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor:
                                        const Color(0xFF10B981)
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
                                          AppStrings.register,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 800.ms)
                        .slideY(
                            begin: 0.15,
                            end: 0,
                            duration: 800.ms),

                    const SizedBox(height: 28),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.hasAccount,
                          style: TextStyle(
                            color:
                                Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushReplacementNamed(
                                  context, AppRoutes.login),
                          child: const Text(
                            AppStrings.login,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 32),
                  ],
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
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      textCapitalization: capitalization,
      style: TextStyle(
        color: isDark ? Colors.white : AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon:
            Icon(icon, color: const Color(0xFF10B981), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFF0FDF9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _RegisterBgPainter extends CustomPainter {
  final double progress;
  _RegisterBgPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final random = Random(77);

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
  bool shouldRepaint(covariant _RegisterBgPainter oldDelegate) => true;
}