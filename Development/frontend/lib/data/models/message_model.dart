import 'dart:convert';

class Message {
    final int? id;
    final String text;
    final DateTime createdAt;
    final DateTime updatedAt;
    final int senderId;
    final String? senderName;
    final int chatGroupId;
    final bool isRead;
    final DateTime? readAt;

    Message({
        this.id,
        required this.text,
        required this.createdAt,
        required this.updatedAt,
        required this.senderId,
        this.senderName,
        required this.chatGroupId,
        this.isRead = false,
        this.readAt,
    });

    factory Message.fromRawJson(String str) => Message.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json["id"],
        text: json["text"] ?? "",
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : DateTime.now(),
        updatedAt: json["updatedAt"] != null ? DateTime.parse(json["updatedAt"]) : DateTime.now(),
        senderId: json["senderId"] ?? 0,
        senderName: json["senderName"],
        chatGroupId: json["chatGroupId"] ?? 0,
        isRead: json["isRead"] ?? false,
        readAt: json["readAt"] != null ? DateTime.parse(json["readAt"]) : null,
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "text": text,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "senderId": senderId,
        "senderName": senderName,
        "chatGroupId": chatGroupId,
        "isRead": isRead,
        "readAt": readAt?.toIso8601String(),
    };
}