import 'package:frontend/data/models/user_model.dart';

class SettingState {
  final List<User> users; // Pluralized for clarity
  final String errorMessage;

  SettingState({
    this.users = const [],
    this.errorMessage = '',
  });

  SettingState copyWith({
    List<User>? users,
    String? errorMessage,
  }) {
    return SettingState(
      users: users ?? this.users,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory SettingState.initial(Map<String, dynamic>? response) {
    return SettingState(
      users: (response?['users'] as List<dynamic>?)
              ?.map((user) => User.fromJson(user as Map<String, dynamic>))
              .toList() ??
          [],
      errorMessage: response?['errorMessage'] ?? '',
    );
  }
}