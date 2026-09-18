import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/password_strength.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../../widgets/min_tap_target.dart';
import '../../auth/widgets/auth_widgets.dart' show PasswordStrengthMeter;

// ═════════════════════════════════════════════════════════════════════════════
// Piezas
// ═════════════════════════════════════════════════════════════════════════════

/// Cómo te verás en tu perfil, actualizado mientras escribes.
class EditPreviewCard extends StatelessWidget {
  final String name;
  final String username;
  final String archetypeName;
  final String archetypeEmoji;
  final List<Color> colors;

  const EditPreviewCard({
    super.key,
    required this.name,
    required this.username,
    required this.archetypeName,
    required this.archetypeEmoji,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'U';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(colors.first, Colors.white, 0.1)!, colors.last],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withValues(alpha: 0.95), Color.lerp(colors.first, Colors.white, 0.7)!],
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                child: Text(
                  initial,
                  key: ValueKey(initial),
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color.lerp(colors.first, Colors.black, 0.2)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'editProfile.previewLabel'.tr(),
                  style: JournalStyle.hand(TextStyle(fontSize: 16, height: 1.0, color: Colors.white.withValues(alpha: 0.85))),
                ),
                Text(
                  name.isEmpty ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 21, height: 1.2, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.85)),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    '$archetypeEmoji $archetypeName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}

class EditSectionTitle extends StatelessWidget {
  final String kicker;
  final String title;
  final bool isDark;
  const EditSectionTitle({
    super.key,
    required this.kicker, required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kicker, style: JournalStyle.hand(TextStyle(fontSize: 17, height: 1.0, color: isDark ? AppColors.primaryLight : AppColors.primary))),
          Semantics(
            header: true,
            child: Text(title, style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class EditCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const EditCard({
    super.key,
    required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEDEBF7)),
        boxShadow: isDark ? null : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final int? maxLength;
  final String? prefixText;
  final ValueChanged<String> onChanged;
  final String? helper;
  final bool helperIsError;
  final bool helperIsGood;
  final Widget? suffix;

  const EditField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onChanged,
    this.maxLength,
    this.prefixText,
    this.helper,
    this.helperIsError = false,
    this.helperIsGood = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    final helperColor = helperIsError
        ? const Color(0xFFDC5F4A)
        : helperIsGood
            ? const Color(0xFF10B981)
            : (isDark ? Colors.white54 : AppColors.textSecondary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: ink.withValues(alpha: 0.75))),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLength: maxLength,
          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: ink),
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF7F5FF),
            prefixText: prefixText,
            prefixStyle: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: ink.withValues(alpha: 0.5)),
            suffixIcon: suffix == null ? null : Padding(padding: const EdgeInsets.only(right: 12), child: Center(widthFactor: 1, child: suffix)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE6E1F8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
            ),
          ),
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 4),
            child: Row(
              children: [
                if (helperIsGood) const Icon(Icons.check_rounded, size: 13, color: Color(0xFF10B981)),
                if (helperIsError) const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFDC5F4A)),
                if (helperIsGood || helperIsError) const SizedBox(width: 4),
                Expanded(
                  child: Text(helper!, style: TextStyle(fontSize: 11.5, height: 1.3, color: helperColor, fontWeight: helperIsGood || helperIsError ? FontWeight.w700 : FontWeight.w500)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class LockedInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? trailing;
  final bool isDark;

  const LockedInfoRow({
    super.key,
    required this.icon, required this.text, required this.trailing, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final soft = isDark ? Colors.white60 : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF7F5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: soft),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: soft)),
          ),
          if (trailing != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 3),
                  Text(trailing!, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.lock_outline_rounded, size: 14, color: soft),
        ],
      ),
    );
  }
}

class ArchetypeRow extends StatelessWidget {
  final bool isMine;
  final String name;
  final String description;
  final String emoji;
  final Color color;
  final bool isDark;

  const ArchetypeRow({
    super.key,
    required this.isMine,
    required this.name,
    required this.description,
    required this.emoji,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    return Semantics(
      label: '$name. $description${isMine ? '. ${'editProfile.yourArchetype'.tr()}' : ''}',
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isMine ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isMine
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withValues(alpha: isDark ? 0.25 : 0.14), color.withValues(alpha: isDark ? 0.08 : 0.04)],
                  )
                : null,
            color: isMine ? null : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isMine ? color.withValues(alpha: 0.45) : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEDEBF7)),
              width: isMine ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha: isMine ? 0.22 : 0.1), borderRadius: BorderRadius.circular(13)),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: isMine ? (isDark ? Color.lerp(color, Colors.white, 0.35) : Color.lerp(color, Colors.black, 0.2)) : ink.withValues(alpha: 0.75))),
                    Text(description, style: TextStyle(fontSize: 12, height: 1.3, color: isDark ? Colors.white54 : AppColors.textSecondary)),
                  ],
                ),
              ),
              if (isMine)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(9)),
                  child: Text(
                    'editProfile.yourArchetype'.tr(),
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: isDark ? Color.lerp(color, Colors.white, 0.4) : Color.lerp(color, Colors.black, 0.2)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordCard extends StatelessWidget {
  final bool isDark;

  /// Fuerza de la contraseña nueva mientras se escribe.
  final PasswordStrength? strength;
  final ValueChanged<String> onNewPasswordChanged;
  final bool expanded;
  final bool busy;
  final TextEditingController currentController;
  final TextEditingController newController;
  final TextEditingController confirmController;
  final bool obscureCurrent;
  final bool obscureNew;
  final VoidCallback onToggleExpanded;
  final VoidCallback onToggleObscureCurrent;
  final VoidCallback onToggleObscureNew;
  final VoidCallback onSubmit;

  const PasswordCard({
    super.key,
    required this.isDark,
    required this.onNewPasswordChanged,
    this.strength,
    required this.expanded,
    required this.busy,
    required this.currentController,
    required this.newController,
    required this.confirmController,
    required this.obscureCurrent,
    required this.obscureNew,
    required this.onToggleExpanded,
    required this.onToggleObscureCurrent,
    required this.onToggleObscureNew,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    return EditCard(
      isDark: isDark,
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            label: 'profile.changePassword'.tr(),
            onTap: onToggleExpanded,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleExpanded,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.lock_rounded, size: 19, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('profile.changePassword'.tr(), style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: ink)),
                        Text(
                          'editProfile.changePasswordHint'.tr(),
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.expand_more_rounded, color: ink.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    children: [
                      const SizedBox(height: 14),
                      EditField(
                        controller: currentController,
                        label: 'profile.currentPassword'.tr(),
                        icon: Icons.password_rounded,
                        isDark: isDark,
                        onChanged: (_) {},
                        suffix: EyeButton(obscure: obscureCurrent, onTap: onToggleObscureCurrent),
                      ),
                      const SizedBox(height: 12),
                      EditField(
                        controller: newController,
                        label: 'profile.newPassword'.tr(),
                        icon: Icons.lock_reset_rounded,
                        isDark: isDark,
                        onChanged: onNewPasswordChanged,
                        suffix: EyeButton(obscure: obscureNew, onTap: onToggleObscureNew),
                      ),
                      if (strength != null && strength!.level != PasswordLevel.empty) ...[
                        const SizedBox(height: 10),
                        PasswordStrengthMeter(strength: strength!),
                      ],
                      const SizedBox(height: 12),
                      EditField(
                        controller: confirmController,
                        label: 'profile.confirmNewPassword'.tr(),
                        icon: Icons.check_circle_outline_rounded,
                        isDark: isDark,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: busy ? null : onSubmit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: busy
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('profile.changePassword'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class EyeButton extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const EyeButton({
    super.key,
    required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'editProfile.togglePasswordVisibility'.tr(),
      onTap: onTap,
      excludeSemantics: true,
      child: MinTapTarget(
        onTap: onTap,
        child: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 19, color: AppColors.textSecondary),
      ),
    );
  }
}

/// Ofrece unir Google a una cuenta de correo (o dice que ya está unida), para
/// que entrar sea de un toque sin perder nada de lo que ya tiene.
class LinkGoogleCard extends StatelessWidget {
  final bool isDark;
  final bool isLinked;
  final bool busy;
  final VoidCallback onLink;
  const LinkGoogleCard({
    super.key,
    required this.isDark,
    required this.isLinked,
    required this.busy,
    required this.onLink,
  });

  @override
  Widget build(BuildContext context) {
    const google = Color(0xFF4285F4);
    final subtle = isDark ? Colors.white60 : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: google.withValues(alpha: isDark ? 0.28 : 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: google.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isLinked ? Icons.link_rounded : Icons.g_mobiledata_rounded,
                color: google, size: isLinked ? 22 : 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLinked ? 'editProfile.linkGoogleLinked'.tr() : 'editProfile.linkGoogle'.tr(),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'editProfile.linkGoogleDesc'.tr(),
                  style: TextStyle(fontSize: 12.5, height: 1.35, color: subtle),
                ),
              ],
            ),
          ),
          if (!isLinked) ...[
            const SizedBox(width: 10),
            SizedBox(
              height: 42,
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: google),
                      ),
                    )
                  : FilledButton(
                      onPressed: onLink,
                      style: FilledButton.styleFrom(
                        backgroundColor: google,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('editProfile.linkGoogleAction'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
            ),
          ] else
            Icon(Icons.check_circle_rounded, color: google, size: 22),
        ],
      ),
    );
  }
}

class DangerZoneCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onDelete;
  const DangerZoneCard({
    super.key,
    required this.isDark, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFDC5F4A);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: danger.withValues(alpha: isDark ? 0.25 : 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('editProfile.deleteAccount'.tr(), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: danger)),
          const SizedBox(height: 4),
          Text(
            'editProfile.deleteAccountDesc'.tr(),
            style: TextStyle(fontSize: 12.5, height: 1.4, color: isDark ? Colors.white60 : AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text('editProfile.deleteAccount'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                foregroundColor: danger,
                side: BorderSide(color: danger.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
