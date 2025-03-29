import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'package:flutter/foundation.dart';

class SocketService {
  final String baseUrl;
  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;
  String? get socketId => _socket?.id;

  final Set<int> _joinedGroups = {};

  // Store user join dates for groups
  final Map<int, String> _userJoinDates = {};

  // Store active completers to prevent duplicate completion
  final Map<String, Completer<dynamic>> _activeCompleters = {};

  final ValueNotifier<List<String>> activeUsers =
      ValueNotifier<List<String>>([]);
  final ValueNotifier<Map<String, bool>> userTypingStatus =
      ValueNotifier<Map<String, bool>>({});

  Function(Map<String, dynamic>)? onNewMessage;
  Function(Map<String, dynamic>)? onMessageSent;
  Function(List<dynamic>)? onGroupHistory;
  Function(List<dynamic>)? onMessagesSinceJoin;
  Function(Map<String, dynamic>)? onUserStatus;
  Function(Map<String, dynamic>)? onMessageReadConfirmed;
  Function(String)? onError;
  Function(String)? onConnectionStatus;
  Function(Map<String, dynamic>)? onMembershipStatus;
  final ValueNotifier<List<String>> onActiveBusesReceived =
      ValueNotifier<List<String>>([]);

  SocketService({required this.baseUrl});

  void connect(String userId) {
    _log('Attempting to connect to socket server: $baseUrl');
    _log('Using user ID: $userId');

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

    _socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'Access-Control-Allow-Origin': '*'})
            .setReconnectionAttempts(10)
            .setReconnectionDelay(1000)
            .enableReconnection()
            .build());

    _setupEventListeners();

    _log('Connecting to socket...');
    _socket!.connect();

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
      _userJoinDates.clear();

      _activeCompleters.clear();

      _log('Socket disconnected');
      if (onConnectionStatus != null) {
        onConnectionStatus!('Disconnected');
      }
    }
  }

  bool hasJoinedGroup(int chatGroupId) {
    return _joinedGroups.contains(chatGroupId);
  }

  Future<T> _createCompleterWithTimeout<T>({
    required String key,
    required Duration timeout,
    required String timeoutMessage,
  }) {
    if (_activeCompleters.containsKey(key)) {
      _log('Using existing completer for $key');
      return _activeCompleters[key]!.future as Future<T>;
    }

    final completer = Completer<T>();
    _activeCompleters[key] = completer;

    // Set up timeout
    Timer(timeout, () {
      if (!completer.isCompleted && _activeCompleters[key] == completer) {
        _log('Timeout for $key: $timeoutMessage');
        completer.completeError(timeoutMessage);
        _activeCompleters.remove(key);
      }
    });

    return completer.future;
  }

  void _completeAndRemove<T>(String key, T result) {
    if (_activeCompleters.containsKey(key)) {
      final completer = _activeCompleters[key]!;
      if (!completer.isCompleted) {
        completer.complete(result);
      }
      _activeCompleters.remove(key);
    }
  }

  void _completeErrorAndRemove(String key, dynamic error) {
    if (_activeCompleters.containsKey(key)) {
      final completer = _activeCompleters[key]!;
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
      _activeCompleters.remove(key);
    }
  }

  // New method to check user membership in a group
  Future<Map<String, dynamic>> checkUserInGroup(
      String userId, int chatGroupId) async {
    if (!isConnected) {
      _log('Cannot check membership: Not connected to socket server');
      throw Exception('Not connected to socket server');
    }

    final completerKey = 'membership_${userId}_$chatGroupId';

    _log('Checking membership: userId=$userId, chatGroupId=$chatGroupId');
    _socket!.emit('check_group_membership', {
      'userId': userId,
      'chatGroupId': chatGroupId,
    });

    // Use one-time handler to avoid duplicate event handling
    _socket!.once('membership_status', (data) {
      _log('Received membership status: $data');

      if (data['isMember'] == true && data['joinedAt'] != null) {
        _userJoinDates[chatGroupId] = data['joinedAt'];
        if (data['isInRoom'] != true) {
          _socket!.emit('join_room', {'chatGroupId': chatGroupId});
        }
        _joinedGroups.add(chatGroupId);
      }

      if (onMembershipStatus != null) {
        onMembershipStatus!(data);
      }

      _completeAndRemove(completerKey, data);
    });

    _socket!.once('error', (data) {
      _log('Error checking membership: $data');
      _completeErrorAndRemove(
          completerKey, data['message'] ?? 'Failed to check membership');
    });

    return _createCompleterWithTimeout<Map<String, dynamic>>(
        key: completerKey,
        timeout: Duration(seconds: 5),
        timeoutMessage: 'Timeout while checking membership');
  }

  Future<List<dynamic>> fetchMessagesSinceJoin(int chatGroupId) async {
    if (!isConnected) {
      _log('Cannot fetch messages: Not connected to socket server');
      throw Exception('Not connected to socket server');
    }

    if (!_userJoinDates.containsKey(chatGroupId)) {
      _log(
          'Join date not found for group $chatGroupId, fetching full history instead');
      return fetchGroupHistory(chatGroupId);
    }

    final joinedAt = _userJoinDates[chatGroupId];
    _log('Fetching messages since $joinedAt for group $chatGroupId');

    final completerKey = 'messages_since_$chatGroupId';

    _socket!.emit('fetch_messages_since', {
      'chatGroupId': chatGroupId,
      'since': joinedAt,
    });

    _socket!.once('messages_since', (data) {
      _log('Received ${data.length} messages since join date');
      _completeAndRemove(completerKey, data);
    });

    _socket!.once('error', (data) {
      _log('Error fetching messages since join: $data');
      _completeErrorAndRemove(
          completerKey, data['message'] ?? 'Failed to fetch messages');
    });

    return _createCompleterWithTimeout<List<dynamic>>(
        key: completerKey,
        timeout: Duration(seconds: 10),
        timeoutMessage: 'Timeout while fetching messages since join');
  }

  Future<void> sendMessage(int senderId, int chatGroupId, String text) async {
    if (!isConnected) {
      _log('Cannot send message: Not connected to socket server');
      throw Exception('Not connected to socket server');
    }

    if (!_joinedGroups.contains(chatGroupId)) {
      try {
        _log('Checking user membership in group $chatGroupId');
        final membershipData =
            await checkUserInGroup(senderId.toString(), chatGroupId);

        if (membershipData['isMember'] == true) {
          _log('User is already a member of group $chatGroupId');
        } else {
          _log('User is not a member, attempting to join group $chatGroupId');
          await _autoJoinGroup(senderId.toString(), chatGroupId);
        }
      } catch (e) {
        _log('Group membership check failed: $e');
        _log('Will attempt to send message anyway');

        try {
          await _autoJoinGroup(senderId.toString(), chatGroupId);
        } catch (joinError) {
          _log(
              'Auto-join failed, but will attempt to send message anyway: $joinError');
        }
      }
    }

    final messageData = {
      'senderId': senderId,
      'chatGroupId': chatGroupId,
      'text': text,
    };

    _log('Sending message: $messageData');
    _socket!.emit('send_message', messageData);

    final completerKey =
        'send_message_${senderId}_${chatGroupId}_${DateTime.now().millisecondsSinceEpoch}';

    _socket!.once('message_sent', (data) {
      _log('Message sent confirmation received: $data');
      _completeAndRemove(completerKey, null);
    });

    _socket!.once('error', (data) {
      _log('Error sending message: $data');
      _completeErrorAndRemove(
          completerKey, data['message'] ?? 'Failed to send message');
    });

    return _createCompleterWithTimeout<void>(
        key: completerKey,
        timeout: Duration(seconds: 5),
        timeoutMessage: 'Timeout while sending message');
  }

  Future<void> _autoJoinGroup(String userId, int chatGroupId) async {
    final completerKey = 'auto_join_${userId}_$chatGroupId';

    _log('Auto-joining group: userId=$userId, chatGroupId=$chatGroupId');
    _socket!.emit('join_group', {
      'userId': userId,
      'chatGroupId': chatGroupId,
    });

    _socket!.once('group_joined', (data) {
      _log('Successfully joined group: $chatGroupId');
      _joinedGroups.add(chatGroupId);

      if (data != null && data['joinedAt'] != null) {
        _userJoinDates[chatGroupId] = data['joinedAt'];
      } else {
        _userJoinDates[chatGroupId] = DateTime.now().toIso8601String();
      }

      _completeAndRemove(completerKey, null);
    });

    // Use one-time error handler
    _socket!.once('error', (data) {
      _log('Error joining group: $data');
      _completeErrorAndRemove(
          completerKey, data['message'] ?? 'Failed to join group');
    });

    return _createCompleterWithTimeout<void>(
        key: completerKey,
        timeout: Duration(seconds: 5),
        timeoutMessage: 'Timeout while joining group');
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

    final completerKey = 'group_history_$chatGroupId';

    _log('Fetching group history for chatGroupId: $chatGroupId');
    _socket!.emit('fetch_group_history', {'chatGroupId': chatGroupId});

    // Use one-time handler
    _socket!.once('group_history', (data) {
      _log('Received group history: ${data.length} messages');
      _completeAndRemove(completerKey, data);
    });

    // Use one-time error handler
    _socket!.once('error', (data) {
      _log('Error fetching history: $data');
      _completeErrorAndRemove(
          completerKey, data['message'] ?? 'Failed to fetch history');
    });

    return _createCompleterWithTimeout<List<dynamic>>(
        key: completerKey,
        timeout: Duration(seconds: 10),
        timeoutMessage: 'Timeout while fetching history');
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

    final completerKey = 'join_group_${userId}_$chatGroupId';

    _log('Joining group: userId=$userId, chatGroupId=$chatGroupId');
    _socket!.emit('join_group', {'userId': userId, 'chatGroupId': chatGroupId});

    // Use one-time handler
    _socket!.once('group_joined', (data) {
      _log('Successfully joined group: $chatGroupId');
      _joinedGroups.add(chatGroupId);

      // Store join date if provided
      if (data != null && data['joinedAt'] != null) {
        _userJoinDates[chatGroupId] = data['joinedAt'];
      } else {
        // If not provided, use current time
        _userJoinDates[chatGroupId] = DateTime.now().toIso8601String();
      }

      _completeAndRemove(completerKey, null);
    });

    // Use one-time error handler
    _socket!.once('error', (data) {
      _log('Error joining group: $data');
      _completeErrorAndRemove(
          completerKey, data['message'] ?? 'Failed to join group');
    });

    return _createCompleterWithTimeout<void>(
        key: completerKey,
        timeout: Duration(seconds: 5),
        timeoutMessage: 'Timeout while joining group');
  }

  Future<void> leaveGroup(String userId, int chatGroupId) async {
    if (!isConnected) {
      _log('Cannot leave group: Not connected to socket server');
      throw Exception('Not connected to socket server');
    }

    final completerKey = 'leave_group_${userId}_$chatGroupId';

    _log('Leaving group: userId=$userId, chatGroupId=$chatGroupId');
    _socket!
        .emit('leave_group', {'userId': userId, 'chatGroupId': chatGroupId});

    // Use one-time handler
    _socket!.once('group_left', (data) {
      _log('Successfully left group: $chatGroupId');
      _joinedGroups.remove(chatGroupId);
      _userJoinDates.remove(chatGroupId);
      _completeAndRemove(completerKey, null);
    });

    // Use one-time error handler
    _socket!.once('error', (data) {
      _log('Error leaving group: $data');
      _completeErrorAndRemove(
          completerKey, data['message'] ?? 'Failed to leave group');
    });

    return _createCompleterWithTimeout<void>(
        key: completerKey,
        timeout: Duration(seconds: 5),
        timeoutMessage: 'Timeout while leaving group');
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

    final completerKey = 'message_read_$messageId';

    _log('Marking message as read: messageId=$messageId');
    _socket!.emit('message_read', messageId);

    // Use one-time handler
    _socket!.once('message_read_confirmed', (data) {
      _log('Message marked as read: $messageId');
      _completeAndRemove(completerKey, null);
    });

    // Use one-time error handler
    _socket!.once('error', (data) {
      _log('Error marking message as read: $data');
      _completeErrorAndRemove(
          completerKey, data['message'] ?? 'Failed to mark as read');
    });

    return _createCompleterWithTimeout<void>(
        key: completerKey,
        timeout: Duration(seconds: 5),
        timeoutMessage: 'Timeout while marking as read');
  }

  Future<Map<String, dynamic>> ping() async {
    if (!isConnected) {
      _log('Cannot ping: Not connected to socket server');
      throw Exception('Not connected to socket server');
    }

    final completerKey = 'ping_${DateTime.now().millisecondsSinceEpoch}';

    _log('Pinging server');
    _socket!.emit('ping');

    // Use one-time handler
    _socket!.once('pong', (data) {
      _log('Received pong: $data');
      _completeAndRemove(completerKey, data);
    });

    return _createCompleterWithTimeout<Map<String, dynamic>>(
        key: completerKey,
        timeout: Duration(seconds: 5),
        timeoutMessage: 'Timeout while pinging server');
  }

  // Driver-specific tracking
  Function(String, double, double)? onVehicleLocation;
  final Map<String, Map<String, double>> driverLocations = {};

  void registerDriver(int vehicleId) {
    if (isConnected) {
      _log('Registering driver with vehicleId: $vehicleId');
      _socket!.emit('register-driver', {'vehicleId': vehicleId});
    }
  }

  void sendDriverLocation(int vehicleId, double lat, double lng) {
    if (isConnected) {
      _log('Sending driver location for vehicleId $vehicleId: ($lat, $lng)');
      _socket!.emit('driver-location', {
        'vehicleId': vehicleId,
        'lat': lat,
        'lng': lng,
      });
    }
  }

  void requestActiveBuses() {
    if (isConnected) {
      _log('Requesting list of active buses');
      _socket!.emit('get_active_buses');
    }
  }

  void _setupEventListeners() {
    _socket!.on('active_users', (data) {
      _log('Received active users: $data');
      activeUsers.value = List<String>.from(data);
    });

    _socket!.on('active_buses', (data) {
      _log('Received active buses: $data');
      onActiveBusesReceived.value =
          List<String>.from(data.map((e) => e.toString()));
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

    _socket!.on('messages_since', (data) {
      _log('Received messages since join: ${data.length} messages');
      onMessagesSinceJoin?.call(data);
    });

    _socket!.on('user_status', (data) {
      _log('User status update: $data');
      onUserStatus?.call(data);
    });

    _socket!.on('message_read_confirmed', (data) {
      _log('Message read confirmed: $data');
      onMessageReadConfirmed?.call(data);
    });

    _socket!.on('membership_status', (data) {
      _log('Membership status update: $data');
      onMembershipStatus?.call(data);
    });

    _socket!.on('error', (data) {
      _log('Socket error: $data');
      onError?.call(data['message'] ?? 'An error occurred');
    });

    _socket!.on('__ping', (_) {
      _log('Received server heartbeat');
      _socket!.emit('__pong');
    });

    _socket!.on('vehicle-location', (data) {
      final vehicleId = data['vehicleId']?.toString();
      final lat = data['lat'];
      final lng = data['lng'];
      _log('Received vehicle location: $vehicleId => ($lat, $lng)');

      if (vehicleId != null && lat != null && lng != null) {
        driverLocations[vehicleId] = {'lat': lat, 'lng': lng};
        if (onVehicleLocation != null) {
          onVehicleLocation!(vehicleId, lat.toDouble(), lng.toDouble());
        }
      }
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
    _userJoinDates.clear();
    _activeCompleters.clear();
    activeUsers.dispose();
    onActiveBusesReceived.dispose();
    userTypingStatus.dispose();
    _log('Socket service disposed');
  }
}
