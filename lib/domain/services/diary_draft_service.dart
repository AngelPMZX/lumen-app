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

  Future<DiaryDraft?> load(String uid) async {
    try {
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

  Future<void> save(String uid, DiaryDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (draft.isEmpty) {
        await prefs.remove(_key(uid));
      } else {
        await prefs.setString(_key(uid), jsonEncode(draft.toJson()));
      }
    } catch (e) {
      debugPrint('DiaryDraftService save error: $e');
    }
  }

  Future<void> clear(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
    } catch (e) {
      debugPrint('DiaryDraftService clear error: $e');
    }
  }
}
