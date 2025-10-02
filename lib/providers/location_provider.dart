import 'dart:math' show asin, sqrt, sin, cos, pi;
import 'package:flutter/foundation.dart';
import '../services/gps_service.dart';

class LocationProvider with ChangeNotifier {
  String? _currentAddress;
  bool _isLoading = false;
  String? _errorMessage;
  double? _latitude;
  double? _longitude;
  bool _isTracking = false;

  // Getters
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isTracking => _isTracking;

  // Get current location using custom GPS service
  Future<Map<String, double>?> getCurrentLocation() async {
    _setLoading(true);
    _clearError();

    try {
      // Check if GPS service is enabled
      final isGpsEnabled = await GpsService.isGpsEnabled();
      if (!isGpsEnabled) {
        throw Exception('GPS tidak aktif. Mohon aktifkan GPS.');
      }

      // Check permissions
      final hasPermission = await GpsService.hasLocationPermission();
      if (!hasPermission) {
        final permissionGranted = await GpsService.requestLocationPermission();
        if (!permissionGranted) {
          throw Exception('Izin lokasi ditolak.');
        }
      }

      // Get current location
      final location = await GpsService.getCurrentLocation();

      if (location != null) {
        _latitude = location['latitude'];
        _longitude = location['longitude'];

        notifyListeners();

        return {
          'latitude': _latitude!,
          'longitude': _longitude!,
        };
      } else {
        throw Exception('Tidak dapat mendapatkan lokasi.');
      }
    } catch (e) {
      _setError('Error getting location: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await GpsService.isGpsEnabled();
    } catch (e) {
      _setError('Error checking location service: ${e.toString()}');
      return false;
    }
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      return await GpsService.requestLocationPermission();
    } catch (e) {
      _setError('Error requesting permission: ${e.toString()}');
      return false;
    }
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    try {
      await GpsService.openLocationSettings();
    } catch (e) {
      _setError('Error opening settings: ${e.toString()}');
    }
  }

  // Start location tracking (untuk officer)
  Future<void> startLocationTracking() async {
    if (_isTracking) return;

    try {
      _isTracking = true;
      notifyListeners();

      // Update location setiap 10 detik
      while (_isTracking) {
        await getCurrentLocation();
        await Future.delayed(const Duration(seconds: 10));
      }
    } catch (e) {
      _setError('Error in location tracking: ${e.toString()}');
      _isTracking = false;
      notifyListeners();
    }
  }

  // Stop location tracking
  void stopLocationTracking() {
    _isTracking = false;
    notifyListeners();
  }

  // Calculate distance between two points using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));

    double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  // Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Get formatted address string
  String getFormattedAddress() {
    if (_latitude != null && _longitude != null) {
      return 'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}';
    }
    return 'Lokasi tidak tersedia';
  }

  // Check if location is available
  bool hasLocation() {
    return _latitude != null && _longitude != null;
  }

  // Clear location data
  void clearLocation() {
    _latitude = null;
    _longitude = null;
    _currentAddress = null;
    _clearError();
    notifyListeners();
  }

  // Reset tracking
  void resetTracking() {
    _isTracking = false;
    notifyListeners();
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    debugPrint('LocationProvider Error: $message');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}
