import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/petugas_service.dart';
import '../../models/emergency_case.dart';

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic> _dashboardStats = {};
  List<EmergencyCase> _assignedCases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _listenToCaseUpdates();
  }

  void _initializeData() async {
    // Start polling for updates
    PetugasService.startPolling();

    await _loadDashboardData();
  }

  void _listenToCaseUpdates() {
    PetugasService.caseUpdatesStream.listen((cases) {
      if (mounted) {
        setState(() {
          _assignedCases = cases;
        });

        // Show notification for new cases
        if (cases.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ada ${cases.length} kasus baru!'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Lihat',
                textColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1; // Switch to cases tab
                  });
                },
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load dashboard stats
      final statsResponse = await PetugasService.getDashboardStats();
      if (statsResponse.success) {
        setState(() {
          _dashboardStats = statsResponse.data ?? {};
        });
      }

      // Load assigned cases
      final casesResponse = await PetugasService.getAssignedCases();
      if (casesResponse.success) {
        setState(() {
          _assignedCases = casesResponse.data ?? [];
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

  @override
  void dispose() {
    PetugasService.stopPolling();
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

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Text(
                          'Halo, ${authProvider.user?.name ?? "Petugas"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Status: Bertugas',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Statistics Cards
          const Text(
            'Statistik Hari Ini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Kasus Baru',
                  value: _dashboardStats['new_cases']?.toString() ?? '0',
                  icon: Icons.add_alert,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Selesai',
                  value: _dashboardStats['completed_cases']?.toString() ?? '0',
                  icon: Icons.check_circle,
                  color: Colors.green,
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
                  value:
                      _dashboardStats['in_progress_cases']?.toString() ?? '0',
                  icon: Icons.pending,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Kasus',
                  value: _assignedCases.length.toString(),
                  icon: Icons.assignment,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Aksi Cepat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildActionCard(
                title: 'Mulai Bertugas',
                icon: Icons.play_arrow,
                color: Colors.green,
                onTap: () {
                  // TODO: Implement start duty
                },
              ),
              _buildActionCard(
                title: 'Update Lokasi',
                icon: Icons.location_on,
                color: Colors.blue,
                onTap: () {
                  // TODO: Implement update location
                },
              ),
              _buildActionCard(
                title: 'Lihat Kasus',
                icon: Icons.assignment,
                color: Colors.orange,
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              _buildActionCard(
                title: 'Logout',
                icon: Icons.logout,
                color: Colors.red,
                onTap: _logout,
              ),
            ],
          ),
        ],
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
                  Text(
                    'ID: ${case_.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
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

  void _showCaseDetail(EmergencyCase case_) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  Icon(
                    Icons.assignment,
                    color: const Color(0xFF2E7D32),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Detail Kasus',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailItem('ID Kasus', case_.id),
                    _buildDetailItem('Status', case_.statusDisplayName),
                    _buildDetailItem('Kategori', case_.categoryDisplayName),
                    _buildDetailItem('Deskripsi', case_.description),
                    _buildDetailItem('Nomor Telepon', case_.phone),
                    _buildDetailItem(
                      'Koordinat',
                      '${case_.lat.toStringAsFixed(6)}, ${case_.lon.toStringAsFixed(6)}',
                    ),
                    if (case_.locatorText != null &&
                        case_.locatorText!.isNotEmpty)
                      _buildDetailItem('What3Words', case_.locatorText!),
                    if (case_.accuracy != null)
                      _buildDetailItem(
                        'Akurasi GPS',
                        '${case_.accuracy!.toStringAsFixed(1)} meter',
                      ),
                    _buildDetailItem(
                      'Waktu Laporan',
                      '${case_.createdAt.day}/${case_.createdAt.month}/${case_.createdAt.year} ${case_.createdAt.hour.toString().padLeft(2, '0')}:${case_.createdAt.minute.toString().padLeft(2, '0')}',
                    ),
                    if (case_.verifiedAt != null)
                      _buildDetailItem(
                        'Waktu Verifikasi',
                        '${case_.verifiedAt!.day}/${case_.verifiedAt!.month}/${case_.verifiedAt!.year} ${case_.verifiedAt!.hour.toString().padLeft(2, '0')}:${case_.verifiedAt!.minute.toString().padLeft(2, '0')}',
                      ),
                    if (case_.dispatchedAt != null)
                      _buildDetailItem(
                        'Waktu Penugasan',
                        '${case_.dispatchedAt!.day}/${case_.dispatchedAt!.month}/${case_.dispatchedAt!.year} ${case_.dispatchedAt!.hour.toString().padLeft(2, '0')}:${case_.dispatchedAt!.minute.toString().padLeft(2, '0')}',
                      ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Open maps with coordinates
                            },
                            icon: const Icon(Icons.map),
                            label: const Text('Lihat di Peta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Make phone call
                            },
                            icon: const Icon(Icons.call),
                            label: const Text('Hubungi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (case_.notes != null && case_.notes!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Catatan:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...case_.notes!.map((note) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.note,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(note.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
