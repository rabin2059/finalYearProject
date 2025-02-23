import 'package:frontend/data/models/user_model.dart';

class SettingState {
  final List<UserData> users; // Pluralized for clarity
  final String errorMessage;

  SettingState({
    this.users = const [],
    this.errorMessage = '',
  });

  SettingState copyWith({
    List<UserData>? users,
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
              ?.map((user) => UserData.fromJson(user as Map<String, dynamic>))
              .toList() ??
          [],
      errorMessage: response?['errorMessage'] ?? '',
    );
  }
}