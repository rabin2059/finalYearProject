import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/map_model.dart';
import '../../../data/services/map_service.dart';
import 'map_state.dart';

class MapNotifier extends StateNotifier<MapState> {
  final MapService _mapService;
  StreamSubscription<Position>? _positionStream;

  MapNotifier(this._mapService) : super(MapState());

  Future<void> fetchUserLocation() async {
    try {
      state = state.copyWith(isLoading: true);
      Position position = await _mapService.getCurrentLocation();
      LatLng userLatLng = LatLng(position.latitude, position.longitude);

      state = state.copyWith(userLocation: userLatLng, isLoading: false);
    } catch (e, stackTrace) {
      state = state.copyWith(
          error: "Failed to fetch user location", isLoading: false);
      print("Error in fetchUserLocation: $e\n$stackTrace");
    }
  }

  Future<void> searchPlaces(String query) async {
    try {
      print(query);
      state = state.copyWith(isLoading: true);
      List<Map<String, dynamic>> results =
          await _mapService.searchPlaces(query);

      List<LocationModel> searchResults = results.map((place) {
        return LocationModel(
          latitude: double.parse(place['lat']),
          longitude: double.parse(place['lon']),
          address: place['display_name'],
        );
      }).toList();

      state = state.copyWith(searchResults: searchResults, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: "Search failed", isLoading: false);
      print("Error in searchPlaces: $e");
    }
  }

  Future<LocationModel?> getCoordinatesFromAddress(String address) async {
    try {
      List<Map<String, dynamic>> results =
          await _mapService.searchPlaces(address);
      if (results.isNotEmpty) {
        return LocationModel(
          latitude: double.parse(results[0]['lat']),
          longitude: double.parse(results[0]['lon']),
          address: results[0]['display_name'],
        );
      }
      return null;
    } catch (e) {
      state = state.copyWith(error: "Address lookup failed");
      return null;
    }
  }

  Future<void> fetchRoute(LatLng start, LatLng end) async {
    try {
      state = state.copyWith(isLoading: true);

      List<LatLng> routePoints = await _mapService.getRoutePoints(start, end);

      List<LocationModel> locationPoints = routePoints.map((latLng) {
        return LocationModel(
          latitude: latLng.latitude,
          longitude: latLng.longitude,
        );
      }).toList();

      if (locationPoints.isEmpty) {
        state = state.copyWith(error: "No route found", isLoading: false);
        return;
      }

      RouteModel route = RouteModel(routePoints: locationPoints);
      state = state.copyWith(route: route, isLoading: false);
    } catch (e, stackTrace) {
      state = state.copyWith(error: "Failed to fetch route", isLoading: false);
      print("Error in fetchRoute: $e\n$stackTrace");
    }
  }

  void startLiveLocationSharing({
    required int vehicleId,
    required void Function(double lat, double lng) onLocationUpdate,
    required Function(String error) onError,
  }) async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      onError("Location permission not granted");
      return;
    }

    _positionStream?.cancel();

    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (position) {
          final lat = position.latitude;
          final lng = position.longitude;
          onLocationUpdate(lat, lng);
        },
        onError: (e) {
          onError("Location error: $e");
          print("Live location error: $e");
        },
        cancelOnError: false,
      );
    } catch (e, stack) {
      onError("Stream error: $e");
      print("Error starting location stream: $e\n$stack");
    }
  }

  Future<LatLng?> getLatLngFromLocation(String locationName) async {
    return await _mapService.getLatLngFromLocation(locationName);
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

  void clearRoute() {
    state = state.copyWith(route: null);
  }

  void stopLiveLocationSharing() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}

final mapServiceProvider = Provider<MapService>((ref) => MapService());

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(ref.watch(mapServiceProvider));
});
