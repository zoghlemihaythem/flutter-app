import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/session_model.dart';

/// Schedule provider managing event sessions and agenda
class ScheduleProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  // Mock sessions data
  final List<Session> _sessions = [
    // Tech Conference 2026 sessions (event-001)
    Session(
      id: 'session-001',
      eventId: 'event-001',
      title: 'Opening Keynote: The Future of Technology',
      description: 'Welcome address and overview of emerging technology trends that will shape the next decade.',
      startTime: DateTime(2026, 2, 15, 9, 0),
      endTime: DateTime(2026, 2, 15, 10, 0),
      speaker: 'Dr. Jane Smith',
      speakerBio: 'CEO of TechVision, former VP at Google',
      location: 'Main Hall',
    ),
    Session(
      id: 'session-002',
      eventId: 'event-001',
      title: 'AI in Practice: Real-world Applications',
      description: 'Deep dive into how companies are implementing AI solutions today.',
      startTime: DateTime(2026, 2, 15, 10, 30),
      endTime: DateTime(2026, 2, 15, 12, 0),
      speaker: 'Prof. Michael Chen',
      speakerBio: 'AI Research Lead at Stanford University',
      location: 'Room A',
    ),
    Session(
      id: 'session-003',
      eventId: 'event-001',
      title: 'Lunch Break & Networking',
      description: 'Enjoy lunch while networking with fellow attendees.',
      startTime: DateTime(2026, 2, 15, 12, 0),
      endTime: DateTime(2026, 2, 15, 13, 30),
      speaker: 'Networking',
      location: 'Cafeteria',
    ),
    Session(
      id: 'session-004',
      eventId: 'event-001',
      title: 'Cloud Architecture Best Practices',
      description: 'Learn how to design scalable and resilient cloud infrastructure.',
      startTime: DateTime(2026, 2, 15, 13, 30),
      endTime: DateTime(2026, 2, 15, 15, 0),
      speaker: 'Sarah Johnson',
      speakerBio: 'Principal Cloud Architect at AWS',
      location: 'Room B',
    ),
    Session(
      id: 'session-005',
      eventId: 'event-001',
      title: 'Panel Discussion: Ethics in Tech',
      description: 'Industry leaders discuss ethical considerations in modern technology development.',
      startTime: DateTime(2026, 2, 15, 15, 30),
      endTime: DateTime(2026, 2, 15, 17, 0),
      speaker: 'Panel',
      location: 'Main Hall',
    ),

    // Flutter Workshop sessions (event-002)
    Session(
      id: 'session-006',
      eventId: 'event-002',
      title: 'Flutter Fundamentals',
      description: 'Introduction to Flutter framework and Dart programming language.',
      startTime: DateTime(2026, 1, 25, 10, 0),
      endTime: DateTime(2026, 1, 25, 12, 0),
      speaker: 'Alex Developer',
      speakerBio: 'Google Developer Expert for Flutter',
      location: 'Workshop Room 1',
    ),
    Session(
      id: 'session-007',
      eventId: 'event-002',
      title: 'State Management with Provider',
      description: 'Master state management using the Provider package.',
      startTime: DateTime(2026, 1, 25, 13, 0),
      endTime: DateTime(2026, 1, 25, 15, 0),
      speaker: 'Alex Developer',
      speakerBio: 'Google Developer Expert for Flutter',
      location: 'Workshop Room 1',
    ),
    Session(
      id: 'session-008',
      eventId: 'event-002',
      title: 'Building Beautiful UIs',
      description: 'Create stunning user interfaces with Flutter widgets.',
      startTime: DateTime(2026, 1, 25, 15, 30),
      endTime: DateTime(2026, 1, 25, 17, 0),
      speaker: 'Maria Designer',
      speakerBio: 'UI/UX Designer and Flutter Developer',
      location: 'Workshop Room 1',
    ),

    // AI Seminar sessions (event-004)
    Session(
      id: 'session-009',
      eventId: 'event-004',
      title: 'Introduction to Neural Networks',
      description: 'Understanding the basics of neural network architecture.',
      startTime: DateTime(2026, 2, 5, 14, 0),
      endTime: DateTime(2026, 2, 5, 15, 30),
      speaker: 'Dr. Emily Watson',
      speakerBio: 'AI Researcher at OpenAI',
      location: 'Lecture Hall 1',
    ),
    Session(
      id: 'session-010',
      eventId: 'event-004',
      title: 'NLP: From Basics to GPT',
      description: 'Evolution of natural language processing and modern language models.',
      startTime: DateTime(2026, 2, 5, 15, 45),
      endTime: DateTime(2026, 2, 5, 17, 15),
      speaker: 'Dr. David Lee',
      speakerBio: 'NLP Specialist at DeepMind',
      location: 'Lecture Hall 1',
    ),
  ];

  // Getters
  List<Session> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get sessions for a specific event
  List<Session> getSessionsByEvent(String eventId) {
    final eventSessions = _sessions.where((s) => s.eventId == eventId).toList();
    eventSessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return eventSessions;
  }

  /// Get sessions for a specific date within an event
  List<Session> getSessionsByDate(String eventId, DateTime date) {
    return getSessionsByEvent(eventId).where((s) =>
        s.startTime.year == date.year &&
        s.startTime.month == date.month &&
        s.startTime.day == date.day
    ).toList();
  }

  /// Get unique dates for an event (for multi-day events)
  List<DateTime> getEventDates(String eventId) {
    final sessions = getSessionsByEvent(eventId);
    final dates = <DateTime>{};
    for (final session in sessions) {
      dates.add(DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      ));
    }
    return dates.toList()..sort();
  }

  /// Get session by ID
  Session? getSessionById(String id) {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new session
  Future<Session?> createSession({
    required String eventId,
    required String title,
    String description = '',
    required DateTime startTime,
    required DateTime endTime,
    required String speaker,
    String? speakerBio,
    String? location,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final session = Session(
        id: const Uuid().v4(),
        eventId: eventId,
        title: title,
        description: description,
        startTime: startTime,
        endTime: endTime,
        speaker: speaker,
        speakerBio: speakerBio,
        location: location,
      );

      _sessions.add(session);
      _isLoading = false;
      notifyListeners();
      return session;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update a session
  Future<bool> updateSession(Session updatedSession) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final index = _sessions.indexWhere((s) => s.id == updatedSession.id);
      if (index == -1) {
        throw Exception('Session not found');
      }

      _sessions[index] = updatedSession;
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

  /// Delete a session
  Future<bool> deleteSession(String sessionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      _sessions.removeWhere((s) => s.id == sessionId);
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
