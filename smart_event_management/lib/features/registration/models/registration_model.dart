/// Check-in status for event registrations
enum CheckInStatus { registered, checkedIn }

/// Registration model representing a participant's registration for an event
class Registration {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String userEmail;
  final CheckInStatus status;
  final DateTime registeredAt;
  final DateTime? checkedInAt;

  const Registration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.status = CheckInStatus.registered,
    required this.registeredAt,
    this.checkedInAt,
  });

  Registration copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? userEmail,
    CheckInStatus? status,
    DateTime? registeredAt,
    DateTime? checkedInAt,
  }) {
    return Registration(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
    );
  }

  /// Check if participant is checked in
  bool get isCheckedIn => status == CheckInStatus.checkedIn;

  /// Get display status
  String get statusDisplayName {
    switch (status) {
      case CheckInStatus.registered:
        return 'Registered';
      case CheckInStatus.checkedIn:
        return 'Checked In';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Registration &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
