import 'package:frontend/data/models/bus.dart';

class SingleBusState {
  final bool isLoading;
  final Vehicle? vehicle;
  final String error;

  SingleBusState({
    this.isLoading = false,
    this.vehicle,
    this.error = '',
  });

  SingleBusState copyWith({
    bool? isLoading,
    Vehicle? vehicle,
    String? error,
  }) {
    return SingleBusState(
      isLoading: isLoading ?? this.isLoading,
      vehicle: vehicle ?? this.vehicle,
      error: error ?? this.error,
    );
  }

  factory SingleBusState.initial(Map<String, dynamic>? response) {
    return SingleBusState(
      isLoading: false,
      vehicle: response?['vehicle'],
      error: response?['error'] ?? '',
    );
  }
}
