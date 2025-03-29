import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/role.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../../core/constants.dart';
import '../../../../core/shared_prefs_utils.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/socket_service.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService authService;
  final SocketService socketService;

  AuthNotifier({required this.authService, required this.socketService})
      : super(AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await authService.login(email, password);
      final token = response['token'];
      final refreshToken = response['refreshToken'];

      final newState = AuthState.fromLoginResponse(response);

      await SharedPrefsUtil.saveToken(token, newState.tokenExpiry!);
      await SharedPrefsUtil.saveRefreshToken(refreshToken!);

      state = newState;

      if (state.isLoggedIn && state.userId != null) {
        _disconnectSocket();
        socketService.connect(state.userId.toString());
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> logout() async {
    try {
      if (state.isLoggedIn && state.userId != null) {
       _disconnectSocket();
      }

      // Clear tokens and state
      await SharedPrefsUtil.clearAll();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

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

      state = state.copyWith(
        token: newToken,
        tokenExpiry: newExpiry,
        isLoggedIn: true,
      );

      await SharedPrefsUtil.saveToken(newToken, newExpiry);

      if (state.isLoggedIn && state.userId != null) {
        _reconnectSocket();
      }
    } catch (e) {
      _disconnectSocket();
      state = AuthState(error: "Session expired. Please log in again.");
    }
  }

  Future<void> loadSession() async {
    state = state.copyWith(isLoading: true);

    try {
      final tokenData = await SharedPrefsUtil.getToken();
      final refToken = await SharedPrefsUtil.getRefreshToken();

      if (tokenData['token'] != null && tokenData['expiry'] != null) {
        final expiry = DateTime.parse(tokenData['expiry']!);

        if (DateTime.now().isBefore(expiry)) {
          // Token still valid, extract user info
          Map<String, dynamic> decodedToken =
              JwtDecoder.decode(tokenData['token']!);

          state = state.copyWith(
            token: tokenData['token'],
            refreshToken: refToken,
            tokenExpiry: expiry,
            isLoggedIn: true,
            userId: decodedToken['userId'] ?? decodedToken['id'],
            roles: decodedToken['roles'] ?? [],
            isLoading: false,
          );

          // Connect socket with valid session
          if (state.userId != null) {
            socketService.connect(state.userId.toString());
          }
        } else {
          // Token expired, try refresh
          await refreshToken();
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setTemporaryRole(UserRole newRole) {
    state = state.copyWith(currentRole: newRole);
  }

  void _connectSocket() {
    if (state.isLoggedIn && state.userId != null) {
      socketService.connect(state.userId.toString());
    }
  }

  void _disconnectSocket() {
    if (state.userId != null) {
      socketService.disconnect(state.userId.toString());
    }
  }

  void _reconnectSocket() {
    _disconnectSocket();
    _connectSocket();
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService(baseUrl: socketBaseUrl);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = AuthService(baseUrl: apiBaseUrl);
  final socketService = ref.watch(socketServiceProvider);
  return AuthNotifier(authService: authService, socketService: socketService);
});
