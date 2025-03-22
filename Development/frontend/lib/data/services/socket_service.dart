import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'package:flutter/foundation.dart';

class SocketService {
  final String baseUrl;
  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;
  String? get socketId => _socket?.id;

  final Set<int> _joinedGroups = {};

  final ValueNotifier<List<String>> activeUsers =
      ValueNotifier<List<String>>([]);
  final ValueNotifier<Map<String, bool>> userTypingStatus =
      ValueNotifier<Map<String, bool>>({});

  Function(Map<String, dynamic>)? onNewMessage;
  Function(Map<String, dynamic>)? onMessageSent;
  Function(List<dynamic>)? onGroupHistory;
  Function(Map<String, dynamic>)? onUserStatus;
  Function(Map<String, dynamic>)? onMessageReadConfirmed;
  Function(String)? onError;
  Function(String)? onConnectionStatus;

  SocketService({required this.baseUrl});

  void connect(String userId) {
    _log('Attempting to connect to socket server: $baseUrl');
    _log('Using user ID: $userId');

    // Check if we're already connected
    if (_socket != null) {
      if (_socket!.connected) {
        _log('Already connected with socket ID: ${_socket!.id}');
        _socket!.emit('login', userId);
        return;
      } else {
        _log('Socket exists but not connected, cleaning up first');
        _socket!.dispose();
        _socket = null;
      }
    }

    // IMPORTANT: Using websocket transport instead of polling
    // Changed from ['polling'] to ['websocket'] to match server configuration
    _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(
                ['websocket']) // Changed to match server transport config
            .disableAutoConnect()
            .setExtraHeaders({'Access-Control-Allow-Origin': '*'})
            .setReconnectionAttempts(10)
            .setReconnectionDelay(1000)
            .enableReconnection()
            .build());

    _setupEventListeners();

    _log('Connecting to socket...');
    _socket!.connect();

    // Connection event handlers with better logging
    _socket!.onConnect((_) {
      _log('✅ Connected to socket server with ID: ${_socket!.id}');
      if (onConnectionStatus != null) {
        onConnectionStatus!('Connected');
      }

      _log('Sending login event with userId: $userId');
      _socket!.emit('login', userId);
    });

    _socket!.onConnectError((error) {
      _log('❌ Connection error: $error');
      if (onConnectionStatus != null) {
        onConnectionStatus!('Connection error: $error');
      }
    });
  }

  void disconnect(String userId) {
    if (_socket != null) {
      _log('Disconnecting user $userId from socket');

      if (_socket!.connected) {
        _log('Emitting logout event');
        _socket!.emit('logout', userId);
      }

      _log('Disconnecting socket');
      _socket!.disconnect();
      _joinedGroups.clear();

      _log('Socket disconnected');
      if (onConnectionStatus != null) {
        onConnectionStatus!('Disconnected');
      }
    }
  }

  bool hasJoinedGroup(int chatGroupId) {
    return _joinedGroups.contains(chatGroupId);
  }

  Future<void> sendMessage(int senderId, int chatGroupId, String text) async {
    if (!isConnected) {
      _log('Cannot send message: Not connected to socket server');
      throw Exception('Not connected to socket server');
    }

    if (!_joinedGroups.contains(chatGroupId)) {
      try {
        _log('Auto-joining group $chatGroupId before sending message');
        await _autoJoinGroup(senderId.toString(), chatGroupId);
      } catch (e) {
        _log('Auto-join failed, but will attempt to send message anyway: $e');
      }
    }

    final messageData = {
      'senderId': senderId,
      'chatGroupId': chatGroupId,
      'text': text,
    };

    _log('Sending message: $messageData');
    _socket!.emit('send_message', messageData);

    Completer<void> completer = Completer<void>();

    _socket!.once('message_sent', (data) {
      _log('Message sent confirmation received: $data');
      completer.complete();
    });

    _socket!.once('error', (data) {
      _log('Error sending message: $data');
      completer.completeError(data['message'] ?? 'Failed to send message');
    });

    Timer(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        _log('Timeout while sending message');
        completer.completeError('Timeout while sending message');
      }
    });

    return completer.future;
  }

  Future<void> _autoJoinGroup(String userId, int chatGroupId) async {
    final Completer<void> completer = Completer<void>();

    _log('Auto-joining group: userId=$userId, chatGroupId=$chatGroupId');
    _socket!.emit('join_group', {
      'userId': userId,
      'chatGroupId': chatGroupId,
    });

    _socket!.once('group_joined', (data) {
      _log('Successfully joined group: $chatGroupId');
      _joinedGroups.add(chatGroupId);
      completer.complete();
    });

    _socket!.once('error', (data) {
      _log('Error joining group: $data');
      completer.completeError(data['message'] ?? 'Failed to join group');
    });

    Timer(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        _log('Timeout while joining group');
        completer.completeError('Timeout while joining group');
      }
    });

    return completer.future;
  }

  Future<List<dynamic>> fetchGroupHistory(int chatGroupId) async {
    if (!isConnected) {
      _log('Cannot fetch history: Not connected to socket server');
      throw Exception('Not connected to socket server');
    }

    if (!_joinedGroups.contains(chatGroupId)) {
      try {
        String userId = _getUserId() ?? "0";
        _log('Auto-joining group $chatGroupId before fetching history');
        await _autoJoinGroup(userId, chatGroupId);
      } catch (e) {
        _log('Auto-join failed when fetching history: $e');
      }
    }

    final Completer<List<dynamic>> completer = Completer<List<dynamic>>();
    _log('Fetching group history for chatGroupId: $chatGroupId');
    _socket!.emit('fetch_group_history', {'chatGroupId': chatGroupId});

    _socket!.once('group_history', (data) {
      _log('Received group history: ${data.length} messages');
      completer.complete(data);
    });

    _socket!.once('error', (data) {
      _log('Error fetching history: $data');
      completer.completeError(data['message'] ?? 'Failed to fetch history');
    });

    Timer(Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        _log('Timeout while fetching history');
        completer.completeError('Timeout while fetching history');
      }
    });

    return completer.future;
  }

  String? _getUserId() {
    return null;
  }

  Future<void> joinGroup(String userId, int chatGroupId) async {
    if (!isConnected) {
      _log('Cannot join group: Not connected to socket server');
      throw Exception('Not connected to socket server');
    }

    if (_joinedGroups.contains(chatGroupId)) {
      _log('Already joined group: $chatGroupId');
      return;
    }

    final Completer<void> completer = Completer<void>();
    _log('Joining group: userId=$userId, chatGroupId=$chatGroupId');
    _socket!.emit('join_group', {'userId': userId, 'chatGroupId': chatGroupId});

    _socket!.once('group_joined', (data) {
      _log('Successfully joined group: $chatGroupId');
      _joinedGroups.add(chatGroupId);
      completer.complete();
    });

    _socket!.once('error', (data) {
      _log('Error joining group: $data');
      completer.completeError(data['message'] ?? 'Failed to join group');
    });

    Timer(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        _log('Timeout while joining group');
        completer.completeError('Timeout while joining group');
      }
    });

    return completer.future;
  }

  Future<void> leaveGroup(String userId, int chatGroupId) async {
    if (!isConnected) {
      _log('Cannot leave group: Not connected to socket server');
      throw Exception('Not connected to socket server');
    }

    final Completer<void> completer = Completer<void>();
    _log('Leaving group: userId=$userId, chatGroupId=$chatGroupId');
    _socket!
        .emit('leave_group', {'userId': userId, 'chatGroupId': chatGroupId});

    _socket!.once('group_left', (data) {
      _log('Successfully left group: $chatGroupId');
      _joinedGroups.remove(chatGroupId);
      completer.complete();
    });

    _socket!.once('error', (data) {
      _log('Error leaving group: $data');
      completer.completeError(data['message'] ?? 'Failed to leave group');
    });

    Timer(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        _log('Timeout while leaving group');
        completer.completeError('Timeout while leaving group');
      }
    });

    return completer.future;
  }

  void sendTypingIndicator(String userId, int chatGroupId) {
    if (isConnected && _joinedGroups.contains(chatGroupId)) {
      _log(
          'Sending typing indicator: userId=$userId, chatGroupId=$chatGroupId');
      _socket!.emit('typing', {
        'userId': userId,
        'chatGroupId': chatGroupId,
      });
    }
  }

  Future<void> markMessageAsRead(int messageId) async {
    if (!isConnected) {
      _log('Cannot mark message as read: Not connected to socket server');
      throw Exception('Not connected to socket server');
    }

    final Completer<void> completer = Completer<void>();
    _log('Marking message as read: messageId=$messageId');
    _socket!.emit('message_read', messageId);

    _socket!.once('message_read_confirmed', (data) {
      _log('Message marked as read: $messageId');
      completer.complete();
    });

    _socket!.once('error', (data) {
      _log('Error marking message as read: $data');
      completer.completeError(data['message'] ?? 'Failed to mark as read');
    });

    Timer(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        _log('Timeout while marking as read');
        completer.completeError('Timeout while marking as read');
      }
    });

    return completer.future;
  }

  Future<Map<String, dynamic>> ping() async {
    if (!isConnected) {
      _log('Cannot ping: Not connected to socket server');
      throw Exception('Not connected to socket server');
    }

    final Completer<Map<String, dynamic>> completer = Completer();
    _log('Pinging server');
    _socket!.emit('ping');

    _socket!.once('pong', (data) {
      _log('Received pong: $data');
      completer.complete(data);
    });

    Timer(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        _log('Timeout while pinging server');
        completer.completeError('Timeout while pinging server');
      }
    });

    return completer.future;
  }

  void _setupEventListeners() {
    _socket!.on('active_users', (data) {
      _log('Received active users: $data');
      activeUsers.value = List<String>.from(data);
    });

    _socket!.on('new_message', (data) {
      _log('Received new message: $data');
      onNewMessage?.call(data);
    });

    _socket!.on('message_sent', (data) {
      _log('Message sent: $data');
      onMessageSent?.call(data);
    });

    _socket!.on('group_history', (data) {
      _log('Received group history with ${data.length} messages');
      onGroupHistory?.call(data);
    });

    _socket!.on('user_status', (data) {
      _log('User status update: $data');
      onUserStatus?.call(data);
    });

    _socket!.on('message_read_confirmed', (data) {
      _log('Message read confirmed: $data');
      onMessageReadConfirmed?.call(data);
    });

    _socket!.on('error', (data) {
      _log('Socket error: $data');
      onError?.call(data['message'] ?? 'An error occurred');
    });

    _socket!.on('__ping', (_) {
      _log('Received server heartbeat');
      _socket!.emit('__pong');
    });

    _socket!.onDisconnect((_) {
      _log('Socket disconnected');
      _joinedGroups.clear();
      if (onConnectionStatus != null) {
        onConnectionStatus!('Disconnected');
      }
    });

    _socket!.onReconnect((_) {
      _log('Socket reconnected');
      if (onConnectionStatus != null) {
        onConnectionStatus!('Reconnected');
      }
    });

    _socket!.onReconnectAttempt((attempt) {
      _log('Socket reconnection attempt: $attempt');
    });

    _socket!.onReconnectError((error) {
      _log('Socket reconnection error: $error');
    });

    _socket!.onReconnectFailed((_) {
      _log('Socket reconnection failed');
      if (onConnectionStatus != null) {
        onConnectionStatus!('Reconnection failed');
      }
    });
  }

  void _log(String message) {
    if (kDebugMode) {
      print('[SocketService] $message');
    }
  }

  void dispose() {
    _log('Disposing socket service');
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    _joinedGroups.clear();
    activeUsers.dispose();
    userTypingStatus.dispose();
    _log('Socket service disposed');
  }
}
