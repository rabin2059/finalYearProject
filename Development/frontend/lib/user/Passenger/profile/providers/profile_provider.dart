import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart';

import '../../../../core/constants.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/services/user_service.dart';
import '../../setting/providers/setting_state.dart';

class ProfileNotifier extends StateNotifier<SettingState> {
  final UserService userService;

  ProfileNotifier({required this.userService}) : super(SettingState());

  Future<void> updateProfile(int userId, String username, String email,
      String phone, String address, File? imagePath) async {
    try {
      final response = await userService.updateUser(userId, username, email,
          address, phone, imagePath); // ✅ No force unwrap

      if (response['message'] == 'User updated successfully') {
        final user = response['userData'];
        state = state.copyWith(users: [user], errorMessage: '');
      } else {
        state = state.copyWith(errorMessage: response['message']);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error updating profile');
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, SettingState>((ref) {
  final userService = UserService(baseurl: apiBaseUrl);
  return ProfileNotifier(userService: userService);
});
