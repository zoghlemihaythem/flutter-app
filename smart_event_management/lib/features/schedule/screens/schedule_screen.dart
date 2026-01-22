import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../events/providers/event_provider.dart';
import '../models/session_model.dart';
import '../providers/schedule_provider.dart';
import 'session_form_screen.dart';

/// Schedule screen displaying event agenda
class ScheduleScreen extends StatefulWidget {
  final String eventId;
  final bool canEdit;

  const ScheduleScreen({
    super.key,
    required this.eventId,
    this.canEdit = false,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<DateTime> _eventDates = [];

  @override
  void initState() {
    super.initState();
    // Pre-initialize with length 1 to avoid "late initialization" error in build
    _tabController = TabController(length: 1, vsync: this);
    _fetchSessionsAndInit();
  }

  Future<void> _fetchSessionsAndInit() async {
    final scheduleProvider = context.read<ScheduleProvider>();
    await scheduleProvider.fetchSessions(widget.eventId);
    if (mounted) {
      _initTabs();
    }
  }

  void _initTabs() {
    final scheduleProvider = context.read<ScheduleProvider>();
    _eventDates = scheduleProvider.getEventDates(widget.eventId);
    if (_eventDates.isEmpty) {
      final eventProvider = context.read<EventProvider>();
      final event = eventProvider.getEventById(widget.eventId);
      if (event != null) {
        _eventDates = [event.date];
      }
    }
    
    // Create new tab controller with correct length
    final oldController = _tabController;
    _tabController = TabController(length: _eventDates.length.clamp(1, 10), vsync: this);
    setState(() {}); // Refresh UI with new controller
    
    // Clean up old controller if it exists (though it might not on first run)
    try {
      oldController.dispose();
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final eventProvider = context.watch<EventProvider>();
    final event = eventProvider.getEventById(widget.eventId);
    final allSessions = scheduleProvider.getSessionsByEvent(widget.eventId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        bottom: _eventDates.length > 1
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _eventDates.map((date) => Tab(
                  text: DateFormat('MMM dd').format(date),
                )).toList(),
              )
            : null,
      ),
      body: allSessions.isEmpty
          ? EmptyState(
              icon: Icons.schedule,
              title: 'No Sessions Yet',
              subtitle: widget.canEdit
                  ? 'Add sessions to create the event schedule'
                  : 'Schedule will be announced soon',
              action: widget.canEdit
                  ? CustomButton(
                      text: 'Add Session',
                      onPressed: () => _addSession(context),
                    )
                  : null,
            )
          : _eventDates.length > 1
              ? TabBarView(
                  controller: _tabController,
                  children: _eventDates.map((date) {
                    final sessions = scheduleProvider.getSessionsByDate(widget.eventId, date);
                    return _SessionList(
                      sessions: sessions,
                      canEdit: widget.canEdit,
                      eventId: widget.eventId,
                    );
                  }).toList(),
                )
              : _SessionList(
                  sessions: allSessions,
                  canEdit: widget.canEdit,
                  eventId: widget.eventId,
                ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton(
              onPressed: () => _addSession(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _addSession(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionFormScreen(eventId: widget.eventId),
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  final List<Session> sessions;
  final bool canEdit;
  final String eventId;

  const _SessionList({
    required this.sessions,
    required this.canEdit,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _SessionCard(
          session: session,
          canEdit: canEdit,
          isFirst: index == 0,
          isLast: index == sessions.length - 1,
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final bool canEdit;
  final bool isFirst;
  final bool isLast;

  const _SessionCard({
    required this.session,
    required this.canEdit,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.read<ScheduleProvider>();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(
                  DateFormat('HH:mm').format(session.startTime),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session.formattedDuration,
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: isLast ? Colors.transparent : AppTheme.dividerColor,
                  ),
                ),
              ],
            ),
          ),

          // Session card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: AppTheme.cardShadow,
                border: session.isOngoing
                    ? Border.all(color: AppTheme.successColor, width: 2)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (session.isOngoing)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NOW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (canEdit)
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SessionFormScreen(
                                    eventId: session.eventId,
                                    session: session,
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Session'),
                                  content: const Text('Are you sure?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await scheduleProvider.deleteSession(session.id);
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                    ],
                  ),
                  if (session.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      session.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          session.speaker,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (session.location != null) ...[
                        const Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          session.location!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
