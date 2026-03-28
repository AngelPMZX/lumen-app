import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/providers/auth_provider.dart';
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

  final _archetypes = [
    {'id': 'explorador', 'name': 'Explorador Introspectivo', 'emoji': '🔮',
     'color': const Color(0xFF6366F1), 'desc': 'Curioso, reflexivo, busca entenderse'},
    {'id': 'guerrero', 'name': 'Guerrero Resiliente', 'emoji': '⚔️',
     'color': const Color(0xFFEF4444), 'desc': 'Fuerte, persistente, no se rinde'},
    {'id': 'social', 'name': 'Alma Social', 'emoji': '💗',
     'color': const Color(0xFFEC4899), 'desc': 'Empático, conectado, inspira a otros'},
    {'id': 'sabio', 'name': 'Sabio Tranquilo', 'emoji': '🍃',
     'color': const Color(0xFF10B981), 'desc': 'Sereno, equilibrado, busca paz'},
    {'id': 'libre', 'name': 'Espíritu Libre', 'emoji': '🌅',
     'color': const Color(0xFFF59E0B), 'desc': 'Creativo, espontáneo, vive el momento'},
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameController = TextEditingController(text: auth.userName);
    _usernameController = TextEditingController(text: auth.userModel?.username ?? '');
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

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_canSave || _isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();
    try {
      final auth = context.read<AuthProvider>();
      final (success, error) = await auth.updateUserProfile(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim() : null,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Perfil actualizado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ));
          Navigator.pop(context, true);
        } else {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error ?? 'Error'), backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.all(16),
          ));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPassController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('La contraseña debe tener al menos 6 caracteres'),
        backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Las contraseñas no coinciden'),
        backgroundColor: const Color(0xFFEF4444), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _isChangingPass = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return;

      // Re-autenticar
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
        setState(() { _isChangingPass = false; _showPassForm = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.lock_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Contraseña actualizada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isChangingPass = false);
        String msg = 'Error al cambiar contraseña';
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          msg = 'Contraseña actual incorrecta';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg), backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _isChangingPass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final userArchetype = auth.userModel?.archetype;
    final isGoogleUser = auth.firebaseUser?.providerData
        .any((p) => p.providerId == 'google.com') ?? false;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedParticlesBackground(
            particleCount: 12, maxShootingStars: isDark ? 1 : 0,
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
                      IconButton(icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context)),
                      const Expanded(child: Text('Editar perfil', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: FilledButton(
                          onPressed: _canSave ? _save : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: _isSaving
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
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
                        // ── Información personal ──
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.badge_rounded, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text('Información personal', style: TextStyle(fontSize: 15,
                                    fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
                              ]),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _nameController, onChanged: (_) => setState(() {}),
                                style: TextStyle(fontSize: 15, color: isDark ? Colors.white : AppColors.textPrimary),
                                decoration: _inputDeco('Nombre', isDark),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _usernameController,
                                style: TextStyle(fontSize: 15, color: isDark ? Colors.white : AppColors.textPrimary),
                                decoration: _inputDeco('Nombre de usuario', isDark).copyWith(
                                  prefixText: '@', prefixStyle: TextStyle(color: AppColors.textSecondary)),
                              ),
                              const SizedBox(height: 12),
                              // Email (solo lectura)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.email_rounded, size: 18, color: AppColors.textSecondary),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(auth.userEmail,
                                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary))),
                                    Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Cambiar contraseña ──
                        if (!isGoogleUser) ...[
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() => _showPassForm = !_showPassForm),
                                  child: Row(children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.1),
                                        borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(Icons.lock_rounded, color: Color(0xFFF59E0B), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Cambiar contraseña', style: TextStyle(fontSize: 15,
                                            fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
                                        Text('Actualiza tu contraseña de acceso',
                                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                      ],
                                    )),
                                    Icon(_showPassForm ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                        color: AppColors.textSecondary),
                                  ]),
                                ),
                                if (_showPassForm) ...[
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _currentPassController, obscureText: _obscureCurrent,
                                    style: TextStyle(fontSize: 15, color: isDark ? Colors.white : AppColors.textPrimary),
                                    decoration: _inputDeco('Contraseña actual', isDark).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                            size: 20, color: AppColors.textSecondary),
                                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _newPassController, obscureText: _obscureNew,
                                    style: TextStyle(fontSize: 15, color: isDark ? Colors.white : AppColors.textPrimary),
                                    decoration: _inputDeco('Nueva contraseña', isDark).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                            size: 20, color: AppColors.textSecondary),
                                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _confirmPassController, obscureText: _obscureNew,
                                    style: TextStyle(fontSize: 15, color: isDark ? Colors.white : AppColors.textPrimary),
                                    decoration: _inputDeco('Confirmar contraseña', isDark),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity, height: 46,
                                    child: FilledButton(
                                      onPressed: _isChangingPass ? null : _changePassword,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFFF59E0B),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: _isChangingPass
                                          ? const SizedBox(width: 18, height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : const Text('Cambiar contraseña',
                                              style: TextStyle(fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── Arquetipo (solo lectura) ──
                        Text('Tu arquetipo emocional', style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Text('Determinado en tu registro inicial. No se puede cambiar.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic)),
                        const SizedBox(height: 12),
                        ...List.generate(_archetypes.length, (i) {
                          final a = _archetypes[i];
                          final isUser = userArchetype == a['id'];
                          final color = a['color'] as Color;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: isUser ? 1.0 : 0.5,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: isUser ? LinearGradient(colors: [
                                    color.withValues(alpha: isDark ? 0.2 : 0.1),
                                    color.withValues(alpha: isDark ? 0.08 : 0.04)]) : null,
                                  color: isUser ? null
                                      : isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isUser ? color.withValues(alpha: 0.4)
                                        : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                                    width: isUser ? 2 : 1),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46, height: 46,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: isUser ? 0.2 : 0.08),
                                        borderRadius: BorderRadius.circular(14)),
                                      child: Center(child: Text(a['emoji'] as String, style: const TextStyle(fontSize: 22))),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a['name'] as String, style: TextStyle(fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isUser ? color : AppColors.textSecondary)),
                                        Text(a['desc'] as String, style: TextStyle(fontSize: 13,
                                            color: AppColors.textSecondary)),
                                      ],
                                    )),
                                    if (isUser)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8)),
                                        child: Text('Tu arquetipo', style: TextStyle(fontSize: 11,
                                            fontWeight: FontWeight.w700, color: color)),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
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
      labelStyle: TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}