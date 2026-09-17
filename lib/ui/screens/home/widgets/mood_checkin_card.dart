import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/mood_entry.dart';
import '../../../../domain/services/motion_service.dart';
import '../../../widgets/journal/journal_style.dart';
import '../../../widgets/min_tap_target.dart';

/// Check-in de ánimo: burbujas grandes para elegir; una vez elegido, se
/// resume en una franja con el color del ánimo. Abajo, la semana en emojis.
class MoodCheckInCard extends StatefulWidget {
  final MoodType? selected;
  final Map<int, MoodType> weeklyMoods;
  final bool isDark;
  final ValueChanged<MoodType> onSelect;

  const MoodCheckInCard({
    super.key,
    required this.selected,
    required this.weeklyMoods,
    required this.isDark,
    required this.onSelect,
  });

  @override
  State<MoodCheckInCard> createState() => _MoodCheckInCardState();
}

class _MoodCheckInCardState extends State<MoodCheckInCard> {
  /// Mostrar las opciones aunque ya haya ánimo (al tocar "Cambiar").
  bool _editing = false;
  int _burst = 0;

  String _label(MoodType mood) {
    final key = 'mood.${mood.name}';
    final t = key.tr();
    return t == key ? mood.label : t;
  }

  void _pick(MoodType mood) {
    HapticFeedback.selectionClick();
    setState(() {
      _editing = false;
      _burst++;
    });
    widget.onSelect(mood);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final selected = widget.selected;
    final showPicker = selected == null || _editing;
    final ink = isDark ? Colors.white : AppColors.textPrimary;
    final cardColor = selected == null
        ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white)
        : Color.lerp(isDark ? const Color(0xFF1B1C2E) : Colors.white, selected.color, isDark ? 0.16 : 0.1)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: selected?.color.withValues(alpha: 0.35) ?? (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE9E5FF)),
        ),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: (selected?.color ?? AppColors.primary).withValues(alpha: 0.1), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'home.moodCheckIn'.tr(),
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ink),
                  ),
                ),
              ),
              if (selected != null && !_editing)
                MinTapTarget(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _editing = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected.color.withValues(alpha: isDark ? 0.25 : 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 13, color: ink.withValues(alpha: 0.75)),
                        const SizedBox(width: 4),
                        Text('home.moodChange'.tr(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink.withValues(alpha: 0.75))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: showPicker ? _buildPicker(isDark) : _buildChosen(selected, isDark, ink),
          ),
          const SizedBox(height: 14),
          _buildWeek(isDark, ink),
        ],
      ),
    );
  }

  Widget _buildPicker(bool isDark) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: MoodType.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final mood = MoodType.values[i];
          final isSelected = widget.selected == mood;
          return Semantics(
            button: true,
            selected: isSelected,
            inMutuallyExclusiveGroup: true,
            label: _label(mood),
            onTap: () => _pick(mood),
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => _pick(mood),
              child: SizedBox(
                width: 64,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? mood.color.withValues(alpha: isDark ? 0.3 : 0.2)
                            : mood.color.withValues(alpha: isDark ? 0.1 : 0.07),
                        border: Border.all(color: isSelected ? mood.color : Colors.transparent, width: 2.5),
                      ),
                      child: Center(child: Text(mood.emoji, style: const TextStyle(fontSize: 28))),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _label(mood),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: (25 * i).ms, duration: 250.ms).slideX(begin: 0.25, end: 0, curve: Curves.easeOutCubic);
        },
      ),
    );
  }

  Widget _buildChosen(MoodType mood, bool isDark, Color ink) {
    return Row(
      key: ValueKey(mood),
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (_burst > 0 && !MotionService.reduced(context)) SparkleBurst(key: ValueKey('burst_$_burst'), color: mood.color, size: 120, seed: _burst),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: mood.color.withValues(alpha: isDark ? 0.3 : 0.2),
                ),
                child: Center(child: Text(mood.emoji, style: const TextStyle(fontSize: 36))),
              ).animate(key: ValueKey('pop_${mood.name}_$_burst')).scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                    duration: 450.ms,
                    curve: Curves.elasticOut,
                  ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'home.moodTodayLabel'.tr(),
                style: JournalStyle.hand(TextStyle(fontSize: 19, color: ink.withValues(alpha: 0.65))),
              ),
              Text(
                _label(mood),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Color.lerp(mood.color, Colors.white, 0.35) : Color.lerp(mood.color, Colors.black, 0.3),
                ),
              ),
              Text(
                mood.category == 'negative'
                    ? 'home.moodHardNote'.tr()
                    : mood.category == 'positive'
                        ? 'home.moodGoodNote'.tr()
                        : 'home.moodNeutralNote'.tr(),
                style: TextStyle(fontSize: 12.5, height: 1.35, color: ink.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// La semana: lunes a domingo con el emoji registrado cada día.
  Widget _buildWeek(bool isDark, Color ink) {
    const dayKeys = ['days.monMini', 'days.tueMini', 'days.wedMini', 'days.thuMini', 'days.friMini', 'days.satMini', 'days.sunMini'];
    final today = DateTime.now().weekday;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (int d = 1; d <= 7; d++)
            () {
              final mood = widget.weeklyMoods[d];
              final isToday = d == today;
              final future = d > today;
              return Semantics(
                label: '${dayKeys[d - 1].tr()}: ${mood == null ? '—' : _label(mood)}',
                excludeSemantics: true,
                child: Column(
                  children: [
                    Text(
                      dayKeys[d - 1].tr(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                        color: isToday ? ink : ink.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: mood?.color.withValues(alpha: isDark ? 0.28 : 0.18),
                        border: isToday
                            ? Border.all(color: mood?.color ?? AppColors.primary, width: 2)
                            : (mood == null && !future
                                ? Border.all(color: ink.withValues(alpha: 0.12))
                                : null),
                      ),
                      child: Center(
                        child: mood != null
                            ? Text(mood.emoji, style: const TextStyle(fontSize: 17))
                            : Text(future ? '' : '·', style: TextStyle(fontSize: 16, color: ink.withValues(alpha: 0.3))),
                      ),
                    ),
                  ],
                ),
              );
            }(),
        ],
      ),
    );
  }
}
