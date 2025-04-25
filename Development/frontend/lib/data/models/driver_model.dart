import 'dart:convert';

class DriverData {
    final User? user;
    final DriverStats? driverStats;

    DriverData({
        this.user,
        this.driverStats,
    });

    factory DriverData.fromRawJson(String str) => DriverData.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory DriverData.fromJson(Map<String, dynamic> json) => DriverData(
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        driverStats: json["driverStats"] == null ? null : DriverStats.fromJson(json["driverStats"]),
    );

    Map<String, dynamic> toJson() => {
        "user": user?.toJson(),
        "driverStats": driverStats?.toJson(),
    };
}

class DriverStats {
    final int? totalTrips;
    final int? totalEarnings;
    final int? rating;
    final String? status;

    DriverStats({
        this.totalTrips,
        this.totalEarnings,
        this.rating,
        this.status,
    });

    factory DriverStats.fromRawJson(String str) => DriverStats.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory DriverStats.fromJson(Map<String, dynamic> json) => DriverStats(
        totalTrips: json["totalTrips"],
        totalEarnings: json["totalEarnings"],
        rating: json["rating"],
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "totalTrips": totalTrips,
        "totalEarnings": totalEarnings,
        "rating": rating,
        "status": status,
    };
}

class User {
    final int? id;
    final String? username;
    final String? email;
    final dynamic images;
    final String? status;

    User({
        this.id,
        this.username,
        this.email,
        this.images,
        this.status,
    });

    factory User.fromRawJson(String str) => User.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        username: json["username"],
        email: json["email"],
        images: json["images"],
        status: json["status"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "images": images,
        "status": status,
    };
}
