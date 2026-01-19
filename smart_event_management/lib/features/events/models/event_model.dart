/// Event model representing an event in the system
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime endDate;
  final String location;
  final String organizerId;
  final String organizerName;
  final bool isPublished;
  final String? imageUrl;
  final int capacity;
  final String category;
  final DateTime createdAt;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.endDate,
    required this.location,
    required this.organizerId,
    required this.organizerName,
    this.isPublished = false,
    this.imageUrl,
    required this.capacity,
    required this.category,
    required this.createdAt,
  });

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? endDate,
    String? location,
    String? organizerId,
    String? organizerName,
    bool? isPublished,
    String? imageUrl,
    int? capacity,
    String? category,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      isPublished: isPublished ?? this.isPublished,
      imageUrl: imageUrl ?? this.imageUrl,
      capacity: capacity ?? this.capacity,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if event is upcoming
  bool get isUpcoming => date.isAfter(DateTime.now());

  /// Check if event is ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(date) && now.isBefore(endDate);
  }

  /// Check if event is past
  bool get isPast => endDate.isBefore(DateTime.now());

  /// Get event status as string
  String get status {
    if (isPast) return 'Completed';
    if (isOngoing) return 'Ongoing';
    return 'Upcoming';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Available event categories
class EventCategories {
  static const List<String> all = [
    'Conference',
    'Workshop',
    'Seminar',
    'Meetup',
    'Webinar',
    'Hackathon',
    'Networking',
    'Other',
  ];
}
