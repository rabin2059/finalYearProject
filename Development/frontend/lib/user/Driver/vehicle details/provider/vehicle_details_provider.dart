import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants.dart';
import '../../../../data/services/vehicle_service.dart';
import 'vehicle_details_state.dart';

class VehicleNotifier extends StateNotifier<VehicleState> {
  final VehicleService vehicleService;

  VehicleNotifier({ required this.vehicleService }) : super(VehicleState.initial());

  Future<void> loadVehicle(int vehicleId) async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final vehicle = await vehicleService.fetchVehicleDetails(vehicleId);
      print(vehicleId);
      state = state.copyWith(vehicle: vehicle, isLoading: false);

    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoading:    false,
      );
    }
  }
}

final vehicleProvider = StateNotifierProvider<VehicleNotifier, VehicleState>((ref) {
  final service = VehicleService(baseUrl: apiBaseUrl);
  return VehicleNotifier(vehicleService: service);
});