import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/lumi.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/journal/journal_style.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import '../../widgets/min_tap_target.dart';
import 'widgets/auth_widgets.dart';

/// Entrar a Lumen con correo o con Google.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _indigo = Color(0xFF6366F1);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      SoundService.instance.play(Sfx.wrong, volume: 0.4);
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      SoundService.instance.play(Sfx.unlock, volume: 0.45);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (auth.needsEmailVerification) {
      // Login correcto pero falta verificar el correo
      Navigator.pushReplacementNamed(context, AppRoutes.verifyEmail);
    } else {
      SoundService.instance.play(Sfx.wrong, volume: 0.4);
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _loginWithGoogle() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    setState(() => _googleLoading = true);
    final success = await auth.loginWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (success) {
      SoundService.instance.play(Sfx.unlock, volume: 0.45);
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (auth.errorMessage != null) {
      SoundService.instance.play(Sfx.wrong, volume: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          const AuthBackground(colors: [Color(0xFF6C63FF), Color(0xFF4A42DB), Color(0xFF1E1157)]),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                children: [
                  // Lumi da la bienvenida
                  const LumiAvatar(mood: LumiMood.happy, size: 88)
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 700.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 6),
                  Semantics(
                    header: true,
                    child: Text(
                      'app.name'.tr(),
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                  Text(
                    'auth.streakWaiting'.tr(),
                    textAlign: TextAlign.center,
                    style: JournalStyle.hand(TextStyle(fontSize: 20, height: 1.1, color: Colors.white.withValues(alpha: 0.9))),
                  ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                  const SizedBox(height: 20),
                  AuthCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'auth.login'.tr(),
                            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.textPrimary),
                          ),
                          const SizedBox(height: 18),
                          if (auth.errorMessage != null) AuthErrorBanner(message: auth.errorMessage!),
                          AuthField(
                            controller: _emailController,
                            label: 'auth.email'.tr(),
                            icon: Icons.email_rounded,
                            accent: _indigo,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.email,
                            autofillHint: AutofillHints.username,
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            controller: _passwordController,
                            label: 'auth.password'.tr(),
                            icon: Icons.lock_rounded,
                            accent: _indigo,
                            obscure: _obscurePassword,
                            validator: Validators.password,
                            autofillHint: AutofillHints.password,
                            textInputAction: TextInputAction.done,
                            onSubmitted: _login,
                            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                              style: TextButton.styleFrom(foregroundColor: _indigo, minimumSize: const Size(48, 44)),
                              child: Text('auth.forgotPassword'.tr(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          AuthPrimaryButton(
                            label: 'auth.login'.tr(),
                            color: _indigo,
                            loading: auth.isLoading && !_googleLoading,
                            onTap: _login,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? Colors.white24 : const Color(0xFFE6E1F8))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('common.or'.tr(), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                              Expanded(child: Divider(color: isDark ? Colors.white24 : const Color(0xFFE6E1F8))),
                            ],
                          ),
                          const SizedBox(height: 18),
                          GoogleButton(onTap: _loginWithGoogle, loading: _googleLoading || auth.isLoading),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('auth.noAccount'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14)),
                      const SizedBox(width: 6),
                      Semantics(
                        button: true,
                        label: 'auth.register'.tr(),
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.register),
                        excludeSemantics: true,
                        child: MinTapTarget(
                          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.register),
                          child: Text(
                            'auth.register'.tr(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 450.ms, duration: 350.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
