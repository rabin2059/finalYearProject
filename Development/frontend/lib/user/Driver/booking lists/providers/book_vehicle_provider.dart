import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants.dart';
import '../../../../data/services/book_vehicle_service.dart';
import 'book_vehicle_state.dart';

class BookVehicleNotifier extends StateNotifier<BookVehicleState> {
  final BookVehicleService bookVehicleService;

  BookVehicleNotifier({required this.bookVehicleService})
      : super(BookVehicleState());

  Future<void> fetchBookingsByVehicle(int vehicleId) async {
    try {
      state = state
          .copyWith(isLoading: true, errorMessage: '', bookingByVehicle: []);
      print(state);
      final bookVehicle =
          await bookVehicleService.fetchBookingsByVehicle(vehicleId);
      state = state.copyWith(isLoading: false, bookingByVehicle: bookVehicle);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final bookVehicleProvider =
    StateNotifierProvider<BookVehicleNotifier, BookVehicleState>((ref) {
  final bookVehicleService = BookVehicleService(baseUrl: apiBaseUrl);
  return BookVehicleNotifier(bookVehicleService: bookVehicleService);
});
