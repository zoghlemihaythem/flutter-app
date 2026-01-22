import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/session_model.dart';

/// Schedule provider managing event sessions and agenda
class ScheduleProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  final _supabase = sb.Supabase.instance.client;

  List<Session> _sessions = [];

  // Getters
  List<Session> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Current event being fetched to avoid redundant calls
  String? _currentFetchingEventId;

  /// Fetch sessions for a specific event
  Future<void> fetchSessions(String eventId) async {
    // Avoid redundant calls for the same event if already loading
    if (_isLoading && _currentFetchingEventId == eventId) return;

    _isLoading = true;
    _currentFetchingEventId = eventId;
    _error = null;
    
    // Use a slight delay or post-frame next cycle if needed, 
    // but usually not calling notifyListeners here if we can help it or doing it carefully
    // notifyListeners(); // Removed to avoid "setState during build" errors if called from build

    try {
      debugPrint('📅 Fetching sessions for event: $eventId');
      final response = await _supabase
          .from('sessions')
          .select()
          .eq('event_id', eventId)
          .order('start_time', ascending: true);

      final List<dynamic> data = response;
      
      // Filter out old sessions for this event and replace with new ones
      _sessions.removeWhere((s) => s.eventId == eventId);
      
      final eventSessions = data.map((json) => Session(
        id: json['id'],
        eventId: json['event_id'],
        title: json['title'],
        description: json['description'] ?? '',
        startTime: DateTime.parse(json['start_time']),
        endTime: DateTime.parse(json['end_time']),
        speaker: json['speaker'] ?? 'Speaker',
        speakerBio: json['speaker_bio'],
        location: json['location'],
      )).toList();

      _sessions.addAll(eventSessions);
      
      debugPrint('✅ Loaded ${eventSessions.length} sessions');
      _isLoading = false;
      _currentFetchingEventId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error fetching sessions: $e');
      _error = e.toString();
      _isLoading = false;
      _currentFetchingEventId = null;
      notifyListeners();
    }
  }

  /// Get sessions for a specific event (filtered from local list)
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
    if (sessions.isEmpty) return [];
    
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

    try {
      final response = await _supabase.from('sessions').insert({
        'event_id': eventId,
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'speaker': speaker,
        'speaker_bio': speakerBio,
        'location': location,
      }).select().single();

      final session = Session(
        id: response['id'],
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
      debugPrint('❌ Error creating session: $e');
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

    try {
      await _supabase.from('sessions').update({
        'title': updatedSession.title,
        'description': updatedSession.description,
        'start_time': updatedSession.startTime.toIso8601String(),
        'end_time': updatedSession.endTime.toIso8601String(),
        'speaker': updatedSession.speaker,
        'speaker_bio': updatedSession.speakerBio,
        'location': updatedSession.location,
      }).eq('id', updatedSession.id);

      final index = _sessions.indexWhere((s) => s.id == updatedSession.id);
      if (index != -1) {
        _sessions[index] = updatedSession;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error updating session: $e');
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

    try {
      await _supabase.from('sessions').delete().eq('id', sessionId);
      
      _sessions.removeWhere((s) => s.id == sessionId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting session: $e');
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
