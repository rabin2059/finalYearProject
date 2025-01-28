import '../../../core/role.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthState {
  final String? token; // Access token for API requests
  final String? refreshToken; // Token for renewing the access token
  final String? userId; // User identifier
  final DateTime? tokenExpiry; // Expiration time of the access token
  final DateTime? sessionExpiry; // Expiration time of the session
  final UserRole? currentRole; // Currently active role
  final List<UserRole> roles; // All roles assigned to the user
  final bool isLoading; // Tracks if an authentication operation is ongoing
  final String? error; // Stores error messages
  final bool isLoggedIn; // Indicates if the user is authenticated

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
    String? userId,
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
    final userId = decodedToken['userId']?.toString();
    final tokenExpiry = JwtDecoder.getExpirationDate(token);

    return AuthState(
      token: token,
      refreshToken: refreshToken,
      userId: userId,
      tokenExpiry: tokenExpiry,
      sessionExpiry:
          DateTime.now().add(Duration(hours: 12)), // Example session duration
      currentRole: UserRole.USER, // Default role; customize as needed
      roles: [
        UserRole.USER,
        UserRole.DRIVER
      ], // Example roles; fetch from response
      isLoggedIn: true,
    );
  }
}
