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
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
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