import 'dart:convert';

class BusModel {
  final String? message;
  final List<Bus>? bus;

  BusModel({
    this.message,
    this.bus,
  });

  factory BusModel.fromRawJson(String str) =>
      BusModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BusModel.fromJson(Map<String, dynamic> json) => BusModel(
        message: json["message"],
        bus: json["bus"] == null
            ? []
            : List<Bus>.from(json["bus"]!.map((x) => Bus.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "bus":
            bus == null ? [] : List<dynamic>.from(bus!.map((x) => x.toJson())),
      };
}

class Bus {
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
  final List<VehicleSeat>? vehicleSeat;
  final List<Booking>? booking;
  final Route? route;

  Bus({
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

  factory Bus.fromRawJson(String str) => Bus.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Bus.fromJson(Map<String, dynamic> json) => Bus(
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
            : List<VehicleSeat>.from(
                json["VehicleSeat"]!.map((x) => VehicleSeat.fromJson(x))),
        booking: json["Booking"] == null
            ? []
            : List<Booking>.from(
                json["Booking"]!.map((x) => Booking.fromJson(x))),
        route: json["Route"] == null ? null : Route.fromJson(json["Route"]),
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
        "Route": route?.toJson(),
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
  final List<BookingSeat>? bookingSeats;

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
        bookingSeats: json["bookingSeats"] == null
            ? []
            : List<BookingSeat>.from(
                json["bookingSeats"]!.map((x) => BookingSeat.fromJson(x))),
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
        "bookingSeats": bookingSeats == null
            ? []
            : List<dynamic>.from(bookingSeats!.map((x) => x.toJson())),
      };
}

class BookingSeat {
  final int? id;
  final int? bookingId;
  final int? seatNo;
  final String? createdAt;

  BookingSeat({
    this.id,
    this.bookingId,
    this.seatNo,
    this.createdAt,
  });

  factory BookingSeat.fromRawJson(String str) =>
      BookingSeat.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BookingSeat.fromJson(Map<String, dynamic> json) => BookingSeat(
        id: json["id"],
        bookingId: json["bookingId"],
        seatNo: json["seatNo"],
        createdAt: json["createdAt"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "bookingId": bookingId,
        "seatNo": seatNo,
        "createdAt": createdAt,
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
  final List<BusStop>? busStops;

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
            : List<BusStop>.from(
                json["busStops"]!.map((x) => BusStop.fromJson(x))),
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

class BusStop {
  final int? id;
  final int? routeId;
  final int? busStopId;
  final int? sequence;

  BusStop({
    this.id,
    this.routeId,
    this.busStopId,
    this.sequence,
  });

  factory BusStop.fromRawJson(String str) => BusStop.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BusStop.fromJson(Map<String, dynamic> json) => BusStop(
        id: json["id"],
        routeId: json["routeId"],
        busStopId: json["busStopId"],
        sequence: json["sequence"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "routeId": routeId,
        "busStopId": busStopId,
        "sequence": sequence,
      };
}

class VehicleSeat {
  final int? id;
  final int? vehicleId;
  final int? seatNo;
  final String? createdAt;
  final String? updatedAt;

  VehicleSeat({
    this.id,
    this.vehicleId,
    this.seatNo,
    this.createdAt,
    this.updatedAt,
  });

  factory VehicleSeat.fromRawJson(String str) =>
      VehicleSeat.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory VehicleSeat.fromJson(Map<String, dynamic> json) => VehicleSeat(
        id: json["id"],
        vehicleId: json["vehicleId"],
        seatNo: json["seatNo"],
        createdAt: json["createdAt"],
        updatedAt: json["updatedAt"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "vehicleId": vehicleId,
        "seatNo": seatNo,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
      };
}
