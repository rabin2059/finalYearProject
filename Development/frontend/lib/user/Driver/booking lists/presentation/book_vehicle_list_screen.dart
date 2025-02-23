import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:frontend/user/Passenger/setting/providers/setting_provider.dart';
import 'package:intl/intl.dart';

import '../../../Passenger/booking lists/providers/book_list_provider.dart';

class BookVehicleListScreen extends ConsumerStatefulWidget {
  const BookVehicleListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BookVehicleListScreenState();
}

class _BookVehicleListScreenState extends ConsumerState<BookVehicleListScreen> {
  @override
  void initState() {
    final vehicleId = ref.read(settingProvider).users[0].vehicleId;
    super.initState();
    Future.microtask(() {
      if (vehicleId != null) {
        ref.watch(bookListProvider.notifier).fetchBookings(vehicleId);
      }
    });
  }

  Future<void> getBookings() async {
    final vehicleId = ref.read(settingProvider).users[0].vehicleId;
    if (vehicleId != null) {
      try {
        await ref.read(bookListProvider.notifier).fetchBookings(vehicleId);
      } catch (e) {
        print('Error fetching bookings: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookState = ref.watch(bookListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings List'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black12,
          
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: bookState.loading
              ? _buildLoadingUI()
              : (bookState.books == null || bookState.books!.isEmpty)
                  ? _buildNoBookingsUI()
                  : ListView.builder(
                      itemCount: bookState.books!.length,
                      itemBuilder: (context, index) {
                        final sortedBookings = bookState.books!
                          ..sort((a, b) => b.id!.compareTo(a.id!));
        
                        final booking = sortedBookings[index];
                        return _buildBookingCard(booking);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(booking) {
    DateTime bookingDate = DateTime.parse(booking.bookingDate);
    String formattedDate = DateFormat('yyyy-MM-dd').format(bookingDate);

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ) ,


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

  Widget _buildLoadingUI() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildNoBookingsUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus, size: 80, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "No bookings found",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
