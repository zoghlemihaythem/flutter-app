import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';

/// Event provider managing CRUD operations for events
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Event provider managing CRUD operations for events
class EventProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<Event> _events = [];
  final _supabase = sb.Supabase.instance.client;

  EventProvider() {
    fetchEvents();
  }

  /// Fetch all events from Supabase
  Future<void> fetchEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('events')
          .select()
          .order('date', ascending: true);

      final List<dynamic> data = response;
      _events = data.map((json) => Event(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        location: json['location'],
        date: DateTime.parse(json['date']),
        endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : DateTime.now(),
        capacity: json['capacity'] ?? 0,
        category: json['category'] ?? 'General',
        isPublished: json['is_published'] ?? false,
        organizerId: json['organizer_id'],
        organizerName: 'Organizer', // We would need a join to get name, simplified for now
        imageUrl: json['image_url'],
        createdAt: DateTime.parse(json['created_at']),
      )).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

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

    try {
      final response = await _supabase.from('events').insert({
        'title': title,
        'description': description,
        'location': location,
        'date': date.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'capacity': capacity,
        'category': category,
        'is_published': isPublished,
        'organizer_id': organizerId,
        'image_url': imageUrl,
      }).select().single();

      final event = Event(
        id: response['id'],
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
        createdAt: DateTime.parse(response['created_at']),
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

    try {
      await _supabase.from('events').update({
        'title': updatedEvent.title,
        'description': updatedEvent.description,
        'location': updatedEvent.location,
        'date': updatedEvent.date.toIso8601String(),
        'end_date': updatedEvent.endDate.toIso8601String(),
        'capacity': updatedEvent.capacity,
        'category': updatedEvent.category,
        'is_published': updatedEvent.isPublished,
        'image_url': updatedEvent.imageUrl,
      }).eq('id', updatedEvent.id);

      final index = _events.indexWhere((e) => e.id == updatedEvent.id);
      if (index != -1) {
        _events[index] = updatedEvent;
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

  /// Delete an event
  Future<bool> deleteEvent(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _supabase.from('events').delete().eq('id', eventId);
      
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
