import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/my_case.dart';
import '../../models/emergency_case_new.dart';
import '../../config/app_theme.dart';

class CaseDetailScreen extends StatelessWidget {
  final MyCase caseItem;

  const CaseDetailScreen({super.key, required this.caseItem});

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

  IconData _getCategoryIcon(EmergencyCategory category) {
    switch (category) {
      case EmergencyCategory.MEDIS:
      case EmergencyCategory.SAKIT:
        return Icons.local_hospital;
      case EmergencyCategory.KECELAKAAN:
        return Icons.car_crash;
      case EmergencyCategory.KEBOCORAN_GAS:
        return Icons.warning;
      case EmergencyCategory.BENCANA_ALAM:
        return Icons.storm;
      case EmergencyCategory.POHON_TUMBANG:
        return Icons.park;
      case EmergencyCategory.BANJIR:
        return Icons.water;
      default:
        return Icons.emergency;
    }
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  Future<void> _openMap(double lat, double lon) async {
    final url = 'https://www.google.com/maps?q=$lat,$lon';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(caseItem.status);

    return Scaffold(
      appBar: AppBar(
        title: Text('Case #${caseItem.shortId}'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: statusColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(caseItem.status),
                    size: 48,
                    color: statusColor,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(caseItem.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Case Information
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  _buildInfoCard(
                    icon: _getCategoryIcon(caseItem.category),
                    iconColor: Colors.red,
                    title: 'Kategori',
                    content: _getCategoryText(caseItem.category),
                  ),
                  const SizedBox(height: 16),

                  // Created Date
                  _buildInfoCard(
                    icon: Icons.access_time,
                    iconColor: Colors.blue,
                    title: 'Waktu Laporan',
                    content: _formatDate(caseItem.createdAt),
                  ),
                  const SizedBox(height: 16),

                  // Location
                  _buildInfoCard(
                    icon: Icons.location_on,
                    iconColor: Colors.green,
                    title: 'Lokasi',
                    content: caseItem.location ?? caseItem.locatorText,
                    trailing: IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
                      onPressed: () => _openMap(caseItem.lat, caseItem.lon),
                      tooltip: 'Buka di Maps',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Coordinates
                  _buildInfoCard(
                    icon: Icons.pin_drop,
                    iconColor: Colors.orange,
                    title: 'Koordinat',
                    content:
                        'Lat: ${caseItem.lat.toStringAsFixed(6)}\nLon: ${caseItem.lon.toStringAsFixed(6)}\nAkurasi: ${caseItem.accuracy}m',
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  _buildInfoCard(
                    icon: Icons.phone,
                    iconColor: Colors.purple,
                    title: 'Nomor Telepon',
                    content: caseItem.phone,
                  ),

                  // Description (if available)
                  if (caseItem.description != null &&
                      caseItem.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.description,
                      iconColor: Colors.teal,
                      title: 'Deskripsi',
                      content: caseItem.description!,
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Status Timeline
                  const Text(
                    'Timeline Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTimelineItem(
                    icon: Icons.add_circle,
                    iconColor: Colors.blue,
                    title: 'Laporan Dibuat',
                    time: _formatDate(caseItem.createdAt),
                    isCompleted: true,
                  ),

                  if (caseItem.dispatchedAt != null)
                    _buildTimelineItem(
                      icon: Icons.send,
                      iconColor: Colors.orange,
                      title: 'Unit Dikirim',
                      time: _formatDate(caseItem.dispatchedAt!),
                      isCompleted: true,
                    ),

                  if (caseItem.onSceneAt != null)
                    _buildTimelineItem(
                      icon: Icons.location_on,
                      iconColor: Colors.purple,
                      title: 'Unit Tiba di Lokasi',
                      time: _formatDate(caseItem.onSceneAt!),
                      isCompleted: true,
                    ),

                  if (caseItem.closedAt != null)
                    _buildTimelineItem(
                      icon: Icons.check_circle,
                      iconColor: Colors.green,
                      title: 'Kasus Selesai',
                      time: _formatDate(caseItem.closedAt!),
                      isCompleted: true,
                      isLast: true,
                    ),

                  // Assigned Unit (if available)
                  if (caseItem.assignedUnit != null) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Unit yang Ditugaskan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.red,
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    caseItem.assignedUnit!.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (caseItem.assignedUnit!.type != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.category,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    caseItem.assignedUnit!.type!,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (caseItem.assignedUnit!.address != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      caseItem.assignedUnit!.address!,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (caseItem.assignedUnit!.phone != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.phone,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    caseItem.assignedUnit!.phone!,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
    Widget? trailing,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String time,
    required bool isCompleted,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? iconColor : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? iconColor : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(EmergencyStatus status) {
    switch (status) {
      case EmergencyStatus.PENDING:
      case EmergencyStatus.NEW:
        return Icons.schedule;
      case EmergencyStatus.VERIFIED:
        return Icons.verified;
      case EmergencyStatus.DISPATCHED:
        return Icons.send;
      case EmergencyStatus.ON_THE_WAY:
        return Icons.directions_car;
      case EmergencyStatus.ON_SCENE:
        return Icons.location_on;
      case EmergencyStatus.RESOLVED:
        return Icons.check_circle;
      case EmergencyStatus.CANCELLED:
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
