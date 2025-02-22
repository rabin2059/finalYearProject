import '../../../../data/models/map_model.dart';

class MapState {
  final LocationModel? userLocation;
  final LocationModel? selectedLocation;
  final RouteModel? route;
  final List<LocationModel>? searchResults;
  final bool isLoading;
  final String? error;

  MapState({
    this.userLocation,
    this.selectedLocation,
    this.route,
    this.searchResults,
    this.isLoading = false,
    this.error,
  });

  MapState copyWith({
    LocationModel? userLocation,
    LocationModel? selectedLocation,
    RouteModel? route,
    List<LocationModel>? searchResults,
    bool? isLoading,
    String? error,
  }) {
    return MapState(
      userLocation: userLocation ?? this.userLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      route: route ?? this.route,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
