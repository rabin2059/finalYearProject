import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../components/CustomButton.dart';
import '../../../../components/AppColors.dart';

class SelectSeatsScreen extends StatefulWidget {
  final String vehicleType;
  final Set<String> selectedSeats;

  const SelectSeatsScreen({
    super.key,
    required this.vehicleType,
    required this.selectedSeats,
  });

  @override
  _SelectSeatsScreenState createState() => _SelectSeatsScreenState();
}

class _SelectSeatsScreenState extends State<SelectSeatsScreen>
    with SingleTickerProviderStateMixin {
  Set<String> _selectedSeats = {};
  late AnimationController _animationController;
  late Animation<double> _animation;

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

  List<List<String>> getSeatLayout() {
    if (widget.vehicleType == 'Bus') {
      return [
        ['1', '2', '', '3', '4'],
        ['5', '6', '', '7', '8'],
        ['9', '10', '', '11', '12'],
        ['13', '14', '', '15', '16'],
        ['17', '18', '', '19', '20'],
        ['21', '22', '', '23', '24'],
        ['25', '26', '', '27', '28'],
        ['29', '30', '', '31', '32'],
        ['33', '34', '', '35', '36'],
        ['37', '38', '39', '40', '41'],
      ];
    } else {
      return [
        ['1', '2'],
        ['3', '4'],
        ['5', '6']
      ];
    }
  }

  void _toggleSeatSelection(String seat) {
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else {
        _selectedSeats.add(seat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Select Seats",
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
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: FadeTransition(
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 5.w),
                        padding: EdgeInsets.all(15.w),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.event_seat,
                                      color: AppColors.primary,
                                      size: 24.r,
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      widget.vehicleType,
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  "Select your preferred seats",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                "${_selectedSeats.length} Selected",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 5.w),
                        padding: EdgeInsets.all(15.w),
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
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLegendItem(AppColors.primary, "Selected"),
                            _buildLegendItem(Colors.grey[300]!, "Available"),
                            _buildLegendItem(Colors.grey[500]!, "Unavailable"),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 5.w),
                        padding: EdgeInsets.symmetric(
                            horizontal: 15.w, vertical: 20.h),
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
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 15.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                    color: AppColors.textSecondary
                                        .withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.airline_seat_recline_extra,
                                          color: AppColors.primary,
                                          size: 20.sp),
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
                            SizedBox(height: 30.h),
                            _buildSeatLayout(),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, _selectedSeats);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(vertical: 15.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              _selectedSeats.isEmpty
                                  ? "Confirm"
                                  : "Confirm (${_selectedSeats.length} Selected)",
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20.w,
          height: 20.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(
              color: color.computeLuminance() > 0.5
                  ? Colors.grey[300]!
                  : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSeatLayout() {
    final layout = getSeatLayout();

    return Column(
      children: layout.asMap().entries.map((rowEntry) {
        final rowIndex = rowEntry.key;
        final row = rowEntry.value;

        final rowSpacing =
            rowIndex > 0 && rowIndex < layout.length - 1 ? 18.h : 12.h;

        Widget rowWidget = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Allow dynamic width for overflow
          children: row.asMap().entries.map((seatEntry) {
            final seatIndex = seatEntry.key;
            final seat = seatEntry.value;

            final isAisle = seat.isEmpty;
            final horizontalPadding = isAisle ? 15.w : 6.w;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: seat.isNotEmpty
                  ? GestureDetector(
                      onTap: () => _toggleSeatSelection(seat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: rowIndex == layout.length - 1 ? 48.w : 52.w,
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
                                color: _selectedSeats.contains(seat)
                                    ? AppColors.primary
                                    : AppColors.buttonText,
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
                                color: _selectedSeats.contains(seat)
                                    ? AppColors.primary.withOpacity(0.7)
                                    : AppColors.textSecondary,
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                            Text(
                              seat,
                              style: TextStyle(
                                color: _selectedSeats.contains(seat)
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
        );

        // Wrap the last row in a SingleChildScrollView to prevent overflow
        if (rowIndex == layout.length - 1) {
          rowWidget = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: rowWidget,
          );
        }

        return Column(
          children: [
            rowWidget,
            SizedBox(height: rowSpacing),
            if (rowIndex < layout.length - 1 && rowIndex % 4 == 3)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 15.w),
                child: Container(
                  height: 1,
                  color: AppColors.textSecondary.withOpacity(0.3),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  void _showInfoDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
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
              "Seat Selection Guide",
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
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      icon: Icons.event_seat,
                      label: "Seat Selection",
                      value:
                          "Select the number of seats from your vehicle and you can select them in the layout of your vehicle.",
                    ),
                    Divider(height: 30.h),
                    _buildInfoRow(
                      icon: Icons.category,
                      label: "Vehicle Type",
                      value: widget.vehicleType,
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
