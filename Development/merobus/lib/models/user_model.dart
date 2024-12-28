import 'dart:convert';

class UserModel {
  final User? user;

  UserModel({
    this.user,
  });

  factory UserModel.fromRawJson(String str) =>
      UserModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        user: json["user"] == null ? null : User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
        "user": user?.toJson(),
      };
}

class User {
  final int id;
  final String? username;
  final String? email;
  final String? password;
  final dynamic phone;
  final dynamic address;
  final String? licenseNo;
  final String? createdAt;
  final String? updatedAt;
  final int? role;
  final dynamic otp;
  final dynamic otpExpiry;
  final String? status;
  final String? vehicleNo;

  User({
    required this.id,
    this.username,
    this.email,
    this.password,
    this.phone,
    this.address,
    this.licenseNo,
    this.createdAt,
    this.updatedAt,
    this.role,
    this.otp,
    this.otpExpiry,
    this.status,
    this.vehicleNo,
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
        createdAt: json["createdAt"],
        updatedAt: json["updatedAt"],
        role: json["role"],
        otp: json["otp"],
        otpExpiry: json["otp_expiry"],
        status: json["status"],
        vehicleNo: json["vehicleNo"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "password": password,
        "phone": phone,
        "address": address,
        "licenseNo": licenseNo,
        "createdAt": createdAt,
        "updatedAt": updatedAt,
        "role": role,
        "otp": otp,
        "otp_expiry": otpExpiry,
        "status": status,
        "vehicleNo": vehicleNo,
      };
}
