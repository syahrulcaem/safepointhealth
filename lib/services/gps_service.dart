import 'package:flutter/services.dart';

class GpsService {
  static const MethodChannel _channel = MethodChannel('safepoint/gps');

  // Mendapatkan lokasi GPS saat ini
  static Future<Map<String, double>?> getCurrentLocation() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod('getCurrentLocation');

      if (result != null) {
        return {
          'latitude': result['latitude']?.toDouble() ?? 0.0,
          'longitude': result['longitude']?.toDouble() ?? 0.0,
        };
      }
      return null;
    } on PlatformException catch (e) {
      print("Error getting location: ${e.message}");
      return null;
    }
  }

  // Mengecek apakah GPS permission sudah diberikan
  static Future<bool> hasLocationPermission() async {
    try {
      final bool result = await _channel.invokeMethod('hasLocationPermission');
      return result;
    } on PlatformException catch (e) {
      print("Error checking permission: ${e.message}");
      return false;
    }
  }

  // Meminta GPS permission
  static Future<bool> requestLocationPermission() async {
    try {
      final bool result =
          await _channel.invokeMethod('requestLocationPermission');
      return result;
    } on PlatformException catch (e) {
      print("Error requesting permission: ${e.message}");
      return false;
    }
  }

  // Mengecek apakah GPS service aktif
  static Future<bool> isGpsEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isGpsEnabled');
      return result;
    } on PlatformException catch (e) {
      print("Error checking GPS status: ${e.message}");
      return false;
    }
  }

  // Membuka pengaturan lokasi
  static Future<void> openLocationSettings() async {
    try {
      await _channel.invokeMethod('openLocationSettings');
    } on PlatformException catch (e) {
      print("Error opening location settings: ${e.message}");
    }
  }
}
