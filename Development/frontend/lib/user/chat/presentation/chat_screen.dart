import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:frontend/data/services/socket_service.dart';
import 'package:frontend/core/constants.dart';

/// **Chat Screen UI**
class ChatScreen extends ConsumerStatefulWidget {
  final int groupId;
  final String groupName;

  const ChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isSending = false;
  String? connectionStatus;
  
  @override
  void initState() {
    super.initState();
    _setupSocketService();
  }
  
  void _setupSocketService() async {
    final socketService = ref.read(socketServiceProvider);
    final authState = ref.read(authProvider);
    final userId = authState.userId;
    
    if (userId == null) {
      setState(() {
        connectionStatus = "Error: User not logged in";
        isLoading = false;
      });
      return;
    }
    
    // Set up connection status callback
    socketService.onConnectionStatus = (status) {
      setState(() {
        connectionStatus = status;
      });
    };
    
    // Set up new message callback
    socketService.onNewMessage = (data) {
      if (data['chatGroupId'] == widget.groupId) {
        setState(() {
          messages.add(data);
        });
        _scrollToBottom();
      }
    };
    
    // Set up message sent callback
    socketService.onMessageSent = (data) {
      if (data['chatGroupId'] == widget.groupId) {
        setState(() {
          messages.add(data);
          isSending = false;
        });
        _scrollToBottom();
      }
    };
    
    // Load message history
    try {
      await socketService.joinGroup(userId.toString(), widget.groupId);
      
      final history = await socketService.fetchGroupHistory(widget.groupId);
      setState(() {
        messages.addAll(List<Map<String, dynamic>>.from(history));
        isLoading = false;
      });
      
      // Mark messages as read
      _markMessagesAsRead(userId);
      
      // Scroll to bottom after loading history
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        connectionStatus = "Error: $e";
        isLoading = false;
      });
    }
  }
  
  Future<void> _sendMessage() async {
    if (messageController.text.trim().isEmpty) return;
    
    final authState = ref.read(authProvider);
    final userId = authState.userId;
    
    if (userId == null) return;
    
    setState(() {
      isSending = true;
    });
    
    try {
      final socketService = ref.read(socketServiceProvider);
      await socketService.sendMessage(
        userId,
        widget.groupId,
        messageController.text.trim()
      );
      messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send message: $e"))
      );
      setState(() {
        isSending = false;
      });
    }
  }
  
  void _markMessagesAsRead(int userId) async {
    try {
      // Get all unread messages not sent by current user
      final unreadMessages = messages.where((msg) => 
        msg['senderId'] != userId && msg['isRead'] == false
      ).toList();
      
      if (unreadMessages.isEmpty) return;
      
      final socketService = ref.read(socketServiceProvider);
      
      // Mark each message as read
      for (final message in unreadMessages) {
        try {
          await socketService.markMessageAsRead(message['id']);
        } catch (e) {
          // Continue with other messages if one fails
          print("Failed to mark message ${message['id']} as read: $e");
        }
      }
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }
  
  final ScrollController _scrollController = ScrollController();
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUserId = authState.userId;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName),
            if (connectionStatus != null)
              Text(
                connectionStatus!,
                style: TextStyle(fontSize: 12.sp),
              ),
          ],
        ),
        backgroundColor: Colors.pink.shade50,
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet.\nStart the conversation!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : GroupedListView<Map<String, dynamic>, DateTime>(
                    elements: messages,
                    controller: _scrollController,
                    groupBy: (message) {
                      final date = DateTime.parse(message['createdAt'] ?? DateTime.now().toIso8601String());
                      return DateTime(date.year, date.month, date.day);
                    },
                    groupHeaderBuilder: (message) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.r),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.r,
                            vertical: 4.r,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            _formatMessageDate(DateTime.parse(
                                message['createdAt'] ?? 
                                DateTime.now().toIso8601String())),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    itemBuilder: (context, message) {
                      final isMe = message['senderId'] == currentUserId;
                      
                      return Align(
                        alignment: isMe 
                            ? Alignment.centerRight 
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 12.r,
                            vertical: 4.r,
                          ),
                          padding: EdgeInsets.all(12.r),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.blue.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  message['senderName'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              if (!isMe) SizedBox(height: 4.h),
                              Text(
                                message['text'] ?? '',
                                style: TextStyle(fontSize: 14.sp),
                              ),
                              SizedBox(height: 4.h),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatMessageTime(DateTime.parse(
                                          message['createdAt'] ?? 
                                          DateTime.now().toIso8601String())),
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (isMe) SizedBox(width: 4.w),
                                    if (isMe)
                                      Icon(
                                        message['isRead'] 
                                            ? Icons.done_all 
                                            : Icons.done,
                                        size: 12.r,
                                        color: message['isRead']
                                            ? Colors.blue
                                            : Colors.grey,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    order: GroupedListOrder.ASC,
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
                      decoration: InputDecoration(
                        hintText: "Type a message",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.r),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.r,
                          vertical: 8.r,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: isSending
                          ? SizedBox(
                              width: 18.r,
                              height: 18.r,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.send, color: Colors.white, size: 18.r),
                      onPressed: isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }
  
  String _formatMessageTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
}