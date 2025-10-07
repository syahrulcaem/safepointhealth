import 'dart:async';
import 'package:location/location.dart';
import 'petugas_service.dart';

/// Service untuk tracking lokasi petugas secara real-time
/// dan mengirimkan update ke backend
class LocationTrackingService {
  static final Location _location = Location();
  static StreamSubscription<LocationData>? _locationSubscription;
  static Timer? _updateTimer;
  static LocationData? _lastLocation;
  static DateTime? _lastUpdateTime;
  static const Duration _updateInterval = Duration(seconds: 30);
  static bool _isTracking = false;

  /// Start location tracking
  static Future<bool> startTracking() async {
    if (_isTracking) {
      print('📍 Location tracking already running');
      return true;
    }

    try {
      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print('❌ Location service not enabled');
          return false;
        }
      }

      // Check location permission
      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) {
          print('❌ Location permission denied');
          return false;
        }
      }

      print('✅ Starting location tracking...');

      // Configure location settings
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 10000, // Update every 10 seconds
        distanceFilter: 10, // Only update if moved 10 meters
      );

      // Listen to location changes
      _locationSubscription = _location.onLocationChanged.listen(
        _onLocationUpdate,
        onError: (error) {
          print('❌ Location stream error: $error');
        },
      );

      // Backup: Send location every 30 seconds even if no change
      _updateTimer = Timer.periodic(_updateInterval, (_) {
        if (_lastLocation != null) {
          _sendLocationToServer(_lastLocation!);
        }
      });

      _isTracking = true;
      print('✅ Location tracking started');
      return true;
    } catch (e) {
      print('❌ Error starting location tracking: $e');
      _isTracking = false;
      return false;
    }
  }

  /// Stop location tracking
  static Future<void> stopTracking() async {
    if (!_isTracking) return;

    print('🛑 Stopping location tracking...');

    await _locationSubscription?.cancel();
    _locationSubscription = null;

    _updateTimer?.cancel();
    _updateTimer = null;

    _isTracking = false;
    _lastUpdateTime = null;
    _lastLocation = null;

    print('✅ Location tracking stopped');
  }

  /// Handle location update from stream
  static void _onLocationUpdate(LocationData locationData) {
    _lastLocation = locationData;

    final now = DateTime.now();

    // Throttle updates - kirim setiap 30 detik
    if (_lastUpdateTime != null) {
      final timeSinceLastUpdate = now.difference(_lastUpdateTime!);
      if (timeSinceLastUpdate < _updateInterval) {
        return; // Skip update
      }
    }

    _sendLocationToServer(locationData);
  }

  /// Send location data to server
  static Future<void> _sendLocationToServer(LocationData locationData) async {
    if (locationData.latitude == null || locationData.longitude == null) {
      return;
    }

    final now = DateTime.now();

    print(
        '📍 Sending location: ${locationData.latitude}, ${locationData.longitude}');
    print('   Accuracy: ${locationData.accuracy}m');

    try {
      final response = await PetugasService.updateLocation(
        latitude: locationData.latitude!,
        longitude: locationData.longitude!,
        accuracy: locationData.accuracy,
      );

      if (response.success) {
        _lastUpdateTime = now;
        print('✅ Location updated to server');
      } else {
        print('❌ Failed to update location: ${response.message}');
      }
    } catch (e) {
      print('❌ Error sending location update: $e');
    }
  }

  /// Get current location once
  static Future<LocationData?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print('❌ Location service not enabled');
          return null;
        }
      }

      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) {
          print('❌ Location permission denied');
          return null;
        }
      }

      final locationData = await _location.getLocation();
      _lastLocation = locationData;

      print(
          '📍 Current location: ${locationData.latitude}, ${locationData.longitude}');
      return locationData;
    } catch (e) {
      print('❌ Error getting current location: $e');
      return null;
    }
  }

  /// Check if tracking is active
  static bool get isTracking => _isTracking;

  /// Get last update time
  static DateTime? get lastUpdateTime => _lastUpdateTime;

  /// Get last known location
  static LocationData? get lastLocation => _lastLocation;

  /// Dispose resources
  static void dispose() {
    stopTracking();
  }
}
