import 'dart:convert';

class VehicleDetails {
  final Vehicle? vehicle;

  VehicleDetails({
    this.vehicle,
  });

  factory VehicleDetails.fromRawJson(String str) =>
      VehicleDetails.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory VehicleDetails.fromJson(Map<String, dynamic> json) => VehicleDetails(
        vehicle:
            json["vehicle"] == null ? null : Vehicle.fromJson(json["vehicle"]),
      );

  Map<String, dynamic> toJson() => {
        "vehicle": vehicle?.toJson(),
      };
}

class Vehicle {
  final int? id;
  final String? vehicleNo;
  final String? model;
  final String? vehicleType;
  final String? registerAs;
  final String? departure;
  final String? arrivalTime;
  final String? actualDeparture;
  final String? actualArrival;
  final String? timingCategory;
  final String? createdAt;
  final String? updatedAt;
  final int? ownerId;
  final List<VehicleSeat>? vehicleSeat;
  final List<Route>? route;

  Vehicle({
    this.id,
    this.vehicleNo,
    this.model,
    this.vehicleType,
    this.registerAs,
    this.departure,
    this.arrivalTime,
    this.actualDeparture,
    this.actualArrival,
    this.timingCategory,
    this.createdAt,
    this.updatedAt,
    this.ownerId,
    this.vehicleSeat,
    this.route,
  });

  factory Vehicle.fromRawJson(String str) => Vehicle.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json["id"],
        vehicleNo: json["vehicleNo"],
        model: json["model"],
        vehicleType: json["vehicleType"],
        registerAs: json["registerAs"],
        departure: json["departure"],
        arrivalTime: json["arrivalTime"],
        actualDeparture: json["actualDeparture"],
        actualArrival: json["actualArrival"],
        timingCategory: json["timingCategory"],
        createdAt: json["createdAt"],
        updatedAt: json["updatedAt"],
        ownerId: json["ownerId"],
        vehicleSeat: json["VehicleSeat"] == null
            ? []
            : List<VehicleSeat>.from(
                json["VehicleSeat"]!.map((x) => VehicleSeat.fromJson(x))),
        route: json["Route"] == null
            ? []
            : List<Route>.from(json["Route"]!.map((x) => Route.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "vehicleNo": vehicleNo,
        "model": model,
        "vehicleType": vehicleType,
        "registerAs": registerAs,
        "departure": departure,
        "arrivalTime": arrivalTime,
        "actualDeparture": actualDeparture,
        "actualArrival": actualArrival,
        "timingCategory": timingCategory,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
        "ownerId": ownerId,
        "VehicleSeat": vehicleSeat == null
            ? []
            : List<dynamic>.from(vehicleSeat!.map((x) => x.toJson())),
        "Route": route == null
            ? []
            : List<dynamic>.from(route!.map((x) => x.toJson())),
      };
}

class Route {
  final int? id;
  final String? name;
  final String? startPoint;
  final String? endPoint;
  final int? fare;
  final String? polyline;
  final String? createdAt;
  final String? updatedAt;
  final int? vehicleId;
  final List<BusStopElement>? busStops;

  Route({
    this.id,
    this.name,
    this.startPoint,
    this.endPoint,
    this.fare,
    this.polyline,
    this.createdAt,
    this.updatedAt,
    this.vehicleId,
    this.busStops,
  });

  factory Route.fromRawJson(String str) => Route.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Route.fromJson(Map<String, dynamic> json) => Route(
        id: json["id"],
        name: json["name"],
        startPoint: json["startPoint"],
        endPoint: json["endPoint"],
        fare: json["fare"],
        polyline: json["polyline"],
        createdAt: json["createdAt"],
        updatedAt: json["updatedAt"],
        vehicleId: json["vehicleID"],
        busStops: json["busStops"] == null
            ? []
            : List<BusStopElement>.from(
                json["busStops"]!.map((x) => BusStopElement.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "startPoint": startPoint,
        "endPoint": endPoint,
        "fare": fare,
        "polyline": polyline,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
        "vehicleID": vehicleId,
        "busStops": busStops == null
            ? []
            : List<dynamic>.from(busStops!.map((x) => x.toJson())),
      };
}

class BusStopElement {
  final int? id;
  final int? routeId;
  final int? busStopId;
  final int? sequence;
  final BusStopBusStop? busStop;

  BusStopElement({
    this.id,
    this.routeId,
    this.busStopId,
    this.sequence,
    this.busStop,
  });

  factory BusStopElement.fromRawJson(String str) =>
      BusStopElement.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BusStopElement.fromJson(Map<String, dynamic> json) => BusStopElement(
        id: json["id"],
        routeId: json["routeId"],
        busStopId: json["busStopId"],
        sequence: json["sequence"],
        busStop: json["busStop"] == null
            ? null
            : BusStopBusStop.fromJson(json["busStop"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "routeId": routeId,
        "busStopId": busStopId,
        "sequence": sequence,
        "busStop": busStop?.toJson(),
      };
}

class BusStopBusStop {
  final int? id;
  final String? name;
  final double? latitude;
  final double? longitude;
  final String? createdAt;
  final String? updatedAt;

  BusStopBusStop({
    this.id,
    this.name,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory BusStopBusStop.fromRawJson(String str) =>
      BusStopBusStop.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BusStopBusStop.fromJson(Map<String, dynamic> json) => BusStopBusStop(
        id: json["id"],
        name: json["name"],
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
        createdAt: json["createdAt"],
        updatedAt: json["updatedAt"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "latitude": latitude,
        "longitude": longitude,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
      };
}

class VehicleSeat {
  final int? seatNo;

  VehicleSeat({
    this.seatNo,
  });

  factory VehicleSeat.fromRawJson(String str) =>
      VehicleSeat.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory VehicleSeat.fromJson(Map<String, dynamic> json) => VehicleSeat(
        seatNo: json["seatNo"],
      );

  Map<String, dynamic> toJson() => {
        "seatNo": seatNo,
      };
}
