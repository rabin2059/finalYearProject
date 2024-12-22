import 'dart:convert';

class AllUsers {
  final String? message;
  final List<User>? user;

  AllUsers({
    this.message,
    this.user,
  });

  factory AllUsers.fromRawJson(String str) =>
      AllUsers.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory AllUsers.fromJson(Map<String, dynamic> json) => AllUsers(
        message: json["message"],
        user: json["user"] == null
            ? []
            : List<User>.from(json["user"]!.map((x) => User.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "user": user == null
            ? []
            : List<dynamic>.from(user!.map((x) => x.toJson())),
      };
}

class User {
  final int? id;
  final String? username;
  final String? email;
  final String? password;
  final String? phone;
  final String? address;
  final String? licenseNo;
  final String? vehicleNo;
  final String? createdAt;
  final String? updatedAt;
  final int? role;
  final dynamic otp;
  final dynamic otpExpiry;
  final String? status;

  User({
    this.id,
    this.username,
    this.email,
    this.password,
    this.phone,
    this.address,
    this.licenseNo,
    this.vehicleNo,
    this.createdAt,
    this.updatedAt,
    this.role,
    this.otp,
    this.otpExpiry,
    this.status,
  });

  factory User.fromRawJson(String str) => User.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        username: json["username"],
        email: json["email"],
        password: json["password"],
        phone: json["phone"],
        address: json["address"],
        licenseNo: json["licenseNo"],
        vehicleNo: json["vehicleNo"],
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
        "vehicleNo": vehicleNo,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
        "role": role,
        "otp": otp,
        "otp_expiry": otpExpiry,
        "status": status,
      };
}
