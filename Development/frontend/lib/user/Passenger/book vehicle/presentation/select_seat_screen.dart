import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/components/CustomButton.dart';
import 'package:frontend/user/Passenger/bus%20details/providers/bus_details_provider.dart';

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

class _SelectSeatScreenState extends ConsumerState<SelectSeatScreen> {
  Set<String> _selectedSeats = {};

  @override
  void initState() {
    super.initState();
    _selectedSeats = Set.from(widget.selectedSeats);
  }

  List<List<String>> getSeatLayout() {
    List<List<String>> baseLayout = widget.vehicleType == 'Bus'
        ? [
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
          ]
        : [
            ['1', '2'],
            ['3', '4'],
            ['5', '6'],
          ];

    for (int i = 0; i < baseLayout.length; i++) {
      for (int j = 0; j < baseLayout[i].length; j++) {
        if (widget.bookedSeats.contains(baseLayout[i][j])) {
          baseLayout[i][j] = 'B'; // Mark as booked
        }
      }
    }

    return baseLayout;
  }

  void _toggleSeatSelection(String seat) {
    if (seat == 'B') return; // Cannot select booked seats
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
      appBar: AppBar(
        title: const Text("Select Seats"),
        elevation: 2,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            children: [
              SizedBox(height: 15.h),
              _buildSeatLegend(),
              SizedBox(height: 20.h),
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: _buildSeatLayout(getSeatLayout()),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              CustomButton(
                text: _selectedSeats.isEmpty
                    ? "OK"
                    : "OK (\${_selectedSeats.length} Selected)",
                width: 220.w,
                onPressed: () {
                  Navigator.pop(context, _selectedSeats);
                },
                color: Colors.greenAccent.shade700,
              ),
              SizedBox(height: 5.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeatLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.blueAccent, "Selected"),
        SizedBox(width: 15.w),
        _buildLegendItem(Colors.grey.shade300, "Available"),
        SizedBox(width: 15.w),
        _buildLegendItem(Colors.redAccent, "Booked"),
      ],
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
            borderRadius: BorderRadius.circular(5.r),
          ),
        ),
        SizedBox(width: 5.w),
        Text(label, style: TextStyle(fontSize: 14.sp, color: Colors.black)),
      ],
    );
  }

  Widget _buildSeatLayout(List<List<String>> layout) {
    return Column(
      children: layout.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row.map((seat) {
            return seat.isNotEmpty
                ? Padding(
                    padding: EdgeInsets.all(5.w),
                    child: GestureDetector(
                      onTap: () =>
                          seat != 'B' ? _toggleSeatSelection(seat) : null,
                      child: Container(
                        width: 60.w,
                        height: 70.h,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: seat == 'B'
                              ? Colors.redAccent.shade700
                              : _selectedSeats.contains(seat)
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          seat,
                          style: TextStyle(
                            color: seat == 'B' || _selectedSeats.contains(seat)
                                ? Colors.white
                                : Colors.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ))
                : SizedBox(width: 40.w);
          }).toList(),
        );
      }).toList(),
    );
  }
}
