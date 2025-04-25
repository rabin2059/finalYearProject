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
