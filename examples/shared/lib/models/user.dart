/// User roles with associated permissions
enum UserRole {
  admin(canManageUsers: true, canDeleteAnyTask: true),
  member(canManageUsers: false, canDeleteAnyTask: false);

  const UserRole({
    required this.canManageUsers,
    required this.canDeleteAnyTask,
  });

  final bool canManageUsers;
  final bool canDeleteAnyTask;
}

/// User entity - immutable record
typedef User = ({
  String id,
  String email,
  String passwordHash,
  String name,
  UserRole role,
  DateTime createdAt,
  DateTime? lastLoginAt,
});

extension UserExtension on User {
  User copyWith({
    String? email,
    String? passwordHash,
    String? name,
    UserRole? role,
    DateTime? lastLoginAt,
  }) => (
    id: id,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    name: name ?? this.name,
    role: role ?? this.role,
    createdAt: createdAt,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role.name,
    'createdAt': createdAt.toIso8601String(),
    ...lastLoginAt != null
        ? {'lastLoginAt': lastLoginAt?.toIso8601String()}
        : <String, dynamic>{},
  };
}

/// Data for user registration
typedef CreateUserData = ({String email, String password, String name});

/// Data for login
typedef LoginData = ({String email, String password});

/// Decoded token payload
typedef TokenPayload = ({String userId, DateTime issuedAt, DateTime expiresAt});
