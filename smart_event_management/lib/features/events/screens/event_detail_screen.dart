import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../registration/providers/registration_provider.dart';
import '../../schedule/providers/schedule_provider.dart';
import '../../schedule/screens/schedule_screen.dart';
import '../../tickets/providers/ticket_provider.dart';
import '../../tickets/screens/ticket_selection_screen.dart';
import '../../registration/screens/attendees_screen.dart';
import '../providers/event_provider.dart';
import 'event_form_screen.dart';

/// Detailed view of a single event
class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data once when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ScheduleProvider>().fetchSessions(widget.eventId);
        context.read<RegistrationProvider>().fetchEventRegistrations(widget.eventId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final authProvider = context.watch<AuthProvider>();
    final registrationProvider = context.watch<RegistrationProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();
    final ticketProvider = context.watch<TicketProvider>();

    final event = eventProvider.getEventById(widget.eventId);

    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.error_outline,
          title: 'Event Not Found',
          subtitle: 'This event may have been deleted',
        ),
      );
    }

    final user = authProvider.currentUser;
    final isOrganizer = user?.id == event.organizerId;
    final isAdmin = authProvider.isAdmin;
    final canManage = isOrganizer || isAdmin;
    final registrationCount = registrationProvider.getRegistrationCount(widget.eventId);
    final sessionCount = scheduleProvider.getSessionsByEvent(widget.eventId).length;
    final hasTicket = user != null && ticketProvider.hasTicket(user.id, widget.eventId);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: _getCategoryGradient(event.category)),
                child: Stack(
                  children: [
                    Positioned(
                      left: 20, right: 20, bottom: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Badge(text: event.category),
                              if (!event.isPublished) ...[
                                const SizedBox(width: 8),
                                _Badge(text: 'Draft', color: AppTheme.warningColor),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (canManage) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EventFormScreen(event: event)),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'toggle_publish') {
                      await eventProvider.togglePublish(widget.eventId);
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Event'),
                          content: const Text('Are you sure?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await eventProvider.deleteEvent(widget.eventId);
                        Navigator.pop(context);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'toggle_publish',
                      child: Text(event.isPublished ? 'Unpublish' : 'Publish'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _InfoCard(icon: Icons.calendar_today, title: 'Date', value: DateFormat('MMM dd, yyyy').format(event.date))),
                      const SizedBox(width: 12),
                      Expanded(child: _InfoCard(icon: Icons.access_time, title: 'Time', value: DateFormat('HH:mm').format(event.date))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _InfoCard(icon: Icons.people, title: 'Capacity', value: '$registrationCount / ${event.capacity}')),
                      const SizedBox(width: 12),
                      Expanded(child: _InfoCard(icon: Icons.schedule, title: 'Sessions', value: '$sessionCount')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _LocationCard(location: event.location),
                  const SizedBox(height: 16),
                  _OrganizerCard(name: event.organizerName),
                  const SizedBox(height: 24),
                  const Text('About this event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(event.description, style: const TextStyle(color: AppTheme.textSecondary, height: 1.6)),
                  const SizedBox(height: 24),
                  if (canManage) ...[
                    const Text('Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _ActionButton(
                      icon: Icons.people,
                      title: 'View Attendees',
                      subtitle: '$registrationCount registered',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendeesScreen(eventId: widget.eventId))),
                    ),
                    const SizedBox(height: 8),
                  ],
                  _ActionButton(
                    icon: Icons.calendar_month,
                    title: 'View Schedule',
                    subtitle: '$sessionCount sessions',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleScreen(eventId: widget.eventId, canEdit: canManage))),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: !canManage && authProvider.isParticipant
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(hasTicket ? 'You have a ticket' : 'Register now', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          Text('${event.capacity - registrationCount} spots left', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    CustomButton(
                      text: hasTicket ? 'View Ticket' : 'Get Ticket',
                      useGradient: true,
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TicketSelectionScreen(eventId: widget.eventId))),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  LinearGradient _getCategoryGradient(String category) {
    switch (category) {
      case 'Conference': return const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]);
      case 'Workshop': return const LinearGradient(colors: [Color(0xFF11998E), Color(0xFF38EF7D)]);
      case 'Seminar': return const LinearGradient(colors: [Color(0xFFF093FB), Color(0xFFF5576C)]);
      default: return AppTheme.primaryGradient;
    }
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color? color;
  const _Badge({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ])),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String location;
  const _LocationCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(26), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.location_on, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Location', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Text(location, style: const TextStyle(fontWeight: FontWeight.w600)),
          ])),
        ],
      ),
    );
  }
}

class _OrganizerCard extends StatelessWidget {
  final String name;
  const _OrganizerCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: AppTheme.primaryColor, child: Text(name[0], style: const TextStyle(color: Colors.white))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Organized by', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          ])),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.cardColor, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withAlpha(26), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ])),
            const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
