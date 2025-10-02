import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/location_provider.dart';
import '../../config/app_theme.dart';
import '../../models/emergency_case_new.dart';
import '../auth/login_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({Key? key}) : super(key: key);

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
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

    // Get user's cases and current location
    await Future.wait([
      emergencyProvider.getMyCases(),
      locationProvider.getCurrentLocation(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HomeTab(),
          _CasesTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'My Cases',
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

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
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
                      backgroundColor: AppTheme.primaryRed,
                      child: Text(
                        authProvider.user?.name.substring(0, 1).toUpperCase() ??
                            'U',
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
                            'Hello, ${authProvider.user?.name ?? 'User'}',
                            style: AppTheme.heading3,
                          ),
                          const Text(
                            'Stay safe and connected',
                            style: AppTheme.bodyMedium,
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

            const SizedBox(height: 32),

            // SOS Button
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryRed, AppTheme.dangerRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryRed.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showEmergencyDialog(context),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emergency,
                          size: 64,
                          color: AppTheme.white,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'SOS',
                          style: AppTheme.sosButton,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap for Emergency',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Categories
            const Text(
              'Emergency Categories',
              style: AppTheme.heading3,
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Consumer<EmergencyProvider>(
                builder: (context, emergencyProvider, child) {
                  final categories = emergencyProvider.getEmergencyCategories();

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final categoryInfo =
                          emergencyProvider.getCategoryInfo(category);

                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _reportEmergency(context, category),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  categoryInfo['icon'],
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  categoryInfo['name'],
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Report'),
        content: const Text(
            'This will immediately report an emergency to the authorities. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reportEmergency(context, EmergencyCategory.SAKIT);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
            ),
            child: const Text('Report Emergency'),
          ),
        ],
      ),
    );
  }

  void _reportEmergency(
      BuildContext context, EmergencyCategory category) async {
    final emergencyProvider =
        Provider.of<EmergencyProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Sending emergency report...'),
          ],
        ),
      ),
    );

    try {
      // Get current location
      print('🌍 Getting current location...');
      final locationData = await locationProvider.getCurrentLocation();

      if (locationData == null ||
          locationProvider.latitude == null ||
          locationProvider.longitude == null) {
        print('❌ Failed to get location');
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Unable to get location. Please enable location services.'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
        return;
      }

      final lat = locationProvider.latitude!;
      final lon = locationProvider.longitude!;
      final user = authProvider.user;

      print('📍 Location: $lat, $lon');
      print('📞 Phone: ${user?.phone}');
      print('🚨 Category: $category');

      // Report emergency dengan default description
      final success = await emergencyProvider.reportEmergency(
        phone: user?.phone ?? '',
        latitude: lat,
        longitude: lon,
        category: category,
        description: 'Keadaan darurat - butuh bantuan segera!',
        accuracy: 10.0, // Default accuracy
      );

      print('✅ Emergency report result: $success');
      Navigator.pop(context); // Close loading dialog

      if (success) {
        print('🎉 Success! Showing success message');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency reported successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );

        // Refresh cases
        await emergencyProvider.getMyCases();
      } else {
        print('❌ Failed! Error: ${emergencyProvider.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                emergencyProvider.errorMessage ?? 'Failed to report emergency'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } catch (e) {
      print('💥 Exception in _reportEmergency: $e');
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
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
            title: const Text('My Cases'),
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

                if (emergencyProvider.myCases.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: AppTheme.grey400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No cases found',
                          style: AppTheme.heading3,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your emergency reports will appear here',
                          style: AppTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: emergencyProvider.getMyCases,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: emergencyProvider.myCases.length,
                    itemBuilder: (context, index) {
                      final emergencyCase = emergencyProvider.myCases[index];
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
                              Container(
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
                        backgroundColor: AppTheme.primaryRed,
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'User',
                        style: AppTheme.heading2,
                      ),
                      Text(
                        user?.email ?? '',
                        style: AppTheme.bodyMedium
                            .copyWith(color: AppTheme.grey500),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          user?.role.toString().split('.').last ?? 'CITIZEN',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                              leading: const Icon(Icons.family_restroom),
                              title: const Text('Emergency Contacts'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // TODO: Navigate to emergency contacts
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
