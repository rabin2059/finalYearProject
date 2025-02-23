import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/user/Passenger/booking%20lists/providers/book_list_provider.dart';
import 'package:frontend/user/authentication/login/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class BookingListScreen extends ConsumerStatefulWidget {
  const BookingListScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _BookingListScreenState();
}

class _BookingListScreenState extends ConsumerState<BookingListScreen> {
  @override
  void initState() {
    final userId = ref.read(authProvider).userId;
    super.initState();
    Future.microtask(
        () => ref.watch(bookListProvider.notifier).fetchBookings(userId!));
  }

  Future<void> getBookings() async {
    final userId = ref.read(authProvider).userId;
    if (userId != null) {
      try {
        await ref.read(bookListProvider.notifier).fetchBookings(userId);
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
        title: const Text('Booking List'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: bookState.loading
            ? _buildLoadingUI()
            : (bookState.books == null || bookState.books!.isEmpty)
                ? _buildNoBookingsUI()
                : ListView.builder(
                    itemCount: bookState.books!.length,
                    itemBuilder: (context, index) {
                      // 🔥 Sort bookings by ID (newest first)
                      final sortedBookings = bookState.books!
                        ..sort((a, b) => b.id!
                            .compareTo(a.id!)); // ✅ Sort by ID (Descending)

                      final booking =
                          sortedBookings[index]; // ✅ Use sorted list
                      return _buildBookingCard(booking);
                    },
                  ),
      ),
    );
  }

  /// 🎨 **Booking Card Design**
  Widget _buildBookingCard(booking) {
    DateTime bookingDate = DateTime.parse(booking.bookingDate);
    DateTime now = DateTime.now();
    bool isPastDate = bookingDate.isBefore(now);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Booking ID & Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  // 'Booking ID: ${booking.id}',
                  "",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(booking.status),
              ],
            ),
            const Divider(),

            // 🔹 Pick-up & Drop-off Points
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'From: ${booking.pickUpPoint}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'To: ${booking.dropOffPoint}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 🔹 Booking Date
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Date: ${DateFormat('yyyy-MM-dd').format(bookingDate)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 🔹 Fare & Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fare: Rs.${booking.totalFare}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 🔥 **Dynamic Button Logic**
                isPastDate
                    ? const SizedBox() // No Button if Date has Passed
                    : _buildActionButton(booking.status, booking.id),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 **Dynamic Action Button Logic**
  Widget _buildActionButton(String status, int bookingId) {
    if (status.toLowerCase() == 'pending') {
      return ElevatedButton(
        onPressed: () {
          print('Pay Now for booking $bookingId');
          // Implement Payment Logic Here
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
        ),
        child: const Text('Pay Now'),
      );
    } else if (status.toLowerCase() == 'confirmed') {
      return ElevatedButton(
        onPressed: () {
          print('Cancel booking $bookingId');
          // Implement Cancellation Logic Here
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
        ),
        child: const Text('Cancel'),
      );
    }
    return const SizedBox(); // No button for other statuses
  }

  /// 🔥 **Status Badge**
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
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 🔥 **Loading UI**
  Widget _buildLoadingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 10),
          Text(
            "Fetching bookings...",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 🔥 **No Bookings UI**
  Widget _buildNoBookingsUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 60, color: Colors.grey),
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
