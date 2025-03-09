import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/user/Passenger/setting/providers/setting_provider.dart';
import 'package:intl/intl.dart';
import '../../../Passenger/booking lists/providers/book_list_provider.dart';

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
    Future.microtask(() => fetchBookings());
  }

  void fetchBookings() {
    final vehicleId = ref.read(settingProvider).users[0].vehicleId;
    print('Vehicle ID: $vehicleId');
    if (vehicleId != null) {
      ref.read(bookListProvider.notifier).fetchBookings(vehicleId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookListProvider);

    if (bookState.loading) {
      fetchBookings();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings List'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Text(
            bookState.books!.isNotEmpty
                ? bookState.books![0].id.toString()
                : 'No bookings found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black12,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: bookState.loading
                    ? _buildLoadingUI()
                    : (bookState.books == null || bookState.books!.isEmpty)
                        ? _buildNoBookingsUI()
                        : _buildFilteredBookings(bookState.books!),
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

  /// **Filters and builds the bookings list based on the selected date**
  Widget _buildFilteredBookings(List bookings) {
    List sortedBookings = bookings
        .where((booking) =>
            DateFormat('yyyy-MM-dd')
                .format(DateTime.parse(booking.bookingDate)) ==
            DateFormat('yyyy-MM-dd').format(selectedDate))
        .toList()
      ..sort((a, b) => b.id!.compareTo(a.id!));

    return sortedBookings.isEmpty
        ? _buildNoBookingsUI()
        : ListView.builder(
            itemCount: sortedBookings.length,
            itemBuilder: (context, index) {
              final booking = sortedBookings[index];
              return _buildBookingCard(booking);
            },
          );
  }

  /// **Booking card UI**
  Widget _buildBookingCard(booking) {
    DateTime bookingDate = DateTime.parse(booking.bookingDate);
    String formattedDate = DateFormat('yyyy-MM-dd').format(bookingDate);

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pick-up & Drop-off Points with Bus Icon
            Row(
              children: [
                const Icon(Icons.directions_bus, color: Colors.blue, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationRow(
                          Icons.location_on, 'From:', booking.pickUpPoint),
                      _buildLocationRow(
                          Icons.flag, 'To:', booking.dropOffPoint),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildLocationRow(Icons.calendar_today, 'Date:', formattedDate),
            const SizedBox(height: 8),
            // Fare & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fare: Rs.${booking.totalFare}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                _buildStatusBadge(booking.status),
              ],
            ),
            const SizedBox(height: 8),
            // Delete Button
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => _showDeleteConfirmation(booking.id),
                icon: const Icon(Icons.delete, color: Colors.redAccent),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
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
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
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
    // Implement delete logic here
  }
}
