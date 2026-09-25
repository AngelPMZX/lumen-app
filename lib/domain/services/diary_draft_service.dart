import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/mood_entry.dart';

/// Borrador de una entrada del diario.
class DiaryDraft {
  final MoodType? mood;
  final String text;
  final String gratitude;
  final bool showGratitude;

  const DiaryDraft({
    this.mood,
    this.text = '',
    this.gratitude = '',
    this.showGratitude = false,
  });

  bool get isEmpty => mood == null && text.trim().isEmpty && gratitude.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'mood': mood?.key,
        'text': text,
        'gratitude': gratitude,
        'showGratitude': showGratitude,
      };

  factory DiaryDraft.fromJson(Map<String, dynamic> json) => DiaryDraft(
        mood: json['mood'] == null ? null : MoodTypeExtension.fromKey(json['mood'] as String),
        text: json['text'] as String? ?? '',
        gratitude: json['gratitude'] as String? ?? '',
        showGratitude: json['showGratitude'] as bool? ?? false,
      );
}

/// Guarda el borrador del diario **solo en el teléfono** (SharedPreferences,
/// por usuario) para no perder lo escrito si se cierra la pantalla o la app.
/// Nunca se sube a Firestore hasta que el usuario guarda la entrada.
class DiaryDraftService {
  DiaryDraftService._();
  static final DiaryDraftService instance = DiaryDraftService._();

  static String _key(String uid) => 'diary_draft_$uid';

  /// Las escrituras se hacen en fila.
  ///
  /// Guardar y borrar son asíncronos, así que un borrador que ya estaba
  /// guardándose podía escribirse **después** de borrarlo al guardar la
  /// página: el borrador reaparecía y guardarlo otra vez creaba una copia.
  Future<void> _queue = Future.value();

  Future<void> _enqueue(
      Future<void> Function(SharedPreferences prefs) op, String what) {
    final next = _queue.then((_) async {
      try {
        await op(await SharedPreferences.getInstance());
      } catch (e) {
        debugPrint('DiaryDraftService $what error: $e');
      }
    });
    _queue = next;
    return next;
  }

  Future<DiaryDraft?> load(String uid) async {
    try {
      // Detrás de lo que esté escribiéndose: abrir la pantalla justo después
      // de guardar una página no puede leer el borrador que se está borrando.
      await _queue;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(uid));
      if (raw == null) return null;
      final draft = DiaryDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return draft.isEmpty ? null : draft;
    } catch (e) {
      debugPrint('DiaryDraftService load error: $e');
      return null;
    }
  }

  Future<void> save(String uid, DiaryDraft draft) => _enqueue((prefs) async {
        if (draft.isEmpty) {
          await prefs.remove(_key(uid));
        } else {
          await prefs.setString(_key(uid), jsonEncode(draft.toJson()));
        }
      }, 'save');

  Future<void> clear(String uid) =>
      _enqueue((prefs) => prefs.remove(_key(uid)), 'clear');
}
