import 'dart:convert';

class BookingByVehicleModel {
  final List<BookingByVehicle>? bookingByVehicle;

  BookingByVehicleModel({
    this.bookingByVehicle,
  });

  factory BookingByVehicleModel.fromRawJson(String str) =>
      BookingByVehicleModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BookingByVehicleModel.fromJson(Map<String, dynamic> json) =>
      BookingByVehicleModel(
        bookingByVehicle: json["bookingByVehicle"] == null
            ? []
            : List<BookingByVehicle>.from(json["bookingByVehicle"]!
                .map((x) => BookingByVehicle.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "bookingByVehicle": bookingByVehicle == null
            ? []
            : List<dynamic>.from(bookingByVehicle!.map((x) => x.toJson())),
      };
}

class BookingByVehicle {
  final int? id;
  final int? userId;
  final int? vehicleId;
  final String? bookingDate;
  final String? pickUpPoint;
  final String? dropOffPoint;
  final int? totalFare;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final List<BookingSeat>? bookingSeats;

  BookingByVehicle({
    this.id,
    this.userId,
    this.vehicleId,
    this.bookingDate,
    this.pickUpPoint,
    this.dropOffPoint,
    this.totalFare,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.bookingSeats,
  });

  factory BookingByVehicle.fromRawJson(String str) =>
      BookingByVehicle.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory BookingByVehicle.fromJson(Map<String, dynamic> json) =>
      BookingByVehicle(
        id: json["id"],
        userId: json["userId"],
        vehicleId: json["vehicleId"],
        bookingDate: json["bookingDate"],
        pickUpPoint: json["pickUpPoint"],
        dropOffPoint: json["dropOffPoint"],
        totalFare: json["totalFare"],
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
        "totalFare": totalFare,
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
