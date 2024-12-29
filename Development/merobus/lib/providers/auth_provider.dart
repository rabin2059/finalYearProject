import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:merobus/Services/auth_service.dart';
import 'package:merobus/States/auth_notifier.dart';
import 'package:merobus/States/auth_state.dart';
import 'package:merobus/routes/routes.dart';

// Correct the spelling of 'authServiceProvider'
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(baseUrl: Routes.route); // Ensure Routes.route is correct
});

// Create the StateNotifierProvider for AuthNotifier
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider); // Use the correct provider
  return AuthNotifier(authService: authService);
});