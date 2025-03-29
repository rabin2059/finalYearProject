import 'dart:convert';
import 'bus_model.dart';
import 'user_model.dart';

class ChatGroup {
  final int? id;
  final String name;
  final int? vehicleId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<UserData>? users;
  final BusModel? vehicle;
  final int? unreadCount;

  ChatGroup({
    this.id,
    required this.name,
    this.vehicleId,
    required this.createdAt,
    required this.updatedAt,
    this.users,
    this.vehicle,
    this.unreadCount = 0,
  });

  factory ChatGroup.fromRawJson(String str) =>
      ChatGroup.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ChatGroup.fromJson(Map<String, dynamic> json) => ChatGroup(
        id: json["id"],
        name: json["name"] ?? "",
        vehicleId: json["vehicleId"],
        createdAt: json["createdAt"] != null
            ? DateTime.parse(json["createdAt"])
            : DateTime.now(),
        updatedAt: json["updatedAt"] != null
            ? DateTime.parse(json["updatedAt"])
            : DateTime.now(),
        users: json["users"] != null
            ? List<UserData>.from(
                json["users"].map((x) => UserData.fromJson(x)))
            : null,
        vehicle:
            json["vehicle"] != null ? BusModel.fromJson(json["vehicle"]) : null,
        unreadCount: json["unreadCount"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "vehicleId": vehicleId,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "users": users != null
            ? List<dynamic>.from(users!.map((x) => x.toJson()))
            : null,
        "vehicle": vehicle?.toJson(),
        "unreadCount": unreadCount,
      };

  // Helper method to get list of user IDs
  List<int> get memberIds =>
      users?.map((user) => user.id ?? 0).whereType<int>().toList() ?? [];

  // Helper method to check if a user is a member of this group
  bool isMember(int userId) => memberIds.contains(userId);
}
