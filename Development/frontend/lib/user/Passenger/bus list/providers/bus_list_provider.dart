import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants.dart';
import 'package:frontend/data/services/bus_service.dart';

import 'bus_state.dart';

class BusListNotifier extends StateNotifier<BusState> {
  final BusService busService;

  BusListNotifier({required this.busService}) : super(BusState());

  Future<void> fetchBusList() async {
    try {
      state = state.copyWith(loading: true, buses: [], errorMessage: '');
      final busList = await busService.getBuses();
      state = state.copyWith(loading: false, buses: busList, errorMessage: '');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final busProvider = StateNotifierProvider<BusListNotifier, BusState>((ref) {
  final busService = BusService(baseUrl: apiBaseUrl);
  return BusListNotifier(busService: busService);
});
