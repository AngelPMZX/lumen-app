import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/daily_challenge.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../routes/widgets/route_progress_ring.dart';

/// Reto diario: tarjeta con su color, duración y XP; al completarlo se vuelve
/// verde con un sello.
class DailyChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final String title;
  final String description;
  final String category;
  final bool done;
  final bool isDark;
  final VoidCallback? onTap;

  const DailyChallengeCard({
    super.key,
    required this.challenge,
    required this.title,
    required this.description,
    required this.category,
    required this.done,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF10B981);
    final color = done ? green : challenge.color;
    final ink = isDark ? Colors.white : AppColors.textPrimary;

    return Semantics(
      button: !done,
      label: '${done ? 'challenge.challengeDone'.tr() : 'home.challengeLabel'.tr(namedArgs: {'category': category})}. $title. $description',
      onTap: done ? null : onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: done
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap?.call();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Color.lerp(isDark ? const Color(0xFF1B1C2E) : Colors.white, color, isDark ? 0.16 : 0.09),
            border: Border.all(color: color.withValues(alpha: done ? 0.45 : 0.25), width: done ? 1.6 : 1),
            boxShadow: isDark ? null : [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color.lerp(color, Colors.white, 0.2)!, color]),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Icon(done ? Icons.verified_rounded : challenge.icon, color: Colors.white, size: 28),
              )
                  .animate(onPlay: done ? null : MotionService.loop(context, reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.06, 1.06), duration: 1400.ms, curve: Curves.easeInOut),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            done ? 'challenge.challengeDone'.tr() : 'home.challengeLabel'.tr(namedArgs: {'category': category}),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.4, color: isDark ? Color.lerp(color, Colors.white, 0.3) : Color.lerp(color, Colors.black, 0.25)),
                          ),
                        ),
                        if (!done) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.schedule_rounded, size: 12, color: ink.withValues(alpha: 0.45)),
                          const SizedBox(width: 2),
                          Text(challenge.duration, style: TextStyle(fontSize: 11, color: ink.withValues(alpha: 0.5))),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: ink)),
                    const SizedBox(height: 2),
                    Text(
                      done ? '+${challenge.xpReward} XP 🎉' : description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, height: 1.3, fontWeight: done ? FontWeight.w800 : FontWeight.w400, color: done ? green : (isDark ? Colors.white60 : AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
              if (!done)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Text('+${challenge.xpReward}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: isDark ? Color.lerp(color, Colors.white, 0.3) : Color.lerp(color, Colors.black, 0.2))),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Racha y nivel juntos: la llama con la semana, y el anillo de nivel con XP.
class HomeProgressCard extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final int level;
  final String levelTitle;
  final int xpInLevel;
  final int xpForNext;
  final int totalXp;
  final List<Color> levelColors;
  final bool isDark;

  const HomeProgressCard({
    super.key,
    required this.streak,
    required this.bestStreak,
    required this.level,
    required this.levelTitle,
    required this.xpInLevel,
    required this.xpForNext,
    required this.totalXp,
    required this.levelColors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    final soft = isDark ? Colors.white60 : AppColors.textSecondary;
    const flame = Color(0xFFF97316);
    final todayIndex = DateTime.now().weekday - 1;
    const dayKeys = ['days.monMini', 'days.tueMini', 'days.wedMini', 'days.thuMini', 'days.friMini', 'days.satMini', 'days.sunMini'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFEDE9FE)),
        boxShadow: isDark ? null : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          // ── Racha ─────────────────────────────────────────────────────────
          Semantics(
            label: '${'home.streak'.tr()}: $streak. ${'home.streakBest'.tr()}: $bestStreak',
            excludeSemantics: true,
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: streak > 0
                        ? const RadialGradient(colors: [Color(0xFFFDE68A), Color(0xFFFB923C)])
                        : null,
                    color: streak > 0 ? null : ink.withValues(alpha: 0.06),
                  ),
                  child: Center(
                    child: Text(streak > 0 ? '🔥' : '🌱', style: const TextStyle(fontSize: 30))
                        .animate(onPlay: streak > 0 ? MotionService.loop(context, reverse: true) : null)
                        .scale(begin: const Offset(0.94, 0.94), end: const Offset(1.08, 1.08), duration: 1100.ms, curve: Curves.easeInOut),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        streak == 1 ? 'home.streakDay'.tr() : 'home.streakDays'.tr(namedArgs: {'count': '$streak'}),
                        style: TextStyle(fontSize: 24, height: 1.05, fontWeight: FontWeight.w900, color: ink),
                      ),
                      Text(
                        streak > 0 ? 'home.streakKeepGoing'.tr() : 'home.streakDoCheckin'.tr(),
                        style: JournalStyle.hand(TextStyle(fontSize: 18, color: streak > 0 ? flame : soft)),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 20),
                    Text('$bestStreak', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: ink)),
                    Text('home.streakBest'.tr(), style: TextStyle(fontSize: 10.5, color: soft)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (int i = 0; i < 7; i++)
                  () {
                    final isToday = i == todayIndex;
                    // Días de la semana cubiertos por la racha actual
                    final active = i <= todayIndex && streak > (todayIndex - i);
                    return Column(
                      children: [
                        Text(dayKeys[i].tr(), style: TextStyle(fontSize: 11, fontWeight: isToday ? FontWeight.w900 : FontWeight.w600, color: isToday ? ink : soft)),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: active ? flame.withValues(alpha: isToday ? 1 : 0.35) : ink.withValues(alpha: 0.05),
                            border: isToday && !active ? Border.all(color: flame.withValues(alpha: 0.6), width: 1.5) : null,
                          ),
                          child: active
                              ? Icon(isToday ? Icons.local_fire_department_rounded : Icons.check_rounded, size: isToday ? 17 : 14, color: Colors.white)
                              : null,
                        ),
                      ],
                    );
                  }(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: ink.withValues(alpha: 0.08)),
          ),
          // ── Nivel ─────────────────────────────────────────────────────────
          Semantics(
            label: '${'home.levelShort'.tr()} $level, $levelTitle. $xpInLevel / $xpForNext XP',
            excludeSemantics: true,
            child: Row(
              children: [
                RouteProgressRing(
                  progress: xpForNext == 0 ? 0 : xpInLevel / xpForNext,
                  color: levelColors.first,
                  track: levelColors.first.withValues(alpha: isDark ? 0.2 : 0.14),
                  size: 58,
                  stroke: 5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('home.levelShort'.tr(), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: soft)),
                      Text('$level', style: TextStyle(fontSize: 19, height: 1, fontWeight: FontWeight.w900, color: ink)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(levelTitle, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: ink)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: xpForNext == 0 ? 0 : xpInLevel / xpForNext),
                          duration: MotionService.reduced(context) ? Duration.zero : const Duration(milliseconds: 1100),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 9,
                            backgroundColor: levelColors.first.withValues(alpha: isDark ? 0.18 : 0.12),
                            valueColor: AlwaysStoppedAnimation(levelColors.first),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('$xpInLevel / $xpForNext XP', style: TextStyle(fontSize: 12, color: soft)),
                          const Spacer(),
                          const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFF59E0B)),
                          Text('$totalXp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ink)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Frase del día como nota a mano, para cerrar el Home con calma.
class QuoteNote extends StatelessWidget {
  final String text;
  final String author;
  final bool isDark;

  const QuoteNote({super.key, required this.text, required this.author, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final s = JournalStyle(isDark);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          decoration: BoxDecoration(
            color: s.paper,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: s.paperEdge),
            boxShadow: s.paperShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'home.quoteOfDay'.tr(),
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: s.inkSoft),
              ),
              const SizedBox(height: 6),
              Text(
                '“$text”',
                style: JournalStyle.hand(TextStyle(fontSize: 25, height: 1.15, color: s.ink)),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text('— $author', style: JournalStyle.serif(TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: s.inkSoft))),
              ),
            ],
          ),
        ),
        const Positioned(top: -9, left: 26, child: WashiTape(color: Color(0xFFA78BFA))),
      ],
    );
  }
}
