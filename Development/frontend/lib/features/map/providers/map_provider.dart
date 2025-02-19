import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/map_model.dart';
import '../../../data/services/map_service.dart';
import 'map_state.dart';

class MapNotifier extends StateNotifier<MapState> {
  final MapService _mapService;

  MapNotifier(this._mapService) : super(MapState());

  /// **1. Fetch User Location**
  Future<void> fetchUserLocation(double lat, double lng) async {
    try {
      state = state.copyWith(isLoading: true);
      LocationModel location = await _mapService.getReverseGeocode(lat, lng);
      state = state.copyWith(userLocation: location, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// **2. Fetch Route**
  Future<void> fetchRoute(LocationModel start, LocationModel end) async {
    try {
      state = state.copyWith(isLoading: true);
      RouteModel route = await _mapService.getRoute(start, end);
      state = state.copyWith(route: route, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// **3. Search Places**
  Future<void> searchPlaces(String query) async {
    try {
      state = state.copyWith(isLoading: true);
      List<LocationModel> results = await _mapService.searchPlaces(query);

      // ✅ Print actual values instead of instance reference
      for (var result in results) {
        print(
            "Search Result: ${result.address} | Lat: ${result.latitude}, Lng: ${result.longitude}");
      }

      state = state.copyWith(searchResults: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<LocationModel?> getCoordinatesFromAddress(String address) async {
    try {
      return await _mapService.getCoordinatesFromAddress(address);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void setSelectedLocation(LocationModel location) {
    state = state.copyWith(selectedLocation: location);
  }
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(MapService());
});
