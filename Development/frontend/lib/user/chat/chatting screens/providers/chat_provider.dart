import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants.dart';
import '../../../../data/services/socket_service.dart';

// Create a provider for SocketService that can be accessed throughout the app
final socketServiceProvider = Provider<SocketService>((ref) {
  // Initialize with your socket server URL from constants
  return SocketService(baseUrl: socketBaseUrl);
});
