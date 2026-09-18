import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/lumi.dart';
import '../../../../domain/providers/auth_provider.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../../domain/services/sound_service.dart';
import '../../../widgets/lumi/lumi_avatar.dart';
import 'auth_widgets.dart';

/// Une la cuenta de Google con la de siempre.
///
/// Firebase no fusiona solo una cuenta de correo ya verificada (dejaría entrar
/// en cuentas ajenas), así que se pide la contraseña **una vez**. Lumi explica
/// por qué: pedir una contraseña de la nada asusta, y con razón.
///
/// Devuelve true si quedaron vinculadas.
Future<bool> showLinkGoogleSheet(BuildContext context, String email) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => _LinkGoogleSheet(email: email),
  );
  return result ?? false;
}

class _LinkGoogleSheet extends StatefulWidget {
  final String email;
  const _LinkGoogleSheet({required this.email});

  @override
  State<_LinkGoogleSheet> createState() => _LinkGoogleSheetState();
}

class _LinkGoogleSheetState extends State<_LinkGoogleSheet> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  static const _accent = Color(0xFF6C63FF);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    final (ok, error) = await auth.linkPendingGoogleWithPassword(_controller.text);
    if (!mounted) return;
    if (ok) {
      SoundService.instance.play(Sfx.unlock, volume: 0.5);
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
      return;
    }
    SoundService.instance.play(Sfx.wrong, volume: 0.4);
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  void _cancel() {
    context.read<AuthProvider>().cancelPendingLink();
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    final reduced = MotionService.reduced(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B1830) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                const LumiAvatar(mood: LumiMood.curious, size: 76),
                const SizedBox(height: 12),
                Text(
                  'auth.linkGoogle.title'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: ink),
                ),
                const SizedBox(height: 8),
                Text(
                  'auth.linkGoogle.body'.tr(namedArgs: {'email': widget.email}),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.5, height: 1.4, color: ink.withValues(alpha: 0.72)),
                ),
                const SizedBox(height: 18),
                AuthField(
                  controller: _controller,
                  label: 'auth.password'.tr(),
                  icon: Icons.lock_rounded,
                  accent: _accent,
                  obscure: _obscure,
                  autofillHint: AutofillHints.password,
                  textInputAction: TextInputAction.done,
                  onToggleObscure: () => setState(() => _obscure = !_obscure),
                  onSubmitted: _link,
                  validator: Validators.password,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  AuthErrorBanner(message: _error!),
                ],
                const SizedBox(height: 18),
                AuthPrimaryButton(
                  label: 'auth.linkGoogle.action'.tr(),
                  color: _accent,
                  loading: _loading,
                  icon: Icons.link_rounded,
                  onTap: _link,
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _loading ? null : _cancel,
                  style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
                  child: Text(
                    'common.cancel'.tr(),
                    style: TextStyle(color: ink.withValues(alpha: 0.6), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'auth.linkGoogle.note'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, height: 1.35, color: ink.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
        ),
      ).animate(target: reduced ? 1 : null).fadeIn(duration: 220.ms).slideY(begin: 0.06, end: 0, duration: 260.ms, curve: Curves.easeOutCubic),
    );
  }
}
