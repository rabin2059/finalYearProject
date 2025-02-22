import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:math';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late IO.Socket socket;
  late TextEditingController messageController;
  List<Map<String, dynamic>> messages = [];
  bool isTyping = false;

  final String currentUser = "John Doe";
  final String receiver = "Jane Doe";

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController();
    initSocket();
  }

  void initSocket() {
    socket = IO.io('http://localhost:3089', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    socket.connect();

    // ✅ Listen for incoming messages
    socket.on("message", (data) {
      if (mounted) {
        setState(() {
          messages.add(data);
        });
      }
    });

    // ✅ Typing Indicator
    socket.on("typing", (data) {
      if (mounted) {
        setState(() {
          isTyping = data["isTyping"];
        });
      }
    });
  }

  void sendMessage() {
    if (messageController.text.isNotEmpty) {
      final message = {
        "messageId": Random().nextInt(10000).toString(), // Unique ID
        "message": messageController.text,
        "sender": currentUser,
        "receiver": receiver,
        "read": false,
        "status": "sent",
        "type": "text",
        "timestamp": DateTime.now().toString(),
      };
      
      socket.emit("message", message);

      setState(() {
        messages.add(message);
      });

      messageController.clear();
    }
  }

  @override
  void dispose() {
    socket.disconnect();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                bool isSentByMe = msg["sender"] == currentUser;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Align(
                    alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSentByMe ? Colors.blue[100] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg["message"], style: const TextStyle(fontSize: 16)),
                          Text(
                            msg["timestamp"].split(".")[0], // Show only HH:MM:SS
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // ✅ Typing Indicator
          if (isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "$receiver is typing...",
                  style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (text) {
                      socket.emit("typing", {"isTyping": text.isNotEmpty});
                    },
                    onSubmitted: (_) => sendMessage(), // ✅ Send message on Enter
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}