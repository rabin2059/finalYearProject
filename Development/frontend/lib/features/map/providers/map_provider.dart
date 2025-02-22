import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart';
import '../../../data/models/map_model.dart';
import '../../../data/services/map_service.dart';
import 'map_state.dart';

class MapNotifier extends StateNotifier<MapState> {
  final MapService _mapService;
  StreamSubscription<Position>? _positionStream;

  MapNotifier(this._mapService) : super(MapState());

  /// Fetch User Location
  Future<void> fetchUserLocation(double lat, double lng) async {
    try {
      state = state.copyWith(isLoading: true);
      LocationModel location = await _mapService.getReverseGeocode(lat, lng);
      state = state.copyWith(userLocation: location, isLoading: false);
    } catch (e, stackTrace) {
      state = state.copyWith(error: "Failed to fetch location", isLoading: false);
      print("Error in fetchUserLocation: $e\n$stackTrace");
    }
  }

  /// Fetch Route
  Future<void> fetchRoute(LocationModel start, LocationModel end) async {
    try {
      state = state.copyWith(isLoading: true);
      RouteModel route = await _mapService.getRoute(start, end);
      state = state.copyWith(route: route, isLoading: false);
    } catch (e, stackTrace) {
      state = state.copyWith(error: "Failed to fetch route", isLoading: false);
      print("Error in fetchRoute: $e\n$stackTrace");
    }
  }

  /// Search Places
  Future<void> searchPlaces(String query) async {
    try {
      state = state.copyWith(isLoading: true);
      List<LocationModel> results = await _mapService.searchPlaces(query);
      state = state.copyWith(searchResults: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: "Search failed", isLoading: false);
    }
  }

  Future<LocationModel?> getCoordinatesFromAddress(String address) async {
    try {
      return await _mapService.getCoordinatesFromAddress(address);
    } catch (e) {
      state = state.copyWith(error: "Address lookup failed");
      return null;
    }
  }

  void setSelectedLocation(LocationModel location) {
    state = state.copyWith(selectedLocation: location);
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<void> getLocationUpdates(Socket socket) async {
    if (!await _handleLocationPermission()) return;

    final locationSettings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 100);
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      socket.emit('sendLocation', {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    });
  }

  void stopLocationUpdates() {
    _positionStream?.cancel();
  }
}

/// Dependency Injection
final mapServiceProvider = Provider<MapService>((ref) => MapService());

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(ref.watch(mapServiceProvider));
});