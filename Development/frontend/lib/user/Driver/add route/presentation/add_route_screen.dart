import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

  bool isSearching = false;
  Timer? _debounce;
  bool _isLoading = false;

  List<String> _pickupSuggestions = [];
  List<String> _dropoffSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showDropoffSuggestions = false;

  /// Dynamically Added Bus Stops
  final List<TextEditingController> _busStopControllers = [];
  final Map<int, List<String>> _busStopSuggestionsMap = {}; // Suggestions per stop
  final Map<int, bool> _showBusStopSuggestionsMap = {}; // Visibility per stop

  /// Debounced Search Function
  void _debouncedSearch(String query, MapNotifier mapNotifier, int? stopIndex) {
    setState(() {
      isSearching = true;
    });
    
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        await mapNotifier.searchPlaces(query);
        final searchResults = ref.read(mapProvider).searchResults;

        setState(() {
          isSearching = false;
          if (stopIndex == null) {
            if (_pickupController.text == query) {
              _pickupSuggestions = searchResults
                  .map((location) => location.address ?? "")
                  .toList();
              _showPickupSuggestions = true;
              _showDropoffSuggestions = false;
            } else if (_dropoffController.text == query) {
              _dropoffSuggestions = searchResults
                  .map((location) => location.address ?? "")
                  .toList();
              _showDropoffSuggestions = true;
              _showPickupSuggestions = false;
            }
          } else {
            _showBusStopSuggestionsMap.updateAll((key, value) => false);
            _busStopSuggestionsMap[stopIndex] = searchResults
                .map((location) => location.address ?? "")
                .toList();
            _showBusStopSuggestionsMap[stopIndex] = true;
          }
        });
      } else {
        setState(() {
          isSearching = false;
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

  /// Add a new Bus Stop field
  void _addBusStop() {
    setState(() {
      int index = _busStopControllers.length;
      _busStopControllers.add(TextEditingController());
      _busStopSuggestionsMap[index] = [];
      _showBusStopSuggestionsMap[index] = false; // Ensure new fields don't show suggestions immediately
    });
  }

  /// Remove a Bus Stop field
  void _removeBusStop(int index) {
    setState(() {
      _busStopControllers[index].dispose();
      _busStopControllers.removeAt(index);
      
      // Rebuild the map with new indices
      final Map<int, List<String>> newSuggestionsMap = {};
      final Map<int, bool> newShowSuggestionsMap = {};
      
      for (int i = 0; i < _busStopControllers.length; i++) {
        newSuggestionsMap[i] = _busStopSuggestionsMap[i > index ? i - 1 : i] ?? [];
        newShowSuggestionsMap[i] = _showBusStopSuggestionsMap[i > index ? i - 1 : i] ?? false;
      }
      
      _busStopSuggestionsMap.clear();
      _showBusStopSuggestionsMap.clear();
      _busStopSuggestionsMap.addAll(newSuggestionsMap);
      _showBusStopSuggestionsMap.addAll(newShowSuggestionsMap);
    });
  }

  /// Save Route Data
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
      _showErrorSnackBar("All fields are required!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch lat/lng for start and end points
      final pickupLocation = await mapNotifier.getCoordinatesFromAddress(pickupPoint);
      final dropoffLocation = await mapNotifier.getCoordinatesFromAddress(dropoffPoint);

      if (pickupLocation == null || dropoffLocation == null) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar("Could not fetch coordinates for start or end point!");
        return;
      }

      List<Map<String, dynamic>> busStops = [];

      // Loop through each bus stop and get lat/lng
      for (int i = 0; i < _busStopControllers.length; i++) {
        final busStopName = _busStopControllers[i].text.trim();
        if (busStopName.isNotEmpty) {
          final busStopLocation = await mapNotifier.getCoordinatesFromAddress(busStopName);
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

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSnackBar("Route created successfully!");
        context.pushReplacementNamed('/navigation');
      } else {
        _showErrorSnackBar("Failed to save route");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar("An error occurred: ${e.toString().split('\n')[0]}");
      print("Error saving route: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(10.w),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(10.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapNotifier = ref.read(mapProvider.notifier);

    return GestureDetector(
      onTap: () {
        // Close keyboard and suggestion boxes when tapping outside
        FocusScope.of(context).unfocus();
        setState(() {
          _showPickupSuggestions = false;
          _showDropoffSuggestions = false;
          _showBusStopSuggestionsMap.updateAll((key, value) => false);
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            'Create Route',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 20.sp, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: "Route Information",
                    icon: Icons.route,
                    child: Column(
                      children: [
                        _buildPremiumTextField(
                          controller: _routeNameController,
                          label: "Route Name",
                          hint: "Enter route name",
                          icon: Icons.drive_file_rename_outline,
                        ),
                        SizedBox(height: 20.h),
                        _buildPremiumTextField(
                          controller: _fareController,
                          label: "Fare Amount",
                          hint: "Enter fare amount",
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          prefix: Text(
                            "₹ ",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  _buildSectionCard(
                    title: "Route Locations",
                    icon: Icons.location_on,
                    child: Column(
                      children: [
                        _buildSearchLocationField(
                          controller: _pickupController,
                          label: "Start Point",
                          hint: "Enter start location",
                          icon: Icons.trip_origin,
                          iconColor: Colors.green,
                          onSearch: (query) => _debouncedSearch(query, mapNotifier, null),
                        ),
                        if (_showPickupSuggestions)
                          _buildSuggestionsList(
                            suggestions: _pickupSuggestions, 
                            controller: _pickupController, 
                            isLoading: isSearching,
                            onSelect: (suggestion) {
                              setState(() {
                                _pickupController.text = suggestion;
                                _showPickupSuggestions = false;
                              });
                            },
                          ),
                        
                        SizedBox(height: 20.h),
                        
                        _buildSearchLocationField(
                          controller: _dropoffController,
                          label: "End Point",
                          hint: "Enter end location",
                          icon: Icons.place,
                          iconColor: Colors.red,
                          onSearch: (query) => _debouncedSearch(query, mapNotifier, null),
                        ),
                        if (_showDropoffSuggestions)
                          _buildSuggestionsList(
                            suggestions: _dropoffSuggestions, 
                            controller: _dropoffController, 
                            isLoading: isSearching,
                            onSelect: (suggestion) {
                              setState(() {
                                _dropoffController.text = suggestion;
                                _showDropoffSuggestions = false;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  _buildSectionCard(
                    title: "Bus Stops",
                    icon: Icons.airline_stops,
                    child: Column(
                      children: [
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _busStopControllers.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final controller = _busStopControllers.removeAt(oldIndex);
                              _busStopControllers.insert(newIndex, controller);
                              final suggestions = _busStopSuggestionsMap.remove(oldIndex) ?? [];
                              final show = _showBusStopSuggestionsMap.remove(oldIndex) ?? false;
                              final Map<int, List<String>> newSuggestionsMap = {};
                              final Map<int, bool> newShowMap = {};
                              for (int i = 0; i < _busStopControllers.length; i++) {
                                newSuggestionsMap[i] = (i == newIndex)
                                    ? suggestions
                                    : _busStopSuggestionsMap[i >= newIndex ? i - 1 : i] ?? [];
                                newShowMap[i] = (i == newIndex)
                                    ? show
                                    : _showBusStopSuggestionsMap[i >= newIndex ? i - 1 : i] ?? false;
                              }
                              _busStopSuggestionsMap
                                ..clear()
                                ..addAll(newSuggestionsMap);
                              _showBusStopSuggestionsMap
                                ..clear()
                                ..addAll(newShowMap);
                            });
                          },
                          itemBuilder: (context, index) {
                            final controller = _busStopControllers[index];
                            return Column(
                              key: ValueKey("busStop_$index"),
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 28.w,
                                      height: 28.w,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${index + 1}",
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildSearchLocationField(
                                            controller: controller,
                                            label: "Bus Stop ${index + 1}",
                                            hint: "Enter bus stop location",
                                            icon: Icons.directions_bus,
                                            iconColor: Colors.blue,
                                            showLabel: false,
                                            onSearch: (query) => _debouncedSearch(query, mapNotifier, index),
                                          ),
                                          if (_showBusStopSuggestionsMap[index] == true)
                                            _buildSuggestionsList(
                                              suggestions: _busStopSuggestionsMap[index] ?? [],
                                              controller: controller,
                                              isLoading: isSearching,
                                              onSelect: (suggestion) {
                                                setState(() {
                                                  controller.text = suggestion;
                                                  _showBusStopSuggestionsMap[index] = false;
                                                });
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    GestureDetector(
                                      onTap: () => _removeBusStop(index),
                                      child: Container(
                                        margin: EdgeInsets.only(top: 12.h),
                                        padding: EdgeInsets.all(8.w),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          color: Colors.red,
                                          size: 20.sp,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16.h),
                              ],
                            );
                          },
                        ),
                        
                        SizedBox(height: 10.h),
                        
                        GestureDetector(
                          onTap: _addBusStop,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: Colors.blue.shade300,
                                width: 1.5,
                              ),
                              color: Colors.blue.withOpacity(0.05),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: Colors.blue,
                                  size: 20.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  "Add Bus Stop",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 30.h),
                  
                  ElevatedButton(
                    onPressed: _saveRoute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      minimumSize: Size(double.infinity, 54.h),
                    ),
                    child: Text(
                      "Save Route",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 30.h),
                ],
              ),
            ),
            
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "Creating Route...",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.blue,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    bottomLeft: Radius.circular(12.r),
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue,
                  size: 20.sp,
                ),
              ),
              if (prefix != null) 
                Padding(
                  padding: EdgeInsets.only(left: 12.w),
                  child: prefix,
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  ),
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchLocationField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required Function(String) onSearch,
    bool showLabel = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12.r),
                    bottomLeft: Radius.circular(12.r),
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20.sp,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 15.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey.shade600,
                              size: 18.sp,
                            ),
                            onPressed: () {
                              controller.clear();
                              onSearch("");
                            },
                          )
                        : (isSearching
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                                  ),
                                ),
                              )
                            : null),
                  ),
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.black87,
                  ),
                  onChanged: onSearch,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsList({
    required List<String> suggestions,
    required TextEditingController controller,
    required bool isLoading,
    required Function(String) onSelect,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: 200.h,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: isLoading
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              )
            : suggestions.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      "No locations found",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14.sp,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: suggestions.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return ListTile(
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: Colors.blue,
                          size: 20.sp,
                        ),
                        title: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        dense: true,
                        onTap: () => onSelect(suggestion),
                      );
                    },
                  ),
      ),
    );
  }
}