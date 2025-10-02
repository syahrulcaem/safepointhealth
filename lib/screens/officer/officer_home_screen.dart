import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/location_provider.dart';
import '../../config/app_theme.dart';
import '../../models/emergency_case_new.dart';
import '../auth/login_screen.dart';

class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({Key? key}) : super(key: key);

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final emergencyProvider =
        Provider.of<EmergencyProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);

    // Get assigned cases and start location tracking
    await Future.wait([
      emergencyProvider.getAssignedCases(),
      locationProvider.getCurrentLocation(),
    ]);

    // Start location tracking for officers
    locationProvider.startLocationTracking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardTab(),
          _CasesTab(),
          _MapTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Cases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryBlue,
                      child: Text(
                        authProvider.user?.name.substring(0, 1).toUpperCase() ??
                            'O',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Officer ${authProvider.user?.name ?? 'User'}',
                            style: AppTheme.heading3,
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.successGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'On Duty',
                                style: TextStyle(
                                  color: AppTheme.successGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Add notifications
                      },
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _StatsCard(
                    title: 'Active Cases',
                    value: '3',
                    color: AppTheme.primaryRed,
                    icon: Icons.emergency,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatsCard(
                    title: 'Resolved Today',
                    value: '8',
                    color: AppTheme.successGreen,
                    icon: Icons.check_circle,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StatsCard(
                    title: 'Pending',
                    value: '5',
                    color: AppTheme.warningYellow,
                    icon: Icons.pending,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatsCard(
                    title: 'Total This Week',
                    value: '42',
                    color: AppTheme.primaryBlue,
                    icon: Icons.assessment,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: AppTheme.heading3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.play_arrow,
                            label: 'Start Duty',
                            color: AppTheme.successGreen,
                            onTap: () {
                              // TODO: Start duty
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.stop,
                            label: 'End Duty',
                            color: AppTheme.dangerRed,
                            onTap: () {
                              // TODO: End duty
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.location_on,
                            label: 'Update Location',
                            color: AppTheme.primaryBlue,
                            onTap: () {
                              // TODO: Update location
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.report,
                            label: 'Create Report',
                            color: AppTheme.warningYellow,
                            onTap: () {
                              // TODO: Create report
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Cases
            const Text(
              'Recent Cases',
              style: AppTheme.heading3,
            ),

            const SizedBox(height: 16),

            Consumer<EmergencyProvider>(
              builder: (context, emergencyProvider, child) {
                if (emergencyProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final recentCases = emergencyProvider.cases.take(3).toList();

                if (recentCases.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No recent cases',
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: recentCases.map((emergencyCase) {
                    final categoryInfo = emergencyProvider
                        .getCategoryInfo(emergencyCase.category);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(categoryInfo['color']),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              categoryInfo['icon'],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        title: Text(emergencyCase.categoryDisplayName),
                        subtitle: Text(
                          emergencyCase.description ?? 'Tidak ada deskripsi',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(emergencyProvider
                                .getStatusColor(emergencyCase.status)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            emergencyCase.statusDisplayName,
                            style: const TextStyle(
                              color: AppTheme.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        onTap: () {
                          // TODO: Navigate to case details
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const Spacer(),
                Text(
                  value,
                  style: AppTheme.heading2.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.grey600),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CasesTab extends StatelessWidget {
  const _CasesTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          AppBar(
            title: const Text('Assigned Cases'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppTheme.grey900,
          ),
          Expanded(
            child: Consumer<EmergencyProvider>(
              builder: (context, emergencyProvider, child) {
                if (emergencyProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (emergencyProvider.cases.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: AppTheme.grey400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No assigned cases',
                          style: AppTheme.heading3,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'New case assignments will appear here',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: emergencyProvider.getAssignedCases,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: emergencyProvider.cases.length,
                    itemBuilder: (context, index) {
                      final emergencyCase = emergencyProvider.cases[index];
                      final categoryInfo = emergencyProvider
                          .getCategoryInfo(emergencyCase.category);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(categoryInfo['color']),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                categoryInfo['icon'],
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          title: Text(emergencyCase.categoryDisplayName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(emergencyCase.description ??
                                  'Tidak ada deskripsi'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Color(
                                          emergencyProvider.getStatusColor(
                                              emergencyCase.status)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      emergencyCase.statusDisplayName,
                                      style: const TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: AppTheme.grey400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '2 min ago', // TODO: Calculate actual time
                                    style: AppTheme.bodySmall
                                        .copyWith(color: AppTheme.grey400),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            // TODO: Navigate to case details
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          AppBar(
            title: const Text('Cases Map'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppTheme.grey900,
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppTheme.grey100,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: AppTheme.grey400,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Map View',
                      style: AppTheme.heading3,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Google Maps integration coming soon',
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          return Column(
            children: [
              AppBar(
                title: const Text('Profile'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: AppTheme.grey900,
                actions: [
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const ListTile(
                          leading: Icon(Icons.logout),
                          title: Text('Logout'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () => _logout(context, authProvider),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Header
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.primaryBlue,
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'O',
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Officer ${user?.name ?? 'User'}',
                        style: AppTheme.heading2,
                      ),
                      Text(
                        user?.email ?? '',
                        style: AppTheme.bodyMedium
                            .copyWith(color: AppTheme.grey500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              user?.role.toString().split('.').last ??
                                  'PETUGAS',
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: AppTheme.successGreen,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'ON DUTY',
                                  style: TextStyle(
                                    color: AppTheme.successGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Profile Information
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.phone),
                              title: const Text('Phone'),
                              subtitle: Text(user?.phone ?? ''),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.email),
                              title: const Text('Email'),
                              subtitle: Text(user?.email ?? ''),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.badge),
                              title: const Text('Unit ID'),
                              subtitle: Text(user?.unitId ?? 'Not assigned'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Actions
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('Edit Profile'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // TODO: Navigate to edit profile
                              },
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.schedule),
                              title: const Text('Duty Schedule'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // TODO: Navigate to duty schedule
                              },
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.assessment),
                              title: const Text('Performance Report'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // TODO: Navigate to performance report
                              },
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.settings),
                              title: const Text('Settings'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // TODO: Navigate to settings
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _logout(BuildContext context, AuthProvider authProvider) {
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
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
