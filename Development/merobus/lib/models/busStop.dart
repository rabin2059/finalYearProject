import 'dart:convert';

class Vehicle {
  final int? id;
  final String? vehicleNo;
  final String? model;
  final int? ownerId;
  final Route? route;

  Vehicle({
    this.id,
    this.vehicleNo,
    this.model,
    this.ownerId,
    this.route,
  });

  factory Vehicle.fromRawJson(String str) => Vehicle.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json["id"],
        vehicleNo: json["vehicleNo"],
        model: json["model"],
        ownerId: json["ownerId"],
        route: json["route"] == null ? null : Route.fromJson(json["route"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "vehicleNo": vehicleNo,
        "model": model,
        "ownerId": ownerId,
        "route": route?.toJson(),
      };
}

class Route {
  final int? id;
  final String? startPoint;
  final String? endPoint;
  final List<BusStop>? busStops;

  Route({
    this.id,
    this.startPoint,
    this.endPoint,
    this.busStops,
  });

  factory Route.fromRawJson(String str) => Route.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Route.fromJson(Map<String, dynamic> json) => Route(
        id: json["id"],
        startPoint: json["startPoint"],
        endPoint: json["endPoint"],
        busStops: json["busStops"] == null
            ? []
            : List<BusStop>.from(
                json["busStops"]!.map((x) => BusStop.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "startPoint": startPoint,
        "endPoint": endPoint,
        "busStops": busStops == null
            ? []
            : List<dynamic>.from(busStops!.map((x) => x.toJson())),
      };
}

class BusStop {
  final int? id;
  final String? name;
  final double? latitude;
  final double? longitude;

  BusStop({
    this.id,
    this.name,
    this.latitude,
    this.longitude,
  });

  factory BusStop.fromRawJson(String str) => BusStop.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BusStop.fromJson(Map<String, dynamic> json) => BusStop(
        id: json["id"],
        name: json["name"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "latitude": latitude,
        "longitude": longitude,
      };
}
