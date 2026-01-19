import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/ticket_model.dart';
import '../providers/ticket_provider.dart';

/// Mock payment screen
class PaymentScreen extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final TicketType ticketType;
  final double price;

  const PaymentScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.ticketType,
    required this.price,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    final ticketProvider = context.read<TicketProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return;

    final ticket = await ticketProvider.purchaseTicket(
      eventId: widget.eventId,
      eventTitle: widget.eventTitle,
      userId: user.id,
      userName: user.name,
      type: widget.ticketType,
      price: widget.price,
      cardNumber: _cardNumberController.text.replaceAll(' ', ''),
      expiryDate: _expiryController.text,
      cvv: _cvvController.text,
    );

    if (ticket != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Payment Successful!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your ticket has been generated',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            CustomButton(
              text: 'View Ticket',
              useGradient: true,
              width: double.infinity,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    } else if (ticketProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ticketProvider.error!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = context.watch<TicketProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: LoadingOverlay(
        isLoading: ticketProvider.isProcessingPayment,
        message: 'Processing payment...',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Order summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Event'),
                          Expanded(
                            child: Text(
                              widget.eventTitle,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ticket Type'),
                          Text(
                            widget.ticketType == TicketType.vip ? 'VIP' : 'Standard',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '\$${widget.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Demo notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.infoColor, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Demo Mode: Use any card details. Try 16 zeros to test declined payment.',
                          style: TextStyle(fontSize: 12, color: AppTheme.infoColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Payment form
                const Text(
                  'Card Details',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _nameController,
                  label: 'Cardholder Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _cardNumberController,
                  label: 'Card Number',
                  hint: '1234 5678 9012 3456',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.credit_card),
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    if (v!.replaceAll(' ', '').length < 16) return 'Invalid card number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _expiryController,
                        label: 'Expiry',
                        hint: 'MM/YY',
                        keyboardType: TextInputType.datetime,
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _cvvController,
                        label: 'CVV',
                        hint: '123',
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: 'Pay \$${widget.price.toStringAsFixed(2)}',
                  onPressed: _processPayment,
                  isLoading: ticketProvider.isProcessingPayment,
                  useGradient: true,
                ),

                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 14, color: AppTheme.textTertiary),
                    SizedBox(width: 4),
                    Text(
                      'Secured by Mock Payment Gateway',
                      style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
