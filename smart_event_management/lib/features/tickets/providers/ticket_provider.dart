import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/ticket_model.dart';

/// Ticket and Payment provider managing ticket purchases and mock payments
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Ticket and Payment provider managing ticket purchases and payments
class TicketProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isProcessingPayment = false;
  final _supabase = sb.Supabase.instance.client;

  List<Ticket> _tickets = [];
  Map<String, List<TicketPrice>> _eventTicketPrices = {};

  // Getters
  List<Ticket> get tickets => List.unmodifiable(_tickets);
  bool get isLoading => _isLoading;
  bool get isProcessingPayment => _isProcessingPayment;
  String? get error => _error;

  /// Fetch tickets for the current user
  Future<void> fetchUserTickets(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('tickets')
          .select('*, events(title)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      _tickets = data.map((json) => Ticket(
        id: json['id'],
        eventId: json['event_id'],
        eventTitle: json['events']['title'] ?? 'Unknown Event',
        userId: json['user_id'],
        userName: 'User', // Retrieved from profile usually
        type: _parseTicketType(json['type']),
        price: (json['price'] as num).toDouble(),
        qrCode: json['qr_code'],
        paymentStatus: _parsePaymentStatus(json['payment_status']),
        purchasedAt: DateTime.parse(json['created_at']),
        isUsed: json['is_used'] ?? false,
      )).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get ticket prices for an event (fetched from 'event_ticket_configs' table)
  List<TicketPrice> getTicketPrices(String eventId) {
    return _eventTicketPrices[eventId] ?? [];
  }

  /// Fetch ticket configurations for an event
  Future<void> fetchTicketConfigs(String eventId) async {
    try {
      final response = await _supabase
          .from('event_ticket_configs')
          .select()
          .eq('event_id', eventId);

      final List<dynamic> data = response;
      final prices = data.map((json) => TicketPrice(
        type: _parseTicketType(json['ticket_type']),
        price: (json['price'] as num).toDouble(),
        available: json['available_quantity'],
        description: json['description'] ?? '',
      )).toList();

      _eventTicketPrices[eventId] = prices;
      notifyListeners();
    } catch (e) {
      // If table doesn't exist or empty, fall back to defaults or empty
      debugPrint('Error fetching config: $e');
    }
  }

  /// Purchase a ticket
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
        // 1. Simulate Payment Gateway Check
       if (price > 0) {
         await Future.delayed(const Duration(seconds: 2));
         // Add real payment gateway logic here (Stripe/PayPal)
       }

      // 2. Insert Ticket
      final typeStr = type.toString().split('.').last;
      final qrData = 'EVT-${typeStr.toUpperCase()}-$eventId-$userId';

      final response = await _supabase.from('tickets').insert({
        'event_id': eventId,
        'user_id': userId,
        'type': typeStr,
        'price': price,
        'qr_code': qrData,
        'payment_status': 'completed',
        'is_used': false,
      }).select().single();

      final ticket = Ticket(
        id: response['id'],
        eventId: eventId,
        eventTitle: eventTitle,
        userId: userId,
        userName: userName,
        type: type,
        price: price,
        qrCode: qrData,
        paymentStatus: PaymentStatus.completed,
        purchasedAt: DateTime.parse(response['created_at']),
      );

      _tickets.insert(0, ticket);
      
      _isLoading = false;
      _isProcessingPayment = false;
      notifyListeners();
      return ticket;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isProcessingPayment = false;
      notifyListeners();
      return null;
    }
  }

  /// Mark ticket as used
  Future<bool> useTicket(String ticketId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase
          .from('tickets')
          .update({'is_used': true})
          .eq('id', ticketId);
      
      final index = _tickets.indexWhere((t) => t.id == ticketId);
      if (index != -1) {
        _tickets[index] = _tickets[index].copyWith(isUsed: true);
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

  // --- Helpers ---

  TicketType _parseTicketType(String type) {
    return TicketType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => TicketType.standard,
    );
  }

  PaymentStatus _parsePaymentStatus(String status) {
    return PaymentStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => PaymentStatus.completed,
    );
  }

  /// Set ticket prices (Saves to DB)
  Future<void> setEventTicketPrices(String eventId, List<TicketPrice> prices) async {
    _eventTicketPrices[eventId] = prices;
    notifyListeners();

    // Persist to DB
    try {
      // Clear existing configs for this event
      await _supabase.from('event_ticket_configs').delete().eq('event_id', eventId);
      
      // Insert new configs
      for (var p in prices) {
        await _supabase.from('event_ticket_configs').insert({
          'event_id': eventId,
          'ticket_type': p.type.toString().split('.').last,
          'price': p.price,
          'available_quantity': p.available,
          'description': p.description,
        });
      }
    } catch (e) {
      debugPrint('Error saving ticket config: $e');
    }
  }

  // Legacy/Mock methods to keep UI working until full refactor
  List<Ticket> getTicketsByUser(String userId) => _tickets.where((t) => t.userId == userId).toList();
  Ticket? getUserTicketForEvent(String userId, String eventId) {
     try {
       return _tickets.firstWhere((t) => t.userId == userId && t.eventId == eventId);
     } catch (_) { return null; }
  }
  /// Check if user has ticket for an event
  bool hasTicket(String userId, String eventId) {
    // This assumes fetchUserTickets(userId) has been called.
    return _tickets.any((t) =>
        t.userId == userId &&
        t.eventId == eventId &&
        t.paymentStatus == PaymentStatus.completed
    );
  }
}
