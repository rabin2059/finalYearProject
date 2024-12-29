class AuthState {
  final bool isAuthenticated;
  final String token;
  final int userRole;

  AuthState(
      {required this.isAuthenticated,
      required this.token,
      required this.userRole});

  AuthState copyWith({bool? isAuthenticated, String? token, int? userRole}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      userRole: userRole ?? this.userRole,
    );
  }
}
