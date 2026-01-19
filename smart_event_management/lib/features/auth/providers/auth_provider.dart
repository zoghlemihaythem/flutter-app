import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

/// Authentication provider managing user login, logout, and session state
class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Mock users for authentication
  final List<User> _mockUsers = [
    User(
      id: 'admin-001',
      name: 'Admin User',
      email: 'admin@example.com',
      password: 'admin123',
      role: UserRole.admin,
      createdAt: DateTime(2024, 1, 1),
    ),
    User(
      id: 'organizer-001',
      name: 'John Organizer',
      email: 'organizer@example.com',
      password: 'organizer123',
      role: UserRole.organizer,
      createdAt: DateTime(2024, 1, 15),
    ),
    User(
      id: 'organizer-002',
      name: 'Sarah Events',
      email: 'sarah@example.com',
      password: 'sarah123',
      role: UserRole.organizer,
      createdAt: DateTime(2024, 2, 1),
    ),
    User(
      id: 'participant-001',
      name: 'Alice Participant',
      email: 'alice@example.com',
      password: 'alice123',
      role: UserRole.participant,
      createdAt: DateTime(2024, 2, 10),
    ),
    User(
      id: 'participant-002',
      name: 'Bob Attendee',
      email: 'bob@example.com',
      password: 'bob123',
      role: UserRole.participant,
      createdAt: DateTime(2024, 2, 15),
    ),
    User(
      id: 'participant-003',
      name: 'Charlie Guest',
      email: 'charlie@example.com',
      password: 'charlie123',
      role: UserRole.participant,
      createdAt: DateTime(2024, 3, 1),
    ),
  ];

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<User> get allUsers => List.unmodifiable(_mockUsers);

  // Role-based access helpers
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isOrganizer => _currentUser?.role == UserRole.organizer;
  bool get isParticipant => _currentUser?.role == UserRole.participant;
  bool get canManageEvents => isAdmin || isOrganizer;
  bool get canManageUsers => isAdmin;

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final user = _mockUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase() && u.password == password,
        orElse: () => throw Exception('Invalid email or password'),
      );

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // Check if email already exists
      final exists = _mockUsers.any(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      if (exists) {
        throw Exception('Email already registered');
      }

      final newUser = User(
        id: const Uuid().v4(),
        name: name,
        email: email,
        password: password,
        role: role,
        createdAt: DateTime.now(),
      );

      _mockUsers.add(newUser);
      _currentUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout current user
  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get user by ID
  User? getUserById(String id) {
    try {
      return _mockUsers.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all users by role
  List<User> getUsersByRole(UserRole role) {
    return _mockUsers.where((u) => u.role == role).toList();
  }
}
