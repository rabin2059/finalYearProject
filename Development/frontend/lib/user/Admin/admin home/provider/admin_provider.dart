import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants.dart';
import '../../../../data/services/admin_service.dart';
import 'admin_state.dart';

class AdminNotifier extends StateNotifier<AdminState> {
  final AdminService adminService;

  AdminNotifier({required this.adminService}) : super(AdminState());

  Future<void> fetchAllUser() async {
    try {
      state = state.copyWith(isLoading: true, users: null, errorMessage: '');
      final user = await adminService.getAllUsers();
      print(user);
      state = state.copyWith(isLoading: false, users: user, errorMessage: '');
    } catch (e) {
      // Handle any errors
      print('Error fetching users: $e');
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final adminService = AdminService(baseUrl: apiBaseUrl);
  return AdminNotifier(adminService: adminService);
});
