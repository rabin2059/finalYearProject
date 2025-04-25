class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  /// **Factory Constructor to Parse JSON**
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: double.tryParse(json['lat'].toString()) ?? 0.0, // ✅ Safe conversion
      longitude: double.tryParse(json['lon'].toString()) ?? 0.0, // ✅ Safe conversion
      address: json['display_name'] ?? "Unknown Location",
    );
  }
}

class RouteModel {
  final List<LocationModel> routePoints;

  RouteModel({required this.routePoints});

  /// **Factory Constructor to Parse Route JSON (OSRM API)**
  factory RouteModel.fromJson(Map<String, dynamic> json) {
    if (json['routes'] != null && json['routes'].isNotEmpty) {
      List<dynamic> coordinates = json['routes'][0]['geometry']['coordinates'];

      List<LocationModel> routePoints = coordinates.map((coord) {
        return LocationModel(
          latitude: double.tryParse(coord[1].toString()) ?? 0.0, // ✅ Safe conversion
          longitude: double.tryParse(coord[0].toString()) ?? 0.0, // ✅ Safe conversion
        );
      }).toList();

      return RouteModel(routePoints: routePoints);
    } else {
      throw Exception("Invalid route data");
    }
  }
}