import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Modelo de un recordatorio programable.
class Reminder {
  final String id;
  final String title;
  final String? message;
  final TimeOfDay time;
  final List<int> repeatDays;
  final bool isEnabled;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.title,
    this.message,
    required this.time,
    this.repeatDays = const [],
    this.isEnabled = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Minutos desde medianoche — para ordenar en Firestore con un solo campo
  int get timeInMinutes => time.hour * 60 + time.minute;

  String get repeatLabel {
    if (repeatDays.isEmpty) return 'reminders.once'.tr();
    if (repeatDays.length == 7) return 'reminders.everyday'.tr();
    final weekdays = [1, 2, 3, 4, 5];
    final weekend = [6, 7];
    if (repeatDays.length == 5 &&
        weekdays.every((d) => repeatDays.contains(d))) {
      return 'reminders.mondayToFriday'.tr();
    }
    if (repeatDays.length == 2 &&
        weekend.every((d) => repeatDays.contains(d))) {
      return 'reminders.weekendsLabel'.tr();
    }
    final dayKeys = {
      1: 'days.monShort',
      2: 'days.tueShort',
      3: 'days.wedShort',
      4: 'days.thuShort',
      5: 'days.friShort',
      6: 'days.satShort',
      7: 'days.sunShort',
    };
    final sorted = List<int>.from(repeatDays)..sort();
    return sorted.map((d) => (dayKeys[d] ?? '').tr()).join(', ');
  }

  String get timeLabel {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  IconData get timeIcon {
    if (time.hour < 12) return Icons.wb_sunny_rounded;
    if (time.hour < 18) return Icons.wb_twilight_rounded;
    return Icons.nightlight_round;
  }

  Color get timeColor {
    if (time.hour < 12) return const Color(0xFFF59E0B);
    if (time.hour < 18) return const Color(0xFFF97316);
    return const Color(0xFF6366F1);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'message': message,
        'hour': time.hour,
        'minute': time.minute,
        'timeInMinutes': timeInMinutes,
        'repeatDays': repeatDays,
        'isEnabled': isEnabled,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'],
      time: TimeOfDay(
        hour: map['hour'] ?? 9,
        minute: map['minute'] ?? 0,
      ),
      repeatDays: List<int>.from(map['repeatDays'] ?? []),
      isEnabled: map['isEnabled'] ?? true,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Reminder copyWith({
    String? title,
    String? message,
    TimeOfDay? time,
    List<int>? repeatDays,
    bool? isEnabled,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      repeatDays: repeatDays ?? this.repeatDays,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}