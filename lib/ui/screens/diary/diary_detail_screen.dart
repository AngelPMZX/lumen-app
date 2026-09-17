import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/diary_entry.dart';
import '../../../data/models/lumi.dart';
import '../../../data/models/mood_entry.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../widgets/journal/journal_style.dart';
import '../../widgets/lumi/lumi_avatar.dart';

/// Una página del diario, como en un cuaderno: fecha a mano, ánimo, el texto
/// sobre renglones, la gratitud en una nota adhesiva y unas palabras de Lumi.
class DiaryDetailScreen extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryDetailScreen({super.key, required this.entry});

  String _locale(BuildContext context) {
    final l = context.locale;
    return l.countryCode?.isNotEmpty == true ? '${l.languageCode}_${l.countryCode}' : l.languageCode;
  }

  String _moodLabel(MoodType mood) {
    final key = 'mood.${mood.name}';
    final translated = key.tr();
    return translated == key ? mood.label : translated;
  }

  Future<void> _deleteEntry(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('diary.deleteEntry'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text('journal.deleteConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    try {
      await context.read<AuthProvider>().deleteDiaryEntry(entry.id);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('diary.deleteError'.tr(namedArgs: {'error': e.toString()})),
          backgroundColor: const Color(0xFFEF4444),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = JournalStyle.of(context);
    final locale = _locale(context);
    final date = DateFormat('EEEE d MMMM yyyy', locale).format(entry.createdAt);
    final time = DateFormat.jm(locale).format(entry.createdAt);
    final mood = entry.mood;
    final hasGratitude = entry.gratitude != null && entry.gratitude!.isNotEmpty;
    final hard = mood.category == 'negative';
    const fontSize = 16.5;
    const lineHeight = 1.8;

    return Scaffold(
      backgroundColor: Color.lerp(
        s.isDark ? const Color(0xFF12131F) : const Color(0xFFFBF6EC),
        mood.color,
        s.isDark ? 0.05 : 0.04,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: s.ink,
        actions: [
          IconButton(
            tooltip: 'diary.deleteEntry'.tr(),
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            onPressed: () => _deleteEntry(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                JournalPaper(
                  tint: s.paperFor(mood),
                  // Los renglones van con el texto (RuledText), no con la hoja
                  firstLine: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 26, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date[0].toUpperCase() + date.substring(1),
                        style: JournalStyle.hand(TextStyle(fontSize: 27, height: 1.1, fontWeight: FontWeight.w700, color: s.ink)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(time, style: JournalStyle.hand(TextStyle(fontSize: 19, color: s.inkSoft))),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: mood.color.withValues(alpha: s.isDark ? 0.24 : 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(
                                  _moodLabel(mood),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: s.isDark ? Color.lerp(mood.color, Colors.white, 0.3) : Color.lerp(mood.color, Colors.black, 0.25),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      RuledText(
                        lineHeight: fontSize * lineHeight,
                        child: SelectableText(
                          entry.text,
                          style: JournalStyle.serif(TextStyle(fontSize: fontSize, height: lineHeight, color: s.ink)),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, end: 0),
                Positioned(top: -9, left: 30, child: WashiTape(color: mood.color)),
                Positioned(top: -7, right: 34, child: WashiTape(color: const Color(0xFFA78BFA), width: 60, angle: 0.08)),
              ],
            ),
            if (hasGratitude) ...[
              const SizedBox(height: 30),
              StickyNote(
                angle: 0.015,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.prompt ?? 'diary.gratitudeTitle'.tr(),
                      style: JournalStyle.hand(TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: s.isDark ? const Color(0xFFFEF3C7) : const Color(0xFF78350F),
                      )),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      entry.gratitude!,
                      style: JournalStyle.serif(TextStyle(
                        fontSize: 15.5,
                        height: 1.6,
                        color: s.isDark ? const Color(0xFFFEF3C7) : const Color(0xFF78350F),
                      )),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            ],
            const SizedBox(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                LumiAvatar(mood: hard ? LumiMood.caring : JournalStyle.lumiFor(mood), size: 56),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hard
                        ? 'journal.lumiDetailHard'.tr()
                        : mood.category == 'positive'
                            ? 'journal.lumiDetailGood'.tr()
                            : 'journal.lumiDetailNeutral'.tr(),
                    style: JournalStyle.hand(TextStyle(fontSize: 20, height: 1.15, color: s.inkSoft)),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 13, color: s.inkSoft),
                const SizedBox(width: 5),
                Text('journal.onlyYou'.tr(), style: TextStyle(fontSize: 12, color: s.inkSoft)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
