import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/emergency_case_new.dart';
import '../providers/emergency_provider.dart';

class EmergencyCategoryDialog extends StatefulWidget {
  final Function(EmergencyCategory) onCategorySelected;

  const EmergencyCategoryDialog({
    Key? key,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<EmergencyCategoryDialog> createState() =>
      _EmergencyCategoryDialogState();
}

class _EmergencyCategoryDialogState extends State<EmergencyCategoryDialog> {
  Timer? _countdownTimer;
  int _remainingSeconds = 10;
  bool _dialogClosed = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _disposed = true;
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_dialogClosed || !mounted || _disposed) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds > 1) {
        if (mounted && !_disposed) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        // Timer finished - auto select UMUM
        timer.cancel();
        if (!_dialogClosed && mounted && !_disposed) {
          _dialogClosed = true;
          // Call the callback first while context is still valid
          widget.onCategorySelected(EmergencyCategory.UMUM);
          // Then close the dialog
          Navigator.of(context).pop();
        }
      }
    });
  }

  void _selectCategory(EmergencyCategory category) {
    if (_dialogClosed || _disposed) return;

    _dialogClosed = true;
    _countdownTimer?.cancel();

    if (mounted) {
      // Call the callback first while context is still valid
      widget.onCategorySelected(category);
      // Then close the dialog
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _dialogClosed = true;
        _countdownTimer?.cancel();
        return true;
      },
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.emergency,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Pilih Kategori Darurat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_remainingSeconds',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pilih kategori darurat yang sesuai. Jika tidak memilih dalam $_remainingSeconds detik, akan otomatis masuk kategori Umum.',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Consumer<EmergencyProvider>(
              builder: (context, emergencyProvider, child) {
                return Column(
                  children: EmergencyCategory.values.map((category) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: emergencyProvider.isLoading
                            ? null
                            : () => _selectCategory(category),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getCategoryColor(category),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(_getCategoryIcon(category), size: 20),
                        label: Text(
                          _getCategoryName(category),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _dialogClosed = true;
              _countdownTimer?.cancel();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(EmergencyCategory category) {
    switch (category) {
      case EmergencyCategory.UMUM:
        return 'Umum';
      case EmergencyCategory.MEDIS:
        return 'Medis';
      case EmergencyCategory.SAKIT:
        return 'Sakit';
      case EmergencyCategory.KECELAKAAN:
        return 'Kecelakaan';
      case EmergencyCategory.KEBOCORAN_GAS:
        return 'Kebocoran Gas';
      case EmergencyCategory.POHON_TUMBANG:
        return 'Pohon Tumbang';
      case EmergencyCategory.BANJIR:
        return 'Banjir';
      case EmergencyCategory.BENCANA_ALAM:
        return 'Bencana Alam';
    }
  }

  IconData _getCategoryIcon(EmergencyCategory category) {
    switch (category) {
      case EmergencyCategory.UMUM:
        return Icons.help;
      case EmergencyCategory.MEDIS:
        return Icons.local_hospital;
      case EmergencyCategory.SAKIT:
        return Icons.sick;
      case EmergencyCategory.KECELAKAAN:
        return Icons.car_crash;
      case EmergencyCategory.KEBOCORAN_GAS:
        return Icons.gas_meter;
      case EmergencyCategory.POHON_TUMBANG:
        return Icons.park;
      case EmergencyCategory.BANJIR:
        return Icons.water;
      case EmergencyCategory.BENCANA_ALAM:
        return Icons.warning;
    }
  }

  Color _getCategoryColor(EmergencyCategory category) {
    switch (category) {
      case EmergencyCategory.UMUM:
        return Colors.grey[600]!;
      case EmergencyCategory.MEDIS:
        return Colors.red[600]!;
      case EmergencyCategory.SAKIT:
        return Colors.pink[600]!;
      case EmergencyCategory.KECELAKAAN:
        return Colors.blue[600]!;
      case EmergencyCategory.KEBOCORAN_GAS:
        return Colors.orange[600]!;
      case EmergencyCategory.POHON_TUMBANG:
        return Colors.green[600]!;
      case EmergencyCategory.BANJIR:
        return Colors.cyan[600]!;
      case EmergencyCategory.BENCANA_ALAM:
        return Colors.brown[600]!;
    }
  }
}
