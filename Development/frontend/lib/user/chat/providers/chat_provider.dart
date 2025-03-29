import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/services/socket_service.dart';
import 'package:frontend/core/constants.dart';

// Create a provider for SocketService that can be accessed throughout the app
final socketServiceProvider = Provider<SocketService>((ref) {
  // Initialize with your socket server URL from constants
  return SocketService(baseUrl: socketBaseUrl);
});
