class UserModel {
  final String uid;
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final List<String> hobbies;
  final List<String> musicGenres;
  final String? archetype;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.age,
    this.gender,
    this.hobbies = const [],
    this.musicGenres = const [],
    this.archetype,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'age': age,
        'gender': gender,
        'hobbies': hobbies,
        'musicGenres': musicGenres,
        'archetype': archetype,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age'],
      gender: map['gender'],
      hobbies: List<String>.from(map['hobbies'] ?? []),
      musicGenres: List<String>.from(map['musicGenres'] ?? []),
      archetype: map['archetype'],
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  UserModel copyWith({
    String? name,
    int? age,
    String? gender,
    List<String>? hobbies,
    List<String>? musicGenres,
    String? archetype,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      hobbies: hobbies ?? this.hobbies,
      musicGenres: musicGenres ?? this.musicGenres,
      archetype: archetype ?? this.archetype,
      createdAt: createdAt,
    );
  }
}