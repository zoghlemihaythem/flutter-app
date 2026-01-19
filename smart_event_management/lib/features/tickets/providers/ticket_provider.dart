import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';

/// Ticket and Payment provider managing ticket purchases and mock payments
class TicketProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isProcessingPayment = false;

  // Mock tickets data
  final List<Ticket> _tickets = [
    Ticket(
      id: 'ticket-001',
      eventId: 'event-001',
      eventTitle: 'Tech Conference 2026',
      userId: 'participant-001',
      userName: 'Alice Participant',
      type: TicketType.standard,
      price: 99.99,
      qrCode: 'TECH2026-STD-001-ALICE',
      paymentStatus: PaymentStatus.completed,
      purchasedAt: DateTime(2025, 12, 1),
    ),
    Ticket(
      id: 'ticket-002',
      eventId: 'event-001',
      eventTitle: 'Tech Conference 2026',
      userId: 'participant-002',
      userName: 'Bob Attendee',
      type: TicketType.vip,
      price: 249.99,
      qrCode: 'TECH2026-VIP-002-BOB',
      paymentStatus: PaymentStatus.completed,
      purchasedAt: DateTime(2025, 12, 5),
    ),
    Ticket(
      id: 'ticket-003',
      eventId: 'event-002',
      eventTitle: 'Flutter Workshop',
      userId: 'participant-001',
      userName: 'Alice Participant',
      type: TicketType.standard,
      price: 49.99,
      qrCode: 'FLUTTER-STD-003-ALICE',
      paymentStatus: PaymentStatus.completed,
      purchasedAt: DateTime(2025, 12, 10),
    ),
    Ticket(
      id: 'ticket-004',
      eventId: 'event-003',
      eventTitle: 'Startup Networking Meetup',
      userId: 'participant-003',
      userName: 'Charlie Guest',
      type: TicketType.free,
      price: 0.0,
      qrCode: 'STARTUP-FREE-004-CHARLIE',
      paymentStatus: PaymentStatus.completed,
      purchasedAt: DateTime(2025, 12, 20),
    ),
  ];

  // Ticket pricing for events
  final Map<String, List<TicketPrice>> _eventTicketPrices = {
    'event-001': [
      const TicketPrice(type: TicketType.standard, price: 99.99, available: 400, description: 'General admission with access to all sessions'),
      const TicketPrice(type: TicketType.vip, price: 249.99, available: 50, description: 'VIP access with exclusive networking events and priority seating'),
    ],
    'event-002': [
      const TicketPrice(type: TicketType.standard, price: 49.99, available: 40, description: 'Workshop access with materials included'),
    ],
    'event-003': [
      const TicketPrice(type: TicketType.free, price: 0.0, available: 100, description: 'Free admission'),
    ],
    'event-004': [
      const TicketPrice(type: TicketType.free, price: 0.0, available: 150, description: 'Free admission'),
      const TicketPrice(type: TicketType.standard, price: 25.00, available: 50, description: 'Reserved seating with certificate'),
    ],
    'event-005': [
      const TicketPrice(type: TicketType.standard, price: 29.99, available: 100, description: 'Participant registration'),
      const TicketPrice(type: TicketType.vip, price: 79.99, available: 20, description: 'Mentor access and premium support'),
    ],
  };

  // Getters
  List<Ticket> get tickets => List.unmodifiable(_tickets);
  bool get isLoading => _isLoading;
  bool get isProcessingPayment => _isProcessingPayment;
  String? get error => _error;

  /// Get tickets for a specific user
  List<Ticket> getTicketsByUser(String userId) {
    return _tickets.where((t) => t.userId == userId).toList();
  }

  /// Get tickets for a specific event
  List<Ticket> getTicketsByEvent(String eventId) {
    return _tickets.where((t) => t.eventId == eventId).toList();
  }

  /// Get ticket pricing for an event
  List<TicketPrice> getTicketPrices(String eventId) {
    return _eventTicketPrices[eventId] ?? [];
  }

  /// Check if user has ticket for an event
  bool hasTicket(String userId, String eventId) {
    return _tickets.any((t) =>
        t.userId == userId &&
        t.eventId == eventId &&
        t.paymentStatus == PaymentStatus.completed
    );
  }

  /// Get a specific ticket
  Ticket? getTicket(String ticketId) {
    try {
      return _tickets.firstWhere((t) => t.id == ticketId);
    } catch (_) {
      return null;
    }
  }

  /// Get user's ticket for a specific event
  Ticket? getUserTicketForEvent(String userId, String eventId) {
    try {
      return _tickets.firstWhere((t) =>
          t.userId == userId &&
          t.eventId == eventId &&
          t.paymentStatus == PaymentStatus.completed
      );
    } catch (_) {
      return null;
    }
  }

  /// Generate QR code data
  String _generateQRCode(String eventId, TicketType type, String ticketId, String userName) {
    final typePrefix = type == TicketType.vip ? 'VIP' : type == TicketType.free ? 'FREE' : 'STD';
    final namePart = userName.split(' ').first.toUpperCase();
    return 'EVT-$typePrefix-${ticketId.substring(0, 8)}-$namePart';
  }

  /// Purchase a ticket (mock payment)
  Future<Ticket?> purchaseTicket({
    required String eventId,
    required String eventTitle,
    required String userId,
    required String userName,
    required TicketType type,
    required double price,
    String? cardNumber,
    String? expiryDate,
    String? cvv,
  }) async {
    _isLoading = true;
    _isProcessingPayment = true;
    _error = null;
    notifyListeners();

    try {
      // Check if already has ticket
      if (hasTicket(userId, eventId)) {
        throw Exception('You already have a ticket for this event');
      }

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock payment validation (simulate occasional failures for demo)
      if (price > 0 && cardNumber == '0000000000000000') {
        throw Exception('Payment declined. Please check your card details.');
      }

      final ticketId = const Uuid().v4();
      final ticket = Ticket(
        id: ticketId,
        eventId: eventId,
        eventTitle: eventTitle,
        userId: userId,
        userName: userName,
        type: type,
        price: price,
        qrCode: _generateQRCode(eventId, type, ticketId, userName),
        paymentStatus: PaymentStatus.completed,
        purchasedAt: DateTime.now(),
      );

      _tickets.add(ticket);
      _isLoading = false;
      _isProcessingPayment = false;
      notifyListeners();
      return ticket;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      _isProcessingPayment = false;
      notifyListeners();
      return null;
    }
  }

  /// Mark ticket as used (for check-in)
  Future<bool> useTicket(String ticketId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index == -1) {
        throw Exception('Ticket not found');
      }

      if (_tickets[index].isUsed) {
        throw Exception('Ticket has already been used');
      }

      _tickets[index] = _tickets[index].copyWith(isUsed: true);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request refund (mock)
  Future<bool> requestRefund(String ticketId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    try {
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index == -1) {
        throw Exception('Ticket not found');
      }

      if (_tickets[index].isUsed) {
        throw Exception('Cannot refund a used ticket');
      }

      _tickets[index] = _tickets[index].copyWith(paymentStatus: PaymentStatus.refunded);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Set ticket prices for an event (for organizers)
  void setEventTicketPrices(String eventId, List<TicketPrice> prices) {
    _eventTicketPrices[eventId] = prices;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
