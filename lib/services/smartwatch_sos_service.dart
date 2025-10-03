import 'package:flutter/services.dart';
import 'package:safepointhealth/providers/emergency_provider.dart';
import 'package:safepointhealth/services/gps_service.dart';
import 'package:safepointhealth/models/emergency_case_new.dart';
import 'package:safepointhealth/services/auth_service.dart';

class SmartWatchSosService {
  static const MethodChannel _channel = MethodChannel('safepoint/sos_channel');
  static Function(Map<String, dynamic>)? _onSosTrigger;

  /// Initialize SmartWatch SOS listener
  static void initialize({
    Function(Map<String, dynamic>)? onSosTrigger,
  }) {
    _onSosTrigger = onSosTrigger;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSOS') {
        print('=== SmartWatch SOS Trigger Received ===');
        final data = Map<String, dynamic>.from(call.arguments);
        print('Source: ${data['source']}');
        print('Device: ${data['device']}');
        print('Timestamp: ${data['timestamp']}');
        print('======================================');

        // Notify listener
        if (_onSosTrigger != null) {
          _onSosTrigger!(data);
        }

        // Auto-trigger emergency report
        await _handleAutoEmergencyReport(data);
      }
    });

    print('SmartWatch SOS Service initialized');
  }

  /// Auto-trigger emergency report when smartwatch SOS detected
  static Future<void> _handleAutoEmergencyReport(
      Map<String, dynamic> triggerData) async {
    try {
      print('=== Auto Emergency Report from SmartWatch ===');

      // Get current location
      final location = await GpsService.getCurrentLocation();

      if (location == null) {
        print('❌ Failed to get location');
        return;
      }

      final lat = location['latitude'] ?? 0.0;
      final lon = location['longitude'] ?? 0.0;
      
      print('✅ Location: $lat, $lon');

      // Check if user is logged in
      final token = await AuthService.getToken();
      final isGuest = token == null;

      print('User type: ${isGuest ? 'Guest' : 'Authenticated'}');

      // Prepare emergency data
      final description =
          'SOS darurat dari smartwatch: ${triggerData['device'] ?? 'Unknown Device'}';

      // This is a placeholder - in real implementation, you should:
      // 1. Get EmergencyProvider instance from context
      // 2. Call the appropriate report method
      // 3. Show notification to user about SOS being sent

      print('📱 Emergency would be triggered with:');
      print('Description: $description');
      print('Location: $lat, $lon');
      print('Category: KECELAKAAN (default for smartwatch trigger)');

      // TODO: Implement actual emergency report
      // This needs to be connected to EmergencyProvider
      // You may need to use a service locator or pass provider instance

      print('=========================================');
    } catch (e) {
      print('❌ Error handling auto emergency report: $e');
    }
  }

  /// Trigger emergency report from smartwatch manually
  static Future<bool> triggerEmergencyReport({
    required EmergencyProvider emergencyProvider,
    required String description,
    EmergencyCategory category = EmergencyCategory.KECELAKAAN,
  }) async {
    try {
      // Get current location
      final location = await GpsService.getCurrentLocation();

      if (location == null) {
        print('❌ Failed to get location');
        return false;
      }

      // Check if user is logged in
      final token = await AuthService.getToken();
      final isGuest = token == null;

      print('Triggering emergency from smartwatch...');
      print('User type: ${isGuest ? 'Guest' : 'Authenticated'}');

      final lat = location['latitude'] ?? 0.0;
      final lon = location['longitude'] ?? 0.0;
      
      // Call appropriate emergency report method
      if (isGuest) {
        return await emergencyProvider.reportPublicEmergency(
          phone: '',
          latitude: lat,
          longitude: lon,
          category: category,
          description: description,
        );
      } else {
        return await emergencyProvider.reportEmergency(
          phone: '',
          latitude: lat,
          longitude: lon,
          category: category,
          description: description,
        );
      }
    } catch (e) {
      print('❌ Error triggering emergency report: $e');
      return false;
    }
  }

  /// Start background SOS monitoring service
  static Future<void> startBackgroundMonitoring() async {
    try {
      // This would communicate with native Android service
      // For now, just log
      print('Starting background SOS monitoring...');
      // TODO: Implement native service start via MethodChannel
    } catch (e) {
      print('Error starting background monitoring: $e');
    }
  }

  /// Stop background SOS monitoring service
  static Future<void> stopBackgroundMonitoring() async {
    try {
      print('Stopping background SOS monitoring...');
      // TODO: Implement native service stop via MethodChannel
    } catch (e) {
      print('Error stopping background monitoring: $e');
    }
  }
}
