import 'dart:convert';

class UserModel {
    final UserData? userData;

    UserModel({
        this.userData,
    });

    factory UserModel.fromRawJson(String str) => UserModel.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userData: json["userData"] == null ? null : UserData.fromJson(json["userData"]),
    );

    Map<String, dynamic> toJson() => {
        "userData": userData?.toJson(),
    };
}

class UserData {
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
    final dynamic vehicleId;

    UserData({
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
        this.vehicleId,
    });

    factory UserData.fromRawJson(String str) => UserData.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory UserData.fromJson(Map<String, dynamic> json) => UserData(
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
        vehicleId: json["vehicleId"],
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
        "vehicleId": vehicleId,
    };
}
