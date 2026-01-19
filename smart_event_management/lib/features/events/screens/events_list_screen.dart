import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/event_card.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

/// Screen displaying list of events with search and filter
class EventsListScreen extends StatefulWidget {
  final bool showAll;
  final bool showOwnOnly;

  const EventsListScreen({
    super.key,
    this.showAll = false,
    this.showOwnOnly = false,
  });

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Event> _getFilteredEvents(EventProvider eventProvider, AuthProvider authProvider) {
    List<Event> events;

    if (widget.showOwnOnly && authProvider.currentUser != null) {
      events = eventProvider.getEventsByOrganizer(authProvider.currentUser!.id);
    } else if (widget.showAll) {
      events = eventProvider.events;
    } else {
      events = eventProvider.publishedEvents;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      events = events.where((e) =>
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.location.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      events = events.where((e) => e.category == _selectedCategory).toList();
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final authProvider = context.watch<AuthProvider>();
    final events = _getFilteredEvents(eventProvider, authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showOwnOnly ? 'My Events' : 'Events'),
        actions: [
          if (authProvider.canManageEvents)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventFormScreen()),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              controller: _searchController,
              hint: 'Search events...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...EventCategories.all.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: category,
                    isSelected: _selectedCategory == category,
                    onTap: () => setState(() => _selectedCategory = category),
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Events list
          Expanded(
            child: events.isEmpty
                ? EmptyState(
                    icon: Icons.event_busy,
                    title: _searchQuery.isNotEmpty || _selectedCategory != null
                        ? 'No Events Found'
                        : 'No Events Yet',
                    subtitle: _searchQuery.isNotEmpty || _selectedCategory != null
                        ? 'Try adjusting your filters'
                        : widget.showOwnOnly
                            ? 'Create your first event'
                            : 'Check back later',
                    action: widget.showOwnOnly && authProvider.canManageEvents
                        ? CustomButton(
                            text: 'Create Event',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const EventFormScreen()),
                              );
                            },
                          )
                        : null,
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      // Simulate refresh
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return EventCard(
                          event: event,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(eventId: event.id),
                              ),
                            );
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
