import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../widgets/animated_particles_background.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isSaving = false;
  bool _isChangingPass = false;
  bool _showPassForm = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  List<Map<String, dynamic>> get _archetypes => [
        {
          'id': 'explorador',
          'nameKey': 'archetype.explorerName',
          'nameFallback': 'Explorador Introspectivo',
          'emoji': '🔮',
          'color': const Color(0xFF6366F1),
          'descKey': 'editProfile.archetypes.explorador.shortDesc',
          'descFallback': 'Curioso, reflexivo, busca entenderse',
        },
        {
          'id': 'guerrero',
          'nameKey': 'archetype.warriorName',
          'nameFallback': 'Guerrero Resiliente',
          'emoji': '⚔️',
          'color': const Color(0xFFEF4444),
          'descKey': 'editProfile.archetypes.guerrero.shortDesc',
          'descFallback': 'Fuerte, persistente, no se rinde',
        },
        {
          'id': 'social',
          'nameKey': 'archetype.socialName',
          'nameFallback': 'Alma Social',
          'emoji': '💗',
          'color': const Color(0xFFEC4899),
          'descKey': 'editProfile.archetypes.social.shortDesc',
          'descFallback': 'Empático, conectado, inspira a otros',
        },
        {
          'id': 'sabio',
          'nameKey': 'archetype.sageName',
          'nameFallback': 'Sabio Tranquilo',
          'emoji': '🍃',
          'color': const Color(0xFF10B981),
          'descKey': 'editProfile.archetypes.sabio.shortDesc',
          'descFallback': 'Sereno, equilibrado, busca paz',
        },
        {
          'id': 'libre',
          'nameKey': 'archetype.freeSpiritName',
          'nameFallback': 'Espíritu Libre',
          'emoji': '🌅',
          'color': const Color(0xFFF59E0B),
          'descKey': 'editProfile.archetypes.libre.shortDesc',
          'descFallback': 'Creativo, espontáneo, vive el momento',
        },
      ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.userName);
    _usernameController = TextEditingController(
      text: auth.userModel?.username ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  String _tr(
    String key, {
    String? fallback,
    Map<String, String>? namedArgs,
  }) {
    final value = key.tr(namedArgs: namedArgs ?? const <String, String>{});
    return value == key ? (fallback ?? key) : value;
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave || _isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final auth = context.read<AuthProvider>();
      final (success, error) = await auth.updateUserProfile(
        name: _nameController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _tr(
                      'editProfile.updated',
                      fallback: 'Perfil actualizado',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context, true);
        } else {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? _tr('errors.generic', fallback: 'Error')),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPassController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'validation.passwordTooShort',
              fallback: 'La contraseña debe tener al menos 6 caracteres',
            ),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'validation.passwordsDoNotMatch',
              fallback: 'Las contraseñas no coinciden',
            ),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isChangingPass = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        setState(() => _isChangingPass = false);
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPassController.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPassController.text);

      if (mounted) {
        _currentPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
        setState(() {
          _isChangingPass = false;
          _showPassForm = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.lock_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _tr(
                    'profile.passwordChanged',
                    fallback: 'Contraseña actualizada',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isChangingPass = false);

        String message = _tr(
          'editProfile.changePasswordError',
          fallback: 'Error al cambiar contraseña',
        );

        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          message = _tr(
            'editProfile.wrongCurrentPassword',
            fallback: 'Contraseña actual incorrecta',
          );
        } else if (e.code == 'weak-password') {
          message = _tr(
            'errors.weakPassword',
            fallback: 'La contraseña es muy débil',
          );
        } else if (e.code == 'too-many-requests') {
          message = _tr(
            'errors.tooManyRequests',
            fallback: 'Demasiados intentos. Espera un momento.',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isChangingPass = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    HapticFeedback.mediumImpact();
    final garden = context.read<GardenProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (deleted != true) return;

    garden.resetOnLogout();
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _tr('editProfile.accountDeleted', fallback: 'Cuenta eliminada'),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final userArchetype = auth.userModel?.archetype;
    final isGoogleOnly = auth.isGoogleOnly;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedParticlesBackground(
            particleCount: 12,
            maxShootingStars: isDark ? 1 : 0,
            particleColor: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : const Color(0xFF6366F1).withValues(alpha: 0.1),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          _tr(
                            'profile.editProfile',
                            fallback: 'Editar perfil',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: FilledButton(
                          onPressed: _canSave ? _save : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.primary
                                .withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _tr('common.save', fallback: 'Guardar'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.badge_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _tr(
                                      'editProfile.personalInfo',
                                      fallback: 'Información personal',
                                    ),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _nameController,
                                onChanged: (_) => setState(() {}),
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                decoration: _inputDeco(
                                  _tr(
                                    'editProfile.nameLabel',
                                    fallback: 'Nombre',
                                  ),
                                  isDark,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _usernameController,
                                enabled: false,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                                decoration: _inputDeco(
                                  _tr(
                                    'editProfile.usernameLabel',
                                    fallback: 'Nombre de usuario',
                                  ),
                                  isDark,
                                ).copyWith(
                                  prefixText: '@',
                                  prefixStyle: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.03)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.email_rounded,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        auth.userEmail,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!isGoogleOnly) ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _showPassForm = !_showPassForm,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B)
                                              .withValues(
                                            alpha: isDark ? 0.15 : 0.1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.lock_rounded,
                                          color: Color(0xFFF59E0B),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _tr(
                                                'profile.changePassword',
                                                fallback:
                                                    'Cambiar contraseña',
                                              ),
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              _tr(
                                                'editProfile.passwordAccessDesc',
                                                fallback:
                                                    'Actualiza tu contraseña de acceso',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        _showPassForm
                                            ? Icons.expand_less_rounded
                                            : Icons.expand_more_rounded,
                                        color: AppColors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                                if (_showPassForm) ...[
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _currentPassController,
                                    obscureText: _obscureCurrent,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                    decoration: _inputDeco(
                                      _tr(
                                        'profile.currentPassword',
                                        fallback:
                                            'Contraseña actual',
                                      ),
                                      isDark,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureCurrent
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          size: 20,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscureCurrent =
                                              !_obscureCurrent,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _newPassController,
                                    obscureText: _obscureNew,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                    decoration: _inputDeco(
                                      _tr(
                                        'profile.newPassword',
                                        fallback:
                                            'Nueva contraseña',
                                      ),
                                      isDark,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureNew
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          size: 20,
                                          color: AppColors.textSecondary,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscureNew = !_obscureNew,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _confirmPassController,
                                    obscureText: _obscureNew,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                    decoration: _inputDeco(
                                      _tr(
                                        'profile.confirmNewPassword',
                                        fallback:
                                            'Confirmar contraseña',
                                      ),
                                      isDark,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 46,
                                    child: FilledButton(
                                      onPressed: _isChangingPass
                                          ? null
                                          : _changePassword,
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFF59E0B),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: _isChangingPass
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _tr(
                                                'profile.changePassword',
                                                fallback:
                                                    'Cambiar contraseña',
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Text(
                          _tr(
                            'editProfile.emotionalArchetype',
                            fallback: 'Tu arquetipo emocional',
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _tr(
                            'editProfile.archetypeLockedDesc',
                            fallback:
                                'Determinado en tu registro inicial. No se puede cambiar.',
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(_archetypes.length, (i) {
                          final archetype = _archetypes[i];
                          final isUser = userArchetype == archetype['id'];
                          final color = archetype['color'] as Color;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: isUser ? 1.0 : 0.5,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: isUser
                                      ? LinearGradient(
                                          colors: [
                                            color.withValues(
                                              alpha: isDark ? 0.2 : 0.1,
                                            ),
                                            color.withValues(
                                              alpha: isDark ? 0.08 : 0.04,
                                            ),
                                          ],
                                        )
                                      : null,
                                  color: isUser
                                      ? null
                                      : isDark
                                          ? Colors.white.withValues(alpha: 0.03)
                                          : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isUser
                                        ? color.withValues(alpha: 0.4)
                                        : isDark
                                            ? Colors.white.withValues(
                                                alpha: 0.06,
                                              )
                                            : Colors.grey.shade200,
                                    width: isUser ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: color.withValues(
                                          alpha: isUser ? 0.2 : 0.08,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Text(
                                          archetype['emoji'] as String,
                                          style:
                                              const TextStyle(fontSize: 22),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _tr(
                                              archetype['nameKey'] as String,
                                              fallback: archetype['nameFallback']
                                                  as String,
                                            ),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isUser
                                                  ? color
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            _tr(
                                              archetype['descKey'] as String,
                                              fallback: archetype[
                                                      'descFallback']
                                                  as String,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isUser)
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _tr(
                                            'editProfile.yourArchetype',
                                            fallback: 'Tu arquetipo',
                                          ),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 14),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _confirmDeleteAccount,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(
                                  alpha: isDark ? 0.08 : 0.05,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFEF4444).withValues(
                                    alpha: isDark ? 0.15 : 0.1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444)
                                          .withValues(
                                        alpha: isDark ? 0.15 : 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.delete_forever_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _tr(
                                            'editProfile.deleteAccount',
                                            fallback: 'Eliminar cuenta',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                        Text(
                                          _tr(
                                            'editProfile.deleteAccountDesc',
                                            fallback:
                                                'Borra tu cuenta y todos tus datos para siempre',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  InputDecoration _inputDeco(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}

/// Confirma y ejecuta la eliminación de la cuenta. Retorna true al terminar.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  static const _danger = Color(0xFFEF4444);

  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isDeleting = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String _tr(String key, {String? fallback}) {
    final value = key.tr();
    return value == key ? (fallback ?? key) : value;
  }

  bool _canDelete(bool isGoogleOnly) =>
      !_isDeleting &&
      (isGoogleOnly || _passwordController.text.isNotEmpty);

  Future<void> _delete() async {
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final (success, error) = await auth.deleteAccount(
      password: auth.isGoogleOnly ? null : _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isDeleting = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGoogleOnly = context.read<AuthProvider>().isGoogleOnly;

    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _tr('editProfile.deleteAccountTitle',
              fallback: '¿Eliminar tu cuenta?'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tr('editProfile.deleteAccountWarning',
                  fallback:
                      'Se borrarán tu progreso, racha, diario, hábitos, recordatorios y jardín. Esto no se puede deshacer.'),
            ),
            const SizedBox(height: 16),
            if (isGoogleOnly)
              Text(
                _tr('editProfile.deleteAccountGoogleHint',
                    fallback:
                        'Para confirmar, elige tu cuenta de Google en el siguiente paso.'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              )
            else
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                enabled: !_isDeleting,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_canDelete(isGoogleOnly)) _delete();
                },
                decoration: InputDecoration(
                  labelText: _tr('editProfile.deleteAccountPasswordHint',
                      fallback: 'Escribe tu contraseña para confirmar'),
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _danger, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: _danger),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed:
                _isDeleting ? null : () => Navigator.of(context).pop(false),
            child: Text(
              _tr('common.cancel', fallback: 'Cancelar'),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: _canDelete(isGoogleOnly) ? _delete : null,
            style: FilledButton.styleFrom(
              backgroundColor: _danger,
              disabledBackgroundColor: _danger.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _tr('editProfile.deleteAccount',
                        fallback: 'Eliminar cuenta'),
                  ),
          ),
        ],
      ),
    );
  }
}
