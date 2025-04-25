

import '../../../../data/models/passenger_model.dart';

class PassengerState {
  final PassengerData? homeData;
  final String errorMessage;

  PassengerState({
    this.homeData,
    this.errorMessage = '',
  });

  PassengerState copyWith({
    PassengerData? homeData,
    String? errorMessage,
  }) {
    return PassengerState(
      homeData: homeData ?? this.homeData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  factory PassengerState.initial(Map<String, dynamic>? response) {
    return PassengerState(
      homeData: response != null
          ? PassengerData.fromJson(response)
          : null,
      errorMessage: response?['errorMessage'] ?? '',
    );
  }
}
