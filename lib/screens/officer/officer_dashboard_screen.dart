import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/petugas_service.dart';
import '../../services/location_tracking_service.dart';
import '../../models/emergency_case.dart';
import '../citizen/citizen_home_screen.dart';
import 'case_detail_screen.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  int _selectedIndex = 0;
  List<EmergencyCase> _assignedCases = [];
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    print('🚀 OfficerDashboard: initState called');
    _initializeData();
    _listenToUpdates();
  }

  void _initializeData() async {
    print('🔧 Initializing dashboard data...');

    // Wait a bit for authentication to complete
    await Future.delayed(const Duration(milliseconds: 500));

    // Start polling for updates
    PetugasService.startPolling();

    // Start location tracking
    final trackingStarted = await LocationTrackingService.startTracking();
    if (trackingStarted) {
      print('✅ Location tracking started');
    } else {
      print('❌ Failed to start location tracking');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Gagal mengaktifkan tracking lokasi. Periksa izin lokasi.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    try {
      await _loadDashboardData();
    } catch (e) {
      print('❌ Error in _initializeData: $e');
    }
  }

  void _listenToUpdates() {
    // Listen to unread count updates
    PetugasService.unreadCountStream.listen((unreadCount) {
      if (mounted) {
        setState(() {
          _unreadCount = unreadCount.unreadCount;
        });

        // Show notification for new assignments
        if (unreadCount.hasNewAssignments && unreadCount.unreadCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ada ${unreadCount.unreadCount} kasus baru!'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Lihat',
                textColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1; // Switch to cases tab
                  });
                  _loadDashboardData(); // Reload data
                },
              ),
            ),
          );
        }
      }
    });

    // Listen to check updates
    PetugasService.updatesStream.listen((updates) {
      if (mounted && updates.hasUpdates) {
        // Reload cases if there are updates
        _loadAssignedCases();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load assigned cases
      await _loadAssignedCases();

      // Load unread count
      final unreadResponse = await PetugasService.getUnreadCount();
      if (unreadResponse.success && unreadResponse.data != null) {
        setState(() {
          _unreadCount = unreadResponse.data!.unreadCount;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAssignedCases() async {
    print('🔄 Loading assigned cases...');
    final casesResponse = await PetugasService.getAssignedCases();
    print(
        '📦 Cases response - Success: ${casesResponse.success}, Data count: ${casesResponse.data?.length ?? 0}');

    if (casesResponse.success) {
      setState(() {
        _assignedCases = casesResponse.data ?? [];
      });
      print('✅ Assigned cases loaded: ${_assignedCases.length} cases');
      if (_assignedCases.isNotEmpty) {
        print(
            '📋 First case: ${_assignedCases[0].id} - ${_assignedCases[0].category} - ${_assignedCases[0].status}');
      }
    } else {
      print('❌ Failed to load cases: ${casesResponse.message}');
    }
  }

  @override
  void dispose() {
    PetugasService.stopPolling();
    LocationTrackingService.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard Petugas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Keluar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildDashboardTab() : _buildCasesTab(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index <= 1) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Kasus',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatusCard() {
    final isTracking = LocationTrackingService.isTracking;
    final lastUpdate = LocationTrackingService.lastUpdateTime;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTracking ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTracking ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isTracking ? Icons.location_on : Icons.location_off,
            color: isTracking ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTracking ? 'Tracking Aktif' : 'Tracking Tidak Aktif',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isTracking
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                  ),
                ),
                if (isTracking && lastUpdate != null)
                  Text(
                    'Update terakhir: ${_formatLastUpdate(lastUpdate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                if (!isTracking)
                  Text(
                    'Lokasi tidak terkirim ke sistem',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          ),
          if (!isTracking)
            TextButton(
              onPressed: () async {
                final started = await LocationTrackingService.startTracking();
                if (mounted) {
                  setState(() {});
                  if (started) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tracking lokasi diaktifkan'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Aktifkan'),
            ),
        ],
      ),
    );
  }

  String _formatLastUpdate(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} detik lalu';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else {
      return '${diff.inHours} jam lalu';
    }
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Tracking Status
            _buildLocationStatusCard(),
            const SizedBox(height: 16),

            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                authProvider.user?.name
                                        .substring(0, 1)
                                        .toUpperCase() ??
                                    'P',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Halo, ${authProvider.user?.name ?? "Petugas"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Bertugas',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.notifications_active,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Cards
            const Text(
              'Statistik Kasus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Kasus',
                    value: _assignedCases.length.toString(),
                    icon: Icons.assignment,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Ditugaskan',
                    value: _assignedCases
                        .where((c) => c.status == EmergencyStatus.DISPATCHED)
                        .length
                        .toString(),
                    icon: Icons.work,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Dalam Proses',
                    value: _assignedCases
                        .where((c) =>
                            c.status == EmergencyStatus.ON_THE_WAY ||
                            c.status == EmergencyStatus.ON_SCENE)
                        .length
                        .toString(),
                    icon: Icons.pending,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Selesai',
                    value: _assignedCases
                        .where((c) => c.status == EmergencyStatus.RESOLVED)
                        .length
                        .toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Cases Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kasus Terbaru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Lihat Semua'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Recent cases list (max 3)
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: Color(0xFF2E7D32),
                  ),
                ),
              )
            else if (_assignedCases.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada kasus ditugaskan',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _assignedCases
                    .take(3)
                    .map((case_) => _buildCaseCardCompact(case_))
                    .toList(),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCardCompact(EmergencyCase case_) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (case_.status) {
      case EmergencyStatus.DISPATCHED:
        statusColor = Colors.blue;
        statusText = 'Ditugaskan';
        statusIcon = Icons.work;
        break;
      case EmergencyStatus.ON_THE_WAY:
        statusColor = Colors.indigo;
        statusText = 'Dalam Perjalanan';
        statusIcon = Icons.directions_run;
        break;
      case EmergencyStatus.ON_SCENE:
        statusColor = Colors.teal;
        statusText = 'Di Lokasi';
        statusIcon = Icons.location_on;
        break;
      case EmergencyStatus.RESOLVED:
        statusColor = Colors.green;
        statusText = 'Selesai';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = case_.statusDisplayName;
        statusIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCaseDetail(case_),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      case_.categoryDisplayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      case_.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(case_.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCasesTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D32),
        ),
      );
    }

    if (_assignedCases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Kasus',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Saat ini Anda belum memiliki tugas kasus\ndari operator',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _loadDashboardData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _assignedCases.length,
        itemBuilder: (context, index) {
          final case_ = _assignedCases[index];
          return _buildCaseCard(case_);
        },
      ),
    );
  }

  Widget _buildCaseCard(EmergencyCase case_) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (case_.status) {
      case EmergencyStatus.NEW:
        statusColor = Colors.grey;
        statusText = 'Baru';
        statusIcon = Icons.fiber_new;
        break;
      case EmergencyStatus.PENDING:
        statusColor = Colors.orange;
        statusText = 'Menunggu';
        statusIcon = Icons.pending;
        break;
      case EmergencyStatus.VERIFIED:
        statusColor = Colors.blue;
        statusText = 'Terverifikasi';
        statusIcon = Icons.verified;
        break;
      case EmergencyStatus.DISPATCHED:
        statusColor = Colors.blue;
        statusText = 'Ditugaskan';
        statusIcon = Icons.work;
        break;
      case EmergencyStatus.ON_THE_WAY:
        statusColor = Colors.indigo;
        statusText = 'Dalam Perjalanan';
        statusIcon = Icons.directions_run;
        break;
      case EmergencyStatus.ON_SCENE:
        statusColor = Colors.teal;
        statusText = 'Di Lokasi';
        statusIcon = Icons.location_on;
        break;
      case EmergencyStatus.CLOSED:
        statusColor = Colors.green;
        statusText = 'Ditutup';
        statusIcon = Icons.check_circle;
        break;
      case EmergencyStatus.RESOLVED:
        statusColor = Colors.green;
        statusText = 'Selesai';
        statusIcon = Icons.check_circle;
        break;
      case EmergencyStatus.CANCELLED:
        statusColor = Colors.red;
        statusText = 'Dibatalkan';
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCaseDetail(case_),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      'ID: ${case_.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Category
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  case_.categoryDisplayName,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Description
              if (case_.description.isNotEmpty)
                Text(
                  case_.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Phone info
              Row(
                children: [
                  const Icon(
                    Icons.phone,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Kontak: ${case_.phone}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Location info (coordinates)
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Lokasi: ${case_.lat.toStringAsFixed(6)}, ${case_.lon.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // What3Words location if available
              if (case_.locatorText != null && case_.locatorText!.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.place,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'What3Words: ${case_.locatorText}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 4),

              // Time info
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(case_.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCaseDetail(case_),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Detail'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (case_.status == EmergencyStatus.DISPATCHED)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _updateCaseStatus(case_.id, 'ON_THE_WAY'),
                        icon: const Icon(Icons.directions_run, size: 16),
                        label: const Text('Berangkat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (case_.status == EmergencyStatus.ON_THE_WAY)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _updateCaseStatus(case_.id, 'ON_SCENE'),
                        icon: const Icon(Icons.location_on, size: 16),
                        label: const Text('Tiba'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (case_.status == EmergencyStatus.ON_SCENE)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _updateCaseStatus(case_.id, 'RESOLVED'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Selesai'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      // Stop location tracking first
      await LocationTrackingService.stopTracking();

      // Logout from PetugasService (clears token, stops polling)
      await PetugasService.logout();

      // Logout from AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (mounted) {
        // Navigate to citizen home screen (default screen for non-authenticated users)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CitizenHomeScreen()),
          (route) => false,
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  Future<void> _updateCaseStatus(String caseId, String status) async {
    try {
      final response = await PetugasService.updateCaseStatus(
        caseId: caseId,
        status: status,
      );

      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status kasus berhasil diupdate'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload data to refresh the list
        await _loadDashboardData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Gagal update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCaseDetail(EmergencyCase case_) async {
    // Navigate to detailed case screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaseDetailScreen(caseId: case_.id),
      ),
    );

    // Reload cases after returning from detail screen
    _loadAssignedCases();
  }
}
