import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Los 12 estados de ánimo disponibles en Lumen.
/// Enhanced enum con toda la metadata directamente.
enum MoodType {
  // Positivos
  happy(emoji: '😊', label: 'Feliz', color: Color(0xFF10B981), category: 'positive'),
  excited(emoji: '🤩', label: 'Emocionado', color: Color(0xFFF59E0B), category: 'positive'),
  grateful(emoji: '🙏', label: 'Agradecido', color: Color(0xFF8B5CF6), category: 'positive'),
  calm(emoji: '😌', label: 'Tranquilo', color: Color(0xFF3B82F6), category: 'positive'),
  // Neutros
  neutral(emoji: '😐', label: 'Normal', color: Color(0xFF6B7280), category: 'neutral'),
  tired(emoji: '😴', label: 'Cansado', color: Color(0xFF9CA3AF), category: 'neutral'),
  bored(emoji: '🥱', label: 'Aburrido', color: Color(0xFFD1D5DB), category: 'neutral'),
  // Negativos
  sad(emoji: '😢', label: 'Triste', color: Color(0xFF6366F1), category: 'negative'),
  anxious(emoji: '😰', label: 'Ansioso', color: Color(0xFFEF4444), category: 'negative'),
  angry(emoji: '😤', label: 'Enojado', color: Color(0xFFDC2626), category: 'negative'),
  stressed(emoji: '😩', label: 'Estresado', color: Color(0xFFF97316), category: 'negative'),
  lonely(emoji: '🫥', label: 'Solo', color: Color(0xFF8B5CF6), category: 'negative');

  final String emoji;
  final String label;
  final Color color;
  final String category;

  const MoodType({
    required this.emoji,
    required this.label,
    required this.color,
    required this.category,
  });

  /// XP que otorga registrar este mood
  int get xpReward => 10;

  /// Convierte a string para Firestore
  String get key => name;

  /// Crea desde string de Firestore
  static MoodType fromKey(String key) {
    return MoodType.values.firstWhere(
      (e) => e.name == key,
      orElse: () => MoodType.neutral,
    );
  }
}

/// Mantener compatibilidad con código que use MoodTypeExtension.fromKey()
extension MoodTypeExtension on MoodType {
  static MoodType fromKey(String key) => MoodType.fromKey(key);
}

class MoodEntry {
  final String id;
  final MoodType mood;
  final int intensity; // 1-5
  final String? note;
  final DateTime timestamp;

  MoodEntry({
    required this.id,
    required this.mood,
    this.intensity = 3,
    this.note,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'mood': mood.key,
        'intensity': intensity,
        'note': note,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'] ?? '',
      mood: MoodTypeExtension.fromKey(map['mood'] ?? 'neutral'),
      intensity: map['intensity'] ?? 3,
      note: map['note'],
      timestamp: _parseDateTime(map['timestamp']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}