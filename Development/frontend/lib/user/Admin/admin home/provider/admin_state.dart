import 'package:frontend/data/models/all_user_model.dart';

class AdminState {
  final bool isLoading;
  final List<User>? users;
  final String errorMessage;
  AdminState({
    this.isLoading = false,
    this.users = const [],
    this.errorMessage = '',
  });

  AdminState copyWith({
    bool? isLoading,
    List<User>? users,
    String? errorMessage,
  }) {
    return AdminState(
        isLoading: isLoading ?? this.isLoading,
        users: users ?? this.users,
        errorMessage: errorMessage ?? this.errorMessage);
  }

  factory AdminState.initial(Map<String, dynamic>? response) {
    return AdminState(
        isLoading: false,
        errorMessage: response?['error'] ?? '',
        users: response?['user'] ?? []);
  }
}
