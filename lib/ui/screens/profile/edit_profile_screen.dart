import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/lumi.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/garden_provider.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import '../../widgets/min_tap_target.dart';
import '../garden/widgets/garden_common.dart' show GardenSheet;
import 'widgets/edit_profile_widgets.dart';
import 'widgets/profile_widgets.dart' show ArchetypeStyle;

/// Editar perfil: vista previa de cómo te verás, nombre, nombre de usuario
/// (con aviso de disponibilidad), tu arquetipo, contraseña y eliminar cuenta.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _danger = Color(0xFFDC5F4A);

  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  late final String _initialName;
  late final String _initialUsername;

  bool _isSaving = false;
  bool _isChangingPass = false;
  bool _showPassForm = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  // Estado del nombre de usuario
  Timer? _debounce;
  bool _checking = false;
  bool _available = false;
  String? _usernameError;

  static const _archetypes = [
    ('explorador', 'archetype.explorerName', 'editProfile.archetypes.explorador.shortDesc', '🧭', Color(0xFF6366F1)),
    ('guerrero', 'archetype.warriorName', 'editProfile.archetypes.guerrero.shortDesc', '🛡️', Color(0xFFEF4444)),
    ('social', 'archetype.socialName', 'editProfile.archetypes.social.shortDesc', '🤝', Color(0xFFEC4899)),
    ('sabio', 'archetype.sageName', 'editProfile.archetypes.sabio.shortDesc', '🦉', Color(0xFF10B981)),
    ('libre', 'archetype.freeSpiritName', 'editProfile.archetypes.libre.shortDesc', '🕊️', Color(0xFFF59E0B)),
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _initialName = auth.userName;
    _initialUsername = auth.userModel?.username ?? '';
    _nameController = TextEditingController(text: _initialName);
    _usernameController = TextEditingController(text: _initialUsername);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  String get _name => _nameController.text.trim();
  String get _username => _usernameController.text.trim().toLowerCase();
  bool get _usernameChanged => _username != _initialUsername;
  bool get _dirty => _name != _initialName || _usernameChanged;

  bool get _canSave =>
      !_isSaving &&
      _dirty &&
      _name.length >= 2 &&
      (!_usernameChanged || (_usernameError == null && !_checking && (_available || _username.isEmpty)));

  // ═══════════════════════════════════════════════════════════════════════════
  // Nombre de usuario
  // ═══════════════════════════════════════════════════════════════════════════

  void _onUsernameChanged(String value) {
    _debounce?.cancel();
    final clean = value.trim().toLowerCase();
    setState(() {
      _available = false;
      _checking = false;
      _usernameError = clean == _initialUsername ? null : Validators.username(clean);
    });
    if (clean == _initialUsername || _usernameError != null) return;

    setState(() => _checking = true);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final auth = context.read<AuthProvider>();
      final taken = await auth.isUsernameTaken(clean);
      if (!mounted || _username != clean) return;
      setState(() {
        _checking = false;
        _available = !taken;
        _usernameError = taken ? 'profileSetup.usernameTaken'.tr() : null;
      });
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Guardar
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    final auth = context.read<AuthProvider>();
    final (success, error) = await auth.updateUserProfile(
      name: _name,
      username: _usernameChanged && _username.isNotEmpty ? _username : null,
    );
    if (!mounted) return;
    if (success) {
      SoundService.instance.play(Sfx.save, volume: 0.5);
      _toast('editProfile.updated'.tr(), icon: Icons.check_circle_rounded);
      Navigator.pop(context, true);
      return;
    }
    setState(() => _isSaving = false);
    SoundService.instance.play(Sfx.wrong, volume: 0.45);
    _toast(error ?? 'errors.generic'.tr(), color: _danger, icon: Icons.error_outline_rounded);
  }

  void _toast(String text, {Color color = const Color(0xFF10B981), IconData icon = Icons.check_circle_rounded}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, 0.2)!]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5))),
            ],
          ),
        ),
      ));
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final leave = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GardenSheet(
        title: 'editProfile.discardTitle'.tr(),
        leading: const LumiAvatar(mood: LumiMood.curious, size: 54),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('editProfile.discardBody'.tr(), style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text('editProfile.discardLeave'.tr()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('editProfile.discardStay'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return leave ?? false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Contraseña y cuenta
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _changePassword() async {
    if (_newPassController.text.length < 6) {
      SoundService.instance.play(Sfx.wrong, volume: 0.4);
      _toast('validation.passwordTooShort'.tr(), color: _danger, icon: Icons.error_outline_rounded);
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      SoundService.instance.play(Sfx.wrong, volume: 0.4);
      _toast('validation.passwordsDoNotMatch'.tr(), color: _danger, icon: Icons.error_outline_rounded);
      return;
    }
    setState(() => _isChangingPass = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        setState(() => _isChangingPass = false);
        return;
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: _currentPassController.text),
      );
      await user.updatePassword(_newPassController.text);
      if (!mounted) return;
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
      setState(() {
        _isChangingPass = false;
        _showPassForm = false;
      });
      SoundService.instance.play(Sfx.save, volume: 0.5);
      _toast('profile.passwordChanged'.tr(), icon: Icons.lock_rounded);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isChangingPass = false);
      final message = switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'editProfile.wrongCurrentPassword'.tr(),
        'weak-password' => 'errors.weakPassword'.tr(),
        'too-many-requests' => 'errors.tooManyRequests'.tr(),
        _ => 'editProfile.changePasswordError'.tr(),
      };
      SoundService.instance.play(Sfx.wrong, volume: 0.45);
      _toast(message, color: _danger, icon: Icons.error_outline_rounded);
    } catch (_) {
      if (mounted) setState(() => _isChangingPass = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    HapticFeedback.mediumImpact();
    final garden = context.read<GardenProvider>();
    final navigator = Navigator.of(context);
    final deleted = await showDialog<bool>(context: context, builder: (_) => const _DeleteAccountDialog());
    if (deleted != true) return;
    garden.resetOnLogout();
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final archetype = auth.userModel?.archetype;
    final colors = ArchetypeStyle.colors(archetype);
    final ink = isDark ? Colors.white : AppColors.textPrimary;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFF6F3FF),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 4),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'common.back'.tr(),
                      onTap: () => Navigator.maybePop(context),
                      excludeSemantics: true,
                      child: MinTapTarget(
                        onTap: () => Navigator.maybePop(context),
                        child: Icon(Icons.arrow_back_rounded, color: ink),
                      ),
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'profile.editProfile'.tr(),
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: ink),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  children: [
                    EditPreviewCard(
                      name: _name.isEmpty ? _initialName : _name,
                      username: _username,
                      archetypeName: ArchetypeStyle.name(archetype),
                      archetypeEmoji: ArchetypeStyle.emoji(archetype),
                      colors: colors,
                    ),
                    const SizedBox(height: 22),
                    EditSectionTitle(kicker: 'editProfile.infoKicker'.tr(), title: 'editProfile.personalInfo'.tr(), isDark: isDark),
                    const SizedBox(height: 10),
                    EditCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EditField(
                            controller: _nameController,
                            label: 'editProfile.nameLabel'.tr(),
                            icon: Icons.person_rounded,
                            isDark: isDark,
                            maxLength: 30,
                            onChanged: (_) => setState(() {}),
                            helper: _name.isNotEmpty && _name.length < 2 ? 'validation.nameTooShort'.tr() : null,
                            helperIsError: true,
                          ),
                          const SizedBox(height: 14),
                          EditField(
                            controller: _usernameController,
                            label: 'editProfile.usernameLabel'.tr(),
                            icon: Icons.alternate_email_rounded,
                            isDark: isDark,
                            maxLength: 20,
                            prefixText: '@',
                            onChanged: _onUsernameChanged,
                            helper: _usernameError ??
                                (_checking
                                    ? 'editProfile.usernameChecking'.tr()
                                    : _available && _usernameChanged
                                        ? 'editProfile.usernameAvailable'.tr()
                                        : 'editProfile.usernameHint'.tr()),
                            helperIsError: _usernameError != null,
                            helperIsGood: _available && _usernameChanged && _usernameError == null,
                            suffix: _checking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  )
                                : _usernameError != null
                                    ? const Icon(Icons.error_outline_rounded, color: _danger, size: 20)
                                    : _available && _usernameChanged
                                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
                                        : null,
                          ),
                          const SizedBox(height: 14),
                          LockedInfoRow(
                            icon: Icons.email_rounded,
                            text: auth.userEmail,
                            trailing: auth.firebaseUser?.emailVerified == true ? 'editProfile.verified'.tr() : null,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    EditSectionTitle(kicker: 'editProfile.archetypeKicker'.tr(), title: 'profile.archetype'.tr(), isDark: isDark),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 10),
                      child: Text(
                        'editProfile.archetypeLockedDesc'.tr(),
                        style: TextStyle(fontSize: 12.5, height: 1.35, color: isDark ? Colors.white54 : AppColors.textSecondary),
                      ),
                    ),
                    for (final (i, (id, nameKey, descKey, emoji, color)) in _archetypes.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ArchetypeRow(
                          isMine: archetype == id,
                          name: nameKey.tr(),
                          description: descKey.tr(),
                          emoji: emoji,
                          color: color,
                          isDark: isDark,
                        ).animate().fadeIn(delay: (60 * i).ms, duration: 300.ms).slideX(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                      ),
                    if (!auth.isGoogleOnly) ...[
                      const SizedBox(height: 14),
                      EditSectionTitle(kicker: 'editProfile.securityKicker'.tr(), title: 'editProfile.security'.tr(), isDark: isDark),
                      const SizedBox(height: 10),
                      PasswordCard(
                        isDark: isDark,
                        expanded: _showPassForm,
                        busy: _isChangingPass,
                        currentController: _currentPassController,
                        newController: _newPassController,
                        confirmController: _confirmPassController,
                        obscureCurrent: _obscureCurrent,
                        obscureNew: _obscureNew,
                        onToggleExpanded: () {
                          SoundService.instance.play(_showPassForm ? Sfx.toggleOff : Sfx.toggleOn, volume: 0.35);
                          setState(() => _showPassForm = !_showPassForm);
                        },
                        onToggleObscureCurrent: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        onToggleObscureNew: () => setState(() => _obscureNew = !_obscureNew),
                        onSubmit: _changePassword,
                      ),
                    ],
                    const SizedBox(height: 22),
                    DangerZoneCard(isDark: isDark, onDelete: _confirmDeleteAccount),
                  ],
                ),
              ),
              // Barra de guardar: aparece solo si hay cambios
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: _dirty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF17182A) : Colors.white,
                          border: Border(top: BorderSide(color: ink.withValues(alpha: 0.08))),
                        ),
                        child: SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _canSave ? _save : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.first,
                              disabledBackgroundColor: colors.first.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isSaving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(
                                    'editProfile.saveChanges'.tr(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                          ),
                        ),
                      ).animate().slideY(begin: 0.4, end: 0, duration: 250.ms, curve: Curves.easeOutCubic)
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Eliminar cuenta
// ═════════════════════════════════════════════════════════════════════════════

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

  bool _canDelete(bool isGoogleOnly) => !_isDeleting && (isGoogleOnly || _passwordController.text.isNotEmpty);

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: const Text('🕊️', style: TextStyle(fontSize: 30)),
        title: Text(
          'editProfile.deleteAccountTitle'.tr(),
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('editProfile.deleteAccountWarning'.tr(), style: const TextStyle(fontSize: 13.5, height: 1.4)),
            const SizedBox(height: 16),
            if (isGoogleOnly)
              Text(
                'editProfile.deleteAccountGoogleHint'.tr(),
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
                  labelText: 'editProfile.deleteAccountPasswordHint'.tr(),
                  labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _danger, width: 1.5),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(fontSize: 13, color: _danger)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: _canDelete(isGoogleOnly) ? _delete : null,
            style: FilledButton.styleFrom(
              backgroundColor: _danger,
              disabledBackgroundColor: _danger.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isDeleting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('editProfile.deleteAccount'.tr()),
          ),
        ],
      ),
    );
  }
}
