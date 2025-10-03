import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/emergency_case_new.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../widgets/emergency_category_dialog.dart';
import '../auth/login_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE53E3E),
                Color(0xFFCD2E2E),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                SizedBox(height: 24),
                Text(
                  'SafePoint Health',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Initializing...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex.clamp(0, 2),
        children: const [
          _HomeTab(),
          _CasesTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex.clamp(0, 2),
        onTap: (index) {
          if (mounted && index >= 0 && index <= 2) {
            setState(() {
              _selectedIndex = index;
            });
          }
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

class _HomeTab extends StatefulWidget {
  const _HomeTab({Key? key}) : super(key: key);

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _disposed = false;
  double? _currentLatitude;
  double? _currentLongitude;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    // Simulate getting current location - you can implement actual GPS logic here
    // For now, using dummy coordinates
    setState(() {
      _currentLatitude = -6.2088;
      _currentLongitude = 106.8456;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

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
                final isGuest =
                    !authProvider.isAuthenticated || authProvider.user == null;

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFE53E3E),
                      child: Text(
                        isGuest
                            ? 'G'
                            : (authProvider.user!.name.isNotEmpty
                                ? authProvider.user!.name
                                    .substring(0, 1)
                                    .toUpperCase()
                                : 'U'),
                        style: const TextStyle(
                          color: Colors.white,
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
                            isGuest
                                ? 'Hello, Guest'
                                : 'Hello, ${authProvider.user?.name ?? 'User'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Stay safe and connected',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 50),

            // Main SOS Button
            Expanded(
              child: Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFFFF6B6B),
                        Color(0xFFE53E3E),
                        Color(0xFFCD2E2E),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53E3E).withOpacity(0.4),
                        spreadRadius: 8,
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(150),
                      onTap: () => _showCategoryDialog(context),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emergency,
                              size: 80,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tekan untuk bantuan darurat',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 24),
                  SizedBox(height: 8),
                  Text(
                    'Petunjuk Darurat',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tekan tombol SOS dan pilih kategori darurat. Jika tidak memilih dalam 10 detik, akan otomatis masuk kategori umum.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context) {
    if (!mounted || _disposed) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => EmergencyCategoryDialog(
        onCategorySelected: (category) => _reportEmergency(context, category),
      ),
    );
  }

  Future<void> _reportEmergency(
      BuildContext context, EmergencyCategory category) async {
    if (_disposed) return;

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Sending emergency report...'),
            ],
          ),
        ),
      );
    }

    try {
      final emergencyProvider =
          Provider.of<EmergencyProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final isGuest = !authProvider.isAuthenticated || user == null;

      // Check GPS location first
      if (_currentLatitude == null || _currentLongitude == null) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Location Error'),
                ],
              ),
              content: const Text(
                  'Unable to get your current location. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // For guest users, use default phone number or allow emergency without phone
      String phoneNumber;
      if (isGuest) {
        phoneNumber =
            'guest-emergency'; // Special identifier for guest emergencies
      } else {
        phoneNumber = user.phone ?? 'no-phone';
      }

      final success = await emergencyProvider.reportEmergency(
        phone: phoneNumber,
        latitude: _currentLatitude!,
        longitude: _currentLongitude!,
        category: category,
        description: isGuest
            ? 'Emergency reported by guest user from mobile app'
            : 'Emergency reported from mobile app',
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show result dialog
      if (mounted) {
        if (success) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Success'),
                ],
              ),
              content: Text(isGuest
                  ? 'Emergency report sent successfully!\n\nFor better emergency response, consider creating an account to provide contact information.'
                  : 'Emergency report sent successfully!'),
              actions: [
                if (isGuest) ...[
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text('Create Account'),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Error'),
                ],
              ),
              content: const Text('Failed to send emergency report'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Error'),
              ],
            ),
            content: Text('Network error: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class _CasesTab extends StatelessWidget {
  const _CasesTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'My Cases',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your emergency reports will appear here',
            style: TextStyle(color: Colors.grey),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isGuest =
                    !authProvider.isAuthenticated || authProvider.user == null;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          isGuest
                              ? 'G'
                              : (authProvider.user!.name.isNotEmpty
                                  ? authProvider.user!.name
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : 'U'),
                          style: const TextStyle(
                            color: Color(0xFFE53E3E),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isGuest
                            ? 'Guest User'
                            : (authProvider.user?.name ?? 'User Name'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isGuest
                            ? 'Login to access full features'
                            : (authProvider.user?.email ?? 'user@email.com'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isGuest ? 'GUEST' : 'CITIZEN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Conditional content based on authentication status
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isGuest =
                    !authProvider.isAuthenticated || authProvider.user == null;

                if (isGuest) {
                  // Guest mode - show login/register options
                  return Expanded(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Join SafePoint Community',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Login or register to access advanced features like emergency history, profile management, and more.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('Login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53E3E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginScreen(), // TODO: Create RegisterScreen
                                ),
                              );
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Register'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE53E3E),
                              side: const BorderSide(color: Color(0xFFE53E3E)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Continue as Guest info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You can still use emergency SOS features as a guest',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Logged in mode - show profile options
                  return Expanded(
                    child: Column(
                      children: [
                        ListTile(
                          leading:
                              const Icon(Icons.edit, color: Color(0xFFE53E3E)),
                          title: const Text('Edit Profile'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {},
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.history,
                              color: Color(0xFFE53E3E)),
                          title: const Text('Emergency History'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {},
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.settings,
                              color: Color(0xFFE53E3E)),
                          title: const Text('Settings'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {},
                        ),
                        const Divider(),
                        ListTile(
                          leading:
                              const Icon(Icons.help, color: Color(0xFFE53E3E)),
                          title: const Text('Help & Support'),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {},
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Logout'),
                                  content: const Text(
                                      'Are you sure you want to logout?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                              );

                              if (shouldLogout == true && context.mounted) {
                                final authProvider = Provider.of<AuthProvider>(
                                    context,
                                    listen: false);
                                await authProvider.logout();

                                // Stay on citizen home screen (guest mode)
                                // No navigation needed as we'll rebuild with guest UI
                              }
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
