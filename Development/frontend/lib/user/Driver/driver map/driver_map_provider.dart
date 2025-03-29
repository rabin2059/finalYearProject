import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/services/socket_service.dart';

final driverLiveLocationProvider =
    ChangeNotifierProvider<DriverLiveLocationService>((ref) {
  return DriverLiveLocationService();
});

class DriverLiveLocationService extends ChangeNotifier {
  final SocketService _socketService =
      SocketService(baseUrl: "http://localhost:3089");

  bool _isSharing = false;
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentLocation; // ✅ Declare it

  bool get isSharing => _isSharing;
  LatLng? get currentLocation => _currentLocation;

  void connect(int vehicleId) {
    _socketService.connect("driver-$vehicleId");
  }

  void startSharing(int vehicleId) async {
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

      _currentLocation = LatLng(lat, lng); // ✅ Update the location
      _socketService.sendDriverLocation(vehicleId, lat, lng);

      notifyListeners(); // ✅ Notify UI
    });

    _isSharing = true;
    notifyListeners();
  }

  void stopSharing() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isSharing = false;
    notifyListeners();
  }

  void disposeService() {
    stopSharing();
    _socketService.dispose();
  }
}
