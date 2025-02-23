import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/role.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../../core/constants.dart';
import '../../../../core/shared_prefs_utils.dart';
import '../../../../data/services/auth_service.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;

  AuthNotifier({required this.authService}) : super(AuthState());

  /// Login Function
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await authService.login(email, password);
      final token = response['token'];
      final refreshToken = response['refreshToken'];

      final newState = AuthState.fromLoginResponse(response);

      // Save tokens to shared preferences
      await SharedPrefsUtil.saveToken(token, newState.tokenExpiry!);
      await SharedPrefsUtil.saveRefreshToken(refreshToken!);

      state = newState;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Logout Function
  Future<void> logout() async {
    state = AuthState(); // Clear state
    await SharedPrefsUtil.clearAll(); // Clear shared preferences

    state = state.copyWith(isLoggedIn: false);
  }

  /// Refresh Token Function
  Future<void> refreshToken() async {
    if (state.refreshToken == null) {
      state =
          AuthState(error: "No refresh token available. Please log in again.");
      return;
    }

    try {
      final response = await authService.refreshToken(state.refreshToken!);
      final newToken = response['token'];
      final newExpiry = JwtDecoder.getExpirationDate(newToken);

      // Update state with the new token
      state = state.copyWith(
        token: newToken,
        tokenExpiry: newExpiry,
        isLoggedIn: true,
      );

      // Save the new token to shared preferences
      await SharedPrefsUtil.saveToken(newToken, newExpiry);
    } catch (e) {
      state = AuthState(error: "Session expired. Please log in again.");
    }
  }

  /// Load Session on App Start
  Future<void> loadSession() async {
    final tokenData = await SharedPrefsUtil.getToken();
    final refToken = await SharedPrefsUtil.getRefreshToken();

    if (tokenData['token'] != null && tokenData['expiry'] != null) {
      final expiry = DateTime.parse(tokenData['expiry']!);

      // Check if token is expired
      if (DateTime.now().isBefore(expiry)) {
        state = state.copyWith(
          token: tokenData['token'],
          refreshToken: refToken,
          tokenExpiry: expiry,
          isLoggedIn: true,
        );
      } else // Attempt to refresh token if access token has expired
        await refreshToken();
    }
  }

  void setTemporaryRole(UserRole newRole) {
    state = state.copyWith(currentRole: newRole);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = AuthService(baseUrl: apiBaseUrl);
  return AuthNotifier(authService: authService);
});
