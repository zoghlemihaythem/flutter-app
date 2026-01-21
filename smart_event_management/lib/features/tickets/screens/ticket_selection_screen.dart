import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../events/providers/event_provider.dart';
import '../../registration/providers/registration_provider.dart';
import '../models/ticket_model.dart';
import '../providers/ticket_provider.dart';
import 'payment_screen.dart';

/// Screen for selecting ticket type
class TicketSelectionScreen extends StatefulWidget {
  final String eventId;

  const TicketSelectionScreen({super.key, required this.eventId});

  @override
  State<TicketSelectionScreen> createState() => _TicketSelectionScreenState();
}

class _TicketSelectionScreenState extends State<TicketSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch fresh prices from DB
    Future.microtask(() => 
      context.read<TicketProvider>().fetchTicketConfigs(widget.eventId)
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final ticketProvider = context.watch<TicketProvider>();
    final authProvider = context.watch<AuthProvider>();
    final registrationProvider = context.watch<RegistrationProvider>();

    final event = eventProvider.getEventById(widget.eventId);
    final user = authProvider.currentUser;
    // Now this will return data once fetchTicketConfigs completes
    final ticketPrices = ticketProvider.getTicketPrices(widget.eventId);
    
    final existingTicket = user != null
        ? ticketProvider.getUserTicketForEvent(user.id, widget.eventId)
        : null;

    if (event == null || user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.error,
          title: 'Error',
          subtitle: 'Event not found or user not logged in',
        ),
      );
    }

    // If user already has ticket, show it
    if (existingTicket != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Ticket')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _TicketDisplay(ticket: existingTicket, eventTitle: event.title),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Ticket')),
      body: ticketPrices.isEmpty
          ? EmptyState(
              icon: Icons.confirmation_number_outlined,
              title: 'No Tickets Available',
              subtitle: 'Tickets for this event are not on sale yet',
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Event info header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Choose your ticket',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),

                // Ticket options
                ...ticketPrices.map((price) => _TicketOption(
                  ticketPrice: price,
                  onSelect: () async {
                    // First register if not registered
                    if (!registrationProvider.isUserRegistered(user.id, widget.eventId)) {
                      await registrationProvider.registerForEvent(
                        eventId: widget.eventId,
                        userId: user.id,
                        userName: user.name,
                        userEmail: user.email,
                      );
                    }

                    // If free ticket, purchase directly
                    if (price.type == TicketType.free) {
                      final ticket = await ticketProvider.purchaseTicket(
                        eventId: widget.eventId,
                        eventTitle: event.title,
                        userId: user.id,
                        userName: user.name,
                        type: price.type,
                        price: 0,
                      );
                      if (ticket != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ticket acquired successfully!'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } else {
                      // Go to payment screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            eventId: widget.eventId,
                            eventTitle: event.title,
                            ticketType: price.type,
                            price: price.price,
                          ),
                        ),
                      );
                    }
                  },
                )),
              ],
            ),
    );
  }
}

class _TicketOption extends StatelessWidget {
  final TicketPrice ticketPrice;
  final VoidCallback onSelect;

  const _TicketOption({required this.ticketPrice, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isVip = ticketPrice.type == TicketType.vip;
    final isFree = ticketPrice.type == TicketType.free;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
        border: isVip
            ? Border.all(color: const Color(0xFFD4AF37), width: 2)
            : null,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(),
                  color: _getColor(),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getTypeLabel(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: _getColor(),
                          ),
                        ),
                        if (isVip) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticketPrice.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${ticketPrice.available} available',
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isFree ? 'FREE' : '\$${ticketPrice.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _getColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel() {
    switch (ticketPrice.type) {
      case TicketType.free:
        return 'Free';
      case TicketType.standard:
        return 'Standard';
      case TicketType.vip:
        return 'VIP';
    }
  }

  Color _getColor() {
    switch (ticketPrice.type) {
      case TicketType.free:
        return AppTheme.successColor;
      case TicketType.standard:
        return AppTheme.primaryColor;
      case TicketType.vip:
        return const Color(0xFFD4AF37);
    }
  }

  IconData _getIcon() {
    switch (ticketPrice.type) {
      case TicketType.free:
        return Icons.confirmation_number_outlined;
      case TicketType.standard:
        return Icons.confirmation_number;
      case TicketType.vip:
        return Icons.star;
    }
  }
}

class _TicketDisplay extends StatelessWidget {
  final Ticket ticket;
  final String eventTitle;

  const _TicketDisplay({required this.ticket, required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: Column(
              children: [
                Text(
                  ticket.typeDisplayName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  eventTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Ticket info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _InfoRow(label: 'Attendee', value: ticket.userName),
                const Divider(height: 24),
                _InfoRow(label: 'Ticket ID', value: ticket.id.substring(0, 8).toUpperCase()),
                const Divider(height: 24),
                _InfoRow(label: 'Status', value: ticket.paymentStatusDisplayName),
              ],
            ),
          ),

          // QR placeholder
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Column(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      ticket.qrCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Scan at event entry',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
