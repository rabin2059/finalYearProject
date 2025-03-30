import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/data/services/map_service.dart';
import 'package:frontend/user/Driver/driver%20map/driver_map_provider.dart';
import 'package:frontend/user/Passenger/bus%20details/providers/bus_details_provider.dart';
import 'package:latlong2/latlong.dart';

class DriverMapScreen extends ConsumerStatefulWidget {
  final String startLocation;
  final String endLocation;
  final int vehicleId;

  const DriverMapScreen({
    super.key,
    required this.startLocation,
    required this.endLocation,
    required this.vehicleId,
  });

  @override
  DriverMapScreenState createState() => DriverMapScreenState();
}

class DriverMapScreenState extends ConsumerState<DriverMapScreen> {
  bool _showRoute = false;
  late final MapController mapController;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final startLatLng =
        await MapService().getLatLngFromLocation(widget.startLocation);
    final endLatLng =
        await MapService().getLatLngFromLocation(widget.endLocation);
    if (startLatLng == null || endLatLng == null) return;
    final points = await MapService().getRoutePoints(startLatLng, endLatLng);
    if (points.isNotEmpty) {
      setState(() {
        _routePoints = points;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final bounds = LatLngBounds.fromPoints(points);
        final center = LatLng(
          (bounds.north + bounds.south) / 2,
          (bounds.east + bounds.west) / 2,
        );
        final zoom = _getZoomForBounds(bounds);
        mapController.move(center, zoom);
      });
    }
  }

  void _toggleLiveSharing(bool isSharing) {
    final liveServiceNotifier = ref.read(driverLiveLocationProvider);
    if (liveServiceNotifier.isSharing) {
      liveServiceNotifier.stopSharing();
    } else {
      liveServiceNotifier.startSharing(
        widget.vehicleId,
      );
    }
  }

  double _getZoomForBounds(LatLngBounds bounds) {
    const minZoom = 10.0;
    const maxZoom = 18.0;

    final latDiff = bounds.north - bounds.south;
    final lngDiff = bounds.east - bounds.west;
    final distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);

    final zoom = 16.0 - distance * 10;
    return zoom.clamp(minZoom, maxZoom);
  }

  @override
  Widget build(BuildContext context) {
    final liveService = ref.watch(driverLiveLocationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Route"),
        actions: [
          Switch(
            value: liveService.isSharing,
            onChanged: (_) => _toggleLiveSharing(liveService.isSharing),
            activeColor: Colors.green,
            inactiveThumbColor: Colors.grey,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Text(
                liveService.isSharing ? "LIVE" : "OFF",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: _routePoints.isNotEmpty
                  ? _routePoints.first
                  : const LatLng(27.7172, 85.3240),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              if (_showRoute && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    )
                  ],
                ),
              if (liveService.currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: liveService.currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 30,
                      ),
                    )
                  ],
                ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showRoute = true;
                });
              },
              child: const Text("Show My Route"),
            ),
          ),
        ],
      ),
    );
  }
}
