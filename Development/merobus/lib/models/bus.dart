class Bus {
  final String id;
  final String driverName;
  final String busNumber;
  final String routeName;
  final double latitude;
  final double longitude;
  final String status;
  final String nextStop;
  final String estimatedArrival;

  Bus({
    required this.id,
    required this.driverName,
    required this.busNumber,
    required this.routeName,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.nextStop,
    required this.estimatedArrival,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'],
      driverName: json['driver_name'],
      busNumber: json['bus_number'],
      routeName: json['route_name'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      status: json['status'],
      nextStop: json['next_stop'],
      estimatedArrival: json['estimated_arrival'],
    );
  }
} 