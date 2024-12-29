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
      final result = await authService.login(email, password);
      final prefs = await SharedPreferences.getInstance();
      final user = Login.fromJson(result);
      state = AuthState(
          isAuthenticated: true, token: user.token, userRole: user.userRole);
      prefs.setString('token', state.token);
      prefs.setInt('userRole', state.userRole);
      return true;
    } catch (e) {
      print(e);
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

  void _navigateToLogin() {
  }
}
