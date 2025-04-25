import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../../components/AppColors.dart';
import '../../../../components/CustomButton.dart';
import '../../../../core/constants.dart';
import '../../../../core/shared_prefs_utils.dart';
import '../../../../routes/app_router.dart';
import '../providers/bus_details_provider.dart';

class BusDetailScreen extends ConsumerStatefulWidget {
  const BusDetailScreen({super.key, required this.busId});

  final int busId;

  @override
  ConsumerState<BusDetailScreen> createState() => _BusDetailScreenState();
}

class _BusDetailScreenState extends ConsumerState<BusDetailScreen> {
  int? groupId;
  String? groupName;
  double _selectedRating = 0.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  double _averageRating = 0.0;
  int _totalRatings = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(busDetailsProvider.notifier).fetchBusDetail(widget.busId);
      getChatGroup();
      fetchRatings();
    });
  }

  void getChatGroup() async {
    try {
      final url = Uri.parse("$apiBaseUrl/vehicles/${widget.busId}/chatGroup");
      final tokenData = await SharedPrefsUtil.getToken();
      final token = tokenData is Map ? tokenData["token"] : tokenData;
      final header = {
        'Authorization': 'Bearer $token',
      };
      print(token);
      print(url);
      final data = await http.get(url, headers: header);
      print(data.statusCode);
      if (data.statusCode == 200 || data.statusCode == 201) {
        final response = json.decode(data.body);
        final groupData = response['message'];
        groupId = groupData['id'];
        groupName = groupData['name'];
      }
    } catch (e) {
      print(e);
    }
  }

  void fetchRatings() async {
    final driverId = ref.read(busDetailsProvider).vehicle?.owner?.id;
    print("Driver ID for ratings: $driverId");
    if (driverId == null) return;

    final response = await http.get(Uri.parse('$apiBaseUrl/getRating/$driverId'));
    print("Rating fetch status: ${response.statusCode}");
    print("Rating response body: ${response.body}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List ratings = json['result'];
      if (ratings.isEmpty) {
        setState(() {
          _averageRating = 0.0;
          _totalRatings = 0;
        });
        return;
      }
      if (ratings.isNotEmpty) {
        double sum = ratings.fold(0.0, (acc, val) => acc + val['rating']);
        setState(() {
          _averageRating = double.parse((sum / ratings.length).toStringAsFixed(1));
          _totalRatings = ratings.length;
        });
      }
    }
  }

  void _submitReview() async {
    if (_reviewController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    final tokenData = await SharedPrefsUtil.getToken();
    final token = tokenData is Map ? tokenData["token"] : tokenData;
    final driverId = ref.read(busDetailsProvider).vehicle?.owner?.id;

    if (driverId == null) {
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final response = await http.post(
      Uri.parse("$apiBaseUrl/rating"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "driverId": driverId,
        "rating": _selectedRating,
        "review": _reviewController.text.trim(),
      }),
    );

    setState(() {
      _isSubmitting = false;
    });

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Review submitted successfully")),
      );
      _reviewController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit review")),
      );
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busDetailState = ref.watch(busDetailsProvider);

    final vehicle = busDetailState.vehicle;

    int bookedSeatsCount = vehicle?.booking?.where((b) {
          final bookingDate = DateTime.parse(b.bookingDate ?? '');
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          return bookingDate.year == tomorrow.year &&
              bookingDate.month == tomorrow.month &&
              bookingDate.day == tomorrow.day;
        }).fold(
            0, (sum, booking) => sum! + (booking.bookingSeats?.length ?? 0)) ??
        0;

    final seatCount = (vehicle?.vehicleSeat?.length ?? 0) - bookedSeatsCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus Information"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ref.watch(busDetailsProvider).isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBusInfoCard(),
                  SizedBox(height: 16.h),
                  _buildImageGallery(),
                  SizedBox(height: 16.h),
                  _buildDriverDetails(),
                  SizedBox(height: 40.h),
                  CustomButton(
                    text: "Book Seat",
                    onPressed: () => context.pushNamed('/book',
                        pathParameters: {'id': widget.busId.toString()}),
                  ),
                  // --- Rating and Review Section ---
                  SizedBox(height: 20.h),
                  Text("Leave a Review",
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10.h),
                  TextFormField(
                    controller: _reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Write your review',
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      Text("Rating: ", style: TextStyle(fontSize: 14.sp)),
                      RatingBar.builder(
                        initialRating: _selectedRating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          setState(() {
                            _selectedRating = rating;
                          });
                        },
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReview,
                        child: _isSubmitting
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text("Submit"),
                      ),
                    ],
                  ),
                  // --- End Rating and Review Section ---
                  SizedBox(height: 10.h),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (groupId != null && groupName != null) {
            context.pushNamed(
              'chat',
              extra: ChatArgs(groupId!, groupName!),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Chat group not yet loaded. Please wait.')),
            );
          }
        },
        label: Text('Chat'),
        icon: Icon(Icons.chat),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildBusInfoCard() {
    final vehicle = ref.watch(busDetailsProvider).vehicle;

    final bookedSeatsCount = vehicle?.booking?.where((b) {
          final bookingDate = DateTime.parse(b.bookingDate ?? "");
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          return bookingDate.year == tomorrow.year &&
              bookingDate.month == tomorrow.month &&
              bookingDate.day == tomorrow.day;
        }).fold(
            0, (sum, booking) => sum + (booking.bookingSeats?.length ?? 0)) ??
        0;

    final availableSeats =
        (vehicle?.vehicleSeat?.length ?? 0) - bookedSeatsCount;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                radius: 20.r,
                child: const Icon(Icons.directions_bus, color: Colors.blue),
              ),
              SizedBox(width: 10.w),
              Text(
                "Bus No ${vehicle?.vehicleNo ?? 'N/A'}",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text("₹${vehicle?.route?[0].fare ?? 'N/A'}",
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                vehicle?.departure != null
                    ? DateFormat.jm()
                        .format(DateTime.parse(vehicle!.departure!))
                    : 'N/A',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text('-'),
              Text(
                vehicle?.arrivalTime != null
                    ? DateFormat.jm()
                        .format(DateTime.parse(vehicle!.arrivalTime!))
                    : 'N/A',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _buildTag("1:15 h"),
              SizedBox(width: 10.w),
              _buildTag("$availableSeats Seats"),
              const Spacer(),
              _buildRatingTag(_averageRating > 0 ? _averageRating.toString() : "N/A"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverDetails() {
    final owner = ref.watch(busDetailsProvider).vehicle?.owner;

    return Row(
      children: [
        CircleAvatar(
          radius: 30.r,
          backgroundImage: owner?.images != null
              ? NetworkImage(imageUrl + owner!.images!)
              : const AssetImage("assets/profile.png") as ImageProvider,
        ),
        SizedBox(width: 15.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Driver: ${owner?.username ?? 'N/A'}",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            Text(owner?.phone ?? 'N/A',
                style: TextStyle(fontSize: 14.sp, color: Colors.black87)),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () => launchUrl(Uri(scheme: 'tel', path: owner?.phone)),
          icon: const Icon(Icons.call, color: Colors.green, size: 28),
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Image.asset("assets/bus1.png",
                fit: BoxFit.cover, height: 120.h),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child:
                Image.asset("assets/bus.png", fit: BoxFit.cover, height: 120.h),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text(text, style: TextStyle(fontSize: 12.sp)),
    );
  }

  Widget _buildRatingTag(String rating) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text('⭐️ $rating', style: TextStyle(fontSize: 12.sp)),
    );
  }
}
