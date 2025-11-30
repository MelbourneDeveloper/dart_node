import 'package:shared/models/user.dart';

/// In-memory user storage and operations
class UserService {
  final Map<String, User> _users = {};
  int _nextId = 1;

  /// Create a new user
  User create({
    required String email,
    required String password,
    required String name,
  }) {
    final id = 'user_${_nextId++}';
    final user = (
      id: id,
      email: email,
      passwordHash: _hashPassword(password),
      name: name,
      role: UserRole.member,
      createdAt: DateTime.now(),
      lastLoginAt: null,
    );
    _users[id] = user;
    return user;
  }

  /// Find user by ID
  User? findById(String id) => _users[id];

  /// Find user by email
  User? findByEmail(String email) {
    for (final user in _users.values) {
      if (user.email == email) return user;
    }
    return null;
  }

  /// Verify password
  bool verifyPassword(User user, String password) =>
      user.passwordHash == _hashPassword(password);

  /// Update last login time
  void updateLastLogin(String userId) {
    final user = _users[userId];
    if (user != null) {
      _users[userId] = user.copyWith(lastLoginAt: DateTime.now());
    }
  }

  /// Simple password "hash" (in production, use bcrypt!)
  String _hashPassword(String password) =>
      // This is NOT secure - just for demo purposes
      'hashed_$password';
}
