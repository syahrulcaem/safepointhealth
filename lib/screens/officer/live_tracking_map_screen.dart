import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../../models/case_detail.dart';
import '../../services/location_tracking_service.dart';

/// Live tracking map screen dengan Google Maps
/// Menampilkan posisi petugas real-time dan lokasi kejadian seperti Gojek/Grab
class LiveTrackingMapScreen extends StatefulWidget {
  final CaseDetail caseDetail;

  const LiveTrackingMapScreen({
    Key? key,
    required this.caseDetail,
  }) : super(key: key);

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<LocationData>? _locationSubscription;
  LocationData? _currentLocation;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  bool _isTracking = false;
  double? _distanceInKm;
  int? _etaInMinutes;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    // Get current location
    final location = await LocationTrackingService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _currentLocation = location;
      });
      _updateMarkers();
      _updatePolyline();
      _calculateDistance();
    }

    // Start listening to location updates
    _locationSubscription = Location().onLocationChanged.listen((locationData) {
      if (mounted) {
        setState(() {
          _currentLocation = locationData;
        });
        _updateMarkers();
        _updatePolyline();
        _calculateDistance();
        _animateToShowBothMarkers();
      }
    });

    setState(() {
      _isTracking = true;
    });
  }

  void _updateMarkers() {
    _markers.clear();

    // Incident marker (red)
    final incidentLat =
        double.tryParse(widget.caseDetail.location.latitude.toString()) ?? 0.0;
    final incidentLng =
        double.tryParse(widget.caseDetail.location.longitude.toString()) ?? 0.0;

    _markers.add(
      Marker(
        markerId: const MarkerId('incident'),
        position: LatLng(incidentLat, incidentLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Lokasi Kejadian',
          snippet: widget.caseDetail.shortId,
        ),
      ),
    );

    // Officer marker (blue)
    if (_currentLocation != null &&
        _currentLocation!.latitude != null &&
        _currentLocation!.longitude != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('officer'),
          position: LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Posisi Anda',
            snippet: 'Petugas',
          ),
        ),
      );
    }
  }

  void _updatePolyline() {
    _polylines.clear();

    if (_currentLocation == null ||
        _currentLocation!.latitude == null ||
        _currentLocation!.longitude == null) {
      return;
    }

    final incidentLat =
        double.tryParse(widget.caseDetail.location.latitude.toString()) ?? 0.0;
    final incidentLng =
        double.tryParse(widget.caseDetail.location.longitude.toString()) ?? 0.0;

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          LatLng(incidentLat, incidentLng),
        ],
        color: Colors.blue,
        width: 5,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );
  }

  void _calculateDistance() {
    if (_currentLocation == null ||
        _currentLocation!.latitude == null ||
        _currentLocation!.longitude == null) {
      return;
    }

    final lat1 = _currentLocation!.latitude!;
    final lon1 = _currentLocation!.longitude!;
    final lat2 =
        double.tryParse(widget.caseDetail.location.latitude.toString()) ?? 0.0;
    final lon2 =
        double.tryParse(widget.caseDetail.location.longitude.toString()) ?? 0.0;

    // Haversine formula
    const R = 6371; // Radius bumi dalam km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (dLat / 2).abs() * (dLat / 2).abs() +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            (dLon / 2).abs() *
            (dLon / 2).abs();

    final c = 2 * asin(sqrt(a));
    final distance = R * c;

    // Asumsi kecepatan rata-rata 40 km/jam
    final eta = (distance / 40 * 60).round();

    if (mounted) {
      setState(() {
        _distanceInKm = distance;
        _etaInMinutes = eta;
      });
    }
  }

  double _toRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  void _animateToShowBothMarkers() {
    if (_mapController == null ||
        _currentLocation == null ||
        _currentLocation!.latitude == null ||
        _currentLocation!.longitude == null) {
      return;
    }

    final incidentLat =
        double.tryParse(widget.caseDetail.location.latitude.toString()) ?? 0.0;
    final incidentLng =
        double.tryParse(widget.caseDetail.location.longitude.toString()) ?? 0.0;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _currentLocation!.latitude! < incidentLat
            ? _currentLocation!.latitude!
            : incidentLat,
        _currentLocation!.longitude! < incidentLng
            ? _currentLocation!.longitude!
            : incidentLng,
      ),
      northeast: LatLng(
        _currentLocation!.latitude! > incidentLat
            ? _currentLocation!.latitude!
            : incidentLat,
        _currentLocation!.longitude! > incidentLng
            ? _currentLocation!.longitude!
            : incidentLng,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Set custom map style (optional - dark mode style)
    _mapController?.setMapStyle('''
      [
        {
          "featureType": "poi",
          "stylers": [{"visibility": "off"}]
        }
      ]
    ''');

    // Animate to show both markers
    if (_currentLocation != null) {
      _animateToShowBothMarkers();
    }
  }

  void _centerOnOfficer() {
    if (_mapController == null || _currentLocation == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        15.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidentLat =
        double.tryParse(widget.caseDetail.location.latitude.toString()) ?? 0.0;
    final incidentLng =
        double.tryParse(widget.caseDetail.location.longitude.toString()) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _centerOnOfficer,
            tooltip: 'Pusatkan ke posisi saya',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(incidentLat, incidentLng),
              zoom: 14.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // Info card di atas
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildInfoCard(),
          ),

          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    // Parse category safely
    String categoryName = 'Darurat';
    try {
      categoryName = widget.caseDetail.category.toString().split('.').last;
    } catch (e) {
      categoryName = widget.caseDetail.category.toString();
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.emergency,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kasus ${widget.caseDetail.shortId}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        categoryName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_distanceInKm != null && _etaInMinutes != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.straighten,
                      label: 'Jarak',
                      value: '${_distanceInKm!.toStringAsFixed(1)} km',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.access_time,
                      label: 'ETA',
                      value: '$_etaInMinutes menit',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tracking indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _isTracking
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isTracking ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isTracking ? 'Tracking aktif' : 'Tracking tidak aktif',
                      style: TextStyle(
                        color: _isTracking ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tutup Peta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
