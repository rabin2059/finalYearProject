import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:merobus/components/CustomButton.dart';
import '../../../../components/AppColors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../provider/vehicle_details_provider.dart';

class ViewVehicleScreen extends ConsumerStatefulWidget {
  const ViewVehicleScreen({super.key});

  @override
  ConsumerState<ViewVehicleScreen> createState() => _ViewVehicleScreenState();
}

class _ViewVehicleScreenState extends ConsumerState<ViewVehicleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<List<String>> getSeatLayout(List<int?> totalSeats) {
    final Set<String> bookedSeats = {};

    final vehicleState = ref.read(vehicleProvider);
    final vehicleType = vehicleState.vehicle?.vehicleType ?? 'Bus';

    List<List<String>> baseLayout = vehicleType == 'Bus'
        ? [
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', 'X', 'X', 'X'],
          ]
        : [
            ['X', 'X'],
            ['X', 'X'],
            ['X', 'X']
          ];

    int seatNumber = 1;
    for (int i = 0; i < baseLayout.length; i++) {
      for (int j = 0; j < baseLayout[i].length; j++) {
        if (baseLayout[i][j] == 'X') {
          String seatStr = seatNumber.toString();
          if (totalSeats.contains(seatNumber)) {
            baseLayout[i][j] = bookedSeats.contains(seatStr) ? 'B' : seatStr;
          } else {
            baseLayout[i][j] = '';
          }
          seatNumber++;
        }
      }
    }

    baseLayout = baseLayout.where((row) {
      return row.any((cell) => cell.isNotEmpty && cell != '');
    }).toList();

    return baseLayout;
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);

    Widget body;
    if (vehicleState.isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (vehicleState.errorMessage.isNotEmpty) {
      body = Center(
        child: Text('Error: ${vehicleState.errorMessage}',
            style: const TextStyle(color: AppColors.accent)),
      );
    } else if (vehicleState.vehicle == null) {
      body = const Center(child: Text('No vehicle found'));
    } else {
      final vehicle = vehicleState.vehicle!;
      final totalSeats =
          vehicle.vehicleSeat?.map((seat) => seat.seatNo).toList() ?? [];
      final primaryColor = AppColors.primary;

      body = FadeTransition(
        opacity: _animation,
        child: Stack(
          children: [
            Container(
              height: 150.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30.r),
                  bottomRight: Radius.circular(30.r),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                    decoration: BoxDecoration(
                      color: AppColors.buttonText,
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Vehicle #${vehicle.vehicleNo}',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          vehicle.vehicleType!,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15.h),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                    decoration: BoxDecoration(
                      color: AppColors.buttonText,
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.textPrimary.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(Icons.directions_car_filled, 'Model',
                            vehicle.model ?? 'N/A'),
                        _buildInfoItem(Icons.event_seat, 'Total Seats',
                            '${totalSeats.length}'),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      padding: EdgeInsets.fromLTRB(15.w, 15.w, 15.w, 10.w),
                      decoration: BoxDecoration(
                        color: AppColors.buttonText,
                        borderRadius: BorderRadius.circular(15.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Seating Arrangement",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 15.h),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 15.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12.r),
                              border:
                                  Border.all(color: AppColors.textSecondary),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.airline_seat_recline_extra,
                                        color: AppColors.primary, size: 20.sp),
                                    SizedBox(width: 8.w),
                                    Text(
                                      "Driver",
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.arrow_forward,
                                        color: AppColors.textSecondary,
                                        size: 16.sp),
                                    SizedBox(width: 5.w),
                                    Text(
                                      "Front",
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: Column(
                                children: [
                                  _buildSeatLayout(getSeatLayout(totalSeats),
                                      AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  CustomButton(
                    text: "Update Route",
                    color: AppColors.primary,
                    fontSize: 20.sp,
                    onPressed: () {
                      final vehicle = ref.read(vehicleProvider).vehicle;
                      final routeId = vehicle?.route?[0].id;
                      if (routeId != null) {
                        context.pushNamed('/routeUpdate',
                            pathParameters: {"id": routeId.toString()});
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text("No Route assigned to this vehicle")),
                        );
                      }
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Vehicle Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.buttonText,
          ),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.buttonText),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.buttonText),
            onPressed: () => _showVehicleInfo(context),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 24.sp,
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatLayout(List<List<String>> layout, Color primaryColor) {
    return Column(
      children: layout.asMap().entries.map((rowEntry) {
        final rowIndex = rowEntry.key;
        final row = rowEntry.value;

        final rowSpacing =
            rowIndex > 0 && rowIndex < layout.length - 1 ? 18.h : 12.h;

        final hasLeft =
            row.sublist(0, row.length ~/ 2).any((s) => s.isNotEmpty);
        final hasRight =
            row.sublist((row.length ~/ 2) + 1).any((s) => s.isNotEmpty);

        MainAxisAlignment alignment = MainAxisAlignment.center;
        if (hasLeft && !hasRight) {
          alignment = MainAxisAlignment.start;
        } else if (!hasLeft && hasRight) {
          alignment = MainAxisAlignment.end;
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: alignment,
              children: row.asMap().entries.map((seatEntry) {
                final seatIndex = seatEntry.key;
                final seat = seatEntry.value;

                // Add additional space for aisle
                final isAisle = seat.isEmpty;
                final horizontalPadding = isAisle ? 15.w : 6.w;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: seat.isNotEmpty
                      ? Container(
                          width: 52.w,
                          height: 52.h,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.textPrimary.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 5.h),
                                width: 42.w,
                                height: 32.h,
                                decoration: BoxDecoration(
                                  color: AppColors.buttonText,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8.r),
                                    topRight: Radius.circular(8.r),
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 30.h),
                                width: 48.w,
                                height: 16.h,
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                              Text(
                                seat,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          width: 30.w,
                          height: 52.h,
                          decoration: BoxDecoration(
                            border: seatIndex == 2
                                ? Border(
                                    right: BorderSide(
                                      color: AppColors.textSecondary,
                                      width: 1,
                                      style: BorderStyle.solid,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                );
              }).toList(),
            ),
            SizedBox(height: rowSpacing),
            if (rowIndex < layout.length - 1 && rowIndex % 4 == 3)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 15.w),
                child: Container(
                  height: 1,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  void _showVehicleInfo(BuildContext context) {
    final vehicle = ref.read(vehicleProvider).vehicle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: AppColors.buttonText,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25.r),
            topRight: Radius.circular(25.r),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Vehicle Information",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.confirmation_number,
                      label: "Vehicle Number",
                      value: vehicle?.vehicleNo ?? 'N/A',
                    ),
                    Divider(height: 30.h),
                    _buildInfoRow(
                      icon: Icons.directions_car,
                      label: "Model",
                      value: vehicle?.model ?? 'N/A',
                    ),
                    Divider(height: 30.h),
                    _buildInfoRow(
                      icon: Icons.category,
                      label: "Vehicle Type",
                      value: vehicle?.vehicleType ?? 'N/A',
                    ),
                    Divider(height: 30.h),
                    if (vehicle?.vehicleSeat != null) ...[
                      Divider(height: 30.h),
                      _buildInfoRow(
                        icon: Icons.event_seat,
                        label: "Total Seats",
                        value: vehicle!.vehicleSeat!.length.toString(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.buttonText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
