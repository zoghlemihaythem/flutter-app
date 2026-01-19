/// Session model representing a session within an event's schedule
class Session {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String speaker;
  final String? speakerBio;
  final String? location;

  const Session({
    required this.id,
    required this.eventId,
    required this.title,
    this.description = '',
    required this.startTime,
    required this.endTime,
    required this.speaker,
    this.speakerBio,
    this.location,
  });

  Session copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? speaker,
    String? speakerBio,
    String? location,
  }) {
    return Session(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      speaker: speaker ?? this.speaker,
      speakerBio: speakerBio ?? this.speakerBio,
      location: location ?? this.location,
    );
  }

  /// Get duration in minutes
  int get durationMinutes => endTime.difference(startTime).inMinutes;

  /// Get formatted duration
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes}m';
  }

  /// Check if session is ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Check if session is completed
  bool get isCompleted => endTime.isBefore(DateTime.now());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
