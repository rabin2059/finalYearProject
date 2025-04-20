import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../../../components/AppColors.dart';
import '../../../core/constants.dart';
import '../../../core/shared_prefs_utils.dart';
import '../../../data/services/map_service.dart';
import '../../Passenger/setting/providers/setting_provider.dart';
import 'driver_map_provider.dart';

class DriverMapScreen extends ConsumerStatefulWidget {
  final int vehicleId;

  const DriverMapScreen({
    super.key,
    required this.vehicleId,
  });

  @override
  DriverMapScreenState createState() => DriverMapScreenState();
}

class DriverMapScreenState extends ConsumerState<DriverMapScreen> {
  bool _showRoute = false;
  late final MapController mapController;
  final List<LatLng> _routePoints = [];
  String startPoint = '';
  String endPoint = '';
  bool isSharing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _initializeState();
  }
  Future<void> _initializeState() async {
    await _loadRoute();
    final savedStatus = await SharedPrefsUtil.getTripStatus();
    if (savedStatus == "true") {
      setState(() {
        isSharing = true;
        _showRoute = true;
      });
      await _handleStartSharing(); // redraw route if needed
    }
  }

  Future<void> _loadRoute() async {
    setState(() {
      isLoading = true;
    });
    
    await _fetchRouteDetails();
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _handleStartSharing() async {
    setState(() {
      isLoading = true;
    });

    await _fetchRouteDetails();

    if (startPoint.isNotEmpty && endPoint.isNotEmpty) {
      final start = await MapService().getLatLngFromLocation(startPoint);
      final end = await MapService().getLatLngFromLocation(endPoint);

      if (start != null && end != null) {
        setState(() {
          _routePoints.clear();
          _routePoints.add(start);
          _routePoints.add(end);
          _showRoute = true;
        });

        final bounds = LatLngBounds.fromPoints([start, end]);
        final zoom = _getZoomForBounds(bounds);
        final center = LatLng(
          (bounds.north + bounds.south) / 2,
          (bounds.east + bounds.west) / 2,
        );
        mapController.move(center, zoom);
      }
    }

    final liveServiceNotifier = ref.read(driverLiveLocationProvider);
    liveServiceNotifier.startSharing(widget.vehicleId);
    final url = Uri.parse("$apiBaseUrl/startTrip?vehicleId=${widget.vehicleId}");
    await http.post(url);

    setState(() {
      isLoading = false;
      isSharing = true;
    });
    await SharedPrefsUtil.saveTripStatus("true");
  }

  Future<void> _fetchRouteDetails() async {
    final url = Uri.parse("$apiBaseUrl/getMyRoute?id=${widget.vehicleId}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final route = jsonResponse['route'];

        if (route != null) {
          startPoint = route['startPoint'] ?? '';
          endPoint = route['endPoint'] ?? '';
          debugPrint("Route loaded: $startPoint to $endPoint");
        } else {
          debugPrint("Route not found in response.");
          _showErrorSnackbar("Route information not found");
        }
      } else {
        debugPrint("Failed to fetch route: ${response.statusCode}");
        _showErrorSnackbar("Failed to fetch route details");
      }
    } catch (e) {
      debugPrint('Exception while fetching route details: $e');
      _showErrorSnackbar("Error loading route: ${e.toString().substring(0, min(50, e.toString().length))}");
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _handleStopSharing() async {
    setState(() {
      isLoading = true;
    });
    
    final liveServiceNotifier = ref.read(driverLiveLocationProvider);
    liveServiceNotifier.stopSharing(widget.vehicleId);
    final url = Uri.parse("$apiBaseUrl/endTrip?vehicleId=${widget.vehicleId}");
    try {
      final response = await http.post(url);
      if (response.statusCode != 200 && response.statusCode != 201) {
        _showErrorSnackbar("Error ending trip. Please try again.");
      }
    } catch (e) {
      _showErrorSnackbar("Network error while ending trip");
    }
    await SharedPrefsUtil.saveTripStatus("false");
    
    setState(() {
      _showRoute = false;
      isLoading = false;
      isSharing = false;
    });
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

  void _centerOnCurrentLocation() {
    final liveService = ref.read(driverLiveLocationProvider);
    if (liveService.currentLocation != null) {
      mapController.move(liveService.currentLocation!, 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveService = ref.watch(driverLiveLocationProvider);
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Driver Route",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => _buildRouteInfoSheet(),
                );
              },
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
              onTap: (_, __) {
                // Hide any open bottom sheets or dialogs
                FocusScope.of(context).unfocus();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.app',
              ),
              if (_showRoute && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: theme.primaryColor,
                      strokeWidth: 5.0,
                      borderColor: Colors.black54,
                      borderStrokeWidth: 1.0,
                    )
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (liveService.currentLocation != null)
                    Marker(
                      point: liveService.currentLocation!,
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2)
                                )
                              ]
                            ),
                            child: Icon(
                              Icons.directions_bus,
                              color: theme.primaryColor,
                              size: 24,
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 6,
                            color: Colors.black87,
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Show start and end markers if route is visible
                  if (_showRoute && _routePoints.isNotEmpty)
                    Marker(
                      point: _routePoints.first,
                      width: 30,
                      height: 30,
                      child: const Icon(
                        Icons.trip_origin,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),
                  if (_showRoute && _routePoints.length > 1)
                    Marker(
                      point: _routePoints.last,
                      width: 30,
                      height: 30,
                      child: const Icon(
                        Icons.place,
                        color: Colors.red,
                        size: 30,
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Control panels
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                _buildMapControlButton(
                  icon: Icons.my_location,
                  onPressed: _centerOnCurrentLocation,
                  tooltip: 'Center on my location',
                ),
                const SizedBox(height: 8),
                _buildMapControlButton(
                  icon: Icons.route,
                  onPressed: () {
                    setState(() {
                      _showRoute = true;
                    });
                    
                    if (_routePoints.length >= 2) {
                      final bounds = LatLngBounds.fromPoints(_routePoints);
                      final zoom = _getZoomForBounds(bounds);
                      final center = LatLng(
                        (bounds.north + bounds.south) / 2,
                        (bounds.east + bounds.west) / 2,
                      );
                      mapController.move(center, zoom);
                    }
                  },
                  tooltip: 'Show route',
                ),
              ],
            ),
          ),
          
          // Status panel at bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isSharing ? Icons.circle : Icons.circle_outlined,
                          color: isSharing ? Colors.green : Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSharing ? "Trip Active" : "Trip Inactive",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSharing ? Colors.green : Colors.red,
                          ),
                        ),
                        const Spacer(),
                        if (isSharing)
                          Text(
                            "Vehicle ID: ${widget.vehicleId}",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.grey.shade200,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: isLoading || isSharing ? null : _handleStartSharing,
                              child: Container(
                              decoration: BoxDecoration(
                                  color: isSharing ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: isSharing ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ] : null,
                                ),
                                alignment: Alignment.center,
                                child: isLoading && !isSharing ? 
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                                    ),
                                  ) :
                                  Text(
                                    "Start Trip",
                                    style: TextStyle(
                                      color: isSharing ? Colors.white : Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: isLoading || !isSharing ? null : _handleStopSharing,
                              child: Container(
                              decoration: BoxDecoration(
                                  color: !isSharing ? Colors.red : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: !isSharing ? [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.4),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ] : null,
                                ),
                                alignment: Alignment.center,
                                child: isLoading && isSharing ? 
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                    ),
                                  ) :
                                  Text(
                                    "End Trip",
                                    style: TextStyle(
                                      color: !isSharing ? Colors.white : Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Loading overlay
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black12,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(30),
      color: Colors.white,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: Colors.black87,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoSheet() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route, size: 24),
              const SizedBox(width: 12),
              Text(
                "Route Information",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRouteInfoRow(
            label: "Start Point",
            value: startPoint.isEmpty ? "Not Set" : startPoint,
            icon: Icons.trip_origin,
            iconColor: Colors.green,
          ),
          const Divider(height: 24),
          _buildRouteInfoRow(
            label: "End Point",
            value: endPoint.isEmpty ? "Not Set" : endPoint,
            icon: Icons.place,
            iconColor: Colors.red,
          ),
          const Divider(height: 24),
          _buildRouteInfoRow(
            label: "Vehicle ID",
            value: widget.vehicleId.toString(),
            icon: Icons.directions_bus,
            iconColor: Theme.of(context).primaryColor,
          ),
          const Divider(height: 24),
          _buildRouteInfoRow(
            label: "Status",
            value: isSharing ? "Trip Active" : "Trip Inactive",
            icon: Icons.info_outline,
            iconColor: isSharing ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoRow({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}