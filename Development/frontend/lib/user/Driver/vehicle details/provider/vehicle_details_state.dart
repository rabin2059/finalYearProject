import '../../../../data/models/vehicle_details_model.dart';

class VehicleState {
  final Vehicle? vehicle;
  final String errorMessage;
  final bool isLoading;

  VehicleState({
    this.vehicle,
    this.errorMessage = '',
    this.isLoading = false,
  });

  VehicleState copyWith({
    Vehicle? vehicle,
    String? errorMessage,
    bool? isLoading,
  }) {
    return VehicleState(
      vehicle:      vehicle      ?? this.vehicle,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading:    isLoading    ?? this.isLoading,
    );
  }

  factory VehicleState.initial() => VehicleState();
}