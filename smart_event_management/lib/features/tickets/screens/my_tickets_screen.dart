import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/ticket_model.dart';
import '../providers/ticket_provider.dart';

/// Screen displaying user's tickets
class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final ticketProvider = context.watch<TicketProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const SizedBox.shrink();

    final tickets = ticketProvider.getTicketsByUser(user.id);
    final validTickets = tickets.where((t) => t.isValid).toList();
    final usedTickets = tickets.where((t) => t.isUsed).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Tickets')),
      body: tickets.isEmpty
          ? const EmptyState(
              icon: Icons.confirmation_number_outlined,
              title: 'No Tickets',
              subtitle: 'Browse events and purchase tickets to attend',
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (validTickets.isNotEmpty) ...[
                  const Text(
                    'Active Tickets',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...validTickets.map((ticket) => _TicketCard(
                    ticket: ticket,
                    onTap: () => _showTicketDetail(context, ticket),
                  )),
                ],
                if (usedTickets.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Used Tickets',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...usedTickets.map((ticket) => _TicketCard(
                    ticket: ticket,
                    isUsed: true,
                    onTap: () => _showTicketDetail(context, ticket),
                  )),
                ],
              ],
            ),
    );
  }

  void _showTicketDetail(BuildContext context, Ticket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TicketDetailSheet(ticket: ticket),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final bool isUsed;
  final VoidCallback onTap;

  const _TicketCard({
    required this.ticket,
    this.isUsed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isUsed ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: AppTheme.cardShadow,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    ticket.type == TicketType.vip ? Icons.star : Icons.confirmation_number,
                    color: _getColor(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticket.eventTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ticket.typeDisplayName,
                              style: TextStyle(
                                color: _getColor(),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isUsed) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.textSecondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'USED',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.qr_code, color: AppTheme.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColor() {
    switch (ticket.type) {
      case TicketType.free:
        return AppTheme.successColor;
      case TicketType.standard:
        return AppTheme.primaryColor;
      case TicketType.vip:
        return const Color(0xFFD4AF37);
    }
  }
}

class _TicketDetailSheet extends StatelessWidget {
  final Ticket ticket;

  const _TicketDetailSheet({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: _getGradient(),
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
                  ticket.eventTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // QR Code
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: QrImageView(
                    data: ticket.qrCode,
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  ticket.qrCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Ticket info
                _DetailRow(label: 'Attendee', value: ticket.userName),
                const Divider(height: 20),
                _DetailRow(
                  label: 'Price',
                  value: ticket.price == 0 ? 'FREE' : '\$${ticket.price.toStringAsFixed(2)}',
                ),
                const Divider(height: 20),
                _DetailRow(
                  label: 'Status',
                  value: ticket.isUsed ? 'Used' : 'Valid',
                  valueColor: ticket.isUsed ? AppTheme.textSecondary : AppTheme.successColor,
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (ticket.type) {
      case TicketType.vip:
        return const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFF4E5B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return AppTheme.heroGradient;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
