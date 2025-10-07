import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safepointhealth/models/my_case.dart';
import 'package:safepointhealth/services/my_cases_service.dart';
import '../../config/app_theme.dart';
import '../../models/emergency_case_new.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../services/emergency_cooldown_service.dart';
import '../../services/gps_service.dart';
import '../../services/bluetooth_service.dart';
import '../../services/smartwatch_sos_service.dart';
import '../../widgets/emergency_category_dialog.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'case_detail_screen.dart';

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  // Bluetooth & SmartWatch status
  bool _isBluetoothEnabled = false;
  bool _isXiaomiWatchConnected = false;
  String _watchName = '';
  bool _hasBluetoothPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeBluetoothAndSmartWatch();
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

  Future<void> _initializeBluetoothAndSmartWatch() async {
    // Initialize SmartWatch SOS listener
    SmartWatchSosService.initialize(
      onSosTrigger: (data) async {
        print('🚨 SmartWatch SOS Trigger Received in UI!');

        // Langsung kirim SOS tanpa konfirmasi
        if (mounted) {
          await _triggerEmergencyFromSmartWatch(data);
        }
      },
    );

    // Check Bluetooth status
    await _checkBluetoothStatus();
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      final status = await BluetoothService.getBluetoothStatus();

      if (mounted) {
        setState(() {
          _hasBluetoothPermission = status['hasPermission'] ?? false;
          _isBluetoothEnabled = status['isEnabled'] ?? false;
          _isXiaomiWatchConnected = status['watchConnected'] ?? false;
          _watchName = status['watchName'] ?? '';
        });
      }

      print('Bluetooth Status:');
      print('- Permission: $_hasBluetoothPermission');
      print('- Enabled: $_isBluetoothEnabled');
      print('- Watch Connected: $_isXiaomiWatchConnected');
      print('- Watch Name: $_watchName');
    } catch (e) {
      print('Error checking Bluetooth status: $e');
    }
  }

  void _showSosAlertOverlay(String watchName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.red.withOpacity(0.9),
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing SOS Icon
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  builder: (context, double scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emergency,
                          size: 60,
                          color: Colors.red,
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    // Loop animation - trigger rebuild
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 32),
                const Text(
                  'SOS DARURAT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.watch, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        watchName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mengirim laporan darurat...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _triggerEmergencyFromSmartWatch(
      Map<String, dynamic> data) async {
    try {
      final emergencyProvider =
          Provider.of<EmergencyProvider>(context, listen: false);

      final watchName = data['device'] ?? 'SmartWatch';

      // Show fullscreen SOS alert
      if (mounted) {
        _showSosAlertOverlay(watchName);
      }

      // Trigger emergency report immediately
      final success = await SmartWatchSosService.triggerEmergencyReport(
        emergencyProvider: emergencyProvider,
        description: 'SOS darurat dari smartwatch: $watchName',
        category: EmergencyCategory.KECELAKAAN,
      );

      // Close overlay
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Wait a moment before showing result
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        if (success) {
          // Show success with fullscreen green
          showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.green.withOpacity(0.9),
            builder: (context) => WillPopScope(
              onWillPop: () async => false,
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 60,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'SOS TERKIRIM!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tim darurat akan segera datang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          // Auto close after 3 seconds
          await Future.delayed(const Duration(seconds: 3));
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(emergencyProvider.errorMessage ??
                        '❌ Gagal mengirim SOS'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Error triggering emergency from smartwatch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('❌ Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
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
                SizedBox(height: 18),
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
  bool _canReportEmergency = true;
  int _remainingCooldownSeconds = 0;
  bool _isLoadingLocation = true;
  String? _locationError;

  // Bluetooth & SmartWatch status
  bool _isBluetoothEnabled = false;
  bool _isXiaomiWatchConnected = false;
  String _watchName = '';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _checkCooldownStatus();
    _checkBluetoothStatus();
  }

  Future<void> _checkBluetoothStatus() async {
    try {
      final status = await BluetoothService.getBluetoothStatus();

      if (mounted) {
        setState(() {
          _isBluetoothEnabled = status['isEnabled'] ?? false;
          _isXiaomiWatchConnected = status['watchConnected'] ?? false;
          _watchName = status['watchName'] ?? '';
        });
      }
    } catch (e) {
      print('Error checking Bluetooth status: $e');
    }
  }

  Future<void> _initializeLocation() async {
    await _checkAndRequestPermissions();
    await _getCurrentLocation();
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      // Check if GPS is enabled
      final isGpsEnabled = await GpsService.isGpsEnabled();
      if (!isGpsEnabled) {
        if (mounted) {
          setState(() {
            _locationError = 'GPS is not enabled. Please enable GPS.';
            _isLoadingLocation = false;
          });
        }
        return;
      }

      // Check if we have location permission
      final hasPermission = await GpsService.hasLocationPermission();
      if (!hasPermission) {
        // Request permission
        final granted = await GpsService.requestLocationPermission();
        if (!granted) {
          if (mounted) {
            setState(() {
              _locationError = 'Location permission denied.';
              _isLoadingLocation = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Error checking permissions: $e';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _isLoadingLocation = true;
        _locationError = null;
      });

      // Get current location from GPS device
      final location = await GpsService.getCurrentLocation();

      if (location != null && mounted) {
        setState(() {
          _currentLatitude = location['latitude'];
          _currentLongitude = location['longitude'];
          _isLoadingLocation = false;
          _locationError = null;
        });

        print(
            '📍 GPS Location: Lat: $_currentLatitude, Lng: $_currentLongitude');
      } else {
        if (mounted) {
          setState(() {
            _locationError = 'Unable to get GPS location';
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Error getting location: $e';
          _isLoadingLocation = false;
        });
      }
      print('❌ Error getting GPS location: $e');
    }
  }

  Future<void> _checkCooldownStatus() async {
    final canReport = await EmergencyCooldownService.canReportEmergency();
    final remaining =
        await EmergencyCooldownService.getRemainingCooldownSeconds();

    if (mounted) {
      setState(() {
        _canReportEmergency = canReport;
        _remainingCooldownSeconds = remaining;
      });

      // If in cooldown, start countdown timer
      if (!canReport && remaining > 0) {
        _startCooldownTimer();
      }
    }
  }

  void _startCooldownTimer() {
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted || _disposed) return;

      final remaining =
          await EmergencyCooldownService.getRemainingCooldownSeconds();
      setState(() {
        _remainingCooldownSeconds = remaining;
        _canReportEmergency = remaining <= 0;
      });

      if (remaining > 0) {
        _startCooldownTimer();
      }
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
                            isGuest ? 'Halo, Teman' : 'Halo, Teman',
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

            const SizedBox(height: 20),

            // GPS Status Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isLoadingLocation
                    ? Colors.blue.shade50
                    : (_locationError != null
                        ? Colors.red.shade50
                        : Colors.green.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isLoadingLocation
                      ? Colors.blue.shade200
                      : (_locationError != null
                          ? Colors.red.shade200
                          : Colors.green.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isLoadingLocation
                        ? Icons.gps_not_fixed
                        : (_locationError != null
                            ? Icons.gps_off
                            : Icons.gps_fixed),
                    color: _isLoadingLocation
                        ? Colors.blue
                        : (_locationError != null ? Colors.red : Colors.green),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isLoadingLocation
                          ? 'Getting GPS location...'
                          : (_locationError != null
                              ? _locationError!
                              : 'GPS Ready'),
                      style: TextStyle(
                        fontSize: 12,
                        color: _isLoadingLocation
                            ? Colors.blue.shade700
                            : (_locationError != null
                                ? Colors.red.shade700
                                : Colors.green.shade700),
                      ),
                    ),
                  ),
                  if (_locationError != null)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _getCurrentLocation,
                      color: Colors.red.shade700,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bluetooth & SmartWatch Status Indicator
            _buildBluetoothStatusCard(),

            const SizedBox(height: 20),

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
                      onTap: _canReportEmergency
                          ? () => _showCategoryDialog(context)
                          : null,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // SOS Text - Large and bold
                            Text(
                              _canReportEmergency ? 'SOS' : 'WAIT',
                              style: TextStyle(
                                color: _canReportEmergency
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _canReportEmergency
                                  ? 'Tekan untuk bantuan darurat'
                                  : 'Cooldown: ${EmergencyCooldownService.formatRemainingTime(_remainingCooldownSeconds)}',
                              style: const TextStyle(
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

  Widget _buildBluetoothStatusCard() {
    if (!_isBluetoothEnabled) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.bluetooth_disabled,
                color: Colors.grey.shade600, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bluetooth Mati',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Aktifkan untuk menghubungkan smartwatch',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_isXiaomiWatchConnected) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.watch, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SmartWatch Terhubung',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _watchName.isNotEmpty ? _watchName : 'Xiaomi Watch',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'SOS Ready',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Bluetooth enabled but no watch connected
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.bluetooth_searching,
              color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bluetooth Aktif',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Menunggu koneksi Xiaomi Watch',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            color: Colors.blue.shade700,
            onPressed: _checkBluetoothStatus,
          ),
        ],
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

      print('\n🚨 === EMERGENCY REPORT DEBUG ===');
      print('👤 Is Guest: $isGuest');
      print('🔐 Is Authenticated: ${authProvider.isAuthenticated}');
      print('👤 User: ${user?.name ?? "null"} (${user?.email ?? "null"})');
      print('📱 Phone: ${user?.phone ?? "null"}');
      print('================================\n');

      // Check cooldown first
      final canReport = await EmergencyCooldownService.canReportEmergency();
      if (!canReport) {
        // Close loading dialog
        if (mounted) Navigator.pop(context);

        final remaining =
            await EmergencyCooldownService.getRemainingCooldownMinutes();
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Cooldown Active'),
                ],
              ),
              content: Text(
                  'Please wait $remaining minutes before reporting another emergency.\n\nThis cooldown helps prevent accidental multiple reports.'),
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

      // Check GPS location
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

      // Choose endpoint based on authentication status
      bool success;

      if (isGuest) {
        // Guest user - use public endpoint (no authentication)
        print('📡 Sending emergency as GUEST (public endpoint)');
        success = await emergencyProvider.reportPublicEmergency(
          latitude: _currentLatitude!,
          longitude: _currentLongitude!,
          category: category,
          description: 'Emergency reported by guest user from mobile app',
          phone: null,
          accuracy: 10.0,
        );
      } else {
        // Logged in user - use authenticated endpoint
        print(
            '📡 Sending emergency as LOGGED IN USER: ${user.name} (${user.email})');
        success = await emergencyProvider.reportEmergency(
          phone: user.phone ?? '', // Use empty string if phone is null
          latitude: _currentLatitude!,
          longitude: _currentLongitude!,
          category: category,
          description: 'Emergency reported by ${user.name} from mobile app',
          accuracy: 10.0,
        );
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Refresh cooldown status after successful report
      if (success) {
        await _checkCooldownStatus();
      }

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
                  ? 'Emergency report sent successfully!\n\n⏱️ 30-minute cooldown activated\n\nFor better emergency response, consider creating an account to provide contact information.'
                  : 'Emergency report sent successfully!\n\n⏱️ 30-minute cooldown activated'),
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

class _CasesTab extends StatefulWidget {
  const _CasesTab();

  @override
  State<_CasesTab> createState() => _CasesTabState();
}

class _CasesTabState extends State<_CasesTab> {
  MyCasesResponse? _casesData;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCases();
    // Auto refresh every 10 seconds untuk real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadCases(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCases({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await MyCasesService.getMyCases();

      if (mounted) {
        setState(() {
          _casesData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.PENDING:
      case EmergencyStatus.NEW:
        return Colors.orange;
      case EmergencyStatus.DISPATCHED:
      case EmergencyStatus.ON_THE_WAY:
        return Colors.blue;
      case EmergencyStatus.ON_SCENE:
        return Colors.purple;
      case EmergencyStatus.RESOLVED:
        return Colors.green;
      case EmergencyStatus.CANCELLED:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.PENDING:
        return 'Menunggu';
      case EmergencyStatus.NEW:
        return 'Baru';
      case EmergencyStatus.VERIFIED:
        return 'Terverifikasi';
      case EmergencyStatus.DISPATCHED:
        return 'Dikirim';
      case EmergencyStatus.ON_THE_WAY:
        return 'Dalam Perjalanan';
      case EmergencyStatus.ON_SCENE:
        return 'Di Lokasi';
      case EmergencyStatus.RESOLVED:
        return 'Selesai';
      case EmergencyStatus.CANCELLED:
        return 'Dibatalkan';
      default:
        return status.toString();
    }
  }

  String _getCategoryText(EmergencyCategory category) {
    switch (category) {
      case EmergencyCategory.MEDIS:
        return 'Medis';
      case EmergencyCategory.UMUM:
        return 'Umum';
      case EmergencyCategory.KECELAKAAN:
        return 'Kecelakaan';
      case EmergencyCategory.KEBOCORAN_GAS:
        return 'Kebocoran Gas';
      case EmergencyCategory.BENCANA_ALAM:
        return 'Bencana Alam';
      case EmergencyCategory.SAKIT:
        return 'Sakit';
      case EmergencyCategory.POHON_TUMBANG:
        return 'Pohon Tumbang';
      case EmergencyCategory.BANJIR:
        return 'Banjir';
      default:
        return category.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading cases',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCases,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final cases = _casesData?.cases.data ?? [];

    if (cases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Cases Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your emergency reports will appear here',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCases,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // AppBar/Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Cases',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadCases,
                  tooltip: 'Refresh',
                  iconSize: 28,
                ),
              ],
            ),
          ),
        ),
        // Cases List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadCases(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cases.length,
              itemBuilder: (context, index) {
                final caseItem = cases[index];
                final statusColor = _getStatusColor(caseItem.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CaseDetailScreen(caseItem: caseItem),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Case ID dan Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '#${caseItem.shortId}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getStatusText(caseItem.status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Category
                          Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getCategoryText(caseItem.category),
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Location
                          if (caseItem.location != null) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    caseItem.location!,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Timestamp
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDateTime(caseItem.createdAt),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),

                          // Assigned Unit (jika ada)
                          if (caseItem.assignedUnit != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    caseItem.assignedUnit!.name,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
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
                            : (authProvider.user?.email ?? 'Pelapor'),
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
                          isGuest ? 'GUEST' : 'WARGA',
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
                          onTap: () async {
                            print('🔘 Edit Profile button tapped');

                            // Verify authentication before navigating
                            final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false);

                            if (!authProvider.isAuthenticated ||
                                authProvider.user == null) {
                              print('❌ User not authenticated, showing error');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Please login to edit your profile'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            print(
                                '✅ User authenticated, navigating to EditProfileScreen');

                            try {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              );
                              print('✅ Returned from EditProfileScreen');
                            } catch (e) {
                              print(
                                  '❌ Error navigating to EditProfileScreen: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
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
