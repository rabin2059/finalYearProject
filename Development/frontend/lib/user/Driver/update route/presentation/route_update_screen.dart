import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:merobus/user/Driver/vehicle%20details/provider/vehicle_details_provider.dart';

import '../../../../components/AppColors.dart';
import '../../../../core/constants.dart';
import '../../../map/providers/map_provider.dart';

class RouteUpdateScreen extends ConsumerStatefulWidget {
  final int routeId;
  const RouteUpdateScreen({super.key, required this.routeId});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _RouteUpdateScreenState();
}

class _RouteUpdateScreenState extends ConsumerState<RouteUpdateScreen> {
  bool _isChanged = false;
  void markChanged() {
    if (!_isChanged) {
      setState(() {
        _isChanged = true;
      });
    }
  }

  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _fareController = TextEditingController();
  final List<TextEditingController> _busStopControllers = [];

  // For location suggestions
  List<String> _pickupSuggestions = [];
  List<String> _dropoffSuggestions = [];
  bool _showPickupSuggestions = false;
  bool _showDropoffSuggestions = false;
  bool isSearching = false;
  Timer? _debounce;
  final Map<int, List<String>> _busStopSuggestionsMap = {};
  final Map<int, bool> _showBusStopSuggestionsMap = {};

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final vehicleState = ref.read(vehicleProvider);
    final data = vehicleState.vehicle;
    final sf = data?.route![0];

    if (sf != null) {
      _routeNameController.text = sf.name ?? '';
      _pickupController.text = sf.startPoint ?? '';
      _dropoffController.text = sf.endPoint ?? '';
      _fareController.text = sf.fare != null ? sf.fare.toString() : '';

      if (sf.busStops != null && sf.busStops!.isNotEmpty) {
        for (int i = 0; i < sf.busStops!.length; i++) {
          final stop = sf.busStops![i];
          final controller =
              TextEditingController(text: stop.busStop?.name ?? '');
          _busStopControllers.add(controller);
          _busStopSuggestionsMap[i] = [];
          _showBusStopSuggestionsMap[i] = false;
        }
      }
    }
  }

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

  Future<void> _updateRoute() async {
    setState(() {
      isLoading = true;
    });
    final vehicleState = ref.read(vehicleProvider);
    final data = vehicleState.vehicle;
    final vehicleId = data!.id;
    final mapNotifier = ref.read(mapProvider.notifier);
    final routeName = _routeNameController.text.trim();
    final pickupPoint = _pickupController.text.trim();
    final dropoffPoint = _dropoffController.text.trim();
    final fare = _fareController.text.trim();

    List<Map<String, dynamic>> busStops = [];

    for (int i = 0; i < _busStopControllers.length; i++) {
      final busStopName = _busStopControllers[i].text.trim();
      if (busStopName.isNotEmpty) {
        final coords = await mapNotifier.getCoordinatesFromAddress(busStopName);

        busStops.add({
          "name": busStopName,
          "latitude": coords?.latitude ?? 0.0,
          "longitude": coords?.longitude ?? 0.0,
          "sequence": i + 1,
        });
      }
    }

    final url = Uri.parse('$apiBaseUrl/updateRoute');

    final bodyData = {
      "routeId": widget.routeId,
      "startPoint": pickupPoint,
      "endPoint": dropoffPoint,
      "fare": double.tryParse(fare) ?? 0.0,
      "name": routeName,
      "busStops": busStops,
    };

    print("Sending update route body: ${jsonEncode(bodyData)}");

    try {
      final response = await http.put(
        url,
        body: json.encode(bodyData),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        setState(() {
          _isChanged = false;
        });
        ref.read(vehicleProvider.notifier).loadVehicle(vehicleId!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Route updated successfully!"),
            backgroundColor: AppColors.primary,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update route"),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapNotifier = ref.read(mapProvider.notifier);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _showPickupSuggestions = false;
          _showDropoffSuggestions = false;
          _showBusStopSuggestionsMap.updateAll((key, value) => false);
        });
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Update Route',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            Container(
              height: 30.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.r),
                  bottomRight: Radius.circular(30.r),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: "Route Information",
                    icon: Icons.route,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _routeNameController,
                          label: "Route Name",
                          hint: "Enter route name",
                          icon: Icons.drive_file_rename_outline,
                        ),
                        SizedBox(height: 16.h),
                        _buildTextField(
                          controller: _fareController,
                          label: "Fare Amount",
                          hint: "Enter fare amount",
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          prefix: Text(
                            "Rs. ",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
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
                          onSearch: (query) =>
                              _debouncedSearch(query, mapNotifier, null),
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
                        SizedBox(height: 16.h),
                        // Route connector
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1.h,
                                  color:
                                      AppColors.textSecondary.withOpacity(0.2),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Icon(
                                  Icons.arrow_downward,
                                  color:
                                      AppColors.textSecondary.withOpacity(0.5),
                                  size: 18.r,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1.h,
                                  color:
                                      AppColors.textSecondary.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        _buildSearchLocationField(
                          controller: _dropoffController,
                          label: "End Point",
                          hint: "Enter end location",
                          icon: Icons.place,
                          iconColor: AppColors.accent,
                          onSearch: (query) =>
                              _debouncedSearch(query, mapNotifier, null),
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
                  SizedBox(height: 16.h),
                  _buildSectionCard(
                    title: "Bus Stops",
                    icon: Icons.airline_stops,
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: _busStopControllers.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 28.w,
                                      height: 28.w,
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${index + 1}",
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _buildSearchLocationField(
                                            controller:
                                                _busStopControllers[index],
                                            label: "Bus Stop ${index + 1}",
                                            hint: "Enter bus stop name",
                                            icon: Icons.location_on_outlined,
                                            iconColor: AppColors.purple,
                                            showLabel: false,
                                            onSearch: (query) =>
                                                _debouncedSearch(
                                                    query, mapNotifier, index),
                                          ),
                                          if (_showBusStopSuggestionsMap[
                                                  index] ==
                                              true)
                                            _buildSuggestionsList(
                                              suggestions:
                                                  _busStopSuggestionsMap[
                                                          index] ??
                                                      [],
                                              controller:
                                                  _busStopControllers[index],
                                              isLoading: isSearching,
                                              onSelect: (suggestion) {
                                                setState(() {
                                                  _busStopControllers[index]
                                                      .text = suggestion;
                                                  _showBusStopSuggestionsMap[
                                                      index] = false;
                                                });
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _busStopControllers.removeAt(index);
                                          // Rebuild suggestion maps
                                          final Map<int, List<String>>
                                              newSuggestionsMap = {};
                                          final Map<int, bool> newShowMap = {};
                                          for (int i = 0;
                                              i < _busStopControllers.length;
                                              i++) {
                                            newSuggestionsMap[i] =
                                                _busStopSuggestionsMap[i > index
                                                        ? i + 1
                                                        : i] ??
                                                    [];
                                            newShowMap[i] =
                                                _showBusStopSuggestionsMap[
                                                        i > index
                                                            ? i + 1
                                                            : i] ??
                                                    false;
                                          }
                                          _busStopSuggestionsMap
                                            ..clear()
                                            ..addAll(newSuggestionsMap);
                                          _showBusStopSuggestionsMap
                                            ..clear()
                                            ..addAll(newShowMap);
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(20.r),
                                      child: Container(
                                        padding: EdgeInsets.all(8.r),
                                        decoration: BoxDecoration(
                                          color:
                                              AppColors.accent.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: AppColors.accent,
                                          size: 20.r,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (index < _busStopControllers.length - 1)
                                  Padding(
                                    padding: EdgeInsets.only(left: 14.w),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 2.w,
                                          height: 20.h,
                                          color: AppColors.textSecondary
                                              .withOpacity(0.2),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 16.h),
                        // Add stop button
                        InkWell(
                          onTap: () {
                            setState(() {
                              int index = _busStopControllers.length;
                              _busStopControllers.add(TextEditingController());
                              _busStopSuggestionsMap[index] = [];
                              _showBusStopSuggestionsMap[index] = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.5),
                                width: 1.5,
                              ),
                              color: AppColors.iconColor.withOpacity(0.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.primary,
                                  size: 20.r,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  "Add Bus Stop",
                                  style: TextStyle(
                                    color: AppColors.primary,
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (isLoading || !_isChanged) ? null : _updateRoute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.5),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20.r,
                              width: 20.r,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.w,
                              ),
                            )
                          : Text(
                              "Update Route",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
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
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
            ],
          ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
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
                  size: 20.r,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
                              size: 18.r,
                            ),
                            onPressed: () {
                              controller.clear();
                              onSearch("");
                              markChanged();
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary),
                                  ),
                                ),
                              )
                            : null),
                  ),
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                  ),
                  onChanged: (val) {
                    onSearch(val);
                    markChanged();
                  },
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.textSecondary.withOpacity(0.1),
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              )
            : suggestions.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Text(
                      "No locations found",
                      style: TextStyle(
                        color: AppColors.textSecondary,
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
                      color: AppColors.textSecondary.withOpacity(0.2),
                    ),
                    itemBuilder: (context, index) {
                      final suggestion = suggestions[index];
                      return ListTile(
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 20.sp,
                        ),
                        title: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textPrimary,
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
              color: AppColors.iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 20.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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

  Widget _buildTextField({
    required TextEditingController controller,
    String? label,
    required String hint,
    required IconData icon,
    Color iconColor = Colors.blue,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
    bool showLabel = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label != null) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
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
                  size: 20.r,
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
                      color: AppColors.textSecondary,
                      fontSize: 14.sp,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  ),
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textPrimary,
                  ),
                  onChanged: (val) {
                    markChanged();
                  },
                ),
              ),
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.textSecondary,
                    size: 18.r,
                  ),
                  onPressed: () {
                    controller.clear();
                    markChanged();
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
