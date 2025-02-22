import '../../../../core/role.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthState {
  final String? token;
  final String? refreshToken;
  final int? userId;
  final DateTime? tokenExpiry;
  final DateTime? sessionExpiry;
  final UserRole? currentRole;
  final List<UserRole> roles;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  const AuthState({
    this.token,
    this.refreshToken,
    this.userId,
    this.tokenExpiry,
    this.sessionExpiry,
    this.currentRole,
    this.roles = const [],
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
  });

  /// Check if the token is expired
  bool get isTokenExpired {
    if (tokenExpiry == null) return true;
    return DateTime.now().isAfter(tokenExpiry!);
  }

  /// Check if the session is expired
  bool get isSessionExpired {
    if (sessionExpiry == null) return true;
    return DateTime.now().isAfter(sessionExpiry!);
  }

  /// Copy with updated fields
  AuthState copyWith({
    String? token,
    String? refreshToken,
    int? userId,
    DateTime? tokenExpiry,
    DateTime? sessionExpiry,
    UserRole? currentRole,
    List<UserRole>? roles,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
  }) {
    return AuthState(
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      sessionExpiry: sessionExpiry ?? this.sessionExpiry,
      currentRole: currentRole ?? this.currentRole,
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  /// Create AuthState from a login response
  factory AuthState.fromLoginResponse(Map<String, dynamic> response) {
    final token = response['token'] as String;
    final refreshToken = response['refreshToken'] as String;

    // Decode the token to extract userId and expiration
    final decodedToken = JwtDecoder.decode(token);
    final userId = decodedToken['userId'] as int;
    final userRoleString = decodedToken['role'] as String;
    final tokenExpiry = JwtDecoder.getExpirationDate(token);

    // ✅ Convert role from String to Enum
    final UserRole userRole = _parseUserRole(userRoleString);

    return AuthState(
      token: token,
      refreshToken: refreshToken,
      userId: userId,
      tokenExpiry: tokenExpiry,
      sessionExpiry:
          DateTime.now().add(Duration(hours: 12)), // Example session duration
      currentRole: userRole,
      roles: [
        UserRole.USER,
        UserRole.DRIVER,
        UserRole.ADMIN,
      ], // Example roles; fetch from response
      isLoggedIn: true,
    );
  }

  /// **Helper function to convert string to `UserRole` enum**
  static UserRole _parseUserRole(String role) {
    switch (role.toUpperCase()) {
      case 'USER':
        return UserRole.USER;
      case 'DRIVER':
        return UserRole.DRIVER;
      case 'ADMIN':
        return UserRole.ADMIN;
      default:
        throw Exception("Invalid role: $role");
    }
  }
}
