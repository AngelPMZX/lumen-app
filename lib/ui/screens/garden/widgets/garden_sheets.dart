import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/utils/image_sizing.dart';
import '../../../../data/models/achievement.dart';
import '../../../../data/models/garden_item.dart';
import '../../../../domain/services/motion_service.dart';
import '../../routes/widgets/route_progress_ring.dart';
import '../garden_defs.dart';
import 'garden_common.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Elegir jardín
// ═════════════════════════════════════════════════════════════════════════════

Future<GardenDef?> showGardenSelectorSheet(
  BuildContext context, {
  required String currentId,
  required Map<String, int> plantsPerGarden,
}) {
  return showModalBottomSheet<GardenDef>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.45,
      expand: false,
      builder: (_, scroll) => GardenSheet(
        kicker: 'garden.selectGardenKicker'.tr(),
        title: 'garden.selectGarden'.tr(),
        scrollable: true,
        controller: scroll,
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
          children: [
            for (final (i, g) in GardensCatalog.all.indexed)
              _GardenCard(
                garden: g,
                current: g.id == currentId,
                plants: plantsPerGarden[g.id] ?? 0,
                onTap: g.isUnlocked ? () => Navigator.pop(ctx, g) : null,
              ).animate().fadeIn(delay: (50 * i).ms, duration: 300.ms).scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), curve: Curves.easeOutCubic),
          ],
        ),
      ),
    ),
  );
}

class _GardenCard extends StatelessWidget {
  final GardenDef garden;
  final bool current;
  final int plants;
  final VoidCallback? onTap;

  const _GardenCard({required this.garden, required this.current, required this.plants, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locked = !garden.isUnlocked;
    final status = locked
        ? 'common.comingSoon'.tr()
        : current
            ? 'garden.active'.tr()
            : 'garden.plantsCount'.tr(namedArgs: {'count': '$plants', 'total': '${garden.slots.length}'});
    return GardenPressable(
      onTap: onTap,
      selected: current,
      semanticsLabel: '${garden.nameKey.tr()}. $status',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: current ? GardenPalette.green : Colors.transparent, width: 3),
          boxShadow: [
            BoxShadow(
              color: (current ? GardenPalette.green : Colors.black).withValues(alpha: current ? 0.35 : 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: locked
                    ? const ColorFilter.matrix([
                        0.33, 0.33, 0.33, 0, 0, //
                        0.33, 0.33, 0.33, 0, 0,
                        0.33, 0.33, 0.33, 0, 0,
                        0, 0, 0, 1, 0,
                      ])
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: Image.asset(
                  garden.assetPath,
                  fit: BoxFit.cover,
                  // Miniatura: el ancho de la hoja, no los 1536 px del archivo.
                  cacheWidth: decodePixels(context, 360),
                  errorBuilder: (_, _, _) => Container(color: garden.tint),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.45, 1],
                    colors: [Colors.transparent, Colors.black.withValues(alpha: locked ? 0.75 : 0.6)],
                  ),
                ),
              ),
              if (locked)
                Center(
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
                  ),
                ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      garden.nameKey.tr(),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 6)]),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: current ? GardenPalette.green : Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Progreso del jardín: números y logros
// ═════════════════════════════════════════════════════════════════════════════

Future<void> showGardenProgressSheet(
  BuildContext context, {
  required String gardenName,
  required int plants,
  required int adults,
  required int decorations,
  required int slots,
}) {
  final achievements = Achievement.all
      .where((a) =>
          a.type == AchievementType.gardenPlants ||
          a.type == AchievementType.gardenAdults ||
          a.type == AchievementType.gardenDecorations)
      .toList();

  bool unlocked(Achievement a) => a.isUnlocked(
        currentStreak: 0,
        longestStreak: 0,
        totalXp: 0,
        level: 0,
        diaryEntries: 0,
        habitsCompleted: 0,
        moodCheckIns: 0,
        totalPlantsEver: plants,
        adultPlants: adults,
        decorationsPlaced: decorations,
      );
  double progress(Achievement a) => a.progress(
        currentStreak: 0,
        longestStreak: 0,
        totalXp: 0,
        level: 0,
        diaryEntries: 0,
        habitsCompleted: 0,
        moodCheckIns: 0,
        totalPlantsEver: plants,
        adultPlants: adults,
        decorationsPlaced: decorations,
      );

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final p = GardenPalette(isDark);
      final done = achievements.where(unlocked).length;
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scroll) => GardenSheet(
          kicker: gardenName,
          title: 'garden.stats.title'.tr(),
          scrollable: true,
          controller: scroll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _StatTile(emoji: '🌱', value: '$plants/$slots', label: 'garden.stats.plants'.tr(), color: GardenPalette.green, isDark: isDark),
                  const SizedBox(width: 10),
                  _StatTile(emoji: '🌸', value: '$adults', label: 'garden.stats.adults'.tr(), color: const Color(0xFFEC4899), isDark: isDark),
                  const SizedBox(width: 10),
                  _StatTile(emoji: '🏮', value: '$decorations', label: 'garden.stats.decos'.tr(), color: GardenPalette.gold, isDark: isDark),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text('garden.sidebar.achievements'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: p.ink)),
                  ),
                  Text(
                    'garden.achievementsSheet.count'.tr(namedArgs: {'unlocked': '$done', 'total': '${achievements.length}'}),
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: p.inkSoft),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final (i, a) in achievements.indexed)
                _AchievementTile(achievement: a, unlocked: unlocked(a), progress: progress(a), isDark: isDark)
                    .animate()
                    .fadeIn(delay: (40 * i).ms, duration: 260.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
            ],
          ),
        ),
      );
    },
  );
}

class _StatTile extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatTile({required this.emoji, required this.value, required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final p = GardenPalette(isDark);
    return Expanded(
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: isDark ? 0.22 : 0.14), p.card],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: p.ink)),
              Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: p.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final double progress;
  final bool isDark;

  const _AchievementTile({required this.achievement, required this.unlocked, required this.progress, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final p = GardenPalette(isDark);
    final title = a.titleKey?.tr() ?? a.title;
    final desc = a.descriptionKey?.tr() ?? a.description;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        label: '$title. $desc. ${unlocked ? '✓' : '${(progress * 100).round()}%'}',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: unlocked ? a.color.withValues(alpha: isDark ? 0.16 : 0.1) : p.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: unlocked ? a.color.withValues(alpha: 0.4) : p.cardBorder),
          ),
          child: Row(
            children: [
              RouteProgressRing(
                progress: unlocked ? 1 : progress,
                color: a.color,
                track: a.color.withValues(alpha: 0.15),
                size: 48,
                stroke: 4,
                child: Opacity(opacity: unlocked ? 1 : 0.5, child: Text(a.emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: p.ink)),
                    const SizedBox(height: 2),
                    Text(desc, style: TextStyle(fontSize: 12, color: p.inkSoft)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              unlocked
                  ? Icon(Icons.check_circle_rounded, color: a.color, size: 24)
                  : Text(
                      '${(progress * a.requirement).round()}/${a.requirement}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: a.color),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Decoración colocada: moverla o guardarla
// ═════════════════════════════════════════════════════════════════════════════

/// Devuelve true si el usuario decide guardar la decoración en la mochila.
Future<bool> showDecoOptionsSheet(BuildContext context, GardenItem item) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final p = GardenPalette(Theme.of(ctx).brightness == Brightness.dark);
      return GardenSheet(
        kicker: 'garden.rarity.${item.rarity.name}'.tr(),
        title: item.nameKey.tr(),
        leading: GardenItemImage(item: item, size: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.descriptionKey.tr(), style: TextStyle(fontSize: 13.5, height: 1.4, color: p.inkSoft)),
            const SizedBox(height: 14),
            _OptionTile(
              icon: Icons.open_with_rounded,
              color: const Color(0xFF3B82F6),
              title: 'garden.decoOptions.move'.tr(),
              subtitle: 'garden.decoOptions.moveHint'.tr(),
              onTap: () => Navigator.pop(ctx, false),
            ),
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.inventory_2_rounded,
              color: GardenPalette.green,
              title: 'garden.decoOptions.store'.tr(),
              subtitle: 'garden.decoOptions.storeHint'.tr(),
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = GardenPalette(Theme.of(context).brightness == Brightness.dark);
    return GardenPressable(
      onTap: onTap,
      semanticsLabel: '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: p.ink)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: p.inkSoft)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.inkSoft),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Escudos de racha
// ═════════════════════════════════════════════════════════════════════════════

/// Devuelve true si el usuario decide usar un escudo ahora.
Future<bool> showShieldSheet(BuildContext context, {required int shields, required bool canUse}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final p = GardenPalette(Theme.of(ctx).brightness == Brightness.dark);
      return GardenSheet(
        kicker: shields == 1 ? 'garden.shields.countOne'.tr() : 'garden.shields.countOther'.tr(namedArgs: {'count': '$shields'}),
        title: 'garden.shields.title'.tr(),
        leading: const Text('🛡️', style: TextStyle(fontSize: 44))
            .animate(onPlay: MotionService.loop(ctx, reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 1100.ms, curve: Curves.easeInOut),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('garden.shields.description'.tr(), style: TextStyle(fontSize: 13.5, height: 1.45, color: p.inkSoft)),
            if (canUse) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.shield_rounded),
                label: Text('garden.shields.useNow'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: GardenPalette.gold,
                  foregroundColor: const Color(0xFF3B2600),
                  minimumSize: const Size.fromHeight(50),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
  return result ?? false;
}

// ═════════════════════════════════════════════════════════════════════════════
// Guardar una planta en la mochila
// ═════════════════════════════════════════════════════════════════════════════

Future<bool> confirmReturnPlant(BuildContext context, GardenItem item) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final p = GardenPalette(Theme.of(ctx).brightness == Brightness.dark);
      return GardenSheet(
        title: 'garden.returnPlantTitle'.tr(namedArgs: {'plant': item.nameKey.tr()}),
        leading: GardenItemImage(item: item, size: 56, stage: PlantStage.seed),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('garden.returnPlantBody'.tr(), style: TextStyle(fontSize: 13.5, height: 1.45, color: p.inkSoft)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.ink,
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(color: p.cardBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('common.cancel'.tr()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFDC6B4A),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('garden.returnToInventory'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}
