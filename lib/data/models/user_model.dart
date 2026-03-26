import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String? username;
  final String email;
  final int? age;
  final String? gender;
  final List<String> hobbies;
  final List<String> musicGenres;
  final String? archetype;
  final bool profileComplete;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    this.username,
    required this.email,
    this.age,
    this.gender,
    this.hobbies = const [],
    this.musicGenres = const [],
    this.archetype,
    this.profileComplete = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Para CREAR un documento nuevo en Firestore (.set())
  /// Usa FieldValue.serverTimestamp() para que el servidor ponga la hora
  Map<String, dynamic> toFirestoreMap() => {
        'uid': uid,
        'name': name,
        'username': username,
        'email': email,
        'age': age,
        'gender': gender,
        'hobbies': hobbies,
        'musicGenres': musicGenres,
        'archetype': archetype,
        'profileComplete': profileComplete,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Para uso LOCAL (no Firestore) — serializa createdAt como ISO string
  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'username': username,
        'email': email,
        'age': age,
        'gender': gender,
        'hobbies': hobbies,
        'musicGenres': musicGenres,
        'archetype': archetype,
        'profileComplete': profileComplete,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      username: map['username'],
      email: map['email'] ?? '',
      age: map['age'],
      gender: map['gender'],
      hobbies: List<String>.from(map['hobbies'] ?? []),
      musicGenres: List<String>.from(map['musicGenres'] ?? []),
      archetype: map['archetype'],
      profileComplete: map['profileComplete'] ?? false,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  /// Parsea fechas que pueden venir como Timestamp de Firestore o String ISO
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  UserModel copyWith({
    String? name,
    String? username,
    int? age,
    String? gender,
    List<String>? hobbies,
    List<String>? musicGenres,
    String? archetype,
    bool? profileComplete,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      hobbies: hobbies ?? this.hobbies,
      musicGenres: musicGenres ?? this.musicGenres,
      archetype: archetype ?? this.archetype,
      profileComplete: profileComplete ?? this.profileComplete,
      createdAt: createdAt,
    );
  }
}