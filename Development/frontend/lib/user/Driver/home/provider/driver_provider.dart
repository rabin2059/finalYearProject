import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/services/driver_service.dart';
import 'package:frontend/user/Driver/home/provider/driver_state.dart';
import '../../../../core/constants.dart';

class DriverNotifier extends StateNotifier<DriverState> {
  final DriverService driverService;

  DriverNotifier({required this.driverService})
      : super(DriverState());

  Future<void> fetchDriverData(int userId) async {
    try {
      final data = await driverService.fetchHomeData(userId);
      state = state.copyWith(driverData: data, errorMessage: '');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final driverProvider =
    StateNotifierProvider<DriverNotifier, DriverState>((ref) {
  final service = DriverService(baseUrl: apiBaseUrl);
  return DriverNotifier(driverService: service);
});