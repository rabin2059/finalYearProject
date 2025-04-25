import 'dart:convert';

class PassengerData {
    final User? user;
    final int? recentTrips;
    final int? totalExpend;

    PassengerData({
        this.user,
        this.recentTrips,
        this.totalExpend,
    });

    factory PassengerData.fromRawJson(String str) => PassengerData.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory PassengerData.fromJson(Map<String, dynamic> json) => PassengerData(
        user: json["user"] == null ? null : User.fromJson(json["user"]),
        recentTrips: json["recentTrips"],
        totalExpend: json["totalExpend"],
    );

    Map<String, dynamic> toJson() => {
        "user": user?.toJson(),
        "recentTrips": recentTrips,
        "totalExpend": totalExpend,
    };
}

class User {
    final int? id;
    final String? username;
    final String? email;
    final dynamic images;

    User({
        this.id,
        this.username,
        this.email,
        this.images,
    });

    factory User.fromRawJson(String str) => User.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        username: json["username"],
        email: json["email"],
        images: json["images"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "images": images,
    };
}
