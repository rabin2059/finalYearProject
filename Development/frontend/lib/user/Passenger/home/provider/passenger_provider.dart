import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants.dart';
import '../../../../data/services/passenger_service.dart';
import 'passenger_state.dart';

class PassengerNotifier extends StateNotifier<PassengerState> {
  final PassengerService passengerService;

  PassengerNotifier({required this.passengerService}) : super(PassengerState());

  Future<void> fetchHomeData(int userId) async {
    try {
      final data = await passengerService.fetchHomeData(userId);
      state = state.copyWith(homeData: data, errorMessage: '');
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final passengerProvider =
    StateNotifierProvider<PassengerNotifier, PassengerState>((ref) {
  final service = PassengerService(baseUrl: apiBaseUrl);
  return PassengerNotifier(passengerService: service);
});
