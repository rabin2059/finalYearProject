import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/core/constants.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// **Socket Provider**
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref),
);

class ChatState {
  final List<Message> messages;
  final String chatLog;

  ChatState({
    required this.messages,
    this.chatLog = '',
  });

  ChatState copyWith({
    List<Message>? messages,
    String? chatLog,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      chatLog: chatLog ?? this.chatLog,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;
  late IO.Socket socket;
  int? currentRoomId;

  ChatNotifier(this.ref) : super(ChatState(messages: [])) {
    _connectToSocket();
  }

  Future<void> _loadMessages(int roomId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3089/api/v1/getMessages/$roomId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final messages =
            (data['messages'] as List).map((m) => Message.fromJson(m)).toList();

        state = state.copyWith(
          messages: messages,
          chatLog: data['chatLog'] ?? '',
        );
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> exportChatLog() async {
    if (currentRoomId == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/chat_log_$currentRoomId.txt');
      await file.writeAsString(state.chatLog);

      /// ✅ Use `Share.shareXFiles()` instead of `shareFiles()`
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Chat Log for Room $currentRoomId',
      );
    } catch (e) {
      print('Error exporting chat log: $e');
    }
  }

  void _connectToSocket() {
    try {
      final userId = ref.read(authProvider).userId;
      if (userId == null) {
        print("User ID is null. Cannot connect to socket.");
        return;
      }

      socket = IO.io("http://127.0.0.1:3089", <String, dynamic>{
        "transports": ["websocket"],
        "autoConnect": true,
        "query": {"userId": userId},
        "reconnection": true,
        "reconnectionAttempts": 5,
        "reconnectionDelay": 1000,
        "timeout": 5000,
      });

      socket.connect();

      socket.onConnect((_) {
        print("Connected to Socket.io server");
        if (currentRoomId != null) {
          joinRoom(currentRoomId!);
        }
      });

      socket.onConnectError((error) {
        print("Connection error: $error");
      });

      socket.on("receiveMessage", (data) {
        final userId = ref.read(authProvider).userId;
        final message = Message.fromJson(data);
        print("Received message: ${message.text}");

        // ✅ Ignore messages that the sender has already sent
        if (message.senderId != userId) {
          state = state.copyWith(messages: [...state.messages, message]);
        }
      });

      socket.onDisconnect((_) {
        print("Disconnected from server");
      });
    } catch (e) {
      print("⚠️ Error connecting to socket: $e");
    }
  }

  Future<void> joinRoom(int roomId) async {
    currentRoomId = roomId;
    socket.emit("joinRoom", roomId);
    await _loadMessages(roomId);
  }

  void leaveRoom() {
    if (currentRoomId != null) {
      socket.emit("leaveRoom", currentRoomId);
      currentRoomId = null;
      state = ChatState(messages: []);
    }
  }

  void sendMessage(String text) {
    if (currentRoomId == null) return;

    final userId = ref.read(authProvider).userId;
    final newMessage = Message(
      text: text,
      date: DateTime.now(),
      isSentByMe: true,
      avatar: "https://randomuser.me/api/portraits/men/1.jpg",
      senderId: userId,
    );

    socket.emit("sendMessage", {
      "roomId": currentRoomId,
      "message": {
        "text": newMessage.text,
        "date": newMessage.date.toIso8601String(),
        "avatar": newMessage.avatar,
      }
    });

    state = state.copyWith(
      messages: [...state.messages, newMessage],
    );
  }

  @override
  void dispose() {
    leaveRoom();
    socket.dispose();
    super.dispose();
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatProvider.notifier).joinRoom(widget.roomId);
    });
  }

  @override
  void dispose() {
    if (mounted) {
      // ✅ Ensure the widget is still mounted before using `ref`
      Future.microtask(() {
        ref.read(chatProvider.notifier).leaveRoom();
      });
    }
    messageController.dispose();

    super.dispose();
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(text);
    messageController.clear();

    try {
      final url = Uri.parse("$apiBaseUrl/sendMessage");
      final body = {
        "roomId": widget.roomId,
        "senderId": ref.read(authProvider).userId,
        "message": {
          "text": text,
          "date": DateTime.now().toIso8601String(),
          "avatar": "https://randomuser.me/api/portraits/men/1.jpg",
          "isSentByMe": true,
        }
      };

      http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
    } catch (e) {
      print('Error scrolling to bottom: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        backgroundColor: Colors.pink.shade50,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => ref.read(chatProvider.notifier).exportChatLog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GroupedListView<Message, DateTime>(
              padding: EdgeInsets.all(12.r),
              elements: chatState.messages,
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

/// **Message Model**
class Message {
  final String text;
  final DateTime date;
  final bool isSentByMe;
  final String avatar;
  final int? senderId;

  Message({
    required this.text,
    required this.date,
    required this.isSentByMe,
    required this.avatar,
    this.senderId,
  });

  /// ✅ Add `fromJson()` method
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'] ?? '',
      date: DateTime.parse(json['date']),
      isSentByMe: json['isSentByMe'] ?? false,
      avatar: json['avatar'] ?? '',
      senderId: json['senderId'],
    );
  }

  /// ✅ Add `toJson()` method (useful for sending messages)
  Map<String, dynamic> toJson() {
    return {
      "text": text,
      "date": date.toIso8601String(),
      "isSentByMe": isSentByMe,
      "avatar": avatar,
      "senderId": senderId,
    };
  }
}
