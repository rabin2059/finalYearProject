import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../data/models/map_model.dart';
import '../../../../data/services/map_service.dart';
import 'map_state.dart';

class MapNotifier extends StateNotifier<MapState> {
  final MapService _mapService;
  StreamSubscription<Position>? _positionStream;

  MapNotifier(this._mapService) : super(MapState());

  /// **1️⃣ Fetch User Location**
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

  /// **2️⃣ Search Places using OpenStreetMap (Only Nepal)**
  Future<void> searchPlaces(String query) async {
    try {
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

  /// **3️⃣ Get Coordinates from Address**
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

  /// **4️⃣ Fetch Route Between Two Locations**
  Future<void> fetchRoute(LatLng start, LatLng end) async {
    try {
      state = state.copyWith(isLoading: true);

      // Fetch route points from MapService
      List<LatLng> routePoints = await _mapService.getRoutePoints(start, end);

      // ✅ Convert List<LatLng> to List<LocationModel>
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

      // ✅ Use the converted List<LocationModel>
      RouteModel route = RouteModel(routePoints: locationPoints);
      state = state.copyWith(route: route, isLoading: false);
    } catch (e, stackTrace) {
      state = state.copyWith(error: "Failed to fetch route", isLoading: false);
      print("Error in fetchRoute: $e\n$stackTrace");
    }
  }

  /// **5️⃣ Get Latitude & Longitude from Location Name**
  Future<LatLng?> getLatLngFromLocation(String locationName) async {
    return await _mapService.getLatLngFromLocation(locationName);
  }

  /// **6️⃣ Set Selected Location**
  void setSelectedLocation(LocationModel location) {
    state = state.copyWith(selectedLocation: location);
  }

  /// **7️⃣ Handle Location Permissions**
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
}

/// **🔹 Dependency Injection for Riverpod**
final mapServiceProvider = Provider<MapService>((ref) => MapService());

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(ref.watch(mapServiceProvider));
});
