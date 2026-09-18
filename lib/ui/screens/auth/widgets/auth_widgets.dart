import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_links.dart';
import '../../../../data/models/password_strength.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../../widgets/min_tap_target.dart';

/// Fondo de las pantallas de cuenta: degradado con luces que flotan.
/// Sin `MaskFilter.blur` (rompe WebGL en web): son degradados radiales.
class AuthBackground extends StatefulWidget {
  final List<Color> colors;
  const AuthBackground({super.key, required this.colors});

  @override
  State<AuthBackground> createState() => _AuthBackgroundState();
}

class _AuthBackgroundState extends State<AuthBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeatUnlessReduced(rest: 0.3);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _AuthBgPainter(t: _ctrl.value, colors: widget.colors),
        ),
      ),
    );
  }
}

class _AuthBgPainter extends CustomPainter {
  final double t;
  final List<Color> colors;

  const _AuthBgPainter({required this.t, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );

    final rng = math.Random(7);
    for (int i = 0; i < 9; i++) {
      final baseX = rng.nextDouble();
      final baseY = rng.nextDouble();
      final radius = size.width * (0.12 + rng.nextDouble() * 0.2);
      final phase = rng.nextDouble() * math.pi * 2;
      final dy = math.sin(t * math.pi * 2 + phase) * size.height * 0.03;
      final dx = math.cos(t * math.pi * 2 + phase) * size.width * 0.02;
      final center = Offset(baseX * size.width + dx, baseY * size.height + dy);
      final alpha = 0.05 + 0.05 * (0.5 + 0.5 * math.sin(t * math.pi * 2 + phase));
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [Colors.white.withValues(alpha: alpha), Colors.white.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(_AuthBgPainter old) => old.t != t || old.colors != colors;
}

/// Tarjeta blanca (o gris oscura) donde vive el formulario.
class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1C2E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 12))],
      ),
      child: child,
    );
  }
}

/// Campo de texto de las pantallas de cuenta.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accent;
  final TextInputType keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onToggleObscure;
  final TextCapitalization capitalization;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;
  final String? autofillHint;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.accent,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.validator,
    this.onChanged,
    this.onToggleObscure,
    this.capitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      onChanged: onChanged,
      textCapitalization: capitalization,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      autofillHints: autofillHint == null ? null : [autofillHint!],
      style: TextStyle(color: ink, fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        floatingLabelStyle: TextStyle(color: accent, fontWeight: FontWeight.w700),
        prefixIcon: Icon(icon, color: accent, size: 20),
        suffixIcon: onToggleObscure == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Semantics(
                  button: true,
                  label: 'editProfile.togglePasswordVisibility'.tr(),
                  onTap: onToggleObscure,
                  excludeSemantics: true,
                  child: MinTapTarget(
                    onTap: onToggleObscure,
                    child: Icon(
                      obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : accent.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : accent.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accent, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC5F4A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC5F4A), width: 1.8),
        ),
        errorMaxLines: 3,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

/// Barra de fuerza de la contraseña con las reglas que faltan.
class PasswordStrengthMeter extends StatelessWidget {
  final PasswordStrength strength;
  final bool showRules;

  const PasswordStrengthMeter({super.key, required this.strength, this.showRules = true});

  static const _levelColors = {
    PasswordLevel.empty: Color(0xFF9CA3AF),
    PasswordLevel.weak: Color(0xFFDC5F4A),
    PasswordLevel.fair: Color(0xFFF59E0B),
    PasswordLevel.good: Color(0xFF10B981),
    PasswordLevel.strong: Color(0xFF059669),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final soft = isDark ? Colors.white54 : AppColors.textSecondary;
    final color = _levelColors[strength.level]!;
    final reduced = MotionService.reduced(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: '${'validation.strengthLabel'.tr()}: ${strength.levelKey.tr()}',
          excludeSemantics: true,
          child: Row(
            children: [
              for (int i = 0; i < 4; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 3 ? 0 : 5),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: reduced ? 0 : 280),
                      curve: Curves.easeOutCubic,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i < strength.score ? color : (isDark ? Colors.white12 : const Color(0xFFE9E5F5)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  strength.levelKey.tr(),
                  key: ValueKey(strength.level),
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
        ),
        if (showRules) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final rule in PasswordStrength.required)
                _RuleChip(
                  label: PasswordStrength.ruleKey(rule).tr(),
                  done: strength.has(rule),
                  soft: soft,
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RuleChip extends StatelessWidget {
  final String label;
  final bool done;
  final Color soft;
  final bool isDark;

  const _RuleChip({required this.label, required this.done, required this.soft, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF10B981);
    return Semantics(
      label: '$label: ${done ? '✓' : '—'}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: done ? green.withValues(alpha: isDark ? 0.2 : 0.12) : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F1FB)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: done ? green.withValues(alpha: 0.45) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                done ? Icons.check_circle_rounded : Icons.circle_outlined,
                key: ValueKey(done),
                size: 13,
                color: done ? green : soft,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: done ? green : soft),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón principal de las pantallas de cuenta.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool loading;
  final VoidCallback? onTap;
  final IconData? icon;

  const AuthPrimaryButton({super.key, required this.label, required this.color, required this.onTap, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: color.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 20)],
                ],
              ),
      ),
    );
  }
}

/// Botón de Google con su logo dibujado (sin assets externos).
class GoogleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool loading;

  const GoogleButton({super.key, required this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: loading ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
          side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFDDD8EE)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GoogleLogoPainter())),
            const SizedBox(width: 12),
            Text('auth.continueWithGoogle'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final stroke = size.width * 0.22;
    final inner = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    void arc(double startDeg, double sweepDeg, Color color) {
      paint.color = color;
      canvas.drawArc(inner, startDeg * math.pi / 180, sweepDeg * math.pi / 180, false, paint);
    }

    arc(-25, 70, const Color(0xFF4285F4)); // azul
    arc(45, 90, const Color(0xFF34A853)); // verde
    arc(135, 90, const Color(0xFFFBBC05)); // amarillo
    arc(225, 100, const Color(0xFFEA4335)); // rojo
    // barra del centro
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.5, size.height * 0.39, size.width * 0.5, stroke),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}

/// Aviso de error de la pantalla (rojo suave, con temblor al aparecer).
class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFDC5F4A);
    final reduced = MotionService.reduced(context);
    final banner = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(message, style: const TextStyle(color: danger, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
    return reduced ? banner : banner.animate().fadeIn(duration: 250.ms).shake(duration: 350.ms, hz: 3);
  }
}

/// Nota de privacidad del registro: abre un resumen de qué se guarda.
class PrivacyNote extends StatelessWidget {
  final Color accent;
  const PrivacyNote({super.key, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final soft = isDark ? Colors.white60 : AppColors.textSecondary;
    return Semantics(
      button: true,
      label: 'auth.privacyLink'.tr(),
      onTap: () => _show(context),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _show(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${'auth.privacyIntro'.tr()} ', style: TextStyle(color: soft, fontSize: 11.5, height: 1.4)),
                TextSpan(
                  text: 'auth.privacyLink'.tr(),
                  style: TextStyle(color: accent, fontSize: 11.5, fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  static void _show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final soft = isDark ? Colors.white70 : AppColors.textSecondary;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF17182A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.fromLTRB(22, 14, 22, 22 + MediaQuery.viewPaddingOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: soft.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('auth.privacyTitle'.tr(), style: JournalStyle.hand(const TextStyle(fontSize: 22, color: AppColors.primary))),
              const SizedBox(height: 8),
              for (final (emoji, key) in const [
                ('🔒', 'auth.privacyPoint1'),
                ('☁️', 'auth.privacyPoint2'),
                ('📊', 'auth.privacyPoint3'),
                ('🗑️', 'auth.privacyPoint4'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(key.tr(), style: TextStyle(fontSize: 13.5, height: 1.45, color: soft))),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => openExternal(AppLinks.privacy(ctx.locale.languageCode)),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text('auth.privacyFull'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('common.ok'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Abre un enlace fuera de la app (política, términos, correo de soporte).
/// Si el teléfono no puede abrirlo, no truena: simplemente no pasa nada.
Future<void> openExternal(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

/// Igual que [openExternal] pero para un `mailto:` ya armado.
Future<void> openMail(Uri uri) async {
  try {
    await launchUrl(uri);
  } catch (_) {}
}
