import 'package:equatable/equatable.dart';

/// User model representing authenticated user
class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final DateTime createdAt;
  final UserPreferences preferences;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    required this.createdAt,
    required this.preferences,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>)
          : const UserPreferences(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'preferences': preferences.toJson(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatar,
    DateTime? createdAt,
    UserPreferences? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  List<Object?> get props => [id, email, name, avatar, createdAt, preferences];
}

/// User preferences
class UserPreferences extends Equatable {
  final String theme;
  final bool notificationsEnabled;
  final String language;

  const UserPreferences({
    this.theme = 'dark',
    this.notificationsEnabled = true,
    this.language = 'en',
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] as String? ?? 'dark',
      notificationsEnabled: json['notifications'] as bool? ?? true,
      language: json['language'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'notifications': notificationsEnabled,
      'language': language,
    };
  }

  UserPreferences copyWith({
    String? theme,
    bool? notificationsEnabled,
    String? language,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
    );
  }

  @override
  List<Object?> get props => [theme, notificationsEnabled, language];
}