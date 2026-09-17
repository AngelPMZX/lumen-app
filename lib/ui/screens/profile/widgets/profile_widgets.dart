import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/lumi.dart';
import '../../../../data/models/medals.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../../domain/services/sound_service.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../../widgets/lumi/lumi_avatar.dart';
import '../../../widgets/medal_badge.dart';
import '../../routes/widgets/route_progress_ring.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Encabezado
// ═════════════════════════════════════════════════════════════════════════════

class ProfileHero extends StatelessWidget {
  final String name;
  final String? username;
  final String archetypeName;
  final String? archetypeEmoji;
  final List<Color> colors;
  final int level;
  final String levelTitle;
  final int xpInLevel;
  final int xpForNext;
  final DateTime? memberSince;
  final LumiLine line;
  final bool isDark;
  final VoidCallback onEdit;

  const ProfileHero({
    super.key,
    required this.name,
    required this.username,
    required this.archetypeName,
    required this.colors,
    required this.level,
    required this.levelTitle,
    required this.xpInLevel,
    required this.xpForNext,
    required this.line,
    required this.isDark,
    required this.onEdit,
    this.archetypeEmoji,
    this.memberSince,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'U';
    final progress = xpForNext == 0 ? 0.0 : (xpInLevel / xpForNext).clamp(0.0, 1.0);
    final top = colors.first;
    final bottom = Color.lerp(colors.last, Colors.black, isDark ? 0.35 : 0.15)!;
    final reduced = MotionService.reduced(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: top.withValues(alpha: isDark ? 0.3 : 0.35), blurRadius: 26, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.lerp(top, Colors.white, 0.12)!, top, bottom],
                  ),
                ),
              ),
            ),
            // Luces suaves de fondo
            Positioned(top: -60, right: -40, child: _glow(190, 0.16)),
            Positioned(bottom: -70, left: -50, child: _glow(200, 0.1)),
            for (final (i, (x, y)) in const [(0.12, 0.18), (0.82, 0.12), (0.9, 0.55), (0.06, 0.62), (0.55, 0.08)].indexed)
              Positioned.fill(
                child: Align(
                  alignment: Alignment(x * 2 - 1, y * 2 - 1),
                  child: Text('✦', style: TextStyle(fontSize: 10.0 + i * 2, color: Colors.white.withValues(alpha: 0.45)))
                      .animate(onPlay: MotionService.loop(context, reverse: true), delay: (i * 350).ms)
                      .fadeOut(begin: 1, duration: (1400 + i * 200).ms)
                      .scale(begin: const Offset(1, 1), end: const Offset(0.6, 0.6), duration: (1400 + i * 200).ms),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Semantics(
                        label: '${'home.levelShort'.tr()} $level',
                        excludeSemantics: true,
                        child: RouteProgressRing(
                          progress: progress,
                          color: Colors.white,
                          track: Colors.white.withValues(alpha: 0.22),
                          size: 92,
                          stroke: 5,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Colors.white.withValues(alpha: 0.95), Color.lerp(top, Colors.white, 0.7)!],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    initial,
                                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color.lerp(top, Colors.black, 0.2)),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFFFDE68A), Color(0xFFF59E0B)]),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Text(
                                    '${'home.levelShort'.tr()} $level',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF713F12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: 600.ms, curve: Curves.elasticOut),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 24, height: 1.1, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ),
                            if (username != null && username!.isNotEmpty)
                              Text(
                                '@$username',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8)),
                              ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${archetypeEmoji ?? '✨'} $archetypeName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'profile.editProfile'.tr(),
                        onTap: onEdit,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onEdit();
                          },
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Nivel
                  Semantics(
                    label: '$levelTitle. $xpInLevel / $xpForNext XP',
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              levelTitle,
                              style: JournalStyle.hand(const TextStyle(fontSize: 21, height: 1.0, color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                            const Spacer(),
                            Text(
                              '$xpInLevel / $xpForNext XP',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.9)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LayoutBuilder(
                          builder: (context, c) => Stack(
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(6)),
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: progress),
                                duration: reduced ? Duration.zero : const Duration(milliseconds: 1100),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, _) => Container(
                                  width: c.maxWidth * v,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFFFFF7D6), Color(0xFFFCD34D)]),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'profileScreen.xpToNext'.tr(namedArgs: {'xp': '${xpForNext - xpInLevel}', 'level': '${level + 1}'}),
                                style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.8)),
                              ),
                            ),
                            if (memberSince != null)
                              Text(
                                'profile.memberSince'.tr(namedArgs: {'date': DateFormat.yMMM(context.locale.languageCode).format(memberSince!)}),
                                style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.8)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Lumi
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      LumiAvatar(mood: line.mood, size: 54, onTap: () {}),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              line.key.tr(namedArgs: line.args),
                              style: const TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ),
                        ).animate().fadeIn(delay: 450.ms, duration: 350.ms).slideX(begin: -0.06, end: 0, curve: Curves.easeOutCubic),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _glow(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [Colors.white.withValues(alpha: alpha), Colors.white.withValues(alpha: 0)]),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// Contadores
// ═════════════════════════════════════════════════════════════════════════════

class ProfileStat {
  final String emoji;
  final int value;
  final String label;
  final Color color;
  const ProfileStat(this.emoji, this.value, this.label, this.color);
}

class ProfileStatsGrid extends StatelessWidget {
  final List<ProfileStat> stats;
  final bool isDark;

  const ProfileStatsGrid({super.key, required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final reduced = MotionService.reduced(context);
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 10.0;
        final w = (c.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (i, s) in stats.indexed)
              Semantics(
                label: '${s.label}: ${s.value}',
                excludeSemantics: true,
                child: Container(
                  width: w,
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [Color.lerp(const Color(0xFF1B1C2E), s.color, 0.18)!, const Color(0xFF17182A)]
                          : [Color.lerp(Colors.white, s.color, 0.1)!, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: s.color.withValues(alpha: isDark ? 0.3 : 0.2)),
                    boxShadow: isDark ? null : [BoxShadow(color: s.color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: s.color.withValues(alpha: isDark ? 0.25 : 0.14), borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(s.emoji, style: const TextStyle(fontSize: 16))),
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: s.value.toDouble()),
                        duration: reduced ? Duration.zero : Duration(milliseconds: 900 + i * 90),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => Text(
                          '${v.round()}',
                          style: TextStyle(
                            fontSize: 22,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        s.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (120 + i * 60).ms, duration: 350.ms).scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), curve: Curves.easeOutCubic),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Vitrina de medallas
// ═════════════════════════════════════════════════════════════════════════════

class MedalShowcaseCard extends StatelessWidget {
  final List<MedalStatus> medals;
  final bool isDark;
  final VoidCallback onOpen;
  final ValueChanged<MedalStatus> onMedal;

  const MedalShowcaseCard({super.key, required this.medals, required this.isDark, required this.onOpen, required this.onMedal});

  @override
  Widget build(BuildContext context) {
    final unlocked = medals.where((m) => m.unlocked).length;
    final showcase = Medals.showcase(medals);
    final next = Medals.nextUp(medals);
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    const gold = Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark ? [const Color(0xFF2A2214), const Color(0xFF17182A)] : [const Color(0xFFFFF8E6), Colors.white],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: gold.withValues(alpha: isDark ? 0.3 : 0.25)),
        boxShadow: isDark ? null : [BoxShadow(color: gold.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: '${'profile.medals'.tr()}. ${'profileScreen.medalsUnlocked'.tr(namedArgs: {'unlocked': '$unlocked', 'total': '${medals.length}'})}',
            onTap: onOpen,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpen,
              child: Row(
                children: [
                  RouteProgressRing(
                    progress: medals.isEmpty ? 0 : unlocked / medals.length,
                    color: gold,
                    track: gold.withValues(alpha: 0.18),
                    size: 48,
                    stroke: 4.5,
                    child: const Text('🏅', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('profileScreen.medalsKicker'.tr(), style: JournalStyle.hand(const TextStyle(fontSize: 17, height: 1.0, color: Color(0xFFD97706)))),
                        Text('profile.medals'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: ink)),
                      ],
                    ),
                  ),
                  Text(
                    '$unlocked/${medals.length}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309)),
                  ),
                  Icon(Icons.chevron_right_rounded, color: ink.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (showcase.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'profileScreen.noMedalsYet'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: ink.withValues(alpha: 0.6)),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (final (i, m) in showcase.indexed)
                  Semantics(
                    button: true,
                    label: m.achievement.titleKey?.tr() ?? m.achievement.title,
                    onTap: () => onMedal(m),
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => onMedal(m),
                      child: SizedBox(
                        width: 72,
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                MedalBadge(medal: m, size: 58),
                                if (m.isNew) const Positioned(top: -4, right: -10, child: NewMedalChip()),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              m.achievement.titleKey?.tr() ?? m.achievement.title,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, height: 1.15, fontWeight: FontWeight.w700, color: ink.withValues(alpha: 0.8)),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (200 + 90 * i).ms, duration: 300.ms).scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          duration: 550.ms,
                          curve: Curves.elasticOut,
                        ),
                  ),
              ],
            ),
          if (next != null) ...[
            const SizedBox(height: 14),
            NextMedalRow(medal: next, isDark: isDark, onTap: () => onMedal(next)),
          ],
        ],
      ),
    );
  }
}

class NewMedalChip extends StatelessWidget {
  const NewMedalChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF472B6), Color(0xFFEC4899)]),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text('profileScreen.newMedal'.tr(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
    )
        .animate(onPlay: MotionService.loop(context, reverse: true))
        .scale(begin: const Offset(1, 1), end: const Offset(1.12, 1.12), duration: 700.ms, curve: Curves.easeInOut);
  }
}

/// "Tu próxima medalla": la bloqueada más cerca, con su avance.
class NextMedalRow extends StatelessWidget {
  final MedalStatus medal;
  final bool isDark;
  final VoidCallback onTap;

  const NextMedalRow({super.key, required this.medal, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    final color = medal.achievement.color;
    final title = medal.achievement.titleKey?.tr() ?? medal.achievement.title;
    final reduced = MotionService.reduced(context);
    return Semantics(
      button: true,
      label: '${'profileScreen.nextMedal'.tr()}: $title. ${medal.current}/${medal.requirement}',
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              MedalBadge(medal: medal, size: 44, showRibbon: false),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('profileScreen.nextMedal'.tr(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink.withValues(alpha: 0.55))),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: ink)),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, c) => Stack(
                        children: [
                          Container(height: 7, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4))),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: medal.progress),
                            duration: reduced ? Duration.zero : const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => Container(
                              width: c.maxWidth * v,
                              height: 7,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Color.lerp(color, Colors.white, 0.3)!, color]),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${medal.current}/${medal.requirement}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: isDark ? Color.lerp(color, Colors.white, 0.35) : Color.lerp(color, Colors.black, 0.2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Grupos de ajustes
// ═════════════════════════════════════════════════════════════════════════════

class SettingsItem {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Si no es null, la fila es un interruptor.
  final bool? toggle;
  final ValueChanged<bool>? onToggle;

  const SettingsItem({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.onTap,
    this.toggle,
    this.onToggle,
  });
}

class SettingsGroup extends StatelessWidget {
  final String title;
  final List<SettingsItem> items;
  final bool isDark;

  const SettingsGroup({super.key, required this.title, required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Semantics(
            header: true,
            child: Text(
              title.toUpperCase(),
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: ink.withValues(alpha: 0.5)),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEDEBF7)),
            boxShadow: isDark ? null : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              children: [
                for (final (i, item) in items.indexed) ...[
                  if (i > 0) Divider(height: 1, indent: 66, color: ink.withValues(alpha: 0.07)),
                  _SettingsRow(item: item, isDark: isDark),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatefulWidget {
  final SettingsItem item;
  final bool isDark;
  const _SettingsRow({required this.item, required this.isDark});

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  bool _down = false;

  void _activate() {
    final item = widget.item;
    HapticFeedback.selectionClick();
    if (item.toggle != null) {
      final v = !item.toggle!;
      SoundService.instance.play(v ? Sfx.toggleOn : Sfx.toggleOff, volume: 0.4);
      item.onToggle?.call(v);
    } else {
      item.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    final isToggle = item.toggle != null;

    return Semantics(
      button: !isToggle,
      toggled: item.toggle,
      label: [item.title, ?item.subtitle].join('. '),
      onTap: _activate,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: _activate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _down ? item.color.withValues(alpha: isDark ? 0.1 : 0.06) : Colors.transparent,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.lerp(item.color, Colors.white, 0.15)!, item.color],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: ink)),
                    if (item.subtitle != null)
                      Text(item.subtitle!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                  ],
                ),
              ),
              if (isToggle)
                IgnorePointer(
                  child: Switch.adaptive(value: item.toggle!, onChanged: (_) {}, activeThumbColor: item.color),
                )
              else
                Icon(Icons.chevron_right_rounded, color: ink.withValues(alpha: 0.35), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
