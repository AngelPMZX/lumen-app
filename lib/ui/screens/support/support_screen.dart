import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_links.dart';
import '../../../data/models/lumi.dart';
import '../../../domain/services/app_review_service.dart';
import '../../../domain/services/motion_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/journal/journal_style.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import '../../widgets/min_tap_target.dart';
import '../auth/widgets/auth_widgets.dart' show openMail;

/// "Apoya a Lumen": quién hace la app, qué logra tu apoyo y las formas de
/// ayudar que existen hoy. Sin promesas ni presión: la ayuda en crisis y el
/// contenido de bienestar siempre serán gratis.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _rosa = Color(0xFFEC4899);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    final soft = isDark ? Colors.white70 : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F23) : const Color(0xFFFFF7FB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(isDark: isDark)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 28 + MediaQuery.viewPaddingOf(context).bottom),
              sliver: SliverList.list(
                children: [
                  // Quién hace Lumen
                  _Card(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'support.madeByKicker'.tr(),
                          style: JournalStyle.hand(TextStyle(fontSize: 19, height: 1.0, color: isDark ? const Color(0xFFF9A8D4) : _rosa)),
                        ),
                        Semantics(
                          header: true,
                          child: Text(
                            'support.madeByTitle'.tr(),
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: ink),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('support.madeByBody'.tr(), style: TextStyle(fontSize: 14.5, height: 1.55, color: soft)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 16),

                  // Qué hace tu apoyo
                  _Card(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'support.whatItDoesTitle'.tr(),
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink),
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final (i, (emoji, key)) in const [
                          ('🆓', 'support.point1'),
                          ('📚', 'support.point2'),
                          ('🤝', 'support.point3'),
                          ('🌱', 'support.point4'),
                        ].indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 17)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(key.tr(), style: TextStyle(fontSize: 13.8, height: 1.45, color: soft))),
                              ],
                            ).animate().fadeIn(delay: (200 + i * 80).ms, duration: 300.ms).slideX(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
                          ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'support.freeWaysKicker'.tr(),
                          style: JournalStyle.hand(TextStyle(fontSize: 18, height: 1.0, color: isDark ? const Color(0xFFF9A8D4) : _rosa)),
                        ),
                        Semantics(
                          header: true,
                          child: Text(
                            'support.freeWaysTitle'.tr(),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ActionCard(
                    emoji: '💌',
                    color: _rosa,
                    title: 'support.shareTitle'.tr(),
                    subtitle: 'support.shareBody'.tr(),
                    isDark: isDark,
                    onTap: () => _share(context),
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    emoji: '⭐',
                    color: const Color(0xFFF59E0B),
                    title: 'support.rateTitle'.tr(),
                    subtitle: 'support.rateBody'.tr(),
                    isDark: isDark,
                    onTap: () {
                      SoundService.instance.play(Sfx.tapNode, volume: 0.4);
                      AppReviewService.instance.openStoreListing();
                    },
                  ),
                  const SizedBox(height: 10),
                  _ActionCard(
                    emoji: '💡',
                    color: const Color(0xFF6366F1),
                    title: 'support.ideaTitle'.tr(),
                    subtitle: 'support.ideaBody'.tr(),
                    isDark: isDark,
                    onTap: () {
                      SoundService.instance.play(Sfx.tapNode, volume: 0.4);
                      openMail(AppLinks.supportMail('support.ideaSubject'.tr()));
                    },
                  ),
                  const SizedBox(height: 20),

                  // Cosméticos de Lumi (aún no disponibles)
                  _ComingSoonCard(isDark: isDark),
                  const SizedBox(height: 18),

                  // Promesa
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.14 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🤍', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'support.promise'.tr(),
                            style: TextStyle(fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w600, color: ink),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 350.ms),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'support.thanks'.tr(),
                      textAlign: TextAlign.center,
                      style: JournalStyle.hand(TextStyle(fontSize: 21, height: 1.25, color: soft)),
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _share(BuildContext context) async {
    SoundService.instance.play(Sfx.tapNode, volume: 0.4);
    try {
      await SharePlus.instance.share(
        ShareParams(text: '${'support.shareText'.tr()}\n\n${AppLinks.playStore}'),
      );
    } catch (e) {
      debugPrint('Share Lumen error: $e');
    }
  }
}

class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF472B6), Color(0xFFEC4899), Color(0xFFBE185D)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'common.back'.tr(),
                    onTap: () => Navigator.pop(context),
                    excludeSemantics: true,
                    child: MinTapTarget(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 19),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 4),
              const LumiAvatar(mood: LumiMood.caring, size: 82)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 700.ms, curve: Curves.elasticOut),
              const SizedBox(height: 6),
              Text(
                'support.headerKicker'.tr(),
                textAlign: TextAlign.center,
                style: JournalStyle.hand(const TextStyle(fontSize: 21, height: 1.1, color: Color(0xFFFFE4F1))),
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
              Semantics(
                header: true,
                child: Text(
                  'support.title'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, height: 1.15, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ).animate().fadeIn(delay: 220.ms, duration: 350.ms),
            ],
          ),
        ),
        // Corazoncitos que suben
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: [
                for (final (i, x) in const [0.12, 0.3, 0.72, 0.88].indexed)
                  Align(
                    alignment: Alignment(x * 2 - 1, 0.9),
                    child: Text('🤍', style: TextStyle(fontSize: 11.0 + i * 2, color: Colors.white.withValues(alpha: 0.6)))
                        .animate(onPlay: MotionService.loop(context), delay: (i * 700).ms)
                        .fadeIn(duration: 600.ms)
                        .moveY(begin: 20, end: -70, duration: 3400.ms, curve: Curves.easeOut)
                        .fadeOut(delay: 2200.ms, duration: 1000.ms),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _Card({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF6DCEA)),
        boxShadow: isDark ? null : [BoxShadow(color: const Color(0xFFEC4899).withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String emoji;
  final Color color;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionCard({
    required this.emoji,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final ink = widget.isDark ? Colors.white : AppColors.textPrimary;
    return Semantics(
      button: true,
      label: '${widget.title}. ${widget.subtitle}',
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.color.withValues(alpha: widget.isDark ? 0.3 : 0.22)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: widget.isDark ? 0.22 : 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(widget.emoji, style: const TextStyle(fontSize: 21))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ink)),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: TextStyle(fontSize: 12.5, height: 1.35, color: widget.isDark ? Colors.white60 : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: ink.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Los cosméticos de Lumi aún no existen: se anuncian sin poder comprarlos.
class _ComingSoonCard extends StatelessWidget {
  final bool isDark;
  const _ComingSoonCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    const violeta = Color(0xFF8B5CF6);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [violeta.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.04)]
              : [violeta.withValues(alpha: 0.12), Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: violeta.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LumiAvatar(mood: LumiMood.excited, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'support.soonTitle'.tr(),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: violeta.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'common.comingSoon'.tr(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFFC4B5FD) : violeta),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'support.soonBody'.tr(),
                  style: TextStyle(fontSize: 13, height: 1.45, color: isDark ? Colors.white70 : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms, duration: 350.ms);
  }
}
