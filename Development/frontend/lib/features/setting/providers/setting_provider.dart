import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/services/user_service.dart';
import 'package:frontend/features/setting/providers/setting_state.dart';

import '../../../core/constants.dart';

class SettingNotifier extends StateNotifier<SettingState> {
  final UserService userService;

  SettingNotifier({required this.userService}) : super(SettingState());

  /// Fetch users from the API
  Future<void> fetchUsers(int userId) async {
    print('Calling fetchUsers() with userId: $userId'); // Debug userId

    try {
      final users = await userService.fetchUsers(userId);
      print('Fetched users: ${users.length}'); // Debug response size

      state = state.copyWith(users: users, errorMessage: '');
    } catch (e) {
      print('Error fetching users: $e');
      state = state.copyWith(errorMessage: "Failed to fetch users: $e");
    }
  }
}

final settingProvider =
    StateNotifierProvider<SettingNotifier, SettingState>((ref) {
  final userService = UserService(baseurl: apiBaseUrl);
  return SettingNotifier(userService: userService);
});
