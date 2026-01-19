import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../events/providers/event_provider.dart';
import '../../registration/providers/registration_provider.dart';
import '../../tickets/providers/ticket_provider.dart';
import '../../../shared/widgets/event_card.dart';
import '../../../shared/widgets/common_widgets.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';
import 'events_list_screen.dart';
import '../../registration/screens/my_registrations_screen.dart';
import '../../tickets/screens/my_tickets_screen.dart';

/// Main dashboard screen with role-based content
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final screens = _getScreensForRole(user.role);
    final navItems = _getNavItemsForRole(user.role);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: navItems,
        ),
      ),
    );
  }

  List<Widget> _getScreensForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return [
          const _HomeTab(),
          const EventsListScreen(showAll: true),
          const _UsersTab(),
          const _ProfileTab(),
        ];
      case UserRole.organizer:
        return [
          const _HomeTab(),
          const EventsListScreen(showOwnOnly: true),
          const _ProfileTab(),
        ];
      case UserRole.participant:
        return [
          const _HomeTab(),
          const MyRegistrationsScreen(),
          const MyTicketsScreen(),
          const _ProfileTab(),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavItemsForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
      case UserRole.organizer:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'My Events'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
      case UserRole.participant:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Registered'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ];
    }
  }
}

/// Home tab showing overview and upcoming events
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with greeting
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.heroGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user?.roleDisplayName ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Quick stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _QuickStats(user: user),
            ),
          ),

          // Upcoming events section
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Upcoming Events',
              actionText: 'See All',
              onActionPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EventsListScreen(),
                  ),
                );
              },
            ),
          ),

          // Event list
          eventProvider.upcomingEvents.isEmpty
              ? SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.event_busy,
                    title: 'No Upcoming Events',
                    subtitle: 'Check back later for new events',
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final event = eventProvider.upcomingEvents[index];
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
                    childCount: eventProvider.upcomingEvents.take(3).length,
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
      floatingActionButton: authProvider.canManageEvents
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventFormScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Event'),
            )
          : null,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

/// Quick stats cards
class _QuickStats extends StatelessWidget {
  final User? user;

  const _QuickStats({required this.user});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final registrationProvider = context.watch<RegistrationProvider>();
    final ticketProvider = context.watch<TicketProvider>();

    if (user == null) return const SizedBox.shrink();

    List<_StatCard> stats;

    switch (user!.role) {
      case UserRole.admin:
        stats = [
          _StatCard(
            icon: Icons.event,
            value: '${eventProvider.events.length}',
            label: 'Total Events',
            color: AppTheme.primaryColor,
          ),
          _StatCard(
            icon: Icons.people,
            value: '${context.read<AuthProvider>().allUsers.length}',
            label: 'Users',
            color: AppTheme.secondaryColor,
          ),
          _StatCard(
            icon: Icons.check_circle,
            value: '${eventProvider.publishedEvents.length}',
            label: 'Published',
            color: AppTheme.successColor,
          ),
        ];
        break;
      case UserRole.organizer:
        final myEvents = eventProvider.getEventsByOrganizer(user!.id);
        stats = [
          _StatCard(
            icon: Icons.event,
            value: '${myEvents.length}',
            label: 'My Events',
            color: AppTheme.primaryColor,
          ),
          _StatCard(
            icon: Icons.check_circle,
            value: '${myEvents.where((e) => e.isPublished).length}',
            label: 'Published',
            color: AppTheme.successColor,
          ),
          _StatCard(
            icon: Icons.people,
            value: '${myEvents.fold<int>(0, (sum, e) => sum + registrationProvider.getRegistrationCount(e.id))}',
            label: 'Registrations',
            color: AppTheme.secondaryColor,
          ),
        ];
        break;
      case UserRole.participant:
        stats = [
          _StatCard(
            icon: Icons.bookmark,
            value: '${registrationProvider.getRegistrationsByUser(user!.id).length}',
            label: 'Registered',
            color: AppTheme.primaryColor,
          ),
          _StatCard(
            icon: Icons.confirmation_number,
            value: '${ticketProvider.getTicketsByUser(user!.id).length}',
            label: 'Tickets',
            color: AppTheme.secondaryColor,
          ),
          _StatCard(
            icon: Icons.event_available,
            value: '${eventProvider.upcomingEvents.length}',
            label: 'Upcoming',
            color: AppTheme.successColor,
          ),
        ];
        break;
    }

    return Row(
      children: stats
          .map((stat) => Expanded(child: stat))
          .toList()
          .expand((widget) => [widget, const SizedBox(width: 12)])
          .toList()
        ..removeLast(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Users management tab (Admin only)
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final users = authProvider.allUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getRoleColor(user.role),
                  child: Text(
                    user.name[0].toUpperCase(),
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
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.roleDisplayName,
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppTheme.errorColor;
      case UserRole.organizer:
        return AppTheme.primaryColor;
      case UserRole.participant:
        return AppTheme.secondaryColor;
    }
  }
}

/// Profile tab
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        authProvider.logout();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.roleDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile options
            _ProfileOption(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit profile coming soon!')),
                );
              },
            ),
            _ProfileOption(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon!')),
                );
              },
            ),
            _ProfileOption(
              icon: Icons.security_outlined,
              title: 'Privacy & Security',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy settings coming soon!')),
                );
              },
            ),
            _ProfileOption(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help center coming soon!')),
                );
              },
            ),
            _ProfileOption(
              icon: Icons.info_outline,
              title: 'About',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Smart Event Management',
                  applicationVersion: '1.0.0',
                  applicationIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  children: [
                    const Text(
                      'A comprehensive event management solution for academic projects.',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }
}
