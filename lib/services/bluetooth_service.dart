import 'package:flutter/services.dart';

class BluetoothService {
  static const MethodChannel _channel = MethodChannel('safepoint/bt_channel');

  /// Get Bluetooth status from native Android
  static Future<Map<String, dynamic>> getBluetoothStatus() async {
    try {
      final result = await _channel.invokeMethod('getBluetoothStatus');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error getting Bluetooth status: $e');
      return {
        'hasPermission': false,
        'isEnabled': false,
        'watchConnected': false,
        'watchName': '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Check if Bluetooth permission is granted
  static Future<bool> hasBluetoothPermission() async {
    try {
      final result = await _channel.invokeMethod('hasBluetoothPermission');
      return result == true;
    } catch (e) {
      print('Error checking Bluetooth permission: $e');
      return false;
    }
  }

  /// Request Bluetooth permission (Android 12+)
  static Future<bool> requestBluetoothPermission() async {
    try {
      final result = await _channel.invokeMethod('requestBluetoothPermission');
      return result == true;
    } catch (e) {
      print('Error requesting Bluetooth permission: $e');
      return false;
    }
  }

  /// Check if Bluetooth is enabled
  static Future<bool> isBluetoothEnabled() async {
    try {
      final result = await _channel.invokeMethod('isBluetoothEnabled');
      return result == true;
    } catch (e) {
      print('Error checking Bluetooth enabled: $e');
      return false;
    }
  }

  /// Check if Xiaomi Watch is connected
  static Future<bool> isXiaomiWatchConnected() async {
    try {
      final result = await _channel.invokeMethod('isXiaomiWatchConnected');
      return result == true;
    } catch (e) {
      print('Error checking Xiaomi Watch connection: $e');
      return false;
    }
  }

  /// Listen to Bluetooth status updates from native
  static void setBluetoothStatusListener(
      Function(Map<String, dynamic>) onStatus) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onBluetoothStatus') {
        final status = Map<String, dynamic>.from(call.arguments);
        onStatus(status);
      }
    });
  }
}
