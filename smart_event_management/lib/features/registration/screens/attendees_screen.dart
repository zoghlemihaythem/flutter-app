import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../events/providers/event_provider.dart';
import '../models/registration_model.dart';
import '../providers/registration_provider.dart';

/// Screen for organizers to view and manage attendees
class AttendeesScreen extends StatefulWidget {
  final String eventId;

  const AttendeesScreen({super.key, required this.eventId});

  @override
  State<AttendeesScreen> createState() => _AttendeesScreenState();
}

class _AttendeesScreenState extends State<AttendeesScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch registrations for this event when screen loads
    Future.microtask(() => 
      context.read<RegistrationProvider>().fetchEventRegistrations(widget.eventId)
    );
  }

  @override
  Widget build(BuildContext context) {
    final registrationProvider = context.watch<RegistrationProvider>();
    final eventProvider = context.watch<EventProvider>();
    final event = eventProvider.getEventById(widget.eventId);
    final registrations = registrationProvider.getRegistrationsByEvent(widget.eventId);
    final checkedInCount = registrationProvider.getCheckedInCount(widget.eventId);
    final isLoading = registrationProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(event?.title ?? 'Attendees'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => registrationProvider.fetchEventRegistrations(widget.eventId),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '$checkedInCount/${registrations.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withOpacity(0.05),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Total',
                    value: '${registrations.length}',
                    icon: Icons.people,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Checked In',
                    value: '$checkedInCount',
                    icon: Icons.check_circle,
                    color: AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Pending',
                    value: '${registrations.length - checkedInCount}',
                    icon: Icons.schedule,
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ),

          // Attendee list
          Expanded(
            child: isLoading && registrations.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : registrations.isEmpty
                    ? const EmptyState(
                        icon: Icons.people_outline,
                        title: 'No Registrations Yet',
                        subtitle: 'Share your event to get more attendees',
                      )
                    : RefreshIndicator(
                        onRefresh: () => registrationProvider.fetchEventRegistrations(widget.eventId),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: registrations.length,
                          itemBuilder: (context, index) {
                            final registration = registrations[index];
                            return _AttendeeCard(
                              registration: registration,
                              onCheckIn: () async {
                                if (registration.isCheckedIn) {
                                  await registrationProvider.undoCheckIn(registration.id);
                                } else {
                                  await registrationProvider.checkIn(registration.id);
                                }
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryColor;
    return Column(
      children: [
        Icon(icon, color: c, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: c,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AttendeeCard extends StatelessWidget {
  final Registration registration;
  final VoidCallback onCheckIn;

  const _AttendeeCard({required this.registration, required this.onCheckIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
        border: registration.isCheckedIn
            ? Border.all(color: AppTheme.successColor.withOpacity(0.3), width: 2)
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: registration.isCheckedIn
                ? AppTheme.successColor
                : AppTheme.primaryColor,
            child: Text(
              registration.userName[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  registration.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  registration.userEmail,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registered: ${DateFormat('MMM dd, HH:mm').format(registration.registeredAt)}',
                  style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: registration.isCheckedIn
                  ? AppTheme.textSecondary
                  : AppTheme.successColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(registration.isCheckedIn ? 'Undo' : 'Check In'),
          ),
        ],
      ),
    );
  }
}
