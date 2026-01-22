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
      debugPrint('🔋 Found existing session for: ${session.user.email}');
      await _loadUserProfile(session.user.id, session.user.email);
    }

    // Listen for auth state changes
    _supabase.auth.onAuthStateChange.listen((data) async {
      final sb.AuthChangeEvent event = data.event;
      final sb.Session? session = data.session;
      
      debugPrint('🔔 Auth State Change: $event (Session: ${session != null ? 'Yes' : 'No'})');

      if (event == sb.AuthChangeEvent.signedIn && session != null) {
        debugPrint('🆕 Sign In detected, loading profile...');
        await _loadUserProfile(session.user.id, session.user.email);
      } else if (event == sb.AuthChangeEvent.signedOut) {
        debugPrint('👋 Sign Out detected, clearing state');
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
    debugPrint('🔍 Loading profile for user: $userId');
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        debugPrint('✅ Profile found: ${response['name']} (${response['role']})');
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
      } else {
        debugPrint('⚠️ No profile found in "profiles" table for user ID: $userId');
        _error = 'User profile not found. Please contact support.';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
      _error = 'Error loading profile: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔐 Attempting login for: $email');
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      debugPrint('✅ Login successful for ID: ${response.user?.id}');
      
      // Explicitly load profile here to ensure it's loaded before we finish login
      if (response.user != null) {
        await _loadUserProfile(response.user!.id, response.user!.email);
      }
      
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

  // ==================== USER MANAGEMENT (Admin) ====================
  
  List<User> _allUsers = [];
  
  /// Get all users (for admin)
  List<User> get allUsers => List.unmodifiable(_allUsers);

  /// Fetch all users from database
  Future<void> fetchAllUsers() async {
    if (!isAdmin) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('📋 Fetching all users...');
      final response = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      _allUsers = data.map((json) {
        final roleStr = json['role'] as String? ?? 'participant';
        UserRole role;
        if (roleStr == 'admin') role = UserRole.admin;
        else if (roleStr == 'organizer') role = UserRole.organizer;
        else role = UserRole.participant;

        return User(
          id: json['id'],
          name: json['name'] ?? 'Unknown',
          email: json['email'] ?? '',
          password: '',
          role: role,
          createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
        );
      }).toList();

      debugPrint('✅ Loaded ${_allUsers.length} users');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetching users: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a user's role (admin only)
  Future<bool> updateUserRole(String userId, UserRole newRole) async {
    if (!isAdmin) return false;

    try {
      debugPrint('🔄 Updating role for user $userId to $newRole');
      
      String roleString = 'participant';
      if (newRole == UserRole.admin) roleString = 'admin';
      if (newRole == UserRole.organizer) roleString = 'organizer';

      await _supabase
          .from('profiles')
          .update({'role': roleString})
          .eq('id', userId);

      // Update local list
      final index = _allUsers.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _allUsers[index] = User(
          id: _allUsers[index].id,
          name: _allUsers[index].name,
          email: _allUsers[index].email,
          password: '',
          role: newRole,
          createdAt: _allUsers[index].createdAt,
        );
      }

      debugPrint('✅ Role updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating role: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a user (admin only)
  /// Note: This deletes the user from the 'profiles' table and all associated data.
  /// It does NOT delete the user from Supabase Auth (auth.users) as that requires 
  /// the Service Role key, which should never be exposed in a client app.
  Future<bool> deleteUser(String userId) async {
    if (!isAdmin) return false;
    if (userId == _currentUser?.id) {
      _error = 'Cannot delete your own account';
      notifyListeners();
      return false;
    }

    try {
      debugPrint('🗑️ [Admin] Starting deletion for user: $userId');
      
      // 1. Handle Organizer Data (Events and their related records)
      final eventResponse = await _supabase
          .from('events')
          .select('id')
          .eq('organizer_id', userId);
      
      final List<dynamic> eventData = eventResponse;
      final List<String> eventIds = eventData.map((e) => e['id'] as String).toList();

      if (eventIds.isNotEmpty) {
        debugPrint('   - Found ${eventIds.length} events owned by this user. Deleting associated records...');
        
        // Delete in order to respect FK constraints
        await _supabase.from('registrations').delete().inFilter('event_id', eventIds);
        await _supabase.from('tickets').delete().inFilter('event_id', eventIds);
        await _supabase.from('event_ticket_configs').delete().inFilter('event_id', eventIds);
        await _supabase.from('sessions').delete().inFilter('event_id', eventIds);
        
        // Delete events
        final deleteEventsRes = await _supabase.from('events').delete().eq('organizer_id', userId).select();
        debugPrint('   - Deleted ${deleteEventsRes.length} events');
      }

      // 2. Handle Participant Data (User's own registrations/tickets)
      debugPrint('   - Deleting user\'s own registrations and tickets...');
      final delRegRes = await _supabase.from('registrations').delete().eq('user_id', userId).select();
      final delTickRes = await _supabase.from('tickets').delete().eq('user_id', userId).select();
      debugPrint('   - Deleted ${delRegRes.length} registrations and ${delTickRes.length} tickets');

      // 3. Delete Profile
      debugPrint('   - Deleting user profile from public.profiles...');
      final profileDelRes = await _supabase.from('profiles').delete().eq('id', userId).select();
      
      if (profileDelRes.isEmpty) {
        debugPrint('   ⚠️ No profile found to delete or RLS blocked deletion');
        // We still continue to local cleanup just in case
      } else {
        debugPrint('   ✅ Profile deleted successfully');
      }

      // 4. Update Local State
      _allUsers.removeWhere((u) => u.id == userId);
      debugPrint('✅ [Admin] Local state updated. User $userId removed.');
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ [Admin] Error during user deletion: $e');
      _error = 'Failed to delete user: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }
}
