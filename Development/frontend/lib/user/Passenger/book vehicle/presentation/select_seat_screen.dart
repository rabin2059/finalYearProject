import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/user/Passenger/bus%20details/providers/bus_details_provider.dart';
import 'package:frontend/components/AppColors.dart';

class SelectSeatScreen extends ConsumerStatefulWidget {
  final String vehicleType;
  final Set<String> selectedSeats;
  final Set<String> bookedSeats;

  const SelectSeatScreen({
    super.key,
    required this.vehicleType,
    required this.selectedSeats,
    required this.bookedSeats,
  });

  @override
  _SelectSeatScreenState createState() => _SelectSeatScreenState();
}

class _SelectSeatScreenState extends ConsumerState<SelectSeatScreen> with SingleTickerProviderStateMixin {
  Set<String> _selectedSeats = {};
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _selectedSeats = Set.from(widget.selectedSeats);
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

  List<List<String>> getSeatLayout(List<int?> totalSeats, Set<String> bookedSeats) {
    List<List<String>> baseLayout = widget.vehicleType == 'Bus'
        ? [
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            // Add extra spacing after row 4 (visual grouping)
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', '', 'X', 'X'],
            // Add extra spacing after row 8 (visual grouping)
            ['X', 'X', '', 'X', 'X'],
            ['X', 'X', 'X', 'X', 'X'], // Back row often has 5 seats
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
    // Remove rows that only have aisles or are fully empty
    baseLayout = baseLayout.where((row) {
      return row.any((cell) => cell.isNotEmpty && cell != '');
    }).toList();

    return baseLayout;
  }

  void _toggleSeatSelection(String seat) {
    if (widget.bookedSeats.contains(seat) || seat == 'B') return;
    
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else {
        _selectedSeats.add(seat);
      }
      
      final busState = ref.read(busDetailsProvider);
      final fare = busState.vehicle?.route?.isNotEmpty ?? false
          ? busState.vehicle!.route![0].fare!
          : 0.0;
      
      _totalPrice = (_selectedSeats.length * fare).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final busState = ref.watch(busDetailsProvider);
    final state = busState.vehicle;
    final totalSeats = state?.vehicleSeat?.map((seat) => seat.seatNo).toList() ?? [];
    final bookedSeats = widget.bookedSeats.map((s) => s.toString()).toSet();
    final fare = busState.vehicle?.route?.isNotEmpty ?? false 
        ? busState.vehicle!.route![0].fare! * _selectedSeats.length 
        : 0;
    
    return FadeTransition(
      opacity: _animation,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Select Your Seats",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: AppColors.primary,
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              onPressed: () => _showSeatInfo(context),
            ),
          ],
        ),
        body: Stack(
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
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem(AppColors.primary, "Selected"),
                        _buildLegendItem(Colors.grey.shade200, "Available"),
                        _buildLegendItem(Colors.red.shade400, "Booked"),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child:             Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      padding: EdgeInsets.fromLTRB(15.w, 15.w, 15.w, 10.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.vehicleType == 'Bus' ? "Bus Seating Arrangement" : "Seating Arrangement",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 15.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.grey.shade200),
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
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.arrow_forward, color: Colors.grey, size: 16.sp),
                                    SizedBox(width: 5.w),
                                    Text(
                                      "Front",
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
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
                         
                          _buildSeatLayout(getSeatLayout(totalSeats, bookedSeats)),
                        ],
                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              "Selected Seats:",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            _selectedSeats.isEmpty
                              ? Text(
                                  "None",
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      _selectedSeats.toList().join(", "),
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      softWrap: false,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Price:",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "रु ${_totalPrice.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, _selectedSeats);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 15.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 1,
                            ),
                            child: Text(
                              _selectedSeats.isEmpty
                                  ? "Confirm Selection"
                                  : "Confirm ${_selectedSeats.length} ${_selectedSeats.length == 1 ? 'Seat' : 'Seats'}",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _showSeatInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Colors.white,
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Seat Selection Guide",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    _buildInfoItem(
                      icon: Icons.check_circle,
                      color: AppColors.primary,
                      title: "How to select seats",
                      description: "Tap on any available seat to select it. Tap again to deselect.",
                    ),
                    Divider(height: 30.h),
                    _buildInfoItem(
                      icon: Icons.lock,
                      color: Colors.red.shade400,
                      title: "Booked seats",
                      description: "Seats shown in red color are already booked and cannot be selected.",
                    ),
                    Divider(height: 30.h),
                    _buildInfoItem(
                      icon: Icons.info,
                      color: Colors.amber.shade700,
                      title: "Seat numbering",
                      description: "Seat numbers are displayed on each seat. The layout may vary based on vehicle type.",
                    ),
                    Divider(height: 30.h),
                    _buildInfoItem(
                      icon: Icons.payments,
                      color: Colors.green,
                      title: "Payment",
                      description: "The total price will be calculated based on the number of seats selected and will be shown at checkout.",
                    ),
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
                    "Got it",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildInfoItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatLayout(List<List<String>> layout) {
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
                final seat = seatEntry.value;
                
                // Add additional space for aisle
                final isAisle = seat.isEmpty;
                final horizontalPadding = isAisle ? 15.w : 6.w;
                
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: seat.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _toggleSeatSelection(seat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 52.w,
                            height: 52.h,
                            decoration: BoxDecoration(
                              color: seat == 'B'
                                  ? Colors.red.shade400
                                  : _selectedSeats.contains(seat)
                                      ? AppColors.primary
                                      : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow: [
                                BoxShadow(
                                  color: (seat == 'B')
                                      ? Colors.red.withOpacity(0.3)
                                      : _selectedSeats.contains(seat)
                                          ? AppColors.primary.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.05),
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
                                    color: (seat == 'B')
                                        ? Colors.red.shade300
                                        : _selectedSeats.contains(seat)
                                            ? AppColors.primary.withOpacity(0.7)
                                            : Colors.grey.shade100,
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
                                    color: (seat == 'B')
                                        ? Colors.red.shade500
                                        : _selectedSeats.contains(seat)
                                            ? AppColors.primary.withOpacity(0.9)
                                            : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                                if (seat != 'B')
                                  Text(
                                    seat,
                                    style: TextStyle(
                                      color: _selectedSeats.contains(seat) ? Colors.white : Colors.black87,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18.sp,
                                  ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          width: 30.w,
                          height: 52.h,
                          decoration: BoxDecoration(
                            // Visualize the aisle with a faint line
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
              }).toList(),
            ),
            SizedBox(height: rowSpacing),
            
            // Add a row divider except after the last row
            if (rowIndex < layout.length - 1 && rowIndex % 4 == 3)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 15.w),
                child: Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}