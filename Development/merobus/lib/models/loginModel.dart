import 'dart:convert';

class Login {
  final String? message;
  final User user;
  final String? token;

  Login({
    this.message,
    required this.user,
    required this.token,
  });

  factory Login.fromRawJson(String str) => Login.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Login.fromJson(Map<String, dynamic> json) => Login(
        message: json["message"],
        user: User.fromJson(json["user"] ?? {}),
        token: json["token"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "user": user.toJson(),
        "token": token,
      };
}

class User {
  final int? id;
  final String? username;
  final String? email;
  final String? password;
  final int role;

  User({
    this.id,
    this.username,
    this.email,
    this.password,
    required this.role,
  });

  factory User.fromRawJson(String str) => User.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"],
        username: json["username"],
        email: json["email"],
        password: json["password"],
        role: json["role"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "password": password,
        "role": role,
      };
}
