import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/setting/providers/setting_state.dart';
import 'package:http/http.dart';

import '../../../core/constants.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/user_service.dart';

class ProfileNotifier extends StateNotifier<SettingState> {
  final UserService userService;

  ProfileNotifier({required this.userService}) : super(SettingState());

  Future<void> updateProfile(int userId, String username, String email,
      String phone, String address, File? imagePath) async {
    try {
      final response = await userService.updateUser(
          userId, username, email, address, phone, imagePath!);

      if (response['message'] == 'User updated successfully') {
        print('Profile updated successfully');
        final user = response['user'];
        state = state.copyWith(users: [user], errorMessage: '');
      } else {
        print('Failed to update profile: ${response['message']}');
        state = state.copyWith(errorMessage: response['message']);
      }
    } catch (e) {
      print('Error updating profile: $e');
      state = state.copyWith(errorMessage: 'Error updating profile');
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, SettingState>((ref) {
  final userService = UserService(baseurl: apiBaseUrl);
  return ProfileNotifier(userService: userService);
});
