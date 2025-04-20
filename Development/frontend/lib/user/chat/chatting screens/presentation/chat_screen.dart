import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';
import 'package:frontend/data/services/socket_service.dart';
import 'package:frontend/core/constants.dart';

import '../../../../components/AppColors.dart';

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
  bool? isMember;
  String? joinedAt;

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

    socketService.onConnectionStatus = (status) {
      setState(() {
        connectionStatus = status;
      });
    };

    socketService.onNewMessage = (data) {
      if (data['chatGroupId'] == widget.groupId) {
        setState(() {
          messages.add(data);
        });
        _scrollToBottom();
      }
    };

    socketService.onMessageSent = (data) {
      if (data['chatGroupId'] == widget.groupId) {
        setState(() {
          messages.add(data);
          isSending = false;
        });
        _scrollToBottom();
      }
    };

    socketService.onMembershipStatus = (data) {
      if (data['chatGroupId'] == widget.groupId) {
        setState(() {
          isMember = data['isMember'];
          joinedAt = data['joinedAt'];
        });
      }
    };

    try {
      final membershipData = await socketService.checkUserInGroup(
          userId.toString(), widget.groupId);

      setState(() {
        isMember = membershipData['isMember'];
        joinedAt = membershipData['joinedAt'];
      });

      if (isMember == true) {
        _log(
            'User is a member of group ${widget.groupId}, loading messages since $joinedAt');

        try {
          final history =
              await socketService.fetchMessagesSinceJoin(widget.groupId);
          setState(() {
            messages.addAll(List<Map<String, dynamic>>.from(history));
            isLoading = false;
          });
        } catch (e) {
          _log('Error fetching messages since join: $e');
          final fullHistory =
              await socketService.fetchGroupHistory(widget.groupId);
          setState(() {
            messages.addAll(List<Map<String, dynamic>>.from(fullHistory));
            isLoading = false;
          });
        }
      } else {
        _log('User is not a member of group ${widget.groupId}, joining...');
        await socketService.joinGroup(userId.toString(), widget.groupId);

        final history = await socketService.fetchGroupHistory(widget.groupId);
        setState(() {
          messages.addAll(List<Map<String, dynamic>>.from(history));
          isLoading = false;
        });
      }

      _markMessagesAsRead(userId);

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

  void _log(String message) {
    if (true) {
      print('[ChatScreen] $message');
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
          userId, widget.groupId, messageController.text.trim());
      messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to send message: $e")));
      setState(() {
        isSending = false;
      });
    }
  }

  void _markMessagesAsRead(int userId) async {
    try {
      final unreadMessages = messages
          .where((msg) => msg['senderId'] != userId && msg['isRead'] == false)
          .toList();

      if (unreadMessages.isEmpty) return;

      final socketService = ref.read(socketServiceProvider);

      for (final message in unreadMessages) {
        try {
          await socketService.markMessageAsRead(message['id']);
        } catch (e) {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: AssetImage('assets/profile.png'),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.groupName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                      color: AppColors.purple,
                    ))
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.r,
                            vertical: 16.r,
                          ),
                          groupBy: (message) {
                            final date = DateTime.parse(message['createdAt'] ??
                                DateTime.now().toIso8601String());
                            return DateTime(date.year, date.month, date.day);
                          },
                          groupHeaderBuilder: (message) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.r),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.r,
                                  vertical: 4.r,
                                ),
                                child: Text(
                                  _formatMessageDate(DateTime.parse(
                                      message['createdAt'] ??
                                          DateTime.now().toIso8601String())),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          itemBuilder: (context, message) {
                            final isMe = message['senderId'] == currentUserId;
                            final messageTime = DateTime.parse(
                                message['createdAt'] ??
                                    DateTime.now().toIso8601String());

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.only(
                                  top: 4.r,
                                  bottom: 4.r,
                                  left: isMe ? 80.r : 0,
                                  right: isMe ? 0 : 80.r,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.r,
                                  vertical: 10.r,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.messageSent
                                      : AppColors.messageReceived,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe && message['senderName'] != null)
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 4.r),
                                        child: Text(
                                          message['senderName'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.sp,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      message['text'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: isMe
                                            ? Colors.black
                                            : Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatMessageTime(
                                                messageTime.toLocal()),
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: isMe
                                                  ? Colors.black54
                                                  : Colors.grey.shade600,
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
                          separator: SizedBox(height: 0),
                        ),
            ),
            Divider(height: 1, color: Colors.grey.shade300),
            SafeArea(
              bottom: true,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.r),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.add, color: AppColors.buttonColor),
                      onPressed: () {},
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.r),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: TextField(
                          controller: messageController,
                          decoration: InputDecoration(
                            hintText: "Type your message here",
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 14.sp,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 12.r),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: isSending
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(Icons.send, color: Colors.white),
                        onPressed: isSending ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'TODAY';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'YESTERDAY';
    } else {
      return DateFormat('MMMM d, yyyy').format(date).toUpperCase();
    }
  }

  String _formatMessageTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }
}
