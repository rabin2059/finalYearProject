import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/services/bus_service.dart';
import 'package:frontend/features/bus%20details/providers/single_bus_state.dart';

import '../../../core/constants.dart';

class BusDetailsNotifier extends StateNotifier<SingleBusState> {
  final BusService busService;

  BusDetailsNotifier({required this.busService}) : super(SingleBusState());

  Future<void> fetchBusDetail(int busId) async {
    try {
      state = state.copyWith(isLoading: true, vehicle: null, error: '');
      final busDetail = await busService.getBus(busId);
      state = state.copyWith(isLoading: false, vehicle: busDetail, error: '');
    } catch (e) {
      state =
          state.copyWith(isLoading: false, vehicle: null, error: e.toString());
    }
  }
}

final busDetailsProvider =
    StateNotifierProvider<BusDetailsNotifier, SingleBusState>((ref) {
  final busService = BusService(baseUrl: apiBaseUrl);
  return BusDetailsNotifier(busService: busService);
});
