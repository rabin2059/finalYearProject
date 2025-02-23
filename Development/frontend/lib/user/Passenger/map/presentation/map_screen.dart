import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';
import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
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

  List<String> _startSuggestions = [];
  List<String> _endSuggestions = [];
  bool _showStartSuggestions = false;
  bool _showEndSuggestions = false;

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
              initialCenter: mapState.userLocation ??
                  const LatLng(27.7172, 85.3240), // Default Kathmandu
              onMapEvent: (event) => _onMapEvent(event),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              if (_showMarker && mapState.userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40.w,
                      height: 40.h,
                      point: mapState.userLocation!,
                      child: const Icon(Icons.location_pin,
                          color: Colors.red, size: 30),
                    )
                  ],
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
                  child: _buildSearchContainer(mapNotifier),
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

  /// **Handles Search UI**
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
                final start = await mapNotifier
                    .getCoordinatesFromAddress(_startController.text);
                final end = await mapNotifier
                    .getCoordinatesFromAddress(_endController.text);

                if (start != null && end != null) {
                  LatLng startLatLng = LatLng(start.latitude, start.longitude);
                  LatLng endLatLng = LatLng(end.latitude, end.longitude);

                  await mapNotifier.fetchRoute(startLatLng, endLatLng);

                  _controller.move(
                    LatLng((start.latitude + end.latitude) / 2,
                        (start.longitude + end.longitude) / 2),
                    _getZoomForBounds(LatLngBounds(startLatLng, endLatLng)),
                  );
                }

                setState(() {
                  isSearching = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// **Handles Search Suggestions Display**
  Widget _buildSuggestions(List<String> suggestions, bool isStart) {
    return Container(
      height: 150.h,
      margin: EdgeInsets.symmetric(vertical: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(suggestions[index]),
            onTap: () {
              setState(() {
                if (isStart) {
                  _startController.text = suggestions[index];
                  _showStartSuggestions = false;
                } else {
                  _endController.text = suggestions[index];
                  _showEndSuggestions = false;
                }
              });
            },
          );
        },
      ),
    );
  }

  /// **Handles Search Suggestions Display**
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

  /// **Debounced Search Function**
  void _debouncedSearch(String query, MapNotifier mapNotifier, bool isStart) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        await mapNotifier.searchPlaces(query);
        final searchResults = ref.read(mapProvider).searchResults;

        setState(() {
          if (isStart) {
            _startSuggestions = searchResults
                .map((location) => location.address ?? "")
                .toList();
            _showStartSuggestions = true;
          } else {
            _endSuggestions = searchResults
                .map((location) => location.address ?? "")
                .toList();
            _showEndSuggestions = true;
          }
        });
      } else {
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
}
