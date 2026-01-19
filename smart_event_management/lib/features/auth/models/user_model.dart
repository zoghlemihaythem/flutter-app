/// User roles in the Smart Event Management System
enum UserRole { admin, organizer, participant }

/// User model representing authenticated users
class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    UserRole? role,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get display name for the role
  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.organizer:
        return 'Event Organizer';
      case UserRole.participant:
        return 'Participant';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
