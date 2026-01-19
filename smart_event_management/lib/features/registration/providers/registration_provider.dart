import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/registration_model.dart';

/// Registration provider managing event registrations and check-ins
class RegistrationProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  // Mock registrations data
  final List<Registration> _registrations = [
    Registration(
      id: 'reg-001',
      eventId: 'event-001',
      userId: 'participant-001',
      userName: 'Alice Participant',
      userEmail: 'alice@example.com',
      status: CheckInStatus.registered,
      registeredAt: DateTime(2025, 12, 1),
    ),
    Registration(
      id: 'reg-002',
      eventId: 'event-001',
      userId: 'participant-002',
      userName: 'Bob Attendee',
      userEmail: 'bob@example.com',
      status: CheckInStatus.checkedIn,
      registeredAt: DateTime(2025, 12, 5),
      checkedInAt: DateTime(2026, 2, 15, 8, 45),
    ),
    Registration(
      id: 'reg-003',
      eventId: 'event-002',
      userId: 'participant-001',
      userName: 'Alice Participant',
      userEmail: 'alice@example.com',
      status: CheckInStatus.registered,
      registeredAt: DateTime(2025, 12, 10),
    ),
    Registration(
      id: 'reg-004',
      eventId: 'event-003',
      userId: 'participant-003',
      userName: 'Charlie Guest',
      userEmail: 'charlie@example.com',
      status: CheckInStatus.registered,
      registeredAt: DateTime(2025, 12, 20),
    ),
  ];

  // Getters
  List<Registration> get registrations => List.unmodifiable(_registrations);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get registrations for a specific event
  List<Registration> getRegistrationsByEvent(String eventId) {
    return _registrations.where((r) => r.eventId == eventId).toList();
  }

  /// Get registrations for a specific user
  List<Registration> getRegistrationsByUser(String userId) {
    return _registrations.where((r) => r.userId == userId).toList();
  }

  /// Get registration count for an event
  int getRegistrationCount(String eventId) {
    return _registrations.where((r) => r.eventId == eventId).length;
  }

  /// Get check-in count for an event
  int getCheckedInCount(String eventId) {
    return _registrations
        .where((r) => r.eventId == eventId && r.status == CheckInStatus.checkedIn)
        .length;
  }

  /// Check if user is registered for an event
  bool isUserRegistered(String userId, String eventId) {
    return _registrations.any((r) => r.userId == userId && r.eventId == eventId);
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

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      // Check if already registered
      if (isUserRegistered(userId, eventId)) {
        throw Exception('Already registered for this event');
      }

      final registration = Registration(
        id: const Uuid().v4(),
        eventId: eventId,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        status: CheckInStatus.registered,
        registeredAt: DateTime.now(),
      );

      _registrations.add(registration);
      _isLoading = false;
      notifyListeners();
      return registration;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
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

    await Future.delayed(const Duration(milliseconds: 500));

    try {
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

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final index = _registrations.indexWhere((r) => r.id == registrationId);
      if (index == -1) {
        throw Exception('Registration not found');
      }

      _registrations[index] = _registrations[index].copyWith(
        status: CheckInStatus.checkedIn,
        checkedInAt: DateTime.now(),
      );

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

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final index = _registrations.indexWhere((r) => r.id == registrationId);
      if (index == -1) {
        throw Exception('Registration not found');
      }

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

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
