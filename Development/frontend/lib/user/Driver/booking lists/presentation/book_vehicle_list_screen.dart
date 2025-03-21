import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/user/Driver/booking%20lists/providers/book_vehicle_provider.dart';
import 'package:frontend/user/Passenger/setting/providers/setting_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BookVehicleListScreen extends ConsumerStatefulWidget {
  const BookVehicleListScreen({super.key});

  @override
  ConsumerState<BookVehicleListScreen> createState() =>
      _BookVehicleListScreenState();
}

class _BookVehicleListScreenState extends ConsumerState<BookVehicleListScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid calling setState during build
    Future.microtask(() => fetchBookings());
  }

  void fetchBookings() {
    final vehicleId = ref.read(settingProvider).users[0].vehicleId;
    print('Vehicle ID: $vehicleId');
    if (vehicleId != null) {
      ref.read(bookVehicleProvider.notifier).fetchBookingsByVehicle(vehicleId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingByVehicletate = ref.watch(bookVehicleProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings List'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: bookingByVehicletate.isLoading
                    ? _buildLoadingUI()
                    : (bookingByVehicletate.bookingByVehicle == null ||
                            bookingByVehicletate.bookingByVehicle!.isEmpty)
                        ? _buildNoBookingsUI()
                        : _buildBusLayoutWithBookings(
                            bookingByVehicletate.bookingByVehicle!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **Builds the horizontal date selector**
  Widget _buildDateSelector() {
    return Container(
      height: 70.h,
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7, // Show 3 days before and 3 days after today
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
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 5.w),
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.white,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(date), // Day abbreviation (e.g. Mon)
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd').format(date), // e.g. Mar 10
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.blueAccent,
                      fontWeight: FontWeight.bold,
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

  /// **Builds bus layout with bookings**
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

    return Column(
      children: [
        SizedBox(height: 16.h),
        _buildSeatLegend(),
        SizedBox(height: 20.h),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildBusLayout(sortedBookings),
                SizedBox(height: 16.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.grey.shade300, "Available"),
        SizedBox(width: 15.w),
        _buildLegendItem(Colors.green.shade500, "Booked"),
        SizedBox(width: 15.w),
        _buildLegendItem(Colors.red.shade400, "Canceled"),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Make the row take only required space
      children: [
        Container(
          width: 16.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildBusLayout(List bookings) {
    // Create a simplified bus layout
    List<List<dynamic>> busLayout = [
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
    ];

    // Assign bookings to seats (this is a simplified example)
    // In a real application, you'd use actual seat numbers from your data
    int seatNumber = 1;
    for (int i = 0; i < busLayout.length; i++) {
      for (int j = 0; j < busLayout[i].length; j++) {
        if (busLayout[i][j] == 'X') {
          // Find a booking for this seat (simplified)
          var booking = bookings.length >= seatNumber
              ? bookings[seatNumber % bookings.length]
              : null;
          
          if (booking != null) {
            // Associate the seat with the booking
            busLayout[i][j] = {'seat': seatNumber.toString(), 'booking': booking};
          } else {
            busLayout[i][j] = {'seat': seatNumber.toString(), 'booking': null};
          }
          seatNumber++;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          )
        ],
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Driver seat
          Row(
            children: [
              Expanded(child: SizedBox()),
              Container(
                width: 60.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.airline_seat_recline_normal,
                  color: Colors.white,
                ),
              ),
              Expanded(child: SizedBox()),
            ],
          ),
          SizedBox(height: 30.h),
          // Steering wheel
          Row(
            children: [
              Expanded(child: SizedBox()),
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bus_alert,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Expanded(child: SizedBox()),
            ],
          ),
          SizedBox(height: 30.h),
          // Bus doors
          Row(
            children: [
              Container(
                width: 20.w,
                height: 60.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(8.r),
                  ),
                ),
              ),
              Expanded(child: SizedBox()),
            ],
          ),
          SizedBox(height: 20.h),
          // Passenger seats
          ...busLayout.map((row) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((seat) {
                if (seat == '') {
                  // Aisle
                  return SizedBox(width: 30.w);
                }
                
                // Get booking status if available
                var booking = seat['booking'];
                var seatNum = seat['seat'];
                Color seatColor = Colors.grey.shade300; // Default color
                
                // Simplify coloring - only show booked (confirmed/pending), available, or canceled
                if (booking != null) {
                  if (booking.status.toLowerCase() == 'canceled') {
                    seatColor = Colors.red.shade400;
                  } else {
                    // All other statuses (confirmed, pending) are treated as "booked"
                    seatColor = Colors.green.shade500;
                  }
                }
                
                return GestureDetector(
                  onTap: () {
                    if (booking != null && booking.status.toLowerCase() != 'canceled') {
                      // Directly navigate to booking details when a booked seat is tapped
                      context.pushNamed('/bookingDetails', pathParameters: {
                        'bookId': booking.id.toString(),
                        'userId': booking.userId.toString(),
                      });
                    }
                  },
                  child: Container(
                    margin: EdgeInsets.all(4.w),
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: seatColor,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: booking != null ? Colors.black45 : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      seatNum,
                      style: TextStyle(
                        color: seatColor == Colors.grey.shade300 
                            ? Colors.black87 
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'canceled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingUI() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildNoBookingsUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text("No bookings found",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(int bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteBooking(bookingId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteBooking(int bookingId) {
    print('Deleting booking $bookingId');
    // Implement your delete logic here
  }
}