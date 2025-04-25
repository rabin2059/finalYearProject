import 'package:flutter/material.dart';
import '../../../../components/AppColors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../Passenger/setting/providers/setting_provider.dart';
import '../../vehicle details/provider/vehicle_details_provider.dart';
import '../providers/book_vehicle_provider.dart';

class BookVehicleListScreen extends ConsumerStatefulWidget {
  const BookVehicleListScreen({super.key});

  @override
  ConsumerState<BookVehicleListScreen> createState() =>
      _BookVehicleListScreenState();
}

class _BookVehicleListScreenState extends ConsumerState<BookVehicleListScreen> with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
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
    
    Future.microtask(() => fetchBookings());
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void fetchBookings() {
    final vehicleId = ref.read(settingProvider).users[0].vehicleId;
    if (vehicleId != null) {
      ref.read(bookVehicleProvider.notifier).fetchBookingsByVehicle(vehicleId);
    }
  }

  List<List<String>> getSeatLayout(List<int?> totalSeats, Set<int> bookedSeats, Map<int, String> seatStatusMap) {
    final vehicleState = ref.read(vehicleProvider);
    final vehicleType = vehicleState.vehicle?.vehicleType ?? 'Bus';

    List<List<String>> baseLayout = vehicleType == 'Bus'
        ? [
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            // Add extra spacing after row 4
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            // Add extra spacing after row 8
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', 'X', 'X', 'X'], // Back row
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
          if (totalSeats.contains(seatNumber)) {
            String status = 'A'; // Available by default
            if (bookedSeats.contains(seatNumber)) {
              status = seatStatusMap[seatNumber] ?? 'B'; // Booked or specific status
            }
            baseLayout[i][j] = '$seatNumber:$status';
          } else {
            baseLayout[i][j] = '';
          }
          seatNumber++;
        }
      }
    }
    
    // Remove rows that only have aisles or are fully empty
    baseLayout = baseLayout.where((row) {
      return row.any((cell) => cell.isNotEmpty && cell != '');
    }).toList();

    return baseLayout;
  }

  @override
  Widget build(BuildContext context) {
    final bookingByVehicleState = ref.watch(bookVehicleProvider);
    final primaryColor = AppColors.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bookings List',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.buttonText,
          ),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.buttonText),
            onPressed: fetchBookings,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _animation,
        child: Stack(
          children: [
            Container(
              height: 120.h,
              decoration: BoxDecoration(
                color: primaryColor,
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
                  _buildDateSelector(),
                  SizedBox(height: 15.h),
                  Expanded(
                    child: bookingByVehicleState.isLoading
                        ? _buildLoadingUI()
                        : (bookingByVehicleState.bookingByVehicle == null ||
                                bookingByVehicleState.bookingByVehicle!.isEmpty)
                            ? _buildNoBookingsUI()
                            : _buildBusLayoutWithBookings(
                                bookingByVehicleState.bookingByVehicle!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 80.h,
      margin: EdgeInsets.symmetric(horizontal: 15.w),
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
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().subtract(Duration(days: 3 - index));
          String formattedDate = DateFormat('yyyy-MM-dd').format(date);
          bool isSelected = selectedDate.day == date.day &&
              selectedDate.month == date.month &&
              selectedDate.year == date.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = date;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: 5.w),
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.buttonText,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.iconColor.withOpacity(0.4),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: isSelected ? AppColors.buttonText : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('MMM dd').format(date),
                    style: TextStyle(
                      color: isSelected ? AppColors.buttonText : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusLayoutWithBookings(List bookings) {
    List sortedBookings = bookings
        .where((booking) =>
            DateFormat('yyyy-MM-dd')
                .format(DateTime.parse(booking.bookingDate)) ==
            DateFormat('yyyy-MM-dd').format(selectedDate))
        .toList()
      ..sort((a, b) => b.id!.compareTo(a.id!));

    if (sortedBookings.isEmpty) {
      return _buildNoBookingsUI();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
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
          SizedBox(height: 16.h),
          _buildSeatLegend(),
          SizedBox(height: 20.h),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Column(
                  children: [
                    _buildBusLayout(sortedBookings),
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

  Widget _buildSeatLegend() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.background),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(AppColors.background, "Available"),
          _buildLegendItem(AppColors.messageSent, "Booked"),
          _buildLegendItem(AppColors.accent, "Canceled"),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 24.w,
          height: 24.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBusLayout(List bookings) {
    final vehicleState = ref.watch(vehicleProvider);
    final seatObjects = vehicleState.vehicle?.vehicleSeat ?? [];
    final seats = seatObjects.map((seat) => seat.seatNo).toList();

    // Create a set of booked seats and map of seat to status
    final bookedSet = <int>{};
    final seatStatusMap = <int, String>{};
    
    for (var booking in bookings) {
      for (var seat in booking.bookingSeats) {
        bookedSet.add(seat.seatNo);
        seatStatusMap[seat.seatNo] = booking.status.toLowerCase() == 'canceled' ? 'C' : 'B';
      }
    }

    if (seats.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.h),
          child: Text(
            'No seats configured for this vehicle',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.background),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.airline_seat_recline_extra, color: AppColors.primary, size: 20.sp),
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
                  Icon(Icons.arrow_forward, color: AppColors.iconColor.withOpacity(0.4), size: 16.sp),
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
        _buildSeatLayoutView(getSeatLayout(seats, bookedSet, seatStatusMap), bookings),
      ],
    );
  }

  Widget _buildSeatLayoutView(List<List<String>> layout, List bookings) {
    return Column(
      children: layout.asMap().entries.map((rowEntry) {
        final rowIndex = rowEntry.key;
        final row = rowEntry.value;
        
        final rowSpacing = rowIndex > 0 && rowIndex < layout.length - 1 ? 18.h : 12.h;
        
        final hasLeft = row.sublist(0, row.length ~/ 2).any((s) => s.isNotEmpty);
        final hasRight = row.sublist((row.length ~/ 2) + 1).any((s) => s.isNotEmpty);
        
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
                final seatInfo = seatEntry.value;
                
                // Add additional space for aisle
                final isAisle = seatInfo.isEmpty;
                final horizontalPadding = isAisle ? 15.w : 6.w;

                if (isAisle) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Container(
                      width: 30.w,
                      height: 52.h,
                      decoration: BoxDecoration(
                        border: seatIndex == 2 ? Border(
                          right: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                            style: BorderStyle.solid,
                          ),
                        ) : null,
                      ),
                    ),
                  );
                }

                // Parse seat number and status
                final parts = seatInfo.split(':');
                final seatNumber = int.tryParse(parts[0]) ?? 0;
                final status = parts.length > 1 ? parts[1] : 'A';

                // Determine colors based on status
                Color seatColor;
                Color textColor;
                if (status == 'C') {
                  seatColor = AppColors.accent;
                  textColor = AppColors.buttonText;
                } else if (status == 'B') {
                  seatColor = AppColors.messageSent;
                  textColor = AppColors.buttonText;
                } else {
                  seatColor = AppColors.background;
                  textColor = AppColors.textPrimary;
                }

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: GestureDetector(
                    onTap: () {
                      if (status == 'B') {
                        final matched = bookings.where((b) =>
                          b.bookingSeats.any((bs) => bs.seatNo == seatNumber)
                        ).toList();
                        if (matched.isNotEmpty) {
                          final booking = matched.first;
                          context.pushNamed(
                            '/bookingDetails',
                            pathParameters: {
                              'bookId': booking.id!.toString(),
                              'userId': booking.userId.toString(),
                            },
                          );
                        }
                      }
                    },
                    child: Container(
                      width: 52.w,
                      height: 52.h,
                      decoration: BoxDecoration(
                        color: seatColor,
                        borderRadius: BorderRadius.circular(10.r),
                        boxShadow: [
                          BoxShadow(
                            color: seatColor.withOpacity(0.3),
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
                              color: seatColor.withOpacity(0.7),
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
                              color: seatColor.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          if (status == 'C')
                            Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18.sp,
                            )
                          else
                            Text(
                              seatNumber.toString(),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: rowSpacing),
            
            // Add a row divider except after the last row
            if (rowIndex < layout.length - 1 && rowIndex % 4 == 3)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 15.w),
                child: Container(
                  height: 1,
                  color: AppColors.background,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLoadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60.w,
            height: 60.h,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            "Loading bookings...",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBookingsUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_bus,
              size: 80.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            "No bookings found",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            "There are no bookings for this date",
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 30.h),
          ElevatedButton(
            onPressed: fetchBookings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.buttonText,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              "Refresh",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}