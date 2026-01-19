import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../events/providers/event_provider.dart';
import '../../events/screens/event_detail_screen.dart';
import '../providers/registration_provider.dart';

/// Screen showing user's event registrations
class MyRegistrationsScreen extends StatelessWidget {
  const MyRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final registrationProvider = context.watch<RegistrationProvider>();
    final eventProvider = context.watch<EventProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const SizedBox.shrink();

    final registrations = registrationProvider.getRegistrationsByUser(user.id);

    return Scaffold(
      appBar: AppBar(title: const Text('My Registrations')),
      body: registrations.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border,
              title: 'No Registrations',
              subtitle: 'Browse events and register to attend',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: registrations.length,
              itemBuilder: (context, index) {
                final registration = registrations[index];
                final event = eventProvider.getEventById(registration.eventId);
                if (event == null) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailScreen(eventId: event.id),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  DateFormat('dd').format(event.date),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM').format(event.date).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.location,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                StatusBadge(
                                  label: registration.statusDisplayName,
                                  color: registration.isCheckedIn
                                      ? AppTheme.successColor
                                      : AppTheme.primaryColor,
                                  icon: registration.isCheckedIn
                                      ? Icons.check_circle
                                      : Icons.schedule,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
