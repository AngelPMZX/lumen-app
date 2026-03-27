import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Modelo de un hábito rastreable con check-in diario.
class Habit {
  final String id;
  final String title;
  final String? description;
  final String emoji;
  final Color color;
  final List<int> activeDays; // 1=Lun..7=Dom. Vacío = todos los días
  final bool isEnabled;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.title,
    this.description,
    required this.emoji,
    required this.color,
    this.activeDays = const [],
    this.isEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'emoji': emoji,
        'colorValue': color.value,
        'activeDays': activeDays,
        'isEnabled': isEnabled,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      emoji: map['emoji'] ?? '✅',
      color: Color(map['colorValue'] ?? 0xFF6366F1),
      activeDays: List<int>.from(map['activeDays'] ?? []),
      isEnabled: map['isEnabled'] ?? true,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Hábitos predeterminados que se sugieren al usuario
  static List<Habit> get presets => [
        Habit(
          id: 'preset_exercise',
          title: 'Hacer ejercicio',
          description: '30 min de actividad física',
          emoji: '💪',
          color: const Color(0xFFEF4444),
        ),
        Habit(
          id: 'preset_water',
          title: 'Tomar 2L de agua',
          description: 'Hidrátate durante el día',
          emoji: '💧',
          color: const Color(0xFF3B82F6),
        ),
        Habit(
          id: 'preset_diary',
          title: 'Escribir en el diario',
          description: 'Reflexiona sobre tu día',
          emoji: '📝',
          color: const Color(0xFF10B981),
        ),
        Habit(
          id: 'preset_meditate',
          title: 'Meditar 5 minutos',
          description: 'Un momento de calma',
          emoji: '🧘',
          color: const Color(0xFF8B5CF6),
        ),
        Habit(
          id: 'preset_read',
          title: 'Leer 15 minutos',
          description: 'Alimenta tu mente',
          emoji: '📖',
          color: const Color(0xFFF59E0B),
        ),
        Habit(
          id: 'preset_sleep',
          title: 'Dormir 8 horas',
          description: 'Descansa bien',
          emoji: '😴',
          color: const Color(0xFF6366F1),
        ),
        Habit(
          id: 'preset_no_social',
          title: 'Sin redes 1 hora',
          description: 'Desconéctate un rato',
          emoji: '📵',
          color: const Color(0xFFF97316),
        ),
        Habit(
          id: 'preset_gratitude',
          title: 'Practicar gratitud',
          description: '3 cosas que agradeces',
          emoji: '🙏',
          color: const Color(0xFFEC4899),
        ),
      ];
}

/// Registro de check-in de un hábito en un día específico
class HabitCheckIn {
  final String habitId;
  final DateTime date;
  final bool completed;

  HabitCheckIn({
    required this.habitId,
    required this.date,
    this.completed = true,
  });

  Map<String, dynamic> toMap() => {
        'habitId': habitId,
        'date': Timestamp.fromDate(date),
        'completed': completed,
      };

  factory HabitCheckIn.fromMap(Map<String, dynamic> map) {
    return HabitCheckIn(
      habitId: map['habitId'] ?? '',
      date: Habit._parseDateTime(map['date']),
      completed: map['completed'] ?? true,
    );
  }

  /// ID del documento en Firestore: habitId_YYYY-MM-DD
  String get docId {
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${habitId}_$d';
  }
}