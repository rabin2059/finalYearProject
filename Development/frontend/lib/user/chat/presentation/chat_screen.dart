import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/core/constants.dart';
import 'package:frontend/user/Passenger/setting/providers/setting_provider.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

/// **Message Model** - Simplified
class Message {
  final String text;
  final DateTime date;
  final bool isSentByMe;  // Changed back to bool for correct UI rendering
  final String avatar;
  final int senderId;

  Message({
    required this.text,
    required this.date,
    required this.isSentByMe,
    required this.avatar,
    required this.senderId,
  });

  // Add factory constructor to create Message from JSON
  factory Message.fromJson(Map<String, dynamic> json, int currentUserId) {
    return Message(
      text: json['text'] ?? 'No message',
      date: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isSentByMe: json['senderId'] == currentUserId,
      avatar: 'https://randomuser.me/api/portraits/men/${json['senderId'] % 10}.jpg',
      senderId: json['senderId'] ?? 0,
    );
  }
}

/// **Chat Screen UI**
class ChatScreen extends ConsumerStatefulWidget {
  final int roomId;
  final String roomName;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    // Fetch messages when screen initializes
    getMessage();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    
    // Clear text field immediately for better UX
    messageController.clear();
    
    // Get current user ID
    final userId = ref.read(authProvider).userId;
    
    // Create a local message to show immediately
    // final newMessage = Message(
    //   text: text,
    //   date: DateTime.now(),
    //   isSentByMe: true,
    //   avatar: 'https://randomuser.me/api/portraits/men/${userId % 10}.jpg',
    //   // senderId: userId,
    // );
    
    // Update UI immediately with the new message
    setState(() {
      // messages.add(newMessage);
    });
    
    // Send message to server
    try {
      final url = Uri.parse("$apiBaseUrl/sendMessage");
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'text': text,
          'senderId': userId,
          'chatGroupId': widget.roomId,
        }),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Failed to send message: ${response.statusCode}');
        // You might want to add error handling here
      }
    } catch (e) {
      print('Error sending message: $e');
      // You might want to add error handling here
    }
  }

  void getMessage() async {
    final userId = ref.read(authProvider).userId;
    final url = Uri.parse("$apiBaseUrl/getmessage/${9}");
    
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        
        // Handle both array and object with messages property
        List<dynamic> messagesJson;
        if (jsonResponse is List) {
          messagesJson = jsonResponse;
        } else if (jsonResponse is Map && jsonResponse.containsKey('messages')) {
          messagesJson = jsonResponse['messages'];
        } else {
          print('Unexpected response format');
          return;
        }
        
        setState(() {
          // Use Message.fromJson factory to create Message objects
          messages = messagesJson
              .map<Message>((json) => Message.fromJson(json, userId!))
              .toList();
        });
      } else {
        // Handle error case
        print('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      // Handle exceptions
      print('Error fetching messages: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        backgroundColor: Colors.pink.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // Add download functionality here
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: getMessage,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty 
              ? const Center(child: Text("No messages yet"))
              : GroupedListView<Message, DateTime>(
                  padding: EdgeInsets.all(12.r),
                  elements: messages,
                  groupBy: (element) => DateTime(
                    element.date.year,
                    element.date.month,
                    element.date.day,
                  ),
                  groupSeparatorBuilder: (DateTime date) => Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.r),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  itemBuilder: (context, Message message) {
                    return MessageBubble(message: message);
                  },
                ),
          ),
          SafeArea(
            bottom: true,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: "Type a message",
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.r),
      child: Row(
        mainAxisAlignment: message.isSentByMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isSentByMe) ...[
            CircleAvatar(
              backgroundImage: NetworkImage(message.avatar),
              radius: 18.r,
            ),
            SizedBox(width: 8.w),
          ],
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: message.isSentByMe ? Colors.blue : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isSentByMe ? Colors.white : Colors.black,
              ),
            ),
          ),
          if (message.isSentByMe) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              backgroundImage: NetworkImage(message.avatar),
              radius: 18.r,
            ),
          ],
        ],
      ),
    );
  }
}