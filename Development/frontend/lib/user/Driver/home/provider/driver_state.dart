
import '../../../../data/models/driver_model.dart';

class DriverState {
  final DriverData? driverData;
  final String errorMessage;

  DriverState({
    this.driverData,
    this.errorMessage = '',
  });

  DriverState copyWith({
    DriverData? driverData,
    String? errorMessage,
  }) {
    return DriverState(
      driverData: driverData ?? this.driverData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory DriverState.initial(Map<String, dynamic>? response) {
    return DriverState(
      driverData:
          response != null ? DriverData.fromJson(response) : null,
      errorMessage: response?['errorMessage'] ?? '',
    );
  }
}