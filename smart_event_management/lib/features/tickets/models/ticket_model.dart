/// Ticket types available for events
enum TicketType { free, standard, vip }

/// Payment status for tickets
enum PaymentStatus { pending, completed, failed, refunded }

/// Ticket model representing a purchased ticket
class Ticket {
  final String id;
  final String eventId;
  final String eventTitle;
  final String userId;
  final String userName;
  final TicketType type;
  final double price;
  final String qrCode;
  final PaymentStatus paymentStatus;
  final DateTime purchasedAt;
  final bool isUsed;

  const Ticket({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userName,
    required this.type,
    required this.price,
    required this.qrCode,
    this.paymentStatus = PaymentStatus.pending,
    required this.purchasedAt,
    this.isUsed = false,
  });

  Ticket copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? userId,
    String? userName,
    TicketType? type,
    double? price,
    String? qrCode,
    PaymentStatus? paymentStatus,
    DateTime? purchasedAt,
    bool? isUsed,
  }) {
    return Ticket(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      price: price ?? this.price,
      qrCode: qrCode ?? this.qrCode,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      isUsed: isUsed ?? this.isUsed,
    );
  }

  /// Get ticket type display name
  String get typeDisplayName {
    switch (type) {
      case TicketType.free:
        return 'Free';
      case TicketType.standard:
        return 'Standard';
      case TicketType.vip:
        return 'VIP';
    }
  }

  /// Get payment status display name
  String get paymentStatusDisplayName {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }

  /// Check if ticket is valid (paid and not used)
  bool get isValid =>
      paymentStatus == PaymentStatus.completed && !isUsed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ticket && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Ticket pricing information for an event
class TicketPrice {
  final TicketType type;
  final double price;
  final int available;
  final String description;

  const TicketPrice({
    required this.type,
    required this.price,
    required this.available,
    required this.description,
  });
}
