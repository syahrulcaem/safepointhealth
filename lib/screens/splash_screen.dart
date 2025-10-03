import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';
import '../models/user.dart';
import '../services/bluetooth_service.dart';
import 'citizen/citizen_home_screen.dart';
import 'officer/officer_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Add delay for splash screen effect
    await Future.delayed(const Duration(seconds: 2));

    // Initialize authentication (but don't require login)
    await authProvider.initializeAuth();

    // Request Bluetooth permission (Android 12+)
    await _requestBluetoothPermission();

    if (mounted) {
      _navigateToNextScreen();
    }
  }

  Future<void> _requestBluetoothPermission() async {
    try {
      final hasPermission = await BluetoothService.hasBluetoothPermission();

      if (!hasPermission) {
        print('Requesting Bluetooth permission...');
        final granted = await BluetoothService.requestBluetoothPermission();

        if (granted) {
          print('✅ Bluetooth permission granted');
        } else {
          print('❌ Bluetooth permission denied');
        }
      } else {
        print('✅ Bluetooth permission already granted');
      }
    } catch (e) {
      print('Error requesting Bluetooth permission: $e');
    }
  }

  void _navigateToNextScreen() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is logged in as petugas
    if (authProvider.isAuthenticated &&
        authProvider.user != null &&
        authProvider.user?.role == UserRole.PETUGAS) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OfficerDashboardScreen()),
      );
    } else {
      // Default to citizen home (guest mode or citizen)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CitizenHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryRed,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emergency,
                  size: 60,
                  color: AppTheme.primaryRed,
                ),
              ),

              const SizedBox(height: 24),

              // App Name
              const Text(
                'SafePoint',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              const Text(
                'Emergency Response System',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.white,
                  fontWeight: FontWeight.w300,
                ),
              ),

              const SizedBox(height: 48),

              // Loading indicator
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Column(
                    children: [
                      const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        authProvider.isLoading
                            ? 'Initializing...'
                            : 'Loading...',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
