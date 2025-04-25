import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:merobus/Services/auth_service.dart';
import 'package:merobus/States/auth_state.dart';
import 'package:merobus/models/loginModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:merobus/main.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;

  AuthNotifier({required this.authService})
      : super(AuthState(isAuthenticated: false, token: '', userRole: 1));

  Future<bool> register(String username, String email, String password,
      String confirmPassword) async {
    try {
      final result = await authService.register(
        username,
        email,
        password,
        confirmPassword,
      );

      return true;
    } catch (e) {
      print('Registration error: $e');
      // Return false in case of any error
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // Call the login API
      final result = await authService.login(email, password);

      // Parse the JSON response
      final user = Login.fromJson(result);
      print(user);

      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Map user role to integers
      int role =
          user.userRole == 'USER' ? 1 : (user.userRole == 'ADMIN' ? 0 : 2);

      // Update application state
      state = AuthState(
        isAuthenticated: true,
        token: user.token,
        userRole: role, // Ensure role is an int
      );

      // Save token and role to SharedPreferences
      await prefs.setString('token', state.token);
      await prefs.setInt('userRole', role); // Store role as an int

      print("Login successful");
      return true;
    } catch (e) {
      // Log the error
      print('Login failed: $e');
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isNotEmpty) {
      try {
        // Check if the token is expired
        bool isExpired = await authService.isTokenExpired(token);
        if (!isExpired) {
          return false;
        } else {
          // If token is expired, navigate to login screen
          await prefs.clear();
          _navigateToLogin(); // Navigate to login screen
          return false;
        }
      } catch (e) {
        print('Error checking token expiration: $e');
        // If there's an error (e.g., malformed token), treat it as expired
        await prefs.clear();
        return true;
      }
    }

    // If no valid token is found, clear preferences and return false
    await prefs.clear();
    return false;
  }

  Future<void> logout() async {
    state = AuthState(isAuthenticated: false, token: '', userRole: 0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  void _navigateToLogin() {}
}
