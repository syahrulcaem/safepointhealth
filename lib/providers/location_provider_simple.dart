import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:async';

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

  // Mock GPS dengan variasi kecil untuk simulasi pergerakan
  static final List<Map<String, double>> _jakartaLocations = [
    {'lat': -6.2088, 'lng': 106.8456}, // Monas
    {'lat': -6.1744, 'lng': 106.8294}, // Bundaran HI
    {'lat': -6.2297, 'lng': 106.8405}, // Blok M
    {'lat': -6.1754, 'lng': 106.8272}, // Thamrin
    {'lat': -6.1817, 'lng': 106.8342}, // Sarinah
  ];

  // Simulate getting current location with random Jakarta coordinates
  Future<Map<String, double>?> getCurrentLocation() async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate GPS delay
      await Future.delayed(const Duration(seconds: 2));

      // Get random Jakarta location
      final random = math.Random();
      final location = _jakartaLocations[random.nextInt(_jakartaLocations.length)];
      
      // Add small random variation to simulate real GPS
      final latVariation = (random.nextDouble() - 0.5) * 0.01; // ~500m variation
      final lngVariation = (random.nextDouble() - 0.5) * 0.01;

      _latitude = location['lat']! + latVariation;
      _longitude = location['lng']! + lngVariation;
      _currentAddress = "Jakarta, Indonesia (GPS Simulation)";

      print('📍 Simulated GPS Location: $_latitude, $_longitude');

      notifyListeners();
      return {'latitude': _latitude!, 'longitude': _longitude!};
    } catch (e) {
      _setError('Failed to get location: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Start location tracking
  void startLocationTracking() {
    _isTracking = true;
    getCurrentLocation();
    notifyListeners();
  }

  // Stop location tracking
  void stopLocationTracking() {
    _isTracking = false;
    notifyListeners();
  }

  // Get address from coordinates (simple implementation)
  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    return "Lat: ${latitude.toStringAsFixed(4)}, Lon: ${longitude.toStringAsFixed(4)}";
  }

  // Calculate distance between two points using Haversine formula
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const double earthRadius = 6371000; // Earth radius in meters

    double deltaLatRad = (endLatitude - startLatitude) * (math.pi / 180);
    double deltaLngRad = (endLongitude - startLongitude) * (math.pi / 180);

    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(startLatitude * (math.pi / 180)) *
            math.cos(endLatitude * (math.pi / 180)) *
            math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // Check if location is within radius (in meters)
  bool isWithinRadius(
    double centerLat,
    double centerLng,
    double targetLat,
    double targetLng,
    double radiusInMeters,
  ) {
    double distance = calculateDistance(centerLat, centerLng, targetLat, targetLng);
    return distance <= radiusInMeters;
  }

  // Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  // Get coordinates from address (fallback implementation)
  Future<Map<String, double>?> getLocationFromAddress(String address) async {
    _setLoading(true);
    _clearError();

    try {
      // Simple fallback implementation
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Use random Jakarta coordinates as default
      final random = math.Random();
      final location = _jakartaLocations[random.nextInt(_jakartaLocations.length)];
      
      _latitude = location['lat']!;
      _longitude = location['lng']!;
      _currentAddress = "$address (Simulated: Jakarta)";

      notifyListeners();
      return {'latitude': _latitude!, 'longitude': _longitude!};
    } catch (e) {
      _setError('Failed to get coordinates: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // Clear all data
  void clearLocation() {
    _latitude = null;
    _longitude = null;
    _currentAddress = null;
    _errorMessage = null;
    _isLoading = false;
    _isTracking = false;
    notifyListeners();
  }
}