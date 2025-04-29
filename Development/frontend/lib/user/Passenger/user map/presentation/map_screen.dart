import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../core/constants.dart';
import '../../../../data/services/socket_service.dart';
import '../../../map/providers/map_provider.dart';
import 'package:http/http.dart' as http;

class MapScreens extends ConsumerStatefulWidget {
  const MapScreens({super.key});

  @override
  ConsumerState<MapScreens> createState() => _MapScreensState();
}

class _MapScreensState extends ConsumerState<MapScreens> {
  final MapController _controller = MapController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  TextEditingController? _activeController;

  bool isSearching = true;
  double _currentZoom = 13.0;
  bool _showMarker = true;

  Timer? _debounce; // Timer for debouncing search requests

  List<String> _startSuggestions = [];
  List<String> _endSuggestions = [];
  bool _showStartSuggestions = false;
  bool _showEndSuggestions = false;

  final List<Marker> _vehicleMarkers = [];
  bool _showDriverInfo = false;
  Map<String, dynamic>? _selectedDriver;
  String? _selectedVehicleId;
  List<Map<String, dynamic>> _filteredVehicles = [];

  LatLng? _startCoordinates;
  LatLng? _endCoordinates;
  List<dynamic> _vehicles = [];
  bool _mounted = true;

  // Tracks if vehicles have been loaded
  bool _vehiclesLoaded = false;

  // Map to track vehicle locations by vehicleId
  final Map<String, LatLng> _vehicleLocations = {};

  // Reference to SocketService
  SocketService? _socketService;

  // Control vehicle list visibility
  bool _showVehicleList = false;
  final Set<String> _activeSocketUsers = {};

  @override
  void initState() {
    super.initState();
    _initSocketService();
  }

  void _initSocketService() {
    _socketService = SocketService(baseUrl: socketBaseUrl);
    _socketService?.connect("user-${DateTime.now().millisecondsSinceEpoch}");

    _socketService?.onVehicleLocation = (vehicleId, lat, lng) {
      if (!mounted) return;
      setState(() {
        _vehicleLocations[vehicleId] = LatLng(lat, lng);
      });
      _updateVehicleMarkers();
    };
    _socketService?.onActiveBusesReceived.addListener(() {
      if (!mounted) return;
      setState(() {
        _activeSocketUsers.clear();
        for (var driverId in _socketService!.onActiveBusesReceived.value) {
          _activeSocketUsers.add('driver-$driverId');
        }
      });
    });
    _socketService?.requestActiveBuses();
  }

  void _clearMapState() {
    final mapNotifier = ref.read(mapProvider.notifier);
    mapNotifier.clearRoute();

    // Reset local state
    setState(() {
      _startController.clear();
      _endController.clear();
      _startCoordinates = null;
      _endCoordinates = null;
      _vehicleMarkers.clear();
      _vehicles.clear();
      _filteredVehicles.clear();
      _vehicleLocations.clear();
      _selectedDriver = null;
      _selectedVehicleId = null;
      _showDriverInfo = false;
      _showVehicleList = false;
      _vehiclesLoaded = false;
      isSearching = true;
    });

    // Reset map to default position
    _controller.move(
        ref.read(mapProvider).userLocation ?? const LatLng(27.7172, 85.3240),
        _currentZoom = 13.0);
  }

  void _updateVehicleMarkers() {
    _vehicleMarkers.clear();

    // Only add a marker for the selected vehicle
    if (_selectedVehicleId != null &&
        _vehicleLocations.containsKey(_selectedVehicleId)) {
      // Find the vehicle info for this vehicleId
      final vehicle = _vehicles.firstWhere(
          (v) => v['vehicleId'].toString() == _selectedVehicleId,
          orElse: () => {
                'vehicleModel': 'Unknown',
                'vehicleType': 'Vehicle',
                'driver': {'name': 'Unknown'}
              });

      final location = _vehicleLocations[_selectedVehicleId]!;

      _vehicleMarkers.add(
        Marker(
          width: 40.w,
          height: 40.h,
          point: location,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final details = await _calculateDistanceAndTime(location);
                setState(() {
                  _selectedDriver = {
                    'name': vehicle['driver']['name'] ?? 'Unknown Driver',
                    'vehicleInfo':
                        '${vehicle['vehicleModel']} - ${vehicle['vehicleType']} (ID: $_selectedVehicleId)',
                    'rating': 4.5,
                    'distance': details['distance'] ?? 'Unknown',
                    'duration': details['duration'] ?? '',
                  };
                  _showDriverInfo = !_showDriverInfo;
                });
              },
              child: Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.directions_bus,
                    color: AppColors.primary,
                    size: 25,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    setState(() {});
  }

  void _selectVehicle(dynamic vehicle) {
    final vehicleId = vehicle['vehicleId'].toString();

    if (vehicle['hasActiveBuses'] == true &&
        vehicle['activeBuses'] != null &&
        vehicle['activeBuses'].isNotEmpty) {
      final busData = vehicle['activeBuses'][0];
      final location = LatLng(
        busData['location']['lat'],
        busData['location']['lng'],
      );

      setState(() {
        _selectedVehicleId = vehicleId;
        _vehicleLocations[vehicleId] = location;
        _selectedDriver = {
          'name': vehicle['driver']['name'] ?? 'Unknown Driver',
          'vehicleInfo':
              '${vehicle['vehicleModel']} - ${vehicle['vehicleType']} (ID: $vehicleId)',
          'rating': 4.5,
          'distance': 'On route',
        };
        _showVehicleList = false; // Close vehicle list when selected
        // _showDriverInfo = true; // Removed to prevent immediate driver info display
      });

      final userLocation = ref.read(mapProvider).userLocation;
      if (userLocation != null) {
        final bounds =
            LatLngBounds(ref.read(mapProvider).userLocation!, location);
        bounds.extend(userLocation);
        bounds.extend(location);
        final center = LatLng(
          (bounds.north + bounds.south) / 2,
          (bounds.east + bounds.west) / 2,
        );
        final zoom = _getZoomForBounds(bounds);
        _controller.move(center, zoom);
      }

      _updateVehicleMarkers();
      _controller.move(location, 15);
    }
  }

  @override
  void dispose() {
    _mounted = false;
    _startController.dispose();
    _endController.dispose();
    _debounce?.cancel();
    _socketService?.dispose();

    // Delay clearing the map if needed, or remove this if handled inside the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mapProvider.notifier).clearRoute();
      }
    });

    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final mapNotifier = ref.read(mapProvider.notifier);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        _clearMapState();
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Map Layer
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialZoom: _currentZoom,
                initialCenter: mapState.userLocation ??
                    const LatLng(27.7172, 85.3240), // Default Kathmandu
                onMapEvent: (event) => _onMapEvent(event),
              ),
              children: [
                // Base Map Tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  tileProvider: NetworkTileProvider(),
                ),

                // User Location Marker
                if (_showMarker && mapState.userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 50.w,
                        height: 50.h,
                        point: mapState.userLocation!,
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.r),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.my_location,
                                color: Colors.blue[700],
                                size: 20.r,
                              ),
                            ),
                            // Shadow effect under marker
                            Container(
                              margin: EdgeInsets.only(top: 4.h),
                              height: 6.h,
                              width: 6.w,
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                // Route Polyline
                if (mapState.route != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: mapState.route!.routePoints
                            .map((e) => LatLng(e.latitude, e.longitude))
                            .toList(),
                        strokeWidth: 5.0,
                        color: AppColors.primary.withOpacity(0.7),
                        borderColor: Colors.white,
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),

                // Start, End, and Vehicle Markers
                MarkerLayer(
                  markers: [
                    ..._vehicleMarkers,
                    if (mapState.route != null) ...[
                      // Start point marker
                      Marker(
                        width: 42.w,
                        height: 42.h,
                        point: LatLng(
                          mapState.route!.routePoints.first.latitude,
                          mapState.route!.routePoints.first.longitude,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.green,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.trip_origin,
                                color: Colors.green,
                                size: 16.r,
                              ),
                            ),
                            // Shadow effect under marker
                            Container(
                              margin: EdgeInsets.only(top: 4.h),
                              height: 6.h,
                              width: 6.w,
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // End point marker
                      Marker(
                        width: 42.w,
                        height: 42.h,
                        point: LatLng(
                          mapState.route!.routePoints.last.latitude,
                          mapState.route!.routePoints.last.longitude,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.red,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.place,
                                color: Colors.red,
                                size: 16.r,
                              ),
                            ),
                            // Shadow effect under marker
                            Container(
                              margin: EdgeInsets.only(top: 4.h),
                              height: 6.h,
                              width: 6.w,
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            // Top App Bar with Back Button and Title
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10.h,
                  left: 15.w,
                  right: 15.w,
                  bottom: 10.h,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Back Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () {
                              _clearMapState();
                              Navigator.pop(context);
                            },
                            child: SizedBox(
                              width: 38.w,
                              height: 38.h,
                              child: Icon(
                                Icons.arrow_back,
                                size: 20.r,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Title
                    Expanded(
                      child: Text(
                        isSearching
                            ? "Find Your Ride"
                            : _showVehicleList
                                ? "Available Vehicles"
                                : _showDriverInfo
                                    ? "Driver Details"
                                    : "Map View",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3.0,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Map Action Button - Show/Hide user location
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Material(
                          color: Colors.white,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _showMarker = !_showMarker;
                              });
                            },
                            child: SizedBox(
                              width: 38.w,
                              height: 38.h,
                              child: Icon(
                                _showMarker
                                    ? Icons.location_on
                                    : Icons.location_off,
                                size: 20.r,
                                color: _showMarker
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            if (!isSearching && !_showVehicleList)
              Positioned(
                bottom: 30.h,
                right: 15.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Vehicle List Button
                    if (_vehiclesLoaded || !_showDriverInfo)
                      Container(
                        margin: EdgeInsets.only(bottom: 16.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Material(
                            color: AppColors.primary,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _showVehicleList = true;
                                });
                              },
                              child: SizedBox(
                                width: 50.w,
                                height: 50.h,
                                child: Icon(
                                  Icons.directions_bus,
                                  size: 26.r,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Search Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Material(
                          color: AppColors.primary,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                isSearching = true;
                                _showVehicleList = false;
                              });
                            },
                            child: SizedBox(
                              width: 50.w,
                              height: 50.h,
                              child: Icon(
                                Icons.search,
                                size: 26.r,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Search UI
            if (isSearching)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildSearchContainer(mapNotifier),
              ),

            // Vehicle List
            if (!isSearching && _showVehicleList && _vehicles.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: screenHeight * 0.5,
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! > 300) {
                      setState(() {
                        _showVehicleList = false;
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20.r)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        // Drag indicator
                        Container(
                          width: 40.w,
                          height: 5.h,
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2.5.r),
                          ),
                        ),

                        // Header with title and close button
                        Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 0, 8.w, 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_bus_filled,
                                    color: AppColors.primary,
                                    size: 24.r,
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    "Available Vehicles",
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: Icon(Icons.keyboard_arrow_down),
                                color: Colors.grey[600],
                                onPressed: () {
                                  setState(() {
                                    _showVehicleList = false;
                                  });
                                },
                              )
                            ],
                          ),
                        ),

                        // (Filter chips removed)

                        SizedBox(height: 8.h),
                        Divider(
                            height: 1, thickness: 1, color: Colors.grey[200]),

                        // Vehicle list
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                                vertical: 8.h, horizontal: 16.w),
                            itemCount: _filteredVehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = _filteredVehicles[index];
                              final isLive = vehicle['hasActiveBuses'] == true;
                              final vehicleId = vehicle['vehicleId'].toString();
                              final isSelected =
                                  vehicleId == _selectedVehicleId;

                              return Card(
                                elevation: isSelected ? 3 : 1,
                                margin: EdgeInsets.symmetric(vertical: 6.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  side: isSelected
                                      ? BorderSide(
                                          color: AppColors.primary, width: 1.5)
                                      : BorderSide.none,
                                ),
                                child: InkWell(
                                  onTap: isLive
                                      ? () => _selectVehicle(vehicle)
                                      : null,
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Padding(
                                    padding: EdgeInsets.all(12.w),
                                    child: Row(
                                      children: [
                                        // Vehicle avatar
                                        Container(
                                          width: 50.w,
                                          height: 50.h,
                                          decoration: BoxDecoration(
                                            color: isLive
                                                ? AppColors.primary
                                                    .withOpacity(0.1)
                                                : Colors.grey[200],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.directions_bus,
                                              color: isLive
                                                  ? AppColors.primary
                                                  : Colors.grey,
                                              size: 28.r,
                                            ),
                                          ),
                                        ),

                                        SizedBox(width: 12.w),

                                        // Vehicle details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${vehicle['vehicleModel']} (${vehicle['vehicleType']})',
                                                style: TextStyle(
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.person,
                                                    size: 14.r,
                                                    color: Colors.grey[600],
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    'Driver: ${vehicle['driver']['name']}',
                                                    style: TextStyle(
                                                      fontSize: 13.sp,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Status badge
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 6.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isLive
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.red.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20.r),
                                            border: Border.all(
                                              color: isLive
                                                  ? Colors.green
                                                  : Colors.red,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8.w,
                                                height: 8.h,
                                                decoration: BoxDecoration(
                                                  color: isLive
                                                      ? Colors.green
                                                      : Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                isLive ? 'ACTIVE' : 'INACTIVE',
                                                style: TextStyle(
                                                  color: isLive
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Driver Info Sheet
            if (_showDriverInfo && _selectedDriver != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! > 10) {
                      setState(() {
                        _showDriverInfo = false;
                      });
                    }
                  },
                  child: _buildDriverInfoSheet(),
                ),
              ),
          ],
        ),
      ),
    );
  }

// Helper method for filter chips
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchContainer(MapNotifier mapNotifier) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, -3))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchField(
              controller: _startController,
              hint: "From Location",
              onSearch: (query) => _debouncedSearch(query, mapNotifier, true)),
          _showStartSuggestions
              ? _buildSuggestions(_startSuggestions, true)
              : const SizedBox(),
          SizedBox(height: 10.h),
          _buildSearchField(
              controller: _endController,
              hint: "To Location",
              onSearch: (query) => _debouncedSearch(query, mapNotifier, false)),
          _showEndSuggestions
              ? _buildSuggestions(_endSuggestions, false)
              : const SizedBox(),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: CustomButton(
              text: "Find Now",
              color: AppColors.primary,
              onPressed: () async {
                await _handleFindNowPress(mapNotifier);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(
      {required TextEditingController controller,
      required String hint,
      required Function(String) onSearch}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r)),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
      ),
      onChanged: onSearch,
    );
  }

  void _debouncedSearch(String query, MapNotifier mapNotifier, bool isStart) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!_mounted || !mounted) return; // 👈 safeguard

      if (query.isNotEmpty) {
        await mapNotifier.searchPlaces(query);
        if (!_mounted || !mounted) return;

        final searchResults = ref.read(mapProvider).searchResults;

        setState(() {
          if (isStart) {
            _startSuggestions =
                searchResults.map((l) => l.address ?? "").toList();
            _showStartSuggestions = true;
          } else {
            _endSuggestions =
                searchResults.map((l) => l.address ?? "").toList();
            _showEndSuggestions = true;
          }
        });
      } else {
        if (!_mounted || !mounted) return;
        setState(() {
          if (isStart) {
            _startSuggestions.clear();
            _showStartSuggestions = false;
          } else {
            _endSuggestions.clear();
            _showEndSuggestions = false;
          }
        });
      }
    });
  }

  double _getZoomForBounds(LatLngBounds bounds) {
    const double minZoom = 10.0;
    const double maxZoom = 18.0;

    // Calculate the distance between two points
    final latDiff = bounds.northEast.latitude - bounds.southWest.latitude;
    final lngDiff = bounds.northEast.longitude - bounds.southWest.longitude;
    final distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);

    double zoom = 16.0 - distance * 10; // Approximate zoom calculation
    _currentZoom = zoom.clamp(minZoom, maxZoom);
    return _currentZoom;
  }

  /// **Handles Map Zoom Events**
  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove) {
      setState(() {
        _currentZoom = _controller.camera.zoom;
        _showMarker =
            _currentZoom >= 12; // Show markers when zoom level is 12 or higher
      });
    }
  }

  Future<Map<String, String>> _calculateDistanceAndTime(
      LatLng driverLocation) async {
    final userLocation = ref.read(mapProvider).userLocation;
    if (userLocation == null) return {'distance': 'Unknown', 'duration': ''};

    final distance =
        Distance().as(LengthUnit.Kilometer, userLocation, driverLocation);
    String distanceStr = "${distance.toStringAsFixed(1)} km";

    // Approximate time assuming 30km/h average speed
    final timeInMinutes = (distance / 30) * 60;
    String timeStr = "${timeInMinutes.round()} mins";

    if (userLocation.latitude > driverLocation.latitude ||
        userLocation.longitude > driverLocation.longitude) {
      return {'distance': distanceStr, 'duration': timeStr};
    } else {
      return {'distance': distanceStr, 'duration': ''}; // ahead
    }
  }

  Future<void> _handleFindNowPress(MapNotifier mapNotifier) async {
    final startCoordinates =
        await mapNotifier.getCoordinatesFromAddress(_startController.text);
    final endCoordinates =
        await mapNotifier.getCoordinatesFromAddress(_endController.text);
    if (startCoordinates == null || endCoordinates == null) return;

    try {
      final url = Uri.parse(
          "$apiBaseUrl/getVehiclesRoute?startLat=${startCoordinates.latitude}&startLng=${startCoordinates.longitude}&endLat=${endCoordinates.latitude}&endLng=${endCoordinates.longitude}");

      final response = await http.get(url);
      _socketService?.requestActiveBuses();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final allVehicles =
            List<Map<String, dynamic>>.from(data['vehicles'] ?? []);

        _vehicles = allVehicles;

        // Sort: active buses on top
        allVehicles.sort((a, b) {
          final aActive = a['hasActiveBuses'] == true ? 0 : 1;
          final bActive = b['hasActiveBuses'] == true ? 0 : 1;
          return aActive.compareTo(bActive);
        });

        _filteredVehicles =
            allVehicles; // show all vehicles, active and inactive

        _vehicleMarkers.clear();

        if (!mounted) return;
        setState(() {
          _showVehicleList = true;
          _vehiclesLoaded = true;
          isSearching = false;
        });
      }
    } catch (e) {
      print('Error fetching vehicles: $e');
    }
  }

  Widget _buildDriverInfoSheet() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40.w,
            height: 5.h,
            margin: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.5.r),
            ),
          ),
          // Content
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Driver info card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Driver avatar with status indicator
                              Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.2),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 32.r,
                                      backgroundColor: Colors.white,
                                      child: ClipOval(
                                        child: Icon(
                                          Icons.person,
                                          size: 32.r,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 16.w,
                                      height: 16.h,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 16.w),
                              // Driver details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedDriver!['name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      _selectedDriver!['vehicleInfo'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // (Rating and distance info removed)
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Book now button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.pushNamed('/book', pathParameters: {
                            'id': _selectedVehicleId ?? '',
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_bus_filled, size: 20.r),
                            SizedBox(width: 10.w),
                            Text(
                              "Book Now",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(List<String> suggestions, bool isStart) {
    return Container(
      height: 150.h,
      margin: EdgeInsets.symmetric(vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: suggestions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 40.r,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "No suggestions found",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final isFirst = index == 0;
                  final isLast = index == suggestions.length - 1;

                  return InkWell(
                    onTap: () async {
                      if (!mounted) return;
                      final selectedLocation = suggestions[index];

                      setState(() {
                        if (isStart) {
                          _startController.text = selectedLocation;
                          _showStartSuggestions = false;
                        } else {
                          _endController.text = selectedLocation;
                          _showEndSuggestions = false;
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.grey[50] : Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: isFirst ? Radius.circular(12.r) : Radius.zero,
                          bottom: isLast ? Radius.circular(12.r) : Radius.zero,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Icon(
                            isStart ? Icons.my_location : Icons.location_on,
                            color: isStart ? Colors.blue : AppColors.primary,
                            size: 20.r,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              suggestions[index],
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[400],
                            size: 14.r,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
