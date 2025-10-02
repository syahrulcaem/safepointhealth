class MapboxConfig {
  // Mapbox Configuration
  static const String accessToken =
      'pk.eyJ1IjoicGFsb24wMDUiLCJhIjoiY21jMjJ4MDJvMDR0bzJqc2ZtMmxrOW56OSJ9.YFif8g-Il5g5qdynTCXLbA';

  // Map Styles
  static const String streetStyle = 'mapbox://styles/mapbox/streets-v12';
  static const String satelliteStyle =
      'mapbox://styles/mapbox/satellite-streets-v12';
  static const String outdoorsStyle = 'mapbox://styles/mapbox/outdoors-v12';
  static const String darkStyle = 'mapbox://styles/mapbox/dark-v11';

  // Default map settings
  static const double defaultZoom = 14.0;
  static const double minZoom = 1.0;
  static const double maxZoom = 20.0;

  // Emergency case marker colors
  static Map<String, String> getCategoryMarkerColor(String category) {
    switch (category.toUpperCase()) {
      case 'DARURAT':
        return {'color': '#ef4444', 'icon': '🚨'};
      case 'BENCANA_ALAM':
        return {'color': '#b45309', 'icon': '🌪️'};
      case 'KECELAKAAN':
        return {'color': '#dc2626', 'icon': '🚗'};
      case 'SAKIT':
        return {'color': '#059669', 'icon': '🏥'};
      case 'POHON_TUMBANG':
        return {'color': '#0891b2', 'icon': '🌳'};
      case 'BANJIR':
        return {'color': '#3b82f6', 'icon': '🌊'};
      default:
        return {'color': '#6b7280', 'icon': '📍'};
    }
  }

  // Officer marker color
  static const String officerMarkerColor = '#10b981';

  // Routes and directions
  static const String directionsApiUrl =
      'https://api.mapbox.com/directions/v5/mapbox';
  static const String geocodingApiUrl =
      'https://api.mapbox.com/geocoding/v5/mapbox.places';
}
