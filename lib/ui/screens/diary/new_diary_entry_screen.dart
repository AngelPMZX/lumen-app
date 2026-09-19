import '../../widgets/clip_sideways.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../data/models/diary_entry.dart';
import '../../../data/models/lumi.dart';
import '../../../data/models/mood_entry.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/diary_draft_service.dart';
import '../../../domain/services/motion_service.dart';
import '../../../domain/services/sound_service.dart';
import '../../widgets/journal/journal_style.dart';
import '../../widgets/lumi/lumi_avatar.dart';
import '../../widgets/min_tap_target.dart';

/// Escribir una página del diario.
///
/// Pensada para dar confianza: papel cálido, la página toma el color del
/// ánimo, Lumi acompaña con una pregunta (que se puede cambiar), nota
/// adhesiva de gratitud, "solo tú puedes leer esto" y **borrador automático
/// en el teléfono**: cerrar la pantalla nunca pierde lo escrito.
class NewDiaryEntryScreen extends StatefulWidget {
  /// Pregunta con la que abre (p. ej. la del día que mostró Lumi).
  final String? initialPromptKey;

  /// Solo para pruebas: sin usuario ni borrador.
  @visibleForTesting
  final bool preview;

  const NewDiaryEntryScreen({super.key, this.initialPromptKey, this.preview = false});

  @override
  State<NewDiaryEntryScreen> createState() => _NewDiaryEntryScreenState();
}

class _NewDiaryEntryScreenState extends State<NewDiaryEntryScreen> {
  static const _minChars = 3;

  MoodType? _mood;
  final _textController = TextEditingController();
  final _gratitudeController = TextEditingController();
  bool _showGratitude = false;
  bool _isSaving = false;
  bool _saved = false;
  bool _restoredDraft = false;

  late String _promptKey;
  late final String _gratitudePromptKey;
  final _rng = math.Random();
  Timer? _draftTimer;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _promptKey = widget.initialPromptKey ?? DiaryPrompts.getRandomReflectionPromptKey();
    _gratitudePromptKey = DiaryPrompts.getRandomGratitudePromptKey();
    if (widget.preview) return;
    _uid = context.read<AuthProvider>().firebaseUser?.uid;
    _restoreDraft();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    // Guardar el borrador al salir (si no se guardó la entrada)
    if (!_saved) _persistDraft();
    _textController.dispose();
    _gratitudeController.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final uid = _uid;
    if (uid == null) return;
    final draft = await DiaryDraftService.instance.load(uid);
    if (draft == null || !mounted) return;
    setState(() {
      _mood = draft.mood;
      _textController.text = draft.text;
      _gratitudeController.text = draft.gratitude;
      _showGratitude = draft.showGratitude;
      _restoredDraft = true;
    });
  }

  DiaryDraft get _draft => DiaryDraft(
        mood: _mood,
        text: _textController.text,
        gratitude: _gratitudeController.text,
        showGratitude: _showGratitude,
      );

  void _persistDraft() {
    final uid = _uid;
    if (uid == null) return;
    DiaryDraftService.instance.save(uid, _draft);
  }

  void _scheduleDraft() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 700), _persistDraft);
  }

  Future<void> _discardDraft() async {
    HapticFeedback.mediumImpact();
    final uid = _uid;
    if (uid != null) await DiaryDraftService.instance.clear(uid);
    if (!mounted) return;
    setState(() {
      _mood = null;
      _textController.clear();
      _gratitudeController.clear();
      _showGratitude = false;
      _restoredDraft = false;
    });
  }

  bool get _canSave => _mood != null && _textController.text.trim().length >= _minChars;

  int get _words => _textController.text.trim().isEmpty
      ? 0
      : _textController.text.trim().split(RegExp(r'\s+')).length;

  String _moodLabel(MoodType mood) {
    final key = 'mood.${mood.name}';
    final translated = key.tr();
    return translated == key ? mood.label : translated;
  }

  void _selectMood(MoodType mood) {
    HapticFeedback.selectionClick();
    SoundService.instance.play(Sfx.toggleOn, volume: 0.45);
    setState(() => _mood = mood);
    _scheduleDraft();
  }

  void _shufflePrompt() {
    HapticFeedback.selectionClick();
    SoundService.instance.play(Sfx.pageTurn, volume: 0.45);
    final keys = DiaryPrompts.reflectionPromptKeys.where((k) => k != _promptKey).toList();
    setState(() => _promptKey = keys[_rng.nextInt(keys.length)]);
  }

  void _toggleGratitude() {
    HapticFeedback.lightImpact();
    SoundService.instance.play(_showGratitude ? Sfx.toggleOff : Sfx.pop, volume: 0.45);
    setState(() => _showGratitude = !_showGratitude);
    _scheduleDraft();
  }

  /// Tocar "Guardar" sin poder hacerlo: antes el botón simplemente no
  /// respondía y parecía que la app se había trabado. Ahora dice qué falta.
  void _explainWhatIsMissing() {
    HapticFeedback.lightImpact();
    SoundService.instance.play(Sfx.toggleOff, volume: 0.4);
    final message = _mood == null
        ? 'journal.needMood'.tr()
        : 'journal.needText'.tr();
    final s = JournalStyle.of(context);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Text(_mood == null ? '🎨' : '✍️', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: s.ink),
              ),
            ),
          ],
        ),
        backgroundColor: s.paper,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: s.paperEdge),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        duration: const Duration(seconds: 2),
      ));
  }

  Future<void> _save() async {
    if (!_canSave || _isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final auth = context.read<AuthProvider>();
    final gratitude = _gratitudeController.text.trim();
    final entry = DiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mood: _mood!,
      text: _textController.text.trim(),
      gratitude: _showGratitude && gratitude.isNotEmpty ? gratitude : null,
      prompt: _showGratitude && gratitude.isNotEmpty ? _gratitudePromptKey.tr() : null,
    );

    // Guardar ya no espera a nadie: Firestore escribe en disco al instante y
    // sincroniza solo (ver `queueWrite`). Esta pantalla **no puede** quedarse
    // colgada esperando, así que se lanza y se sigue.
    _saved = true;
    unawaited(_persist(auth, entry));

    AnalyticsService.instance.diaryEntrySaved();
    SoundService.instance.play(Sfx.journalSaved, volume: 0.7);
    HapticFeedback.heavyImpact();
    if (!mounted) return;

    // Y por si acaso: el aviso se cierra solo, pero nunca puede retener la
    // pantalla más de esto.
    await _SavedOverlay.show(
      context,
      mood: _mood!,
      withGratitude: entry.gratitude != null,
    ).timeout(const Duration(seconds: 4), onTimeout: () {});
    if (mounted) Navigator.pop(context, true);
  }

  /// Guarda de verdad, ya con la pantalla cerrándose.
  ///
  /// Si algo fallara, el borrador **no** se borra: la página sigue en el
  /// teléfono y aparece al volver a escribir.
  Future<void> _persist(AuthProvider auth, DiaryEntry entry) async {
    try {
      await auth.saveDiaryEntry(entry);
      final uid = _uid;
      if (uid != null) await DiaryDraftService.instance.clear(uid);
    } catch (e) {
      debugPrint('Error saving diary entry: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = JournalStyle.of(context);
    final now = DateTime.now();
    final l = context.locale;
    final date = DateFormat('EEEE d MMMM', l.languageCode).format(now);
    final accent = _mood?.color ?? JournalStyle.accent;

    return Scaffold(
      backgroundColor: Color.lerp(
        s.isDark ? const Color(0xFF12131F) : const Color(0xFFFBF6EC),
        accent,
        s.isDark ? 0.05 : 0.04,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Barra superior ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 16, 0),
              child: Row(
                children: [
                  MinTapTarget(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, color: s.inkSoft, semanticLabel: MaterialLocalizations.of(context).closeButtonTooltip),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      date[0].toUpperCase() + date.substring(1),
                      textAlign: TextAlign.center,
                      style: JournalStyle.hand(TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: s.ink)),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_restoredDraft) _buildDraftBanner(s),
                    // ── Lumi con la pregunta ─────────────────────────────────
                    LumiNote(
                      key: ValueKey(_promptKey),
                      text: _promptKey.tr(),
                      mood: JournalStyle.lumiFor(_mood),
                      trailing: Tooltip(
                        message: 'journal.otherQuestion'.tr(),
                        child: MinTapTarget(
                          onTap: _shufflePrompt,
                          child: Icon(Icons.casino_rounded, size: 22, color: accent, semanticLabel: 'journal.otherQuestion'.tr()),
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 18),
                    // ── Ánimo ─────────────────────────────────────────────────
                    Text(
                      'diary.moodLabel'.tr(),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: s.ink),
                    ),
                    const SizedBox(height: 10),
                    _buildMoodPicker(s),
                    const SizedBox(height: 20),
                    // ── La hoja ───────────────────────────────────────────────
                    _buildPage(s, accent),
                    // Deja sitio a la frase de ánimo que aparece bajo la hoja
                    SizedBox(height: _words >= 25 ? 36 : 18),
                    _buildGratitude(s),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 14, color: s.inkSoft),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'journal.privacyNote'.tr(),
                            style: TextStyle(fontSize: 12.5, height: 1.4, color: s.inkSoft),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildSaveBar(s, accent),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftBanner(JournalStyle s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        decoration: BoxDecoration(
          color: JournalStyle.accent.withValues(alpha: s.isDark ? 0.16 : 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: JournalStyle.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Text('💾', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'journal.draftRestored'.tr(),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.ink),
              ),
            ),
            TextButton(
              onPressed: _discardDraft,
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
              child: Text('journal.discardDraft'.tr()),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildMoodPicker(JournalStyle s) {
    return SizedBox(
      height: 92,
      child: ClipSideways(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: MoodType.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final mood = MoodType.values[i];
            final selected = _mood == mood;
            return Semantics(
              button: true,
              selected: selected,
              inMutuallyExclusiveGroup: true,
              label: _moodLabel(mood),
              onTap: () => _selectMood(mood),
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => _selectMood(mood),
                child: SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.12 : 1,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutBack,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? mood.color.withValues(alpha: s.isDark ? 0.3 : 0.2)
                                : (s.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                            border: Border.all(
                              color: selected ? mood.color : s.paperEdge,
                              width: selected ? 2.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(mood.emoji, style: TextStyle(fontSize: selected ? 30 : 26)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _moodLabel(mood),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                          color: selected
                              ? (s.isDark ? Color.lerp(mood.color, Colors.white, 0.3) : Color.lerp(mood.color, Colors.black, 0.25))
                              : s.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: (25 * i).ms, duration: 250.ms).slideX(begin: 0.2, end: 0);
          },
        ),
),
    );
  }

  Widget _buildPage(JournalStyle s, Color accent) {
    const fontSize = 17.0;
    const lineHeight = 1.75;
    const rule = fontSize * lineHeight;
    final words = _words;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        JournalPaper(
          tint: s.paperFor(_mood),
          lineHeight: rule,
          // Primer renglón alineado con la base de la primera línea de texto
          firstLine: 16 + rule,
          padding: const EdgeInsets.fromLTRB(24, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _textController,
                minLines: 8,
                maxLines: null,
                maxLength: 2000,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: accent,
                onChanged: (_) {
                  setState(() {});
                  _scheduleDraft();
                },
                style: JournalStyle.serif(TextStyle(fontSize: fontSize, height: lineHeight, color: s.ink)),
                decoration: InputDecoration(
                  hintText: 'journal.pageHint'.tr(),
                  hintStyle: JournalStyle.serif(TextStyle(fontSize: fontSize, height: lineHeight, color: s.inkSoft.withValues(alpha: 0.6))),
                  border: InputBorder.none,
                  counterText: '',
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.only(top: 6),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  words == 0 ? '' : 'journal.words'.plural(words),
                  key: ValueKey(words == 0),
                  style: JournalStyle.hand(TextStyle(fontSize: 17, color: s.inkSoft)),
                ),
              ),
            ],
          ),
        ),
        Positioned(top: -9, right: 26, child: WashiTape(color: accent, angle: 0.05)),
        if (words >= 25)
          Positioned(
            left: 0,
            right: 0,
            bottom: -26,
            child: Center(
              child: Text(
                'journal.encourage'.tr(),
                style: JournalStyle.hand(TextStyle(fontSize: 18, color: accent)),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),
            ),
          ),
      ],
    );
  }

  Widget _buildGratitude(JournalStyle s) {
    if (!_showGratitude) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Semantics(
          button: true,
          label: 'journal.addGratitude'.tr(),
          onTap: _toggleGratitude,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: _toggleGratitude,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: JournalStyle.sticky.withValues(alpha: s.isDark ? 0.08 : 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35), width: 1.3),
              ),
              child: Row(
                children: [
                  const Text('💛', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'journal.addGratitude'.tr(),
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: s.ink),
                    ),
                  ),
                  Text(
                    'diary.gratitudeXp'.tr(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final noteInk = s.isDark ? const Color(0xFFFEF3C7) : const Color(0xFF78350F);
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: StickyNote(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _gratitudePromptKey.tr(),
                    style: JournalStyle.hand(TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: noteInk)),
                  ),
                ),
                MinTapTarget(
                  onTap: _toggleGratitude,
                  child: Icon(Icons.close_rounded, size: 18, color: noteInk.withValues(alpha: 0.6), semanticLabel: 'journal.removeGratitude'.tr()),
                ),
              ],
            ),
            TextField(
              controller: _gratitudeController,
              minLines: 2,
              maxLines: null,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              cursorColor: const Color(0xFFD97706),
              onChanged: (_) => _scheduleDraft(),
              style: JournalStyle.serif(TextStyle(fontSize: 15.5, height: 1.6, color: noteInk)),
              decoration: InputDecoration(
                hintText: 'journal.gratitudeHint'.tr(),
                hintStyle: JournalStyle.serif(TextStyle(fontSize: 15.5, color: noteInk.withValues(alpha: 0.45))),
                border: InputBorder.none,
                counterText: '',
                isDense: true,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).scale(
            begin: const Offset(0.94, 0.94),
            end: const Offset(1, 1),
            curve: Curves.easeOutBack,
            duration: 350.ms,
          ),
    );
  }

  Widget _buildSaveBar(JournalStyle s, Color accent) {
    final enabled = _canSave && !_isSaving;
    final hint = _mood == null
        ? 'journal.needMood'.tr()
        : _textController.text.trim().length < _minChars
            ? 'journal.needText'.tr()
            : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: BoxDecoration(
        color: s.isDark ? const Color(0xFF12131F) : const Color(0xFFFBF6EC),
        border: Border(top: BorderSide(color: s.paperEdge)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hint != null) ...[
            Text(hint, style: TextStyle(fontSize: 12, color: s.inkSoft)),
            const SizedBox(height: 6),
          ],
          SizedBox(
            width: double.infinity,
            height: 54,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: enabled
                      ? [Color.lerp(accent, Colors.white, 0.15)!, Color.lerp(accent, Colors.black, 0.15)!]
                      : [accent.withValues(alpha: 0.3), accent.withValues(alpha: 0.3)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: enabled ? 0.35 : 0),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _isSaving
                      ? null
                      : (enabled ? _save : _explainWhatIsMissing),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bookmark_added_rounded, color: Colors.white.withValues(alpha: enabled ? 1 : 0.8)),
                              const SizedBox(width: 8),
                              Text(
                                'journal.saveToDiary'.tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: enabled ? 1 : 0.85),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Celebración breve al guardar: la página se cierra en un corazón y Lumi
/// agradece. Dura ~1.6 s (menos con movimiento reducido).
class _SavedOverlay extends StatelessWidget {
  final MoodType mood;
  final bool withGratitude;

  const _SavedOverlay({required this.mood, required this.withGratitude});

  static Future<void> show(BuildContext context, {required MoodType mood, required bool withGratitude}) {
    final reduced = MotionService.reduced(context);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: Duration(milliseconds: reduced ? 100 : 280),
      pageBuilder: (dialogContext, _, _) {
        // Se cierra sola, y cierra **su** ruta.
        //
        // Antes llamaba a `pop()` sobre el navegador a secas: si mientras
        // tanto se había abierto cualquier otra cosa encima —una celebración
        // de nivel, que el propio XP del diario puede disparar— ese `pop`
        // cerraba esa otra cosa y este aviso se quedaba abierto para siempre,
        // con el botón girando. De ahí el "se queda guardando y hay que salir
        // a la fuerza".
        Future.delayed(Duration(milliseconds: reduced ? 1100 : 1700), () {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        });
        return _SavedOverlay(mood: mood, withGratitude: withGratitude);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = JournalStyle.of(context);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 270,
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            color: s.paperFor(mood),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: s.paperEdge),
            boxShadow: s.paperShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SparkleBurst(color: mood.color, size: 130),
                    const Text('📖', style: TextStyle(fontSize: 56))
                        .animate()
                        .scale(begin: const Offset(0.4, 0.4), end: const Offset(1, 1), duration: 420.ms, curve: Curves.easeOutBack)
                        .then(delay: 150.ms)
                        .fadeOut(duration: 200.ms),
                    const Text('💚', style: TextStyle(fontSize: 58))
                        .animate(delay: 650.ms)
                        .fadeIn(duration: 200.ms)
                        .scale(begin: const Offset(0.3, 0.3), end: const Offset(1, 1), duration: 420.ms, curve: Curves.elasticOut),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'journal.savedTitle'.tr(),
                textAlign: TextAlign.center,
                style: JournalStyle.hand(TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: s.ink)),
              ),
              const SizedBox(height: 4),
              Text(
                withGratitude ? 'journal.savedXpGratitude'.tr() : 'journal.savedXp'.tr(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LumiAvatar(mood: mood.category == 'negative' ? LumiMood.caring : LumiMood.proud, size: 44),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      mood.category == 'negative' ? 'journal.lumiSavedHard'.tr() : 'journal.lumiSaved'.tr(),
                      style: TextStyle(fontSize: 12.5, height: 1.35, color: s.inkSoft),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
