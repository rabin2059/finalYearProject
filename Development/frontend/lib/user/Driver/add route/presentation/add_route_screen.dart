import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/components/CustomTextField.dart';
import 'package:frontend/core/constants.dart';
import 'package:frontend/user/map/providers/map_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class AddRouteScreen extends ConsumerStatefulWidget {
  const AddRouteScreen({super.key, required this.vehicleId});
  final int vehicleId;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends ConsumerState<AddRouteScreen> {
  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _fareController = TextEditingController();

  bool isSearching = true;
  Timer? _debounce;

  List<String> _pickupSuggestions = [];
  List<String> _dropoffSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showDropoffSuggestions = false;

  /// **Dynamically Added Bus Stops**
  final List<TextEditingController> _busStopControllers = [];
  final Map<int, List<String>> _busStopSuggestionsMap =
      {}; // Suggestions per stop
  final Map<int, bool> _showBusStopSuggestionsMap = {}; // Visibility per stop

  /// **Debounced Search Function**
  void _debouncedSearch(String query, MapNotifier mapNotifier, int? stopIndex) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        await mapNotifier.searchPlaces(query);
        final searchResults = ref.read(mapProvider).searchResults;

        setState(() {
          if (stopIndex == null) {
            if (_pickupController.text == query) {
              _pickupSuggestions = searchResults
                  .map((location) => location.address ?? "")
                  .toList();
              _showPickupSuggestions = true;
            } else if (_dropoffController.text == query) {
              _dropoffSuggestions = searchResults
                  .map((location) => location.address ?? "")
                  .toList();
              _showDropoffSuggestions = true;
            }
          } else {
            _busStopSuggestionsMap[stopIndex] = searchResults
                .map((location) => location.address ?? "")
                .toList();
            _showBusStopSuggestionsMap.forEach((key, value) {
              _showBusStopSuggestionsMap[key] = false;
            }); // Close other suggestions
            _showBusStopSuggestionsMap[stopIndex] = true;
          }
        });
      } else {
        setState(() {
          if (stopIndex == null) {
            _pickupSuggestions.clear();
            _dropoffSuggestions.clear();
            _showPickupSuggestions = false;
            _showDropoffSuggestions = false;
          } else {
            _busStopSuggestionsMap[stopIndex]?.clear();
            _showBusStopSuggestionsMap[stopIndex] = false;
          }
        });
      }
    });
  }

  /// **Add a new Bus Stop field**
  void _addBusStop() {
    setState(() {
      int index = _busStopControllers.length;
      _busStopControllers.add(TextEditingController());
      _busStopSuggestionsMap[index] = [];
      _showBusStopSuggestionsMap[index] =
          false; // Ensure new fields don't show suggestions immediately
    });
  }

  /// **Remove a Bus Stop field**
  void _removeBusStop(int index) {
    setState(() {
      _busStopControllers[index].dispose();
      _busStopControllers.removeAt(index);
      _busStopSuggestionsMap.remove(index);
      _showBusStopSuggestionsMap.remove(index);
    });
  }

  /// **Save Route Data**
  Future<void> _saveRoute() async {
    final mapNotifier = ref.read(mapProvider.notifier);

    final routeName = _routeNameController.text.trim();
    final pickupPoint = _pickupController.text.trim();
    final dropoffPoint = _dropoffController.text.trim();
    final fare = _fareController.text.trim();

    if (routeName.isEmpty ||
        pickupPoint.isEmpty ||
        dropoffPoint.isEmpty ||
        fare.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields are required!")),
      );
      return;
    }

    try {
      // Fetch lat/lng for start and end points
      final pickupLocation =
          await mapNotifier.getCoordinatesFromAddress(pickupPoint);
      final dropoffLocation =
          await mapNotifier.getCoordinatesFromAddress(dropoffPoint);

      if (pickupLocation == null || dropoffLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("Could not fetch coordinates for start or end point!")),
        );
        return;
      }

      List<Map<String, dynamic>> busStops = [];

      // Loop through each bus stop and get lat/lng
      for (int i = 0; i < _busStopControllers.length; i++) {
        final busStopName = _busStopControllers[i].text.trim();
        if (busStopName.isNotEmpty) {
          final busStopLocation =
              await mapNotifier.getCoordinatesFromAddress(busStopName);
          if (busStopLocation != null) {
            busStops.add({
              "name": busStopName,
              "latitude": busStopLocation.latitude,
              "longitude": busStopLocation.longitude,
              "sequence": i + 1, // Ensure sequential order
            });
          }
        }
      }

      final routeData = {
        "name": routeName,
        "startPoint": pickupPoint,
        "endPoint": dropoffPoint,
        "vehicleID": widget.vehicleId,
        "fare": double.tryParse(fare) ?? 0.0,
        "busStops": busStops,
      };

      final url = Uri.parse('$apiBaseUrl/createRoute');

      final response = await http.post(
        url,
        body: json.encode(routeData),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        context.pushReplacementNamed('/navigation');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save route")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save route: $e")),
      );
      print("Error saving route: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapNotifier = ref.read(mapProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Route'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 10.h),
        child: Column(
          children: [
            _buildLabel("Route Name"),
            CustomTextField(
              controller: _routeNameController,
              hint: 'Enter Route Name',
              hintColor: Colors.black,
            ),
            SizedBox(height: 10),

            _buildLabel("Start Point"),
            _buildSearchField(
              controller: _pickupController,
              hint: "Start Location",
              onSearch: (query) => _debouncedSearch(query, mapNotifier, null),
            ),
            _showPickupSuggestions
                ? _buildSuggestions(_pickupSuggestions, _pickupController, null)
                : const SizedBox(),
            SizedBox(height: 16.h),

            _buildLabel("End Point"),
            _buildSearchField(
              controller: _dropoffController,
              hint: "End Location",
              onSearch: (query) => _debouncedSearch(query, mapNotifier, null),
            ),
            _showDropoffSuggestions
                ? _buildSuggestions(
                    _dropoffSuggestions, _dropoffController, null)
                : const SizedBox(),
            SizedBox(height: 10),

            _buildLabel("Fare"),
            CustomTextField(
              controller: _fareController,
              hint: 'Enter Fare',
              hintColor: Colors.black,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),

            /// **Bus Stops Section**
            _buildLabel("Bus Stops"),
            ..._busStopControllers.asMap().entries.map((entry) {
              int index = entry.key;
              TextEditingController controller = entry.value;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSearchField(
                          controller: controller,
                          hint: "Bus Stop",
                          onSearch: (query) =>
                              _debouncedSearch(query, mapNotifier, index),
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeBusStop(index),
                      ),
                    ],
                  ),
                  if (_showBusStopSuggestionsMap[index] == true)
                    _buildSuggestions(
                        _busStopSuggestionsMap[index] ?? [], controller, index),
                ],
              );
            }),

            /// **Add Bus Stop Button**
            TextButton.icon(
              onPressed: _addBusStop,
              icon: const Icon(Icons.add, color: Colors.blue),
              label: const Text("Add Bus Stop"),
            ),

            SizedBox(height: 20),

            /// **Save Button**
            ElevatedButton(
              onPressed: _saveRoute,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
                backgroundColor: Colors.green,
              ),
              child: Text(
                "Save Route",
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **Reusable Label Widget**
  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5.h),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// **Builds Search Field**
  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required Function(String) onSearch,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.r)),
      ),
      onChanged: onSearch,
    );
  }

  /// **Builds Suggestions for Locations**
  Widget _buildSuggestions(List<String> suggestions,
      TextEditingController controller, int? stopIndex) {
    return Column(
      children: suggestions.map((suggestion) {
        return ListTile(
          title: Text(suggestion),
          onTap: () {
            setState(() {
              controller.text = suggestion;

              if (stopIndex == null) {
                // If it's a start or end point
                _showPickupSuggestions = false;
                _showDropoffSuggestions = false;
              } else {
                // If it's a bus stop
                _showBusStopSuggestionsMap[stopIndex] = false;
              }
            });
          },
        );
      }).toList(),
    );
  }
}
