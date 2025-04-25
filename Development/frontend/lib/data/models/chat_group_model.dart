import 'dart:convert';

class ChatGroupModel {
  final List<ChatGroup>? chatGroups;

  ChatGroupModel({
    this.chatGroups,
  });

  factory ChatGroupModel.fromRawJson(String str) =>
      ChatGroupModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ChatGroupModel.fromJson(Map<String, dynamic> json) => ChatGroupModel(
        chatGroups: json["chatGroups"] == null
            ? []
            : List<ChatGroup>.from(
                json["chatGroups"]!.map((x) => ChatGroup.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "chatGroups": chatGroups == null
            ? []
            : List<dynamic>.from(chatGroups!.map((x) => x.toJson())),
      };
}

class ChatGroup {
  final int? id;
  final String? name;
  final int? vehicleId;
  final VehicleInfo? vehicleInfo;
  final String? createdAt;
  final List<dynamic>? members;
  final int? messageCount;

  ChatGroup({
    this.id,
    this.name,
    this.vehicleId,
    this.vehicleInfo,
    this.createdAt,
    this.members,
    this.messageCount,
  });

  factory ChatGroup.fromRawJson(String str) =>
      ChatGroup.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ChatGroup.fromJson(Map<String, dynamic> json) => ChatGroup(
        id: json["id"],
        name: json["name"],
        vehicleId: json["vehicleId"],
        vehicleInfo: json["vehicleInfo"] == null
            ? null
            : VehicleInfo.fromJson(json["vehicleInfo"]),
        createdAt: json["createdAt"],
        members: json["members"] == null
            ? []
            : List<dynamic>.from(json["members"]!.map((x) => x)),
        messageCount: json["messageCount"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "vehicleId": vehicleId,
        "vehicleInfo": vehicleInfo?.toJson(),
        "createdAt": createdAt,
        "members":
            members == null ? [] : List<dynamic>.from(members!.map((x) => x)),
        "messageCount": messageCount,
      };
}

class VehicleInfo {
  final int? id;
  final String? vehicleNo;
  final String? model;

  VehicleInfo({
    this.id,
    this.vehicleNo,
    this.model,
  });

  factory VehicleInfo.fromRawJson(String str) =>
      VehicleInfo.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory VehicleInfo.fromJson(Map<String, dynamic> json) => VehicleInfo(
        id: json["id"],
        vehicleNo: json["vehicleNo"],
        model: json["model"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "vehicleNo": vehicleNo,
        "model": model,
      };
}
