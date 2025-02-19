import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import '../../../components/AppColors.dart';
import '../../../components/CustomButton.dart';
import '../providers/map_provider.dart';

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

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final mapNotifier = ref.read(mapProvider.notifier);

    return Scaffold(
      body: Stack(
        children: [
          // **Flutter Map**
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialZoom: _currentZoom,
              initialCenter: mapState.userLocation != null
                  ? LatLng(mapState.userLocation!.latitude,
                      mapState.userLocation!.longitude)
                  : const LatLng(27.7172, 85.3240), // Default Kathmandu
              onMapEvent: _onMapEvent, // Handle map events
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // Removed subdomains
              ),
              if (mapState.route != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: mapState.route!.routePoints
                          .map((e) => LatLng(e.latitude, e.longitude))
                          .toList(),
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
            ],
          ),

          // **Back Button**
          Positioned(
            top: 50.h,
            left: 15.w,
            child: FloatingActionButton(
              heroTag: "back",
              mini: true,
              backgroundColor: Colors.white,
              elevation: 2,
              onPressed: () {
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back, size: 25.r),
            ),
          ),

          // **Search UI**
          isSearching
              ? Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30.r)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSearchField(
                          controller: _startController,
                          hint: "From Location",
                          icon: Icons.location_on_outlined,
                          onSearch: (query) =>
                              _debouncedSearch(query, mapNotifier),
                        ),
                        if (_activeController == _startController &&
                            mapState.searchResults != null &&
                            mapState.searchResults!.isNotEmpty)
                          _buildSearchResults(mapNotifier),
                        SizedBox(height: 10.h),
                        _buildSearchField(
                          controller: _endController,
                          hint: "To Location",
                          icon: Icons.location_on_outlined,
                          onSearch: (query) =>
                              _debouncedSearch(query, mapNotifier),
                        ),
                        if (_activeController == _endController &&
                            mapState.searchResults != null &&
                            mapState.searchResults!.isNotEmpty)
                          _buildSearchResults(mapNotifier),
                        SizedBox(height: 20.h),
                        CustomButton(
                          text: "Find Now",
                          color: AppColors.primary,
                          onPressed: () async {
                            final start =
                                await mapNotifier.getCoordinatesFromAddress(
                                    _startController.text);
                            final end = await mapNotifier
                                .getCoordinatesFromAddress(_endController.text);

                            if (start != null && end != null) {
                              mapNotifier.fetchRoute(start, end);

                              // Convert LocationModel to LatLng before passing it
                              _controller.move(
                                LatLng(
                                  (start.latitude + end.latitude) / 2,
                                  (start.longitude + end.longitude) / 2,
                                ),
                                _getZoomForBounds(LatLngBounds(
                                  LatLng(start.latitude, start.longitude),
                                  LatLng(end.latitude, end.longitude),
                                )),
                              );
                            }

                            // ✅ Keep the text fields filled
                            setState(() {
                              isSearching = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                )
              : Positioned(
                  bottom: 30.h,
                  right: 15.w,
                  child: FloatingActionButton(
                    heroTag: "search",
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      setState(() {
                        isSearching = true;
                      });
                    },
                    child: Icon(Icons.search, size: 25.r),
                  ),
                ),
        ],
      ),
    );
  }

  /// **Debounced Search Function to Prevent API Overload**
  void _debouncedSearch(String query, MapNotifier mapNotifier) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _activeController = query.isNotEmpty
          ? (_startController.text == query ? _startController : _endController)
          : null;
      mapNotifier.searchPlaces(query);
    });
  }

  /// **Handles Search Suggestions Display**
  Widget _buildSearchResults(MapNotifier mapNotifier) {
    final mapState = ref.watch(mapProvider);
    return Container(
      height: 150.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: mapState.searchResults!.length,
        itemBuilder: (context, index) {
          final location = mapState.searchResults![index];
          return ListTile(
            title: Text(location.address ?? "Unknown Place"),
            onTap: () {
              _activeController!.text = location.address ?? "";
              mapNotifier.setSelectedLocation(location);
              setState(() {
                _activeController = null;
              });
            },
          );
        },
      ),
    );
  }

  /// **Search Field Widget**
  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Function(String) onSearch,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      onChanged: onSearch,
    );
  }

  double _getZoomForBounds(LatLngBounds bounds) {
    const double minZoom = 10.0;
    const double maxZoom = 18.0;

    // Calculate the distance between the two corners (diagonal of the bounds)
    final latDiff = bounds.northEast.latitude - bounds.southWest.latitude;
    final lngDiff = bounds.northEast.longitude - bounds.southWest.longitude;
    // Approximate the distance (a simple Pythagorean theorem approach)
    final distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);

    // Map the distance to a zoom level (this is an approximation)
    double zoom = 16.0 - distance * 10; // Adjust multiplier for finer control
    _currentZoom =
        zoom.clamp(minZoom, maxZoom); // Clamp between min and max zoom levels
    return _currentZoom;
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMove) {
      setState(() {
        _currentZoom = event.camera.zoom;
        _showMarker = event.camera.zoom >= 12;
      });
    }
  }
}
