class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: double.parse(json['lat'].toString()), // ✅ Convert to double
      longitude: double.parse(json['lon'].toString()), // ✅ Convert to double
      address: json['display_name'],
    );
  }
}

class RouteModel {
  final List<LocationModel> routePoints;

  RouteModel({required this.routePoints});

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> coordinates = json['features'][0]['geometry']['coordinates'];

    List<LocationModel> routePoints = coordinates.map((coord) {
      return LocationModel(
        latitude: double.parse(coord[1].toString()), // ✅ Convert to double
        longitude: double.parse(coord[0].toString()), // ✅ Convert to double
      );
    }).toList();

    return RouteModel(routePoints: routePoints);
  }
}
