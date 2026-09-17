import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/lumi.dart';
import '../../../data/models/medals.dart';
import '../../../domain/services/motion_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/journal/journal_style.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import '../../widgets/medal_badge.dart';
import '../../widgets/min_tap_target.dart';
import '../garden/widgets/garden_common.dart' show LightRays;
import '../routes/widgets/route_progress_ring.dart';
import 'widgets/profile_widgets.dart';

String medalTitle(MedalStatus m) => m.achievement.titleKey?.tr() ?? m.achievement.title;
String medalDescription(MedalStatus m) => m.achievement.descriptionKey?.tr() ?? m.achievement.description;

/// Vitrina completa de medallas: avance total, metales, filtros por tipo y
/// una cuadrícula de medallas que se pueden tocar para ver su detalle.
class AchievementsScreen extends StatefulWidget {
  final AchievementStats stats;

  /// Se llama con las medallas nuevas una vez mostradas.
  final ValueChanged<Set<String>>? onSeen;

  const AchievementsScreen({super.key, required this.stats, this.onSeen});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  MedalCategory? _filter;
  late final List<MedalStatus> _medals = Medals.evaluate(widget.stats);

  @override
  void initState() {
    super.initState();
    final fresh = _medals.where((m) => m.isNew).map((m) => m.id).toSet();
    if (fresh.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        SoundService.instance.play(Sfx.achievement, volume: 0.5);
        widget.onSeen?.call(fresh);
      });
    }
  }

  void _setFilter(MedalCategory? c) {
    if (c == _filter) return;
    SoundService.instance.play(Sfx.tapNode, volume: 0.35);
    HapticFeedback.selectionClick();
    setState(() => _filter = c);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    final unlocked = _medals.where((m) => m.unlocked).length;
    final tiers = Medals.tierCounts(_medals);
    final next = Medals.nextUp(_medals);
    final visible = _medals.where((m) => _filter == null || m.category == _filter).toList()
      ..sort((a, b) {
        if (a.unlocked != b.unlocked) return a.unlocked ? -1 : 1;
        return b.progress.compareTo(a.progress);
      });
    final bg = isDark ? const Color(0xFF0F0F23) : const Color(0xFFFBF7EE);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              unlocked: unlocked,
              total: _medals.length,
              tiers: tiers,
              isDark: isDark,
              line: _lumiLine(unlocked, next),
            ),
          ),
          if (next != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: NextMedalRow(medal: next, isDark: isDark, onTap: () => showMedalDetail(context, next))
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 350.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                children: [
                  _FilterChip(label: 'medals.all'.tr(), emoji: '✨', selected: _filter == null, isDark: isDark, onTap: () => _setFilter(null)),
                  for (final c in MedalCategory.values)
                    _FilterChip(
                      label: 'medals.category.${c.name}'.tr(),
                      emoji: _categoryEmoji(c),
                      selected: _filter == c,
                      isDark: isDark,
                      onTap: () => _setFilter(c),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 32 + MediaQuery.viewPaddingOf(context).bottom),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 130,
                mainAxisExtent: 158,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final m = visible[i];
                  return _MedalTile(medal: m, isDark: isDark, ink: ink)
                      .animate(key: ValueKey('${_filter?.name}_${m.id}'))
                      .fadeIn(delay: (40 * i).ms, duration: 300.ms)
                      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 450.ms, curve: Curves.easeOutBack);
                },
                childCount: visible.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LumiLine _lumiLine(int unlocked, MedalStatus? next) {
    if (_medals.any((m) => m.isNew)) return const LumiLine('medals.lumi.new', LumiMood.excited);
    if (next == null) return const LumiLine('medals.lumi.all', LumiMood.proud);
    if (unlocked == 0) return const LumiLine('medals.lumi.none', LumiMood.happy);
    return const LumiLine('medals.lumi.some', LumiMood.proud);
  }

  static String _categoryEmoji(MedalCategory c) => switch (c) {
        MedalCategory.streak => '🔥',
        MedalCategory.growth => '⚡',
        MedalCategory.diary => '📝',
        MedalCategory.mood => '😊',
        MedalCategory.habits => '✅',
        MedalCategory.garden => '🌱',
      };
}

class _Header extends StatelessWidget {
  final int unlocked;
  final int total;
  final Map<MedalTier, int> tiers;
  final bool isDark;
  final LumiLine line;

  const _Header({required this.unlocked, required this.total, required this.tiers, required this.isDark, required this.line});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.viewPaddingOf(context).top;
    final progress = total == 0 ? 0.0 : unlocked / total;
    final colors = isDark
        ? const [Color(0xFF3B2A0B), Color(0xFF1E1633), Color(0xFF0F0F23)]
        : const [Color(0xFFFCD34D), Color(0xFFF59E0B), Color(0xFFD97706)];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors)),
        padding: EdgeInsets.fromLTRB(8, top + 4, 16, 22),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text('profile.medals'.tr(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 8),
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      LightRays(color: Colors.white.withValues(alpha: 0.7), size: 170),
                      Semantics(
                        label: 'achievementsScreen.headerCount'.tr(namedArgs: {'unlocked': '$unlocked', 'total': '$total'}),
                        excludeSemantics: true,
                        child: RouteProgressRing(
                          progress: progress,
                          color: Colors.white,
                          track: Colors.white.withValues(alpha: 0.25),
                          size: 118,
                          stroke: 7,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 34))
                                  .animate(onPlay: MotionService.loop(context, reverse: true))
                                  .moveY(begin: 0, end: -4, duration: 1400.ms, curve: Curves.easeInOut),
                              Text(
                                '$unlocked/$total',
                                style: const TextStyle(fontSize: 20, height: 1.1, fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'medals.kicker'.tr(),
                        style: JournalStyle.hand(const TextStyle(fontSize: 21, height: 1.0, color: Colors.white)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'achievementsScreen.headerSubtitle'.tr(),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85)),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final t in MedalTier.values) _TierPill(tier: t, count: tiers[t] ?? 0),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                LumiAvatar(mood: line.mood, size: 50, onTap: () {}),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      line.key.tr(namedArgs: line.args),
                      style: const TextStyle(fontSize: 12.5, height: 1.3, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _TierPill extends StatelessWidget {
  final MedalTier tier;
  final int count;
  const _TierPill({required this.tier, required this.count});

  @override
  Widget build(BuildContext context) {
    final metal = MedalMetal.of(tier);
    return Semantics(
      label: '${'medals.tier.${tier.name}'.tr()}: $count',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 9, 3),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [metal.light, metal.mid, metal.dark]),
              ),
            ),
            const SizedBox(width: 5),
            Text('$count', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.emoji, required this.selected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFF59E0B);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        label: label,
        onTap: onTap,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: selected ? const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFD97706)]) : null,
              color: selected ? null : (isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: selected ? Colors.transparent : gold.withValues(alpha: isDark ? 0.25 : 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedalTile extends StatelessWidget {
  final MedalStatus medal;
  final bool isDark;
  final Color ink;

  const _MedalTile({required this.medal, required this.isDark, required this.ink});

  @override
  Widget build(BuildContext context) {
    final title = medalTitle(medal);
    final status = medal.unlocked ? 'medals.tier.${medal.tier.name}'.tr() : '${medal.current}/${medal.requirement}';
    return Semantics(
      button: true,
      label: '$title. ${medal.unlocked ? status : '${'profile.medalLocked'.tr()}, $status'}',
      onTap: () => showMedalDetail(context, medal),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => showMedalDetail(context, medal),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                MedalBadge(medal: medal, size: 76),
                if (medal.isNew) const Positioned(top: -2, right: -12, child: NewMedalChip()),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, height: 1.15, fontWeight: FontWeight.w800, color: medal.unlocked ? ink : ink.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: medal.unlocked
                    ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                    : ink.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Detalle de una medalla
// ═════════════════════════════════════════════════════════════════════════════

Future<void> showMedalDetail(BuildContext context, MedalStatus medal) {
  HapticFeedback.lightImpact();
  if (medal.unlocked) {
    SoundService.instance.medal(medal.tier.index, volume: 0.5);
  } else {
    SoundService.instance.play(Sfx.tapNode, volume: 0.4);
  }
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MedalDetailSheet(medal: medal),
  );
}

class MedalDetailSheet extends StatelessWidget {
  final MedalStatus medal;
  const MedalDetailSheet({super.key, required this.medal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    final color = medal.achievement.color;
    final reduced = MotionService.reduced(context);
    final metal = MedalMetal.of(medal.tier);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF17182A) : const Color(0xFFFFFCF5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(22, 12, 22, 22 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(color: ink.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2)),
          ),
          SizedBox(
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (medal.unlocked) LightRays(color: Color.lerp(color, metal.mid, 0.5)!, size: 250),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: reduced ? 0 : 1, end: 0),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, t, child) => Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateY(t * math.pi * 2),
                    child: child,
                  ),
                  child: MedalBadge(medal: medal, size: 140),
                ),
                if (medal.unlocked && !reduced) SparkleBurst(color: color, size: 240, seed: medal.id.hashCode),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _Tag(text: 'medals.category.${medal.category.name}'.tr(), color: color, isDark: isDark),
              if (medal.unlocked) _Tag(text: 'medals.tier.${medal.tier.name}'.tr(), color: metal.dark, isDark: isDark),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(medalTitle(medal), textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: ink)),
          ),
          const SizedBox(height: 4),
          Text(
            medalDescription(medal),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, height: 1.4, color: isDark ? Colors.white70 : AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          if (!medal.unlocked) ...[
            Row(
              children: [
                Text('medals.progress'.tr(), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: ink.withValues(alpha: 0.6))),
                const Spacer(),
                Text('${medal.current}/${medal.requirement}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: ink)),
              ],
            ),
            const SizedBox(height: 6),
            LayoutBuilder(
              builder: (context, c) => Stack(
                children: [
                  Container(height: 10, decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6))),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: medal.progress),
                    duration: reduced ? Duration.zero : const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Container(
                      width: c.maxWidth * v,
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Color.lerp(color, Colors.white, 0.3)!, color]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LumiAvatar(mood: medal.unlocked ? LumiMood.proud : LumiMood.caring, size: 48, onTap: () {}),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                    ),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    medal.unlocked
                        ? 'medals.lumi.unlocked'.tr()
                        : 'medals.lumi.locked'.tr(namedArgs: {'count': '${medal.remaining}'}),
                    style: JournalStyle.hand(TextStyle(fontSize: 18, height: 1.15, color: ink.withValues(alpha: 0.85))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;
  const _Tag({required this.text, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.25 : 0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isDark ? Color.lerp(color, Colors.white, 0.45) : Color.lerp(color, Colors.black, 0.2),
        ),
      ),
    );
  }
}
