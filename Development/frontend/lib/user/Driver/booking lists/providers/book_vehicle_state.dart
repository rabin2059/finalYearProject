import 'package:frontend/data/models/booking_vehicle_model.dart';

class BookVehicleState {
  final bool isLoading;
  final String? errorMessage;
  final List<BookingByVehicle>? bookingByVehicle;

  BookVehicleState({
    this.isLoading = false,
    this.errorMessage = '',
    this.bookingByVehicle = const [],
  });

  BookVehicleState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<BookingByVehicle>? bookingByVehicle,
  }) {
    return BookVehicleState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      bookingByVehicle: bookingByVehicle ?? this.bookingByVehicle,
    );
  }

  factory BookVehicleState.initial(Map<String, dynamic>? response) {
    return BookVehicleState(
      isLoading: false,
      errorMessage: '',
      bookingByVehicle: response?['bookingByVehicle'] ?? [],
    );
  }
}
