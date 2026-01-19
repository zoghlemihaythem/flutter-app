import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';

/// Event provider managing CRUD operations for events
class EventProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  // Mock events data
  final List<Event> _events = [
    Event(
      id: 'event-001',
      title: 'Tech Conference 2026',
      description: 'Annual technology conference featuring the latest innovations in AI, cloud computing, and software development. Join industry leaders and experts for keynotes, workshops, and networking opportunities.',
      date: DateTime(2026, 2, 15, 9, 0),
      endDate: DateTime(2026, 2, 17, 18, 0),
      location: 'Convention Center, New York',
      organizerId: 'organizer-001',
      organizerName: 'John Organizer',
      isPublished: true,
      capacity: 500,
      category: 'Conference',
      createdAt: DateTime(2025, 11, 1),
    ),
    Event(
      id: 'event-002',
      title: 'Flutter Workshop',
      description: 'Hands-on workshop covering Flutter fundamentals, state management with Provider, and building beautiful mobile applications. Perfect for beginners and intermediate developers.',
      date: DateTime(2026, 1, 25, 10, 0),
      endDate: DateTime(2026, 1, 25, 17, 0),
      location: 'Tech Hub, San Francisco',
      organizerId: 'organizer-001',
      organizerName: 'John Organizer',
      isPublished: true,
      capacity: 50,
      category: 'Workshop',
      createdAt: DateTime(2025, 12, 1),
    ),
    Event(
      id: 'event-003',
      title: 'Startup Networking Meetup',
      description: 'Monthly networking event for entrepreneurs, investors, and startup enthusiasts. Share ideas, find co-founders, and connect with the local startup ecosystem.',
      date: DateTime(2026, 1, 30, 18, 0),
      endDate: DateTime(2026, 1, 30, 21, 0),
      location: 'Innovation Hub, Austin',
      organizerId: 'organizer-002',
      organizerName: 'Sarah Events',
      isPublished: true,
      capacity: 100,
      category: 'Networking',
      createdAt: DateTime(2025, 12, 15),
    ),
    Event(
      id: 'event-004',
      title: 'AI & Machine Learning Seminar',
      description: 'Deep dive into the latest advancements in artificial intelligence and machine learning. Topics include neural networks, natural language processing, and practical AI applications.',
      date: DateTime(2026, 2, 5, 14, 0),
      endDate: DateTime(2026, 2, 5, 18, 0),
      location: 'University Auditorium, Boston',
      organizerId: 'organizer-002',
      organizerName: 'Sarah Events',
      isPublished: true,
      capacity: 200,
      category: 'Seminar',
      createdAt: DateTime(2025, 12, 20),
    ),
    Event(
      id: 'event-005',
      title: 'Hackathon 2026',
      description: '48-hour hackathon challenging developers to build innovative solutions. Prizes for best overall, most creative, and best use of technology.',
      date: DateTime(2026, 3, 1, 9, 0),
      endDate: DateTime(2026, 3, 3, 17, 0),
      location: 'Tech Campus, Seattle',
      organizerId: 'organizer-001',
      organizerName: 'John Organizer',
      isPublished: false,
      capacity: 150,
      category: 'Hackathon',
      createdAt: DateTime(2026, 1, 5),
    ),
  ];

  // Getters
  List<Event> get events => List.unmodifiable(_events);
  List<Event> get publishedEvents => _events.where((e) => e.isPublished).toList();
  List<Event> get upcomingEvents => 
      publishedEvents.where((e) => e.isUpcoming || e.isOngoing).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get events by organizer ID
  List<Event> getEventsByOrganizer(String organizerId) {
    return _events.where((e) => e.organizerId == organizerId).toList();
  }

  /// Get event by ID
  Event? getEventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get events by category
  List<Event> getEventsByCategory(String category) {
    return publishedEvents.where((e) => e.category == category).toList();
  }

  /// Search events by title or description
  List<Event> searchEvents(String query) {
    final lowerQuery = query.toLowerCase();
    return publishedEvents.where((e) =>
        e.title.toLowerCase().contains(lowerQuery) ||
        e.description.toLowerCase().contains(lowerQuery) ||
        e.location.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Create a new event
  Future<Event?> createEvent({
    required String title,
    required String description,
    required DateTime date,
    required DateTime endDate,
    required String location,
    required String organizerId,
    required String organizerName,
    required int capacity,
    required String category,
    bool isPublished = false,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final event = Event(
        id: const Uuid().v4(),
        title: title,
        description: description,
        date: date,
        endDate: endDate,
        location: location,
        organizerId: organizerId,
        organizerName: organizerName,
        isPublished: isPublished,
        imageUrl: imageUrl,
        capacity: capacity,
        category: category,
        createdAt: DateTime.now(),
      );

      _events.add(event);
      _isLoading = false;
      notifyListeners();
      return event;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update an existing event
  Future<bool> updateEvent(Event updatedEvent) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final index = _events.indexWhere((e) => e.id == updatedEvent.id);
      if (index == -1) {
        throw Exception('Event not found');
      }

      _events[index] = updatedEvent;
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

  /// Delete an event
  Future<bool> deleteEvent(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      _events.removeWhere((e) => e.id == eventId);
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

  /// Toggle event publish status
  Future<bool> togglePublish(String eventId) async {
    final event = getEventById(eventId);
    if (event == null) return false;

    return updateEvent(event.copyWith(isPublished: !event.isPublished));
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
