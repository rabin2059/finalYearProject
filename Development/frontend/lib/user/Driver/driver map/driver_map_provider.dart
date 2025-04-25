import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants.dart';
import '../../../data/services/socket_service.dart';

final driverLiveLocationProvider =
    ChangeNotifierProvider<DriverLiveLocationService>((ref) {
  return DriverLiveLocationService();
});

class DriverLiveLocationService extends ChangeNotifier {
  final SocketService _socketService = SocketService(baseUrl: socketBaseUrl);

  bool _isSharing = false;
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation; // ✅ Declare it

  bool get isSharing => _isSharing;
  LatLng? get currentLocation => _currentLocation;

  void connect(int vehicleId) {
    _socketService.connect("driver-$vehicleId");
  }

  void startSharing(int vehicleId) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    // Step 2: Check and request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception("Location permissions are denied.");
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    // Step 3: Connect and start sending location
    connect(vehicleId);
    _socketService.registerDriver(vehicleId);

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      final lat = position.latitude;
      final lng = position.longitude;

      _currentLocation = LatLng(lat, lng);
      _socketService.sendDriverLocation(vehicleId, lat, lng);
      notifyListeners();
    });

    _isSharing = true;
    notifyListeners();
  }

  void stopSharing(int vehicleId) async {
    _socketService.removeRegisteredDriver(vehicleId);
    await _positionStream?.cancel();
    _positionStream = null;
    _isSharing = false;
    notifyListeners();
  }

  void disposeService() {
    _socketService.dispose();
  }
}
