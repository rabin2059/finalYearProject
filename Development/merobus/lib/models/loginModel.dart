import 'package:meta/meta.dart';
import 'dart:convert';

class Login {
  final String message;
  final String token;
  final int userRole;

  Login({
    required this.message,
    required this.token,
    required this.userRole,
  });

  factory Login.fromRawJson(String str) => Login.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Login.fromJson(Map<String, dynamic> json) => Login(
        message: json["message"],
        token: json["token"],
        userRole: json["userRole"],
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "token": token,
        "userRole": userRole,
      };
}
