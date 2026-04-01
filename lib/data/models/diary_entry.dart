import 'package:cloud_firestore/cloud_firestore.dart';
import 'mood_entry.dart';

/// Modelo para una entrada del diario emocional.
/// Cada entrada tiene un mood asociado, texto libre y opcionalmente
/// respuestas a prompts de gratitud.
class DiaryEntry {
  final String id;
  final MoodType mood;
  final String text;
  final String? gratitude; // Respuesta al prompt de gratitud
  final String? prompt; // El prompt que se mostró
  final DateTime createdAt;

  DiaryEntry({
    required this.id,
    required this.mood,
    required this.text,
    this.gratitude,
    this.prompt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'mood': mood.key,
        'text': text,
        'gratitude': gratitude,
        'prompt': prompt,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] ?? '',
      mood: MoodTypeExtension.fromKey(map['mood'] ?? 'neutral'),
      text: map['text'] ?? '',
      gratitude: map['gratitude'],
      prompt: map['prompt'],
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}

/// Prompts de gratitud y reflexión que se muestran aleatoriamente
class DiaryPrompts {
  static const List<String> gratitudePrompts = [
    '¿Qué 3 cosas agradeces hoy?',
    '¿Quién te hizo sonreír hoy?',
    '¿Qué momento de hoy quieres recordar?',
    '¿Qué aprendiste hoy sobre ti mismo?',
    '¿Qué te dio paz hoy?',
    '¿Por qué pequeña cosa estás agradecido?',
    '¿Qué fortaleza usaste hoy?',
    '¿Qué harías diferente mañana?',
    '¿Cuál fue tu mayor logro de hoy?',
    '¿Qué persona impactó positivamente tu día?',
  ];

  static const List<String> reflectionPrompts = [
    '¿Cómo te sentiste al despertar vs ahora?',
    '¿Qué emoción dominó tu día?',
    '¿Hubo algo que te costó manejar?',
    '¿Qué necesitas soltar antes de dormir?',
    '¿Te diste permiso de descansar hoy?',
    '¿Qué límite estableciste hoy?',
    '¿Algo te sorprendió emocionalmente?',
    '¿Cómo cuidaste tu bienestar hoy?',
    '¿Qué te gustaría decirle a tu yo de mañana?',
    '¿Qué patrón emocional notas esta semana?',
  ];

  static const List<String> gratitudePromptKeys = [
    'diary.prompts.gratitude.0',
    'diary.prompts.gratitude.1',
    'diary.prompts.gratitude.2',
    'diary.prompts.gratitude.3',
    'diary.prompts.gratitude.4',
    'diary.prompts.gratitude.5',
    'diary.prompts.gratitude.6',
    'diary.prompts.gratitude.7',
    'diary.prompts.gratitude.8',
    'diary.prompts.gratitude.9',
  ];

  static const List<String> reflectionPromptKeys = [
    'diary.prompts.reflection.0',
    'diary.prompts.reflection.1',
    'diary.prompts.reflection.2',
    'diary.prompts.reflection.3',
    'diary.prompts.reflection.4',
    'diary.prompts.reflection.5',
    'diary.prompts.reflection.6',
    'diary.prompts.reflection.7',
    'diary.prompts.reflection.8',
    'diary.prompts.reflection.9',
  ];

  /// Obtiene un prompt aleatorio basado en el día
  static String getRandomGratitudePrompt() {
    final index = DateTime.now().day % gratitudePrompts.length;
    return gratitudePrompts[index];
  }

  static String getRandomReflectionPrompt() {
    final index = (DateTime.now().day + 5) % reflectionPrompts.length;
    return reflectionPrompts[index];
  }

  static String getRandomGratitudePromptKey() {
    final index = DateTime.now().day % gratitudePromptKeys.length;
    return gratitudePromptKeys[index];
  }

  static String getRandomReflectionPromptKey() {
    final index = (DateTime.now().day + 5) % reflectionPromptKeys.length;
    return reflectionPromptKeys[index];
  }
}