import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/registration_model.dart';

/// Registration provider managing event registrations and check-ins
class RegistrationProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  final _supabase = sb.Supabase.instance.client;

  List<Registration> _registrations = [];

  // Getters
  List<Registration> get registrations => List.unmodifiable(_registrations);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch registrations for a specific user
  Future<void> fetchUserRegistrations(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('registrations')
          .select('*, events(title, date)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      final List<dynamic> data = response;
      _registrations = data.map((json) => Registration(
        id: json['id'],
        eventId: json['event_id'],
        userId: json['user_id'],
        userName: json['user_name'] ?? 'User',
        userEmail: json['user_email'] ?? '',
        status: _parseCheckInStatus(json['status']),
        registeredAt: DateTime.parse(json['created_at']),
        checkedInAt: json['checked_in_at'] != null 
            ? DateTime.parse(json['checked_in_at']) 
            : null,
      )).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching registrations: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register user for an event
  Future<Registration?> registerForEvent({
    required String eventId,
    required String userId,
    required String userName,
    required String userEmail,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if already registered (double check on client side)
      if (isUserRegistered(userId, eventId)) {
        throw Exception('Already registered for this event');
      }

      final response = await _supabase.from('registrations').insert({
        'event_id': eventId,
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'status': 'registered',
      }).select().single();

      final registration = Registration(
        id: response['id'],
        eventId: eventId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        status: CheckInStatus.registered,
        registeredAt: DateTime.parse(response['created_at']),
      );

      _registrations.insert(0, registration);
      _isLoading = false;
      notifyListeners();
      return registration;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Cancel registration
  Future<bool> cancelRegistration(String registrationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('registrations').delete().eq('id', registrationId);
      _registrations.removeWhere((r) => r.id == registrationId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check in a participant
  Future<bool> checkIn(String registrationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now().toIso8601String();
      await _supabase.from('registrations').update({
        'status': 'checked_in',
        'checked_in_at': now,
      }).eq('id', registrationId);

      final index = _registrations.indexWhere((r) => r.id == registrationId);
      if (index != -1) {
        _registrations[index] = _registrations[index].copyWith(
          status: CheckInStatus.checkedIn,
          checkedInAt: DateTime.parse(now),
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Undo check-in (set status back to registered)
  Future<bool> undoCheckIn(String registrationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('registrations').update({
        'status': 'registered',
        'checked_in_at': null,
      }).eq('id', registrationId);

      final index = _registrations.indexWhere((r) => r.id == registrationId);
      if (index != -1) {
        _registrations[index] = Registration(
          id: _registrations[index].id,
          eventId: _registrations[index].eventId,
          userId: _registrations[index].userId,
          userName: _registrations[index].userName,
          userEmail: _registrations[index].userEmail,
          status: CheckInStatus.registered,
          registeredAt: _registrations[index].registeredAt,
          checkedInAt: null,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Helpers & Sync Methods ---

  /// Get check-in count for an event
  int getCheckedInCount(String eventId) {
    return _registrations
        .where((r) => r.eventId == eventId && r.status == CheckInStatus.checkedIn)
        .length;
  }

  /// Get a specific registration
  Registration? getRegistration(String userId, String eventId) {
    try {
      return _registrations.firstWhere(
        (r) => r.userId == userId && r.eventId == eventId,
      );
    } catch (_) {
      return null;
    }
  }

  CheckInStatus _parseCheckInStatus(String status) {
    return CheckInStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => CheckInStatus.registered,
    );
  }

  List<Registration> getRegistrationsByEvent(String eventId) {
    return _registrations.where((r) => r.eventId == eventId).toList();
  }

  List<Registration> getRegistrationsByUser(String userId) {
    return _registrations.where((r) => r.userId == userId).toList();
  }

  int getRegistrationCount(String eventId) {
    return _registrations.where((r) => r.eventId == eventId).length;
  }

  bool isUserRegistered(String userId, String eventId) {
    return _registrations.any((r) => r.userId == userId && r.eventId == eventId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
