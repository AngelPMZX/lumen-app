import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/lumi.dart';
import '../../../data/models/password_strength.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/journal/journal_style.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import '../../widgets/min_tap_target.dart';
import 'widgets/auth_widgets.dart';

/// Crear cuenta: nombre, correo y una contraseña que de verdad proteja la
/// cuenta (mínimo 8, con letras y números, nada de las más usadas ni tus
/// propios datos).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _green = Color(0xFF10B981);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  PasswordStrength _strength = PasswordStrength.check('');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  List<String> get _personal => [_emailController.text.trim(), _nameController.text.trim()];

  void _onPasswordChanged(String value) {
    setState(() => _strength = PasswordStrength.check(value, personal: _personal));
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      SoundService.instance.play(Sfx.wrong, volume: 0.4);
      HapticFeedback.mediumImpact();
      return;
    }
    final auth = context.read<AuthProvider>();
    final success = await auth.registerWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      languageCode: context.locale.languageCode,
    );
    if (!mounted) return;
    if (success) {
      SoundService.instance.play(Sfx.unlock, volume: 0.5);
      Navigator.pushReplacementNamed(context, AppRoutes.verifyEmail);
    } else {
      SoundService.instance.play(Sfx.wrong, volume: 0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          const AuthBackground(colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFF064E3B)]),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                children: [
                  Row(
                    children: [
                      Semantics(
                        button: true,
                        label: 'common.back'.tr(),
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                        excludeSemantics: true,
                        child: MinTapTarget(
                          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 21),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'auth.journeyStarts'.tr(),
                              style: JournalStyle.hand(const TextStyle(fontSize: 19, height: 1.0, color: Color(0xFFA7F3D0))),
                            ),
                            Semantics(
                              header: true,
                              child: Text(
                                'auth.joinLumen'.tr(),
                                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const LumiAvatar(mood: LumiMood.excited, size: 58),
                    ],
                  ).animate().fadeIn(duration: 450.ms).slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 22),
                  AuthCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'auth.register'.tr(),
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('auth.completeData'.tr(), style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                          const SizedBox(height: 20),
                          if (auth.errorMessage != null) AuthErrorBanner(message: auth.errorMessage!),
                          AuthField(
                            controller: _nameController,
                            label: 'auth.name'.tr(),
                            icon: Icons.person_rounded,
                            accent: _green,
                            validator: Validators.name,
                            capitalization: TextCapitalization.words,
                            autofillHint: AutofillHints.name,
                            onChanged: (_) => _onPasswordChanged(_passwordController.text),
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            controller: _emailController,
                            label: 'auth.email'.tr(),
                            icon: Icons.email_rounded,
                            accent: _green,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.email,
                            autofillHint: AutofillHints.email,
                            onChanged: (_) => _onPasswordChanged(_passwordController.text),
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            controller: _passwordController,
                            label: 'auth.password'.tr(),
                            icon: Icons.lock_rounded,
                            accent: _green,
                            obscure: _obscurePassword,
                            autofillHint: AutofillHints.newPassword,
                            validator: (v) => Validators.strongPassword(v, personal: _personal),
                            onChanged: _onPasswordChanged,
                            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(height: 10),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: _strength.level == PasswordLevel.empty
                                ? const SizedBox(width: double.infinity)
                                : PasswordStrengthMeter(strength: _strength),
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            controller: _confirmController,
                            label: 'auth.confirmPassword'.tr(),
                            icon: Icons.lock_reset_rounded,
                            accent: _green,
                            obscure: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onSubmitted: _register,
                            validator: (v) => Validators.confirmPassword(v, _passwordController.text),
                            onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          const SizedBox(height: 22),
                          AuthPrimaryButton(
                            label: 'auth.register'.tr(),
                            color: _green,
                            loading: auth.isLoading,
                            onTap: _register,
                          ),
                          const SizedBox(height: 12),
                          const PrivacyNote(accent: _green),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.hasAccount'.tr(),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Semantics(
                        button: true,
                        label: 'auth.login'.tr(),
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                        excludeSemantics: true,
                        child: MinTapTarget(
                          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                          child: Text(
                            'auth.login'.tr(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms, duration: 350.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
