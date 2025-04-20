
import '../../../../data/models/bus_model.dart';

class BusState {
  final bool loading;
  final List<Bus> buses;
  final String errorMessage;

  BusState({
    this.loading = true,
    this.buses = const [],
    this.errorMessage = '',
  });

  BusState copyWith({
    bool? loading,
    List<Bus>? buses,
    String? errorMessage,
  }) {
    return BusState(
      loading: loading ?? this.loading,
      buses: buses ?? this.buses,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// **Fix: Properly converts `response['buses']` from `List<dynamic>` to `List<BusModel>`**
  factory BusState.initial(Map<String, dynamic>? response) {
    return BusState(
      loading: false,
      buses: (response?['buses'] as List<dynamic>?)
              ?.map((bus) =>
                  Bus.fromJson(bus)) // ✅ Converts each item to `BusModel`
              .toList() ??
          [], // ✅ Default to an empty list
      errorMessage: response?['message'] ?? '',
    );
  }
}
