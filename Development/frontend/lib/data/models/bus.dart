import 'dart:convert';

class VehicleModel {
  final Vehicle? vehicle;

  VehicleModel({
    this.vehicle,
  });

  factory VehicleModel.fromRawJson(String str) =>
      VehicleModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
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
  final String? createdAt;
  final String? updatedAt;
  final int? ownerId;
  final Owner? owner;
  final List<Seat>? vehicleSeat;
  final List<Booking>? booking;
  final List<Route>? route;

  Vehicle({
    this.id,
    this.vehicleNo,
    this.model,
    this.vehicleType,
    this.registerAs,
    this.departure,
    this.arrivalTime,
    this.createdAt,
    this.updatedAt,
    this.ownerId,
    this.owner,
    this.vehicleSeat,
    this.booking,
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
        createdAt: json["createdAt"],
        updatedAt: json["updatedAt"],
        ownerId: json["ownerId"],
        owner: json["owner"] == null ? null : Owner.fromJson(json["owner"]),
        vehicleSeat: json["VehicleSeat"] == null
            ? []
            : List<Seat>.from(
                json["VehicleSeat"]!.map((x) => Seat.fromJson(x))),
        booking: json["Booking"] == null
            ? []
            : List<Booking>.from(
                json["Booking"]!.map((x) => Booking.fromJson(x))),
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
        "createdAt": createdAt,
        "updatedAt": updatedAt,
        "ownerId": ownerId,
        "owner": owner?.toJson(),
        "VehicleSeat": vehicleSeat == null
            ? []
            : List<dynamic>.from(vehicleSeat!.map((x) => x.toJson())),
        "Booking": booking == null
            ? []
            : List<dynamic>.from(booking!.map((x) => x.toJson())),
        "Route": route == null
            ? []
            : List<dynamic>.from(route!.map((x) => x.toJson())),
      };
}

class Booking {
  final int? id;
  final int? userId;
  final int? vehicleId;
  final String? bookingDate;
  final String? pickUpPoint;
  final String? dropOffPoint;
  final String? paymentStatus;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final User? user;
  final List<Seat>? bookingSeats;

  Booking({
    this.id,
    this.userId,
    this.vehicleId,
    this.bookingDate,
    this.pickUpPoint,
    this.dropOffPoint,
    this.paymentStatus,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.bookingSeats,
  });

  factory Booking.fromRawJson(String str) => Booking.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json["id"],
        userId: json["userId"],
        vehicleId: json["vehicleId"],
        bookingDate: json["bookingDate"],
        pickUpPoint: json["pickUpPoint"],
        dropOffPoint: json["dropOffPoint"],
        paymentStatus: json["paymentStatus"],
        status: json["status"],
        createdAt: json["createdAt"],
        updatedAt: json["updatedAt"],
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        bookingSeats: json["bookingSeats"] == null
            ? []
            : List<Seat>.from(
                json["bookingSeats"]!.map((x) => Seat.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "userId": userId,
        "vehicleId": vehicleId,
        "bookingDate": bookingDate,
        "pickUpPoint": pickUpPoint,
        "dropOffPoint": dropOffPoint,
        "paymentStatus": paymentStatus,
        "status": status,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
        "user": user?.toJson(),
        "bookingSeats": bookingSeats == null
            ? []
            : List<dynamic>.from(bookingSeats!.map((x) => x.toJson())),
      };
}

class Seat {
  final int? seatNo;

  Seat({
    this.seatNo,
  });

  factory Seat.fromRawJson(String str) => Seat.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Seat.fromJson(Map<String, dynamic> json) => Seat(
        seatNo: json["seatNo"],
      );

  Map<String, dynamic> toJson() => {
        "seatNo": seatNo,
      };
}

class User {
  final int? id;
  final String? username;

  User({
    this.id,
    this.username,
  });

  factory User.fromRawJson(String str) => User.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        username: json["username"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
      };
}

class Owner {
  final int? id;
  final String? username;
  final String? email;
  final String? password;
  final dynamic phone;
  final dynamic address;
  final dynamic licenseNo;
  final dynamic images;
  final dynamic licenceImage;
  final String? createdAt;
  final String? updatedAt;
  final String? role;
  final dynamic otp;
  final dynamic otpExpiry;
  final dynamic status;

  Owner({
    this.id,
    this.username,
    this.email,
    this.password,
    this.phone,
    this.address,
    this.licenseNo,
    this.images,
    this.licenceImage,
    this.createdAt,
    this.updatedAt,
    this.role,
    this.otp,
    this.otpExpiry,
    this.status,
  });

  factory Owner.fromRawJson(String str) => Owner.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Owner.fromJson(Map<String, dynamic> json) => Owner(
        id: json["id"],
        username: json["username"],
        email: json["email"],
        password: json["password"],
        phone: json["phone"],
        address: json["address"],
        licenseNo: json["licenseNo"],
        images: json["images"],
        licenceImage: json["licenceImage"],
        createdAt: json["createdAt"],
        updatedAt: json["updatedAt"],
        role: json["role"],
        otp: json["otp"],
        otpExpiry: json["otp_expiry"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "password": password,
        "phone": phone,
        "address": address,
        "licenseNo": licenseNo,
        "images": images,
        "licenceImage": licenceImage,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
        "role": role,
        "otp": otp,
        "otp_expiry": otpExpiry,
        "status": status,
      };
}

class Route {
  final int? id;
  final String? name;
  final String? startPoint;
  final String? endPoint;
  final int? fare;
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
