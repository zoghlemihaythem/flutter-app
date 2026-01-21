import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

/// Authentication provider managing user login, logout, and session state
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Authentication provider managing user login, logout, and session state
class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  final _supabase = sb.Supabase.instance.client;

  AuthProvider() {
    debugPrint('🔌 Supabase Config Check:');
    // detailed logging removed to avoid compilation error
    _init();
  }

  // Restore session
  Future<void> _init() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _loadUserProfile(session.user.id, session.user.email);
    }

    // Listen for auth state changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final sb.AuthChangeEvent event = data.event;
      final sb.Session? session = data.session;

      if (event == sb.AuthChangeEvent.signedIn && session != null) {
        await _loadUserProfile(session.user.id, session.user.email);
      } else if (event == sb.AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Role-based access helpers
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isOrganizer => _currentUser?.role == UserRole.organizer;
  bool get isParticipant => _currentUser?.role == UserRole.participant;
  bool get canManageEvents => isAdmin || isOrganizer;
  bool get canManageUsers => isAdmin;

  /// Load user profile from 'profiles' table
  Future<void> _loadUserProfile(String userId, String? email) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final roleStr = response['role'] as String? ?? 'participant';
        UserRole role;
        if (roleStr == 'admin') role = UserRole.admin;
        else if (roleStr == 'organizer') role = UserRole.organizer;
        else role = UserRole.participant;

        _currentUser = User(
          id: userId,
          name: response['name'] ?? 'User',
          email: email ?? '',
          password: '', // Not stored locally
          role: role,
          createdAt: DateTime.parse(response['created_at']),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔐 Attempting login for: $email');
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      debugPrint('✅ Login successful');
      // onAuthStateChange will handle setting _currentUser
      _isLoading = false;
      notifyListeners();
      return true;
    } on sb.AuthException catch (e) {
      debugPrint('❌ Login error: ${e.message} (code: ${e.statusCode})');
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected login error: $e');
      _error = e.toString();
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

    try {
      // 1. Sign up auth user
      debugPrint('👤 Attempting registration for: $email with role: $role');
      
      // Profile will be created automatically via database trigger (handle_new_user)
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.toString().split('.').last,
        },
      );

      debugPrint('✅ Registration call completed. User ID: ${authResponse.user?.id}');

      if (authResponse.user == null) {
        debugPrint('❌ Registration failed: User in response is null');
        throw Exception('Registration failed');
      }

      // Wait briefly for the database trigger to create the profile
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify profile was created by the database trigger
      try {
        final profile = await _supabase
            .from('profiles')
            .select()
            .eq('id', authResponse.user!.id)
            .maybeSingle();
        
        if (profile != null) {
          debugPrint('✅ Profile created by database trigger');
        } else {
          debugPrint('⚠️ Profile not found - database trigger may not be set up');
        }
      } catch (e) {
        debugPrint('⚠️ Could not verify profile: $e');
      }

      // 3. Set local state immediately for better UX
      _currentUser = User(
        id: authResponse.user!.id,
        name: name,
        email: email,
        password: '',
        role: role,
        createdAt: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on sb.AuthException catch (e) {
      debugPrint('❌ Auth error: ${e.message} (code: ${e.statusCode})');
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
